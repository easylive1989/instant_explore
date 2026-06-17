---
name: lorescape-unsplash-images
description: Use after /lorescape-manual-daily-story when the user wants diverse Unsplash images for the generated place — different angles, perspectives, and moods beyond Wikipedia's single cover photo.
---

# Lorescape: Find Diverse Unsplash Images

## Overview

After a daily story draft is generated, this skill finds **5 angle-diverse sets
of Unsplash images** for the same place. Wikipedia's single cover photo is often
a frontal landmark shot; Unsplash lets you pick atmospheric, regional, cultural,
and detail-level perspectives for IG cards and App thumbnails.

**Core principle:** Each angle uses a different search strategy — not five
variations of the same query.

## Input

`/tmp/lorescape_daily_story_draft.json` — written by the `generate` command.
This file must exist before running this skill.

## Workflow

### Step 1 — Extract place context

```bash
python3 -c "
import json
d = json.load(open('/tmp/lorescape_daily_story_draft.json'))
en = d['stories']['en']
print('Place  :', d['wikipedia_title_en'])
print('Location:', en['place_location'])
print('Era    :', en.get('era', ''))
print()
print(en['paragraphs'][0][:400])
"
```

### Step 2 — Derive 5 angle queries

Read the output and compose 5 search queries. Adapt keywords to the ACTUAL place
type — a limestone cave gets different angles than a baroque palace.

| # | Angle | Strategy | Example — Chauvet Cave |
|---|-------|----------|------------------------|
| 1 | **Direct** | Place name exact | `Chauvet Cave` |
| 2 | **Natural environment** | Region + dominant geography | `Ardèche gorge river France` |
| 3 | **Cultural/historical element** | Core subject matter from story | `prehistoric cave painting` |
| 4 | **Atmospheric** | Place + mood adjective | `Chauvet Cave ancient mysterious` |
| 5 | **Broader landmark** | Nearby famous feature or regional alias | `Pont d'Arc natural arch` |

For a palace: detail shot of facade, ornate interior, garden aerial, local
cityscape, night illumination. Tailor angles to WHAT makes this place visually
distinctive.

### Step 3 — Search Unsplash

**Option A — Python script (preferred when UNSPLASH_ACCESS_KEY is available)**

Add `UNSPLASH_ACCESS_KEY=your_key` to `backend/.env` (free demo key from
https://unsplash.com/developers, 50 req/hr), then from `backend/`:

```bash
uv run python -m scripts.unsplash_images              # uses today's date
uv run python -m scripts.unsplash_images --date 2026-06-16
```

Script reads the draft automatically, runs all 5 queries, and saves results to
`backend/outputs/daily_image/{date}/unsplash_results.json` (directory created
automatically).

**Option B — WebSearch fallback (no API key required)**

For each of the 5 queries, call WebSearch with:
```
site:unsplash.com "{query}"
```
Collect any Unsplash photo URLs found and note which angles were well-covered
vs. sparse.

### Step 4 — Present results to user

Group photos by angle. For each photo show:
- Image URL (regular size, `?w=800` for preview)
- Photographer name + link to their Unsplash profile
- Unsplash photo page link (required for attribution)
- One-line note on what perspective this represents

Flag sparse angles (< 2 results) so the user knows to try alternate keywords.

## Quick Reference

| Item | Detail |
|------|--------|
| Draft path | `/tmp/lorescape_daily_story_draft.json` |
| Output path | `backend/outputs/daily_image/{date}/unsplash_results.json` |
| API key env | `UNSPLASH_ACCESS_KEY` in `backend/.env` |
| Free tier | 50 requests/hour (demo key, no credit card needed) |
| Preferred orientation | `landscape` — matches IG card and App thumbnail ratio |
| Results per angle | 5 photos → 25 total to choose from |
| Attribution required | Must credit photographer when publishing |

## Unsplash API Key Setup (one-time)

1. Go to https://unsplash.com/developers → "New Application"
2. Accept guidelines (select "Demo" for non-production)
3. Copy the **Access Key** (public key, safe to put in `.env`)
4. Add to `backend/.env`: `UNSPLASH_ACCESS_KEY=your_access_key`

## Common Issues

- **"No results" for direct query** — The place is too specific for Unsplash.
  Broaden to the city or landmark type (e.g., "cave art France" instead of
  "Chauvet Cave").
- **All photos look the same** — queries are too similar; diversify angle #3-5
  with different subject words.
- **UNSPLASH_ACCESS_KEY not found** — check `backend/.env` has the key with no
  extra spaces; the script also reads it directly from that file.
