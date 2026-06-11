---
name: lorescape-manual-daily-story
description: Use when the user wants to manually generate, review, regenerate, or publish a Lorescape daily story (the server's 08:00 cron is paused via DAILY_STORY_ENABLED=0), pick the next place from daily_story_places, or fix/overwrite a specific date's daily story in Supabase.
---

# Lorescape Manual Daily Story

## Overview

Interactive replacement for the paused daily-story cron: pick a place
from Supabase → generate zh-TW + en stories with Gemini → the user
reviews them **in chat** → regenerate with feedback until satisfied →
only then write to `daily_stories`.

**Core principle: the App has NO review gate.** It shows whatever row
has the newest `publish_date` for the language — `review_state` is only
used by the (paused) Instagram flow. The moment `publish` runs, users
can see the story. Review must finish BEFORE publish, never after.

## The Tool

Everything runs through `backend/scripts/manual_daily_story.py`
(reuses the cron job's own modules: place_picker, wikipedia,
gemini_client, prompts, story_writer). Run from `backend/`:

```bash
uv run python -m scripts.manual_daily_story generate
uv run python -m scripts.manual_daily_story generate --place-title "Alhambra"
uv run python -m scripts.manual_daily_story generate --feedback "第二段太乾，希望更有畫面感"
uv run python -m scripts.manual_daily_story publish              # today
uv run python -m scripts.manual_daily_story publish --date 2026-06-12
```

`generate` writes the draft to `/tmp/lorescape_daily_story_draft.json`
and touches NOTHING in Supabase. `publish` upserts both language rows
(idempotent on publish_date+language) and marks the place used.

## Workflow

1. **Generate.** Run `generate` (add `--place-title` if the user named a
   place). Takes ~1 min (Wikipedia fetch + 2 Gemini calls).
2. **Present for review.** Relay the printed preview to the user —
   both languages, all paragraphs, pull quote, hashtags, and whether a
   cover image exists. Don't summarize the story text; the user is
   reviewing the actual copy.
3. **Iterate.** If the user wants changes, re-run `generate` with their
   feedback verbatim in `--feedback`. The draft file is overwritten each
   time. To switch place, re-run with `--place-title`.
4. **Publish only after explicit approval.** Run `publish` (today) or
   `publish --date YYYY-MM-DD`. The script prints a verification query
   of the written rows — relay it.
5. Remind the user the App shows it immediately.

## Quick Reference

| Fact | Detail |
|---|---|
| Draft location | `/tmp/lorescape_daily_story_draft.json` (no DB writes until publish) |
| Place selection | Unused active place first (oldest `created_at`), then recycles oldest `used_at`; `--place-title` overrides |
| `story` column | Joined `card_paragraphs` (short), NOT the long `paragraphs` — matches the cron job |
| Cover image | Only commercially licensed Wikipedia lead images (CC0/CC BY/CC BY-SA); otherwise NULL — see lorescape-fix-missing-card-image skill |
| Overwriting a date | `publish --date X` upserts, so re-publishing the same date replaces it |
| `review_state` | Left at default `pending`; harmless while the IG publish job is paused |
| Languages | Always both `zh-TW` and `en` (App queries per language) |

## Gotchas

- **GOOGLE_API_KEY shadowing:** the google-genai SDK prefers
  `GOOGLE_API_KEY` over `GEMINI_API_KEY` when both are set, and this
  machine's `GOOGLE_API_KEY` is NOT a Gemini key → 400 "API key not
  valid". The script pops it from the env; if you call the modules
  directly in ad-hoc Python, do the same.
- **Don't publish an unreviewed draft.** Even if the user seems in a
  hurry — generation costs seconds to redo; an unreviewed story going
  live in the App does not. Get an explicit "可以/通過/發布" first.
- **Gemini 503 "high demand"** happens in spikes; just re-run generate
  after a minute. Quota resets daily (Pacific midnight).
- **`mark_place_used` only runs on publish**, so abandoned drafts don't
  burn the place rotation.

## When NOT to Use

- Diagnosing why a past story is missing/broken → use the
  lorescape-debug skill (read-only) first.
- A published story missing only its cover image → use
  lorescape-fix-missing-card-image.
- Re-enabling the automatic pipeline → set `DAILY_STORY_ENABLED=1` on
  the VPS and restart the container instead.
