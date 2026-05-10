-- Grant table privileges for the daily story feature.
--
-- The migration that creates `daily_story_places` and `daily_stories` enables
-- RLS but does not grant table-level privileges. Without these GRANTs, even
-- the service_role gets `permission denied for table` (Postgres error 42501)
-- because RLS-bypass only kicks in *after* basic table privileges are in
-- place.
--
-- This mirrors the pattern used for `passport_entries` (see
-- 20251213000001_grant_passport_permissions.sql).
--
-- Role summary:
-- - service_role: backend cron job. Needs full read/write on both tables.
-- - anon / authenticated: app readers. Only SELECT on daily_stories, gated
--   further by the RLS policy added in 20260510000000 to past publish_dates.
-- - daily_story_places: deliberately NOT granted to anon/authenticated. The
--   master place list is admin-only (managed via Supabase Dashboard).

grant select, insert, update, delete on table public.daily_story_places to service_role;
grant select, insert, update, delete on table public.daily_stories to service_role;
grant select on table public.daily_stories to anon, authenticated;
