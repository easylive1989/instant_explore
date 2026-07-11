# Lorescape Publisher

Standalone social-publishing project for Lorescape, split out of `backend/`
on 2026-07-11 (see `docs/adr/0004-split-social-publisher-from-backend.md`).
Runs the daily-story pipeline, a Discord Gateway review bot, and Instagram
publishing (wander carousel + reel). The mobile-app-facing narration/
subscriptions API stays in `backend/`.

## Architecture

- **`daily_story/`** — generates the day's place story (Gemini + Wikipedia)
  and posts it to Discord for review (`python -m lorescape_publisher.daily_story`).
- **`bot.py` + `bot_flows/`** — `PublisherBot`, a `discord.Client` connected
  to the Gateway (no fixed publish time, no host-side cron). Polls
  `social_posts` on a ~60s loop:
  - posts a review message with four buttons (✅ 核准 / 🕘 排程 / 🚀 立即發布 /
    ❌ 拒絕) for each pending row that doesn't have a Discord message yet —
    carousel slides staged by `scripts/send_carousel_for_review.py`, or a
    reel video staged by `scripts/send_reel_for_review.py`;
  - publishes any row that is both **approved** and whose **scheduled time
    has arrived** (🕘 排程 opens a modal for an Asia/Taipei date/time); 🚀
    立即發布 approves and publishes immediately, bypassing the schedule.
  - only Discord users in `DISCORD_APPROVER_IDS` can use the buttons.
  - state machine lives in the `social_posts` table (pending →
    published/failed/rejected, or scheduled in between).
  - `DAILY_STORY_PUBLISH_ENABLED=0` pauses only the scheduled auto-publish
    loop — the bot stays connected and still posts review messages and
    accepts ✅/🕘/❌; 🚀 立即發布 still works even while paused.
- **`card/`, `wander/`** — IG image rendering: the legacy single-card
  template (`card/`) and the current wander-style carousel (`wander/`,
  fixed style since 2026-07-06 — see
  `.claude/skills/lorescape-wander-carousel/SKILL.md`).
- **`reel_publisher.py`, `instagram.py`** — IG Reels / Graph API publishing.
- **`story_prompt.py`, `genai.py`** — deliberately duplicated from
  `backend/src/lorescape_backend/shared/` (not shared as a library). See
  ADR 0004 for why; changes to either file need manual review of whether the
  other copy should follow.

## Local development

```bash
cd publisher
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env  # then fill in real values — see below
pytest
```

Run the bot locally:

```bash
cd publisher && uv run python -m lorescape_publisher.bot
```

Run the daily-story job manually (for testing / back-fill):

```bash
cd publisher && uv run python -m lorescape_publisher.daily_story             # defaults to today
cd publisher && uv run python -m lorescape_publisher.daily_story 2026-05-15  # for a specific date
```

## `.env`

See `publisher/.env.example` for the full list. In short:
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — required.
- `GEMINI_API_KEY` (or `GEMINI_BACKEND=vertex` + `GOOGLE_CLOUD_PROJECT` /
  service account) — required for daily-story generation.
- `DISCORD_BOT_TOKEN`, `DISCORD_REVIEW_CHANNEL_ID`, `DISCORD_APPROVER_IDS` —
  required for the review bot; missing any of these makes
  `Config.review_enabled` false and the bot refuses to start (`main()`
  raises `SystemExit`).
- `IG_USER_ID`, `META_PAGE_ACCESS_TOKEN` — required for publishing to
  Instagram (obtain via `scripts/meta_token_helper.py --platform instagram`).
- `BRAND_HANDLE_IG` — used in captions.
- `DAILY_VIDEO_DIR` — set by `docker-compose.yml` to the container path of
  the bind-mounted reel media volume; only set it locally for local reel runs.

`scripts/` (the six publish-related CLIs: `publish_reel.py`,
`send_carousel_for_review.py`, `send_reel_for_review.py`,
`daily_video_post.py`, `manual_daily_story.py`, `archive_ig_cards.py`) reads
this `publisher/.env` too — its `pyproject.toml` path-depends on `publisher`,
not `backend`.

## Deploying to a VPS

Independent Docker Compose project, independent image (`lorescape-publisher`),
independent from `backend/`'s compose project. Deployed via GitHub Actions
`deploy-publisher.yml` (`workflow_dispatch`).

**First-time VPS migration is manual** — see
`docs/adr/0004-split-social-publisher-from-backend.md` for the full
step-by-step (building `publisher/.env` out of the old combined
`backend/.env`, copying `service-account.json` if using Vertex, deploy
ordering). In short: run `Deploy Backend` first (its
`--remove-orphans` clears any stale pre-split publisher container), complete
the manual `.env` migration, then run `Deploy Publisher`.

`docker-compose.yml` bind-mounts `/opt/lorescape-media/daily_video:/media/daily_video:ro`
— create that directory once on the host
(`mkdir -p /opt/lorescape-media/daily_video`) before the first deploy; it's
rsynced into by `scripts/upload_reel_to_vps.sh` from the operator's machine.
