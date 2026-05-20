-- Phase 2 of IG card auto-post: extend the daily story schema with the fields
-- that the IG card renderer (Phase 1) needs.
--
-- Two groups:
-- 1. daily_story_places: 5 static-per-place fields (English spine name,
--    single-char + uppercase city, lat/lng). These are admin-curated, not
--    LLM-generated.
-- 2. daily_stories: 6 story-dynamic fields produced by Gemini in the zh-TW
--    path. All `card_` prefixed for clarity vs existing `story` / `era`.
--
-- All columns nullable. Existing rows stay NULL. The Phase 3 publisher will
-- NULL-check before attempting an IG post; Threads keeps working without
-- these fields.

alter table public.daily_story_places
  add column card_location_en text,
  add column card_city_ch     text,
  add column card_city_en     text,
  add column latitude         numeric,
  add column longitude        numeric;

alter table public.daily_stories
  add column card_title_ch               text,
  add column card_title_sub_ch           text,
  add column card_paragraphs_ch          text[],
  add column card_pull_quote_ch          text,
  add column card_pull_quote_attrib_ch   text,
  add column card_anno_roman             text;
