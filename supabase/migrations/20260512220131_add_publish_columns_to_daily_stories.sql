-- Adds social-publishing workflow columns to daily_stories.
-- Flow: 09:00 Asia/Taipei cron writes a row with review_state='pending' and
-- the Discord review message id. 21:00 Asia/Taipei cron reads Discord
-- reactions and transitions the state to 'published' / 'rejected' /
-- 'skipped' / 'failed'.

alter table public.daily_stories
  add column threads_summary text,
  add column hashtags text[],
  add column discord_message_id text,
  add column review_state text not null default 'pending',
  add column reviewed_at timestamptz,
  add column published_at timestamptz,
  add column threads_post_id text,
  add column ig_post_id text,
  add column publish_error text;

-- Enforce the allowed state set at the DB layer so a typo in the publisher
-- can't silently corrupt the audit trail.
alter table public.daily_stories
  add constraint daily_stories_review_state_check
  check (review_state in ('pending', 'published', 'rejected', 'skipped', 'failed'));

-- Used by the 21:00 publish job to find rows that still need a decision.
create index daily_stories_review_state_idx
  on public.daily_stories (review_state, publish_date);
