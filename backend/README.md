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
  - `publisher` container (`lorescape_backend.social.publisher_bot`, a
    Discord Gateway bot, same image, always connected — no fixed publish
    time):
    - every ~60s, posts a review message with four buttons (✅ 核准 /
      🕘 排程 / 🚀 立即發布 / ❌ 拒絕) for each pending `social_posts` row
      that doesn't have a Discord message yet — carousel slides staged by
      `send_carousel_for_review.py`, or the reel video staged by
      `send_reel_for_review.py` (invoked by `scripts/upload_reel_to_vps.sh`
      after rsync). Reel previews over Discord's ~9.5MB attachment limit
      are transcoded to 720p with `ffmpeg` for review only; the full file
      is still what's published to IG.
    - every ~60s, publishes any row that is both **approved** and whose
      **scheduled time has arrived** (🕘 排程 opens a modal for an
      Asia/Taipei date/time, defaulting to that day's 21:00 but editable
      to anything); a row that's due but not yet approved is left alone
      and gets a one-time nudge in the channel instead of being published.
      🚀 立即發布 approves and publishes immediately, bypassing the
      schedule. Only Discord users listed in `DISCORD_APPROVER_IDS` can
      use the buttons. State machine lives in the `social_posts` table
      (pending → published/failed/rejected, or scheduled in between)
    - `DAILY_STORY_PUBLISH_ENABLED=0` pauses only the scheduled
      auto-publish loop above — the bot stays connected and still posts
      review messages and accepts ✅ 核准 / 🕘 排程 / ❌ 拒絕; 🚀 立即發布
      still publishes immediately even while paused, since it's an
      explicit manual action. There is no `/republish` slash command —
      back-filling a stuck row is a manual Python call to
      `lorescape_backend.social.bot.interactions.republish()` (or, for
      the legacy default-card path, the CLI below).
    - the bot uses `discord.Client` over the Gateway with default
      (non-privileged) intents to receive button/modal interactions — no
      HTTP Interactions Endpoint URL needs configuring in the Developer
      Portal, just invite the bot with permission to send messages /
      attach files in the review channel.

### Wander carousel + reel review (the primary IG path)

`scripts/send_carousel_for_review.py` (run after
`lorescape_backend.social.wander.renderer`) and
`scripts/send_reel_for_review.py` (run by `upload_reel_to_vps.sh` after
rsync) upload the finished slides/video and upsert a clean `pending`
`social_posts` row themselves — they no longer post to Discord directly.
The `publisher` container's bot polls for these rows, posts the buttoned
review message described above, and its scheduler publishes once a row is
both approved and due (or immediately on 🚀 立即發布). ❌ 拒絕, or never
approving, means no post for that day — there is no fallback to the
default card rendering. This is the only path carousels take today, since
carousel style is fixed to wander (2026-07-06 decision); the
`daily_stories`-based default-card path below is a manual-only legacy
fallback and is no longer synced from this flow. See
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
fires the generate job at 09:00 Asia/Taipei, and the `publisher` container
(the `publisher_bot` Discord Gateway bot) stays connected and polls
`social_posts` on a ~60s loop to post review buttons and publish
approved-and-due rows (no fixed publish time). For the reel jobs, create
the media directory once on the host
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
| `DISCORD_BOT_TOKEN` + `DISCORD_REVIEW_CHANNEL_ID` + `DISCORD_APPROVER_IDS` | a private review channel | daily story review embed at 09:00 (legacy default-card path, ✅/❌ reactions); wander carousel + reel review posted with ✅ 核准/🕘 排程/🚀 立即發布/❌ 拒絕 buttons by `publisher_bot`, buttons usable only by `DISCORD_APPROVER_IDS` |

Behaviour when the review-bot keys are missing:
- 09:00 generate still runs and writes rows to `daily_stories` (with
  `discord_message_id = NULL`)
- the review post is **skipped** (logged, but no Discord message is sent)
- running the legacy default-card publish job (`python -m
  lorescape_backend.social.publisher`, see below — it's manual-only, not
  on any schedule) notices `review_enabled=False` and **leaves rows in
  `pending` untouched**; if `DISCORD_WEBHOOK_URL` is set, an alert is
  posted so the operator notices the silent accumulation. The
  `publisher_bot` container itself refuses to start at all without a
  complete review config (`Config.review_enabled` gates its `main()`), so
  `social_posts` rows just accumulate in `pending` with no Discord message
  until the config is fixed and the container is restarted.

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
