-- Grant the backend access to narration_hooks_cache.
--
-- Same defect as social_posts (see 20260705120000): the create-table
-- migration (20260611000000) never granted service_role, so every backend
-- cache read/write has failed with `42501 permission denied` since the
-- table was created — hooks were regenerated on every request instead of
-- being served from cache. App clients stay locked out.

grant select, insert, update, delete
  on table public.narration_hooks_cache to service_role;
