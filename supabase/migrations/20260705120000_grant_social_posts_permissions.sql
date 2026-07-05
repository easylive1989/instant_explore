-- Grant the backend publisher access to social_posts.
--
-- Tables in this project get no automatic PostgREST role grants (see
-- 20260510000001_grant_daily_story_permissions.sql): creating a table and
-- enabling RLS leaves even service_role with `42501 permission denied`.
-- 20260705000000 created social_posts without the grant, so the publisher
-- container could not read/write it. App clients stay locked out — no
-- anon/authenticated grants and no RLS policies.

grant select, insert, update, delete
  on table public.social_posts to service_role;
