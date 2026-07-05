-- social_posts: per-day Instagram publish outcomes, one row per media type.
--
-- Written ONLY by the backend publisher (service role):
--   * carousel — the 21:00 publish job (was previously recorded on
--     daily_stories.ig_post_id / publish_error / published_at; those columns
--     are dropped in a follow-up migration once this table is live)
--   * reel     — the 21:10 reel publish job (new)
--
-- A publish attempt upserts its row: status 'published' on success (with
-- ig_post_id), 'failed' on error (with the error text). Retries overwrite
-- the same (publish_date, media_type) row, which is what makes the reel
-- job's 21:10 / 23:10 double-run idempotent.
CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  publish_date DATE NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('carousel', 'reel')),
  status TEXT NOT NULL CHECK (status IN ('published', 'failed')),
  ig_post_id TEXT,
  error TEXT,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (publish_date, media_type)
);

-- Enable Row Level Security with no policies: the table is service-role
-- only (the backend bypasses RLS); app clients have no access.
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
