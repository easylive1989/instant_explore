-- Unify card_* columns across languages. The `_ch` suffix was added when
-- card_* fields only existed on zh-TW rows. Each row is already keyed by
-- (publish_date, language), so the suffix is redundant — and confusing
-- once en rows also produce card_* content.
--
-- DEPLOY ORDER: this migration MUST run back-to-back with the matching
-- backend deploy (see docs/superpowers/specs/2026-05-25-daily-story-card-
-- unification-design.md §8). Running standalone will break the 09:00 and
-- 21:00 Asia/Taipei cron jobs until backend restarts.
--
-- Companion changes:
--   - backend prompts.py / gemini_client.py / story_writer.py / job.py
--     and social/card/mapper.py all switch to the new column names in the
--     same release.
--   - Frontend DailyStory model gains the new fields and the App renders
--     a card-style layout when they are present (see spec).
--
-- daily_story_places.card_city_ch / card_city_en stay as-is — they store
-- two language names for the *same* place in a single row, so the suffix
-- is meaningful there.

alter table public.daily_stories
  rename column card_title_ch              to card_title;
alter table public.daily_stories
  rename column card_title_sub_ch          to card_title_sub;
alter table public.daily_stories
  rename column card_paragraphs_ch         to card_paragraphs;
alter table public.daily_stories
  rename column card_pull_quote_ch         to card_pull_quote;
alter table public.daily_stories
  rename column card_pull_quote_attrib_ch  to card_pull_quote_attrib;
-- card_anno_roman already has no _ch suffix; leave as-is.
