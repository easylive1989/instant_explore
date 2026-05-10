# Lorescape Backend

VPS backend for Lorescape:
- **Daily story cron job** (P2) — generates daily place narratives via Gemini, writes to Supabase
- **FastAPI app** (placeholder) — will host future APIs

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

## Run the cron job manually (for testing)

```bash
python -m lorescape_backend.daily_story         # for tomorrow (default)
python -m lorescape_backend.daily_story 2026-05-15  # for specific date
```

## Run the FastAPI dev server

```bash
uvicorn lorescape_backend.api:app --reload --port 8000
```

---

## Deploying to a VPS

Topology: Docker Compose. The container is on the docker network only — no
host port is published, because the cron job uses `docker exec` and there is
no public HTTP surface yet. When future endpoints need exposure, add a
`ports:` entry to `docker-compose.yml` (or front with nginx) at that point.

### One-time bootstrap (manual, on the VPS)

```bash
ssh root@<your-vps-ip>

git clone https://github.com/easylive1989/instant_explore /opt/lorescape
cd /opt/lorescape/backend

# Configure secrets — required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
# GEMINI_API_KEY. Optional but recommended: DISCORD_WEBHOOK_URL.
cp .env.example .env
$EDITOR .env

# First build + run
docker compose up -d --build
docker compose ps  # api should be Up (healthy)

# Smoke test — verify env vars resolved and SDKs import
docker exec lorescape-backend python -c \
  "from lorescape_backend.config import Config; Config.from_env(); print('config ok')"

# Install crontab
sudo mkdir -p /var/log/lorescape
crontab -l 2>/dev/null > /tmp/cron.bak || true
cat /opt/lorescape/backend/deploy/crontab.example >> /tmp/cron.bak
crontab /tmp/cron.bak
crontab -l  # verify
```

### Subsequent updates (automated by CI)

Once bootstrap is done, every `master` push automatically:

1. SSHes into the VPS via `appleboy/ssh-action`
2. `git fetch && git reset --hard origin/master` in `/opt/lorescape`
3. `docker compose up -d --build` in `backend/`

See the `deploy-backend` job in `.github/workflows/ci.yml`.

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

### Discord webhook (optional but recommended)

If `DISCORD_WEBHOOK_URL` is set in `.env`, all-retries-failed will post a
message to the channel. To test the wiring without breaking anything:

```bash
docker exec -e SUPABASE_URL=https://invalid.local lorescape-backend \
  python -m lorescape_backend.daily_story 2099-01-01
```

You should see the Discord message appear after ~36 seconds (1+5+30 backoff).
