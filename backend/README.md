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

(Deployment instructions live further down — added in Task 12.)
