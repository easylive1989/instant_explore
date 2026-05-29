-- Drop Threads publishing columns from daily_stories.
--
-- Threads publishing has been removed from the publisher pipeline; only
-- Instagram remains. `threads_summary` was the punchy 300-400 char body for
-- a Threads post and `threads_post_id` the returned Graph API id. Neither
-- is read or written anywhere in the codebase after the removal.

alter table public.daily_stories
  drop column if exists threads_summary,
  drop column if exists threads_post_id;
