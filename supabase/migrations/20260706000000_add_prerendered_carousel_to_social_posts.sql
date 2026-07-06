-- Pre-rendered (wander-style) carousel support.
--
-- The local send-for-review script uploads the day's rendered slides to
-- the public `ig-cards` bucket and records their URLs + IG caption here.
-- A carousel row with non-NULL slide_urls tells the 21:00 publish job to
-- publish these exact images (gated by ✅/❌ on discord_message_id) and
-- to skip the default in-server card rendering entirely.
--
-- No new GRANT needed: 20260705120000 granted table-level
-- select/insert/update/delete on social_posts to service_role, which
-- covers columns added later.
ALTER TABLE public.social_posts
  ADD COLUMN IF NOT EXISTS slide_urls JSONB,
  ADD COLUMN IF NOT EXISTS caption TEXT;
