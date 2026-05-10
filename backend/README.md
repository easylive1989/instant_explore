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

Two supported topologies. Pick whichever fits your VPS layout.

### Option A — system Python + cron (lowest ceremony)

```bash
# On the VPS (assumes a Debian/Ubuntu-style host with python3.11)
sudo mkdir -p /opt/lorescape-backend
sudo chown $USER:$USER /opt/lorescape-backend
git clone https://github.com/easylive1989/instant_explore /tmp/instant_explore
cp -r /tmp/instant_explore/backend/* /opt/lorescape-backend/
cd /opt/lorescape-backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Configure secrets
cp .env.example .env
$EDITOR .env  # fill in real values

# Smoke test (will fail on Wikipedia/Gemini/Supabase if env vars are wrong)
python -m lorescape_backend.daily_story 2030-01-01

# Install the cron schedule
sudo mkdir -p /var/log/lorescape
sudo chown $USER:$USER /var/log/lorescape
crontab -l 2>/dev/null > /tmp/cron.bak || true
cat /opt/lorescape-backend/deploy/crontab.example >> /tmp/cron.bak
crontab /tmp/cron.bak
crontab -l  # verify
```

### Option B — Docker Compose

```bash
# On the VPS
git clone https://github.com/easylive1989/instant_explore /opt/instant_explore
cd /opt/instant_explore/backend
cp .env.example .env
$EDITOR .env  # fill in real values

docker compose up -d --build
docker compose ps
curl http://localhost:8000/health
# Expected: {"status":"ok"}

# Install cron to call the container
crontab -e
# Add the Docker line from deploy/crontab.example
```

### After deployment — manual smoke test

Force a one-off run for tomorrow's date and check Supabase:

```bash
# Option A
cd /opt/lorescape-backend && source .venv/bin/activate
python -m lorescape_backend.daily_story $(date -v+1d +%Y-%m-%d)  # macOS
# or: python -m lorescape_backend.daily_story $(date -d tomorrow +%Y-%m-%d)  # Linux

# Option B
docker exec lorescape-backend python -m lorescape_backend.daily_story $(date -d tomorrow +%Y-%m-%d)
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

If `DISCORD_WEBHOOK_URL` is set in `.env`, all-retries-failed will post a message to the channel. To test the wiring without breaking anything:

```bash
# Run with an intentionally wrong Supabase URL to force failure
SUPABASE_URL=https://invalid.local python -m lorescape_backend.daily_story 2099-01-01
```

You should see the Discord message appear after ~36 seconds (1+5+30 backoff).
