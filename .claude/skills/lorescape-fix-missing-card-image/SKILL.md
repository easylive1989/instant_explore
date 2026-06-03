---
name: lorescape-fix-missing-card-image
description: Use when the Lorescape daily_story_job failed for a date with "missing IG card content" / "Discord review not posted", or a published daily story shows its text but no cover image in the App. The place has no Wikipedia lead image, so image_url is NULL, the IG card can't render, and the review is never posted. This skill recovers that date.
---

# Lorescape — Fix a daily story missing its card image

> **回覆語言：除技術名詞外，一律用繁體中文回覆使用者。**

## Overview

A daily story rendered no IG card and posted no Discord review because the
place has **no Wikipedia lead image** → `daily_stories.image_url` is `NULL` →
`mapper.build_card_content` returns `None` (`image_url` is a required field) →
`send_today_for_review` hits its "missing IG card content" branch and posts a
failure alert instead of the review card. The same `NULL image_url` is why the
App shows the story text but no cover.

**The fix is one data write (back-fill `image_url`) plus the normal manual
back-fill flow — NOT a re-run of the generator.** Re-running the generator
picks a *different* place and burns a day of runway (see Pitfalls).

This skill MUTATES production (DB write + VPS `docker exec` + a Discord post).
That is the point — it is the recovery counterpart to the read-only
`lorescape-debug` skill. Use `lorescape-debug` first to confirm the diagnosis,
then this skill to fix it.

## When to use

- Discord ops alert: `daily_story_job failed for date YYYY-MM-DD` +
  `Row <uuid> missing IG card content — Discord review not posted`.
- App shows a daily story's title/paragraphs but a blank/missing cover image.
- A `daily_stories` row is `pending` with `discord_message_id = NULL` **and**
  `image_url = NULL`.

**When NOT to use:**
- `discord_message_id` is NULL but `image_url` is **populated** → it's a
  plain stranded-review case; just run the README back-fill (steps 4–5 here),
  no image work needed.
- A *place metadata* field is the NULL one (`card_location_en`, `card_city_ch`,
  `card_city_en`, `latitude`, `longitude`) — same recovery shape, but you patch
  `daily_story_places`, not `image_url`. Confirm in Step 1.
- `review_enabled=False` (config outage) — that's the README's config-recovery
  path, unrelated to images.

## Prerequisites

- Read-only creds + constants from the **`lorescape-debug`** skill
  (`SUPABASE_SERVICE_ROLE_KEY`, Supabase URL, Discord vars). Do not re-derive
  them here.
- SSH to the VPS for the `docker exec` steps: `ssh root@$VPS_HOST`
  (`$VPS_HOST` in session env). Container name: `lorescape-backend`.
- `REVIEW_LANGUAGE` is `zh-TW` on current code → the **zh-TW row is the
  tracked row**. If the deployed commit is older than `663dda8`, the tracked
  row is the `en` row instead — verify deployed sha via `lorescape-debug`
  Step 1 before mutating.

## Recovery procedure

### Step 1 — Confirm `image_url` is the only NULL (read-only)

Pull both today's rows and the joined place row. Every field in
`mapper.build_card_content`'s `string_required` set must be populated **except**
`image_url`; `latitude`/`longitude` checked with `is None` (0.0 is valid).

```bash
TODAY=YYYY-MM-DD
curl -s -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?publish_date=eq.${TODAY}&select=id,language,place_id,image_url,card_title,card_paragraphs,discord_message_id,review_state"
```

Expect: both `en` + `zh-TW` rows, content populated, `image_url: null`,
`discord_message_id: null`, `review_state: pending`. Grab `place_id` and
confirm the place row's `card_*`/lat/long are all set and `used_at` is non-NULL
(generation already consumed this place — good, you will NOT re-pick it).

### Step 2 — Source a cover image (read-only; the choice is a HUMAN decision)

The job only reads the **English Wikipedia REST summary thumbnail**
(`wikipedia.fetch_summary`). When that page has no lead image, every automatic
source usually fails too. Walk the fallback chain and surface candidates with
their **license** — do not silently pick one:

```bash
UA="lorescape-backend/1.0 (https://github.com/easylive1989/instant_explore)"
TITLE='<wikipedia_title_en from place row>'
ENC=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$TITLE")
# a) EN summary thumbnail (what the job uses) — may now exist if it was thin at 09:00
curl -s -H "User-Agent: $UA" "https://en.wikipedia.org/api/rest_v1/page/summary/$ENC" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('thumb',(d.get('thumbnail') or {}).get('source'),'orig',(d.get('originalimage') or {}).get('source'))"
# b) Wikidata P18 (image) and P373 (Commons category)
WD='<wikidata_id e.g. Q65685157>'
curl -s -H "User-Agent: $UA" "https://www.wikidata.org/w/api.php?action=wbgetclaims&entity=$WD&property=P18&format=json"
# c) MediaWiki pageimages, and other-language thumbnails (fr/zh wiki)
curl -s -H "User-Agent: $UA" "https://en.wikipedia.org/w/api.php?action=query&format=json&titles=$ENC&prop=pageimages&piprop=original|thumbnail&pithumbsize=1080&redirects=1"
# d) Commons full-text search for the topic (namespace 6 = files)
curl -s -H "User-Agent: $UA" "https://commons.wikimedia.org/w/api.php?action=query&format=json&list=search&srsearch=<topic>&srnamespace=6&srlimit=10"
```

For any candidate file, fetch `imageinfo` with `iiprop=url|extmetadata` to get
the direct `url` and `LicenseShortName` + `Artist`. Then present the options
(content + size + license) and let the operator choose — using a "thematically
related but not the actual site" image is a content-honesty call that is theirs,
not yours. Record the attribution string for the IG caption.

**Before using the chosen URL, verify it is publicly reachable** (the 21:00
publisher uploads `image_url` to Instagram, which fetches it server-side):

```bash
curl -sI -A "Mozilla/5.0" '<CHOSEN_URL>' | grep -iE "HTTP/|content-type"
# must be HTTP 2?? + content-type: image/*
```

### Step 3 — Back-fill `image_url` on BOTH rows (MUTATION)

Patch by `publish_date` (no language filter) so the App cover is fixed for
**both** locales and the zh-TW row the publisher tracks is ready. The
`image_attribution` column is for licensing provenance (the IG mapper does not
read it, but CC-BY-SA needs attribution in the caption).

```bash
curl -s -X PATCH \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?publish_date=eq.${TODAY}" \
  -d '{"image_url":"<CHOSEN_URL>","image_attribution":"<Artist / Source, License>"}'
```

App cover is fixed immediately (next `fetchLatest`; no deploy/restart).

### Step 4 — Re-post the Discord review (MUTATION, on VPS, idempotent)

Run **only** `send_today_for_review` — never `python -m
lorescape_backend.daily_story <date>` (that re-generates; see Pitfalls). With
`image_url` set, `build_card_content` now succeeds, the card renders, and the
review posts. Idempotent: no-ops if `discord_message_id` is already set.

```bash
ssh root@$VPS_HOST 'docker exec lorescape-backend python -c "
from datetime import date
from lorescape_backend.config import Config
from lorescape_backend.daily_story.job import send_today_for_review
send_today_for_review(Config.from_env(), date.fromisoformat(\"YYYY-MM-DD\"))
print(\"DONE\")
"'
```

Verify the zh-TW row now carries a `discord_message_id` (read-only).

### Step 5 — React, then publish (in that order)

1. A reviewer in `DISCORD_APPROVER_IDS` reacts **✅** on the embed. (The bot's
   own seeded ✅/❌ don't count — `check_reaction` intersects reactor IDs with
   approver IDs; approval wins ties.)
2. If 21:00 Asia/Taipei hasn't passed, the in-process scheduler publishes
   automatically — done. If it already passed (or you want it out now), run the
   publisher manually:

```bash
ssh root@$VPS_HOST 'docker exec lorescape-backend \
  python -m lorescape_backend.social.publisher YYYY-MM-DD'
```

Verify `review_state=published`, `ig_post_id` non-NULL, `publish_error=NULL`.

## Pitfalls

| Pitfall | Reality |
|---|---|
| Running `python -m lorescape_backend.daily_story <date>` to "re-run it" | That entrypoint is `run_generate_and_review` → `run_with_retry` → `pick_next_place`, which picks a **different** unused place (today's is already `used_at`) and inserts a **second** row for the date + burns a day of runway. Use `send_today_for_review` ONLY. |
| Patching only the row in the alert (zh-TW) | The App reads `image_url` per locale; the `en` App user still sees no cover. Patch BOTH rows via the `publish_date` filter. |
| Publishing before anyone reacted ✅ | `check_reaction` returns `none` → row flips to `skipped`, which `_load_pending_rows` excludes → date becomes un-publishable without a manual `review_state` reset. React first, publish second. |
| Back-filling a URL that 404s / isn't a direct image | The IG publish downloads `photo_url`; a bad URL sends the row to `failed` with a traceback in `publish_error`. Always `curl -I` it first (Step 2). |
| Assuming the zh-TW row is tracked | Only true on commits ≥ `663dda8`. On older deployed code the `en` row is tracked — verify deployed sha first. |
| "Fixing" a place field that's legitimately `0.0` | `latitude`/`longitude` use `is None`, so 0.0 (equator/prime meridian) is valid — don't overwrite it. |
| Double publish (cron + manual) | Safe: the publisher filters `review_state='pending'`, so once either path flips the row to `published` the other no-ops. Still, pick one path knowingly and re-check `review_state` before a manual run. |

## Prevention (recurring trap)

~4% of places have no Wikipedia lead image (sampled on the 919-place pool),
≈ once a month. To stop manual recovery, either add an image fallback in
`wikipedia.py` (target-lang thumbnail → Wikidata P18 → Commons), or filter
no-image places in `place_picker` at pick time. Use `lorescape-debug`'s pool
scan to list upcoming no-image places before deciding.
