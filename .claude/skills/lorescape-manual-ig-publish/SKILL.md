---
name: lorescape-manual-ig-publish
description: Use when the user wants to publish today's (or a specific date's) daily story to Instagram — renders the IG card, builds the caption, presents both for review in chat, then publishes via Meta Graph API after explicit approval.
---

# Lorescape Manual IG Publish

## Overview

Replaces the paused 21:00 cron for Instagram publishing. The daily story
must already be in `daily_stories` (run `/lorescape-manual-daily-story`
first). Claude previews the card and caption in chat, waits for approval,
then publishes.

**Prerequisite:** The zh-TW daily story row must exist for the target date,
AND `daily_story_places` must have `card_location_en`, `card_city_ch`,
`card_city_en`, `latitude`, `longitude` for the place — otherwise the card
can't render and IG is skipped.

## The Tool

Run from `backend/`:

```bash
uv run python -m scripts.manual_ig_publish preview               # today
uv run python -m scripts.manual_ig_publish preview --date 2026-06-17
uv run python -m scripts.manual_ig_publish publish               # today
uv run python -m scripts.manual_ig_publish publish --date 2026-06-17
```

`preview` — renders card to `/tmp/lorescape_ig_card_{date}.png`, prints
full caption. No DB or IG writes.

`publish` — renders card → uploads PNG to Supabase storage (`ig-cards`
bucket) → posts to Instagram via Meta Graph API (2-step: container +
publish) → updates `daily_stories` row to `review_state=published`.

## Workflow

### Step 1 — Preview

```bash
uv run python -m scripts.manual_ig_publish preview
```

Relay to the user:
- Card path (they can open `/tmp/lorescape_ig_card_{date}.png` to view)
- Full caption text (character count)
- Any WARNING about missing card fields

### Step 2 — Review in chat

Present the caption in full. Let the user read it. If the card renders,
note the path so they can open it locally.

**Caption tweaks:** The caption is derived from the `daily_stories` row
(place_name, era, story, hashtags). If the user wants to tweak wording,
update the relevant fields in Supabase directly, then re-run `preview`.

### Step 3 — Publish after explicit approval

Only after "可以" / "發布" / "ok" / "yes":

```bash
uv run python -m scripts.manual_ig_publish publish
```

Relay the result: `ig_post_id` + confirmation that the DB row is updated.

## Quick Reference

| Fact | Detail |
|------|--------|
| Prerequisite | zh-TW daily_story row exists for the date |
| Card fields needed | `daily_story_places`: card_location_en, card_city_ch, card_city_en, latitude, longitude |
| Card size | 1080×1350 px (4:5 portrait, Chinese-only layout) |
| Card preview | `/tmp/lorescape_ig_card_{date}.png` |
| Caption limit | 2200 chars (story body truncated if needed; hashtags/footer always kept) |
| Image hosting | Supabase storage `ig-cards/{date}/{row_id}.png` (public URL for Meta) |
| IG API | 2-step: create container → 5s delay → publish |
| DB update | `review_state=published`, `ig_post_id=<id>` on zh-TW row only |
| Idempotent? | Yes — `publish` overwrites if re-run (upsert on storage, new IG post each time) |

## Common Issues

- **Card content incomplete** — `daily_story_places` is missing location
  fields for this place. Fill them in Supabase, then retry.
- **Instagram not configured** — `IG_USER_ID` or `META_PAGE_ACCESS_TOKEN`
  missing from `backend/.env`. Check `.env.example` for the required vars.
- **Meta API 400** — Token may be expired; long-lived tokens last ~60 days
  after last refresh. Regenerate via `scripts/meta_token_helper.py`.
- **Image URL not reachable** — Meta fetches the image from Supabase
  storage; if the bucket isn't public, publishing fails. Check bucket
  permissions in Supabase dashboard.
