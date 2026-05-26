# Daily Story Card Unification — Deploy & Verification Checklist

**Related:**
- Plan: `docs/superpowers/plans/2026-05-25-daily-story-card-unification.md`
- Spec: `docs/superpowers/specs/2026-05-25-daily-story-card-unification-design.md` (esp. §8 deploy order, §11 manual checklist)

## Deploy order (operator runs this after PR merge)

- [ ] 1. Merge PR to `master` (code shipped, not yet deployed)
- [ ] 2. Run migration on prod Supabase:
       `supabase migration up --linked`  (or via Dashboard SQL editor)
- [ ] 3. Immediately deploy backend to VPS (within seconds of step 2):
       `ssh vps "cd lorescape-backend && git pull && systemctl restart lorescape-backend"`
       (or whatever the VPS deploy command is for this project)
- [ ] 4. Backfill dry-run from local:
       `cd backend && uv run python -m scripts.backfill_card_fields --dry-run`
       confirm expected row count (zh-TW rows pre-20260521 + all en rows)
- [ ] 5. Backfill real run:
       `cd backend && uv run python -m scripts.backfill_card_fields`
       capture log; verify summary `processed=N failed=0`
- [ ] 6. Admin: in Supabase Dashboard, fill any new `daily_story_places` rows
       that are missing `card_location_en` / `card_city_ch` / `card_city_en` /
       `latitude` / `longitude`
- [ ] 7. Trigger one IG card publish manually (or wait for 21:00 cron) and
       confirm the IG card still renders correctly
- [ ] 8. App: ship new version to TestFlight / Play internal track
       - [ ] zh-TW locale → see new card layout (title / subtitle / drop-cap /
              3 paragraphs / pull quote / Anno block)
       - [ ] en locale → see new card layout
       - [ ] Old App version (production) still works (legacy layout)
- [ ] 9. Spot-check: in Supabase Dashboard, set one row's `card_paragraphs` to
       NULL; in App, confirm that row falls back to legacy layout; restore the
       value

## Deploy-order short-window risk (spec §8)

Steps 2 (migration) and 3 (backend restart) MUST run back-to-back, ideally as a
single deploy script. Between those steps the backend will fail because it now
expects no-suffix column names while the migration is what actually renames
them. Avoid the 09:00 / 21:00 Asia/Taipei cron windows when running these.

## Test counts (recorded at PR creation time)

- Backend: 123 passed
- Frontend: 534 passed
- Analyze: clean
