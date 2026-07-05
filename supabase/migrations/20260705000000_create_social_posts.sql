-- social_posts: per-day Instagram publish state, one row per media type.
--
-- Written ONLY by backend/local publisher tooling (service role):
--   * carousel — the 21:00 publish job records its outcome here (was
--     previously daily_stories.ig_post_id / publish_error / published_at;
--     those columns are dropped in a follow-up migration once this table
--     is live). Carousel review state stays on daily_stories.review_state.
--   * reel — the local send-for-review step inserts a 'pending' row with
--     the Discord message id of the video review post; the 21:10 / 23:10
--     reel job then reads that message's ✅/❌ and moves the row to
--     published / failed / rejected / skipped. The reel review is fully
--     independent of the carousel's.
--
-- State machine per (publish_date, media_type):
--   pending   → published  (approver ✅ → IG publish succeeded)
--   pending   → failed     (publish call raised; error filled in — the
--                           next scheduled run retries a failed row)
--   pending   → rejected   (approver ❌)
--   pending   → skipped    (no reaction by the final 23:10 pass)
CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_date DATE NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('carousel', 'reel')),
  status TEXT NOT NULL CHECK (
    status IN ('pending', 'published', 'failed', 'rejected', 'skipped')
  ),
  discord_message_id TEXT,
  ig_post_id TEXT,
  error TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (publish_date, media_type)
);

-- Enable Row Level Security with no policies: the table is service-role
-- only (the backend bypasses RLS); app clients have no access.
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
