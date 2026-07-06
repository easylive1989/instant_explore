# Lorescape Backend

VPS backend for Lorescape. Generates Wikipedia-grounded place stories with
Gemini and serves them to the app, plus runs the daily-story / social pipeline.

- **Narration API** — the FastAPI app exposes the on-demand story endpoints the
  mobile app calls:
  - `POST /narration/hooks` — return 2–3 story angles (title + teaser) for a place
  - `POST /narration` — expand a chosen angle into a full 3-paragraph story,
    grounded on Wikipedia, for TTS playback
  - `GET /health` — health check
- **Daily story scheduler** — split across two containers, both in
  Asia/Taipei, no host-side cron:
  - `api` container (FastAPI + APScheduler):
    - `09:00` — generate the day's story and post it to Discord for review
    - `03:00` — reconcile subscriptions against RevenueCat
  - `publisher` container (`lorescape_backend.social.publisher_daemon`,
    same image):
    - `21:00` — read the story review's ✅/❌ and publish the carousel to IG
    - `21:10` / `23:10` — read the reel review's ✅/❌ (its own Discord
      message, independent of the carousel's) and publish the day's reel
      video from `/opt/lorescape-media/daily_video/<date>/`. The video +
      review are submitted by `scripts/upload_reel_to_vps.sh` on the
      operator's machine; state machine lives in the `social_posts` table
      (pending → published/failed/rejected/skipped; still-unreacted at
      23:10 → skipped)

### Pre-rendered (wander-style) carousel

If `scripts/send_carousel_for_review.py` staged a pre-rendered carousel for
the day (a `social_posts` carousel row with non-NULL `slide_urls`), the
21:00 job publishes exactly those images gated by ✅/❌ on that review
message, and the default card rendering is skipped for the day. ❌ or no
reaction means no carousel that day (no fallback). The day's
`daily_stories` row is synced to the same terminal state. See
`.claude/skills/lorescape-wander-carousel/SKILL.md` for the operator flow
and `docs/superpowers/specs/2026-07-06-wander-carousel-style-design.md`
for the design.

See `docs/superpowers/specs/2026-05-10-daily-place-story-design.md` for the full spec.

## Local development

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env  # then fill in real values
pytest
```

## Run the daily story job manually (for testing / back-fill)

```bash
python -m lorescape_backend.daily_story             # defaults to today
python -m lorescape_backend.daily_story 2026-05-15  # for a specific date
```

`send_today_for_review` is idempotent — once a row's `discord_message_id` is
set, re-running won't re-post.

## Run the FastAPI dev server (with the scheduler attached)

```bash
uvicorn lorescape_backend.api:app --reload --port 8000
```

The scheduler will start in the background. Manually-triggered jobs via the
CLI above run independently of the in-process scheduler.

---

## Deploying to a VPS

Topology: Docker Compose. The container is on the docker network only — no
host port is published, because the scheduler runs in-process and there is no
public HTTP surface yet. When future endpoints need exposure, add a `ports:`
entry to `docker-compose.yml` (or front with nginx) at that point.

### One-time bootstrap (manual, on the VPS)

```bash
ssh root@<your-vps-ip>

git clone https://github.com/easylive1989/instant_explore /opt/lorescape
cd /opt/lorescape/backend

# Configure secrets. See .env.example for the full list; in short:
#   Required for generation:  SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
#                             GEMINI_API_KEY
#   Required for review flow: DISCORD_BOT_TOKEN, DISCORD_REVIEW_CHANNEL_ID,
#                             DISCORD_APPROVER_IDS
#   Required for publishing:  IG_USER_ID, META_PAGE_ACCESS_TOKEN
#   Optional failure alerts:  DISCORD_WEBHOOK_URL
# Missing any "required for review/publish" key silently degrades that stage.
cp .env.example .env
$EDITOR .env

# First build + run. The container starts the scheduler immediately.
docker compose up -d --build
docker compose ps  # api should be Up (healthy)

# Smoke test — verify env vars resolved and SDKs import
docker exec lorescape-backend python -c \
  "from lorescape_backend.config import Config; Config.from_env(); print('config ok')"
```

That's it. No crontab, no `docker exec` from outside — the `api` container
fires the generate job at 09:00, and the `publisher` container fires the
carousel publish at 21:00 plus the reel publish at 21:10/23:10, all in
Asia/Taipei. For the reel jobs, create the media directory once on the host
(`mkdir -p /opt/lorescape-media/daily_video`) — it is bind-mounted read-only
into the publisher container.

### Subsequent updates (automated by CI)

The `deploy-backend` job runs every **Friday at 02:00 UTC (10:00 Asia/Taipei)**
on the `.github/workflows/deploy.yml` cron, and can also be triggered manually
from the GitHub Actions UI (`workflow_dispatch`). When it runs it:

1. SSHes into the VPS via `appleboy/ssh-action`
2. `git fetch && git reset --hard origin/master` in `/opt/lorescape`
3. `docker compose up -d --build` in `backend/` (which rebuilds the
   container, which restarts the scheduler with the new code)

Plain `master` pushes only run CI (lint + unit tests); they do **not** deploy.
If you need a deploy outside the weekly window, trigger the workflow manually.

Required GitHub secrets:
- `VPS_HOST` — VPS IP or hostname
- `VPS_USER` — SSH user (e.g. `root`)
- `VPS_SSH_KEY` — SSH private key with permission to write `/opt/lorescape`

### After deployment — manual smoke test

Force a one-off run for tomorrow's date and check Supabase:

```bash
docker exec lorescape-backend python -m lorescape_backend.daily_story \
  $(date -d tomorrow +%Y-%m-%d)
```

Then in Supabase Dashboard SQL Editor:

```sql
SELECT publish_date, language, place_name, era, length(story) AS story_len
FROM public.daily_stories
ORDER BY publish_date DESC, language
LIMIT 4;
```

Expected: two rows (`zh-TW` + `en`) for tomorrow's date with `story_len` ≈ 300-500.

### Discord wiring

There are **two independent Discord channels** the backend talks to:

| Variable | Channel | Used for |
| --- | --- | --- |
| `DISCORD_WEBHOOK_URL` (optional) | any text channel via webhook | failure alerts after all retries (`discord_notify`) |
| `DISCORD_BOT_TOKEN` + `DISCORD_REVIEW_CHANNEL_ID` + `DISCORD_APPROVER_IDS` | a private review channel | daily review embed at 09:00, ✅/❌ reactions read at 21:00 |

Behaviour when the review-bot keys are missing:
- 09:00 generate still runs and writes rows to `daily_stories` (with
  `discord_message_id = NULL`)
- the review post is **skipped** (logged, but no Discord message is sent)
- 21:00 publish notices `review_enabled=False` and **leaves rows in `pending`
  untouched**; if `DISCORD_WEBHOOK_URL` is set, an alert is posted so the
  operator notices the silent accumulation

Once the operator fixes the config, the rows are NOT auto-published — they
must be back-filled manually. Per stranded date `YYYY-MM-DD`:

```bash
# 1. Post the review embed to Discord (populates discord_message_id)
docker exec lorescape-backend python -c "
from datetime import date
from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import send_today_for_review
send_today_for_review(Config.from_env(), date.fromisoformat('YYYY-MM-DD'))
"

# 2. React ✅ (or ❌) on the embed in the review channel.

# 3. Run the publisher for that date.
docker exec lorescape-backend \
  python -m lorescape_backend.social.publisher YYYY-MM-DD
```

The same flow recovers any row that ended up in `pending` with a NULL
`discord_message_id` for other reasons (e.g. the 09:00 Discord post failed).

To smoke-test the failure webhook without affecting today's data:

```bash
docker exec -e SUPABASE_URL=https://invalid.local lorescape-backend \
  python -m lorescape_backend.daily_story 2099-01-01
```

You should see the failure message appear after ~36 seconds (1+5+30 backoff).

To smoke-test the review bot:

```bash
docker exec lorescape-backend python -c "
from datetime import date
from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import send_today_for_review
config = Config.from_env()
print('review_enabled =', config.review_enabled)
send_today_for_review(config, date.today())
"
```

If `review_enabled` prints `True` and an embed appears in the review channel
with ✅/❌ pre-seeded, the bot is wired correctly.
