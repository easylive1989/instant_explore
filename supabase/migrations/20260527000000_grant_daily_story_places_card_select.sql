-- Allow App clients to read the card display fields from daily_story_places.
--
-- Background: 20260510000001 deliberately withheld SELECT on this table from
-- anon/authenticated, treating it as an admin-only master list. Later,
-- 20260521120000 added card_location_en / card_city_ch / card_city_en to
-- power the IG-style card layout in the App. The repository
-- (SupabaseDailyStoryRepository._select) embeds these via PostgREST join
--   daily_story_places!left(card_location_en, card_city_ch, card_city_en)
-- which fails with `42501 permission denied for table daily_story_places`
-- because (a) no table-level SELECT grant and (b) no RLS SELECT policy
-- exist for anon/authenticated.
--
-- Fix: column-level SELECT on the join key + 3 card display columns, plus
-- a permissive RLS SELECT policy. Operational columns
-- (name, country, wikipedia_title_en, is_active, used_at, latitude,
-- longitude, created_at) remain admin-only — neither granted to anon/
-- authenticated nor exposed by the policy alone, since column-level grants
-- gate them.

grant select (id, card_location_en, card_city_ch, card_city_en)
  on table public.daily_story_places to anon, authenticated;

create policy "anon can read card display fields"
  on public.daily_story_places for select to anon, authenticated
  using (true);
