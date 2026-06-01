-- Add a Wikidata Q-id to each daily-story place so the App can build a
-- `wikidata:`-prefixed Place and route the "explore more stories" CTA into
-- the on-demand story generation page (/config) for the SAME place.
--
-- Nullable: existing rows stay NULL until backfilled; the App hides the CTA
-- when wikidata_id is missing.

alter table public.daily_story_places
  add column wikidata_id text;

-- Expose wikidata_id to App clients so the PostgREST join in
-- SupabaseDailyStoryRepository._select can read it without a 42501 error.
grant select (wikidata_id)
  on table public.daily_story_places to anon, authenticated;
