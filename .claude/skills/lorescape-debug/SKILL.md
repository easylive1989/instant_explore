---
name: lorescape-debug
description: Use when debugging the Lorescape daily-story pipeline — diagnosing today's review/publish state, why a Threads/IG post didn't go out, scheduler or timezone drift, what commit is deployed on the VPS, mismatches between Supabase rows and the Discord review message, or inspecting sync tables (journey_entries / quick_guide_entries / trips / saved_locations). Strictly read-only.
---

# Lorescape Debug (production)

Diagnose production state for the daily-story pipeline and sync tables by reading Supabase (PostgREST) + Discord (Bot REST) + GitHub Actions. **Strictly read-only.**

## Read-only contract

NEVER do any of the following from this skill:

- `POST` / `PATCH` / `DELETE` against PostgREST
- Discord `POST` / `PATCH` / `PUT` / `DELETE` (no new messages, no edits, no reactions added/removed)
- `gh workflow run` against `deploy.yml` (deploy is the user's decision)
- `psql` against prod (we don't have / want the DB password)
- Echo a secret env-var value to output — length-check only

If a change is needed, write a one-line plan and ask the user to run it.

## Prerequisites

Set these four env vars before running any recipe. The user sets them via Claude Code's `!` prefix in the input box (so they stay in the session shell, not in any file):

```
! export SUPABASE_SERVICE_ROLE_KEY='...'
! export DISCORD_BOT_TOKEN='...'
! export DISCORD_REVIEW_CHANNEL_ID='...'
! export DISCORD_APPROVER_IDS='123,456,789'
```

| Env var | Used for | How to obtain |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | PostgREST queries (bypasses RLS) | Supabase Dashboard → Project Settings → API → `service_role` (secret) |
| `DISCORD_BOT_TOKEN` | Discord REST | Same token VPS uses (VPS `.env`) |
| `DISCORD_REVIEW_CHANNEL_ID` | Channel scoping | VPS `.env` |
| `DISCORD_APPROVER_IDS` | Reaction vote weighting | VPS `.env` (comma-separated) |

Verify (length-check only, never echo values):

```bash
for v in SUPABASE_SERVICE_ROLE_KEY DISCORD_BOT_TOKEN DISCORD_REVIEW_CHANNEL_ID DISCORD_APPROVER_IDS; do
  val="${!v}"
  if [ -z "$val" ]; then echo "$v: NOT SET"; else echo "$v: SET (len=${#val})"; fi
done
```

If any reports NOT SET, ask the user to export it before proceeding.

## Constants

```
SUPABASE_URL=https://ymndmrefqprhtjxhgsei.supabase.co
PROJECT_REF=ymndmrefqprhtjxhgsei
DISCORD_API=https://discord.com/api/v10
APPROVE_EMOJI=✅   (URL-encoded: %E2%9C%85)
REJECT_EMOJI=❌    (URL-encoded: %E2%9D%8C)
```

PostgREST always needs both auth headers:

```bash
-H "apikey: $SUPABASE_SERVICE_ROLE_KEY"
-H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

Discord always needs:

```bash
-H "Authorization: Bot $DISCORD_BOT_TOKEN"
```

## Today's daily-story health check

When the user asks "今天 daily story 狀態 OK 嗎 / 會正常發嗎 / 為什麼沒發", walk these 8 steps in order. Stop and report as soon as a step reveals the blocker.

### Step 1 — What commit is the VPS running?

```bash
gh run list --workflow=deploy.yml --limit 3 \
  --json conclusion,headSha,event,createdAt \
  --jq '.[] | "\(.createdAt) \(.event) \(.conclusion) \(.headSha[:7])"'
```

VPS = headSha of the **most-recent `success`**. A failed `schedule` run on Friday means the weekly auto-deploy didn't land; look for a later `workflow_dispatch` success.

### Step 2 — What's not yet deployed?

```bash
DEPLOYED_SHA=<sha-from-step-1>
git log "$DEPLOYED_SHA..HEAD" --oneline -- backend/ supabase/
```

If a `feat(review)` / `feat(publisher)` commit is undeployed, the publisher behavior on VPS may differ from `master`. See Gotchas → "REVIEW/PUBLISH language depends on deployed commit".

### Step 3 — Today's rows exist & are populated?

```bash
TODAY=$(date -u +%F)
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?publish_date=eq.${TODAY}&select=id,language,place_name,review_state,discord_message_id,threads_summary,hashtags,card_title_ch,card_paragraphs_ch,reviewed_at,published_at,threads_post_id,ig_post_id,publish_error,created_at"
```

Check:
- Both `en` and `zh-TW` rows exist
- `review_state` per row (pending / published / rejected / skipped / failed)
- **Which** row has `discord_message_id` — that's the row the deployed publisher will track. Cross-check with Step 1's deployed commit (see Gotchas).
- `threads_summary` + `hashtags` populated on whichever row will feed Threads
- `card_title_ch` + `card_paragraphs_ch` populated on the zh-TW row (IG card source)

### Step 4 — Place metadata complete?

Extract `place_id` from Step 3, then:

```bash
PLACE_ID=<place_id-from-step-3>
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_story_places?id=eq.${PLACE_ID}&select=name,is_active,used_at,card_location_en,card_city_ch,card_city_en,latitude,longitude"
```

IG card needs `card_location_en`, `card_city_ch`, `card_city_en`, `latitude`, `longitude` all NOT NULL. If any is NULL, IG publish will skip with `publish_error="ig_skipped_missing_card_content"`. `used_at` must be set (otherwise tomorrow re-picks the same place).

### Step 5 — Discord review message exists?

Get `MESSAGE_ID` from whichever row in Step 3 carries `discord_message_id`:

```bash
MESSAGE_ID=<discord_message_id>
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "https://discord.com/api/v10/channels/${DISCORD_REVIEW_CHANNEL_ID}/messages/${MESSAGE_ID}" \
  | python3 -c "import sys,json; m=json.load(sys.stdin); print('posted_at:', m['timestamp']); print('reactions:', [(r['emoji']['name'], r['count']) for r in m.get('reactions',[])])"
```

`404` here means message was deleted or `discord_message_id` is stale.

### Step 6 — How will reactions be counted?

Fetch reactors per emoji, intersect with `DISCORD_APPROVER_IDS`:

```bash
APPROVERS=$(echo "$DISCORD_APPROVER_IDS" | tr ',' ' ')
for emoji_url in "%E2%9C%85:APPROVE" "%E2%9D%8C:REJECT"; do
  url="${emoji_url%:*}"; label="${emoji_url##*:}"
  reactors=$(curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
    "https://discord.com/api/v10/channels/${DISCORD_REVIEW_CHANNEL_ID}/messages/${MESSAGE_ID}/reactions/${url}?limit=100" \
    | python3 -c "import sys,json; print(' '.join(u['id'] for u in json.load(sys.stdin)))")
  matched=""
  for r in $reactors; do
    for a in $APPROVERS; do [ "$r" = "$a" ] && matched="$matched $r"; done
  done
  echo "$label reactors=$reactors  approver-matches:$matched"
done
```

Predict the 21:00 verdict per `discord_review.check_reaction`:
- Any approver in APPROVE matches → `approved` → will publish
- No APPROVE match but an approver in REJECT matches → `rejected`
- Neither → `skipped`
- Remember: Bot's own ✅+❌ seeds do NOT match approver IDs and are ignored.

### Step 7 — Recent failures or stuck rows?

```bash
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?or=(review_state.eq.failed,publish_error.not.is.null)&order=publish_date.desc&limit=10&select=publish_date,language,review_state,publish_error,threads_post_id,ig_post_id"
```

`threads_skipped_missing_en_row` / `ig_skipped_missing_card_content` are recoverable design choices, not crashes. Anything else = real failure with traceback in `publish_error`.

### Step 8 — Scheduler timezone drift?

```bash
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?language=eq.en&order=publish_date.desc&limit=7&select=publish_date,created_at,reviewed_at"
```

Interpret the hours-of-day:

| `created_at` UTC | `reviewed_at` UTC | State |
|---|---|---|
| ~01:00 | ~13:00 | ✅ Timezone fix is live; cron fires at 09:00 / 21:00 Asia/Taipei as intended |
| ~09:00 | ~21:00 | ⚠️ Pre-tzdata-fix regime; cron fires at 17:00 / 05:00 Asia/Taipei (8h drift) |
| Mixed / other | | Investigate — restart timing or partial deploy |

## Individual recipes

### Latest successful deploy + headSha

```bash
gh run list --workflow=deploy.yml --limit 5 \
  --json conclusion,headSha,createdAt,event \
  --jq '.[] | select(.conclusion=="success") | "\(.createdAt) \(.event) \(.headSha[:7])"' | head -1
```

### Single daily-story row by date + language

```bash
DATE=2026-05-24; LANG=zh-TW
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?publish_date=eq.${DATE}&language=eq.${LANG}&select=*"
```

### Daily-story history scan

```bash
curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_stories?language=eq.en&order=publish_date.desc&limit=14&select=publish_date,review_state,threads_post_id,ig_post_id,publish_error"
```

### Pickable places remaining

```bash
curl -sD - -o /dev/null \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Prefer: count=exact" -H "Range-Unit: items" -H "Range: 0-0" \
  "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/daily_story_places?is_active=eq.true&used_at=is.null&select=id" \
  | grep -i content-range
```

`Content-Range: 0-0/<N>` — N is the number of unused active places (≈ days of runway).

### Sync table row counts

```bash
for t in journey_entries quick_guide_entries trips saved_locations; do
  count=$(curl -sD - -o /dev/null \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Prefer: count=exact" -H "Range-Unit: items" -H "Range: 0-0" \
    "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/${t}?select=user_id" \
    | grep -i content-range | tr -d '\r' | sed 's/.*\///')
  echo "$t: $count"
done
```

### Per-user sync data

```bash
USER_ID=<uuid>
for t in journey_entries quick_guide_entries trips saved_locations; do
  echo "=== $t for $USER_ID ==="
  curl -s \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    "https://ymndmrefqprhtjxhgsei.supabase.co/rest/v1/${t}?user_id=eq.${USER_ID}&order=updated_at.desc&limit=5"
done
```

### Discord channel — recent messages

```bash
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "https://discord.com/api/v10/channels/${DISCORD_REVIEW_CHANNEL_ID}/messages?limit=10" \
  | python3 -c "import sys,json; [print(m['id'], m['timestamp'], (m.get('embeds') or [{}])[0].get('title','')[:60]) for m in json.load(sys.stdin)]"
```

## Gotchas (latent knowledge)

- **REVIEW/PUBLISH language depends on deployed commit.** Commits up to `56df37e` use `REVIEW_LANGUAGE = "en"` and `PUBLISH_LANGUAGE = "en"` → `discord_message_id` lives on the en row; en row carries `review_state` transitions; zh-TW row is just content. From `663dda8` onward both flip to `"zh-TW"`. Always check Step 1's deployed sha before assuming which row to look at. Cross-reference by running `git show <sha>:backend/src/lorescape_backend/social/publisher.py | grep PUBLISH_LANGUAGE`.

- **Discord bot auto-seeds ✅ and ❌** as click-target buttons every time it posts a review (`_add_self_reaction` in `discord_review.py`). Raw counts always start at 1/1; real votes are reactor user IDs ∩ `DISCORD_APPROVER_IDS`. Never read raw `count` to decide outcome — always list reactors and intersect.

- **"Approval wins ties."** In `check_reaction()`, if any approver clicked ✅, the row publishes even if other approvers clicked ❌. Don't tell the user a row will be rejected just because ❌ has more reactions; check ✅ first.

- **Scheduler timezone bug (pre-tzdata fix).** `python:3.11-slim` ships without `/usr/share/zoneinfo`, so APScheduler's `timezone="Asia/Taipei"` silently falls back to UTC and cron fires 8h off (generate at 17:00 Taipei, publish at 05:00 next-day Taipei). Fix is in Dockerfile (`apt install tzdata` + `ENV TZ`). Use Step 8 to detect which regime is live before predicting publish time.

- **zh-TW row stays `pending` forever in old-publisher regime.** Not a bug — old `_load_pending_rows` filters by `language="en"`, so zh-TW row never receives state updates. After 663dda8 deploys, zh-TW becomes the tracked row instead.

- **`date.today()` is UTC inside container until tzdata fix lands.** A publish job firing at 21:00 UTC on 2026-05-24 still reads `date.today() == 2026-05-24` because 21:00 UTC is still the 24th. Don't get confused by clock-vs-date interaction when reasoning about which row a job picks.

- **`place_picker.mark_place_used` can lag row insert by tens of minutes.** Observed: rows inserted 09:00:27 UTC, used_at set 09:45:45 UTC. Probably retry-related; not a correctness issue as long as `used_at` ends up non-NULL. If it stays NULL, the same place gets re-picked.

- **`passport_entries` and `daily_usage` are dropped.** If the user asks about them, point at migration `20260510000002_drop_unused_tables.sql`.

## Anti-patterns

- **No mutations.** If diagnosis ends with "the fix is to update X", write the curl/SQL the user would run and hand it to them — don't run it yourself.
- **No `psql`.** We don't have the DB password and don't want it; PostgREST + service-role key covers every read we need.
- **No deploy.** Never run `gh workflow run deploy.yml`. If a fix needs deploy, say so and stop.
- **No echoing secrets.** Length-check env vars; don't print their values to chat or any file.
- **No guessing.** If Step 1 fails (e.g. `gh` not auth'd), say so and stop — don't invent a deployed commit.
