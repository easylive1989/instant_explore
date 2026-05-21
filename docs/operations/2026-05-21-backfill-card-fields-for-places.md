# Backfill `daily_story_places` card fields (Phase 2)

The Phase 2 migration (`20260521120000_add_card_fields_to_daily_stories.sql`)
adds 5 nullable columns to `daily_story_places`:

- `card_location_en` — spine / footer display string, e.g. `TOUR EIFFEL · PARIS`
- `card_city_ch` — single Chinese character, e.g. `巴`
- `card_city_en` — uppercase city name, e.g. `PARIS`
- `latitude` — numeric, used to format `lat°N/S`
- `longitude` — numeric, used to format `lng°E/W`

New rows are filled in by the admin when adding a place. Existing rows must
be backfilled manually before the Phase 3 publisher can render IG cards for
them — rows missing any of the five values will be skipped at publish time
(Threads still posts).

## Run this in Supabase Dashboard → SQL Editor (prod)

List active places that still need backfill:

```sql
select id, name, country
from public.daily_story_places
where is_active = true
  and (card_location_en is null
    or card_city_ch is null
    or card_city_en is null
    or latitude is null
    or longitude is null)
order by created_at;
```

For each row, run an update like the Eiffel example below. Use Wikipedia /
GeoHack for lat/lng coordinates and the place's canonical city.

```sql
update public.daily_story_places
set card_location_en = 'TOUR EIFFEL · PARIS',
    card_city_ch     = '巴',
    card_city_en     = 'PARIS',
    latitude         =  48.8584,
    longitude        =   2.2945
where name = 'Eiffel Tower';
```

## Conventions

- `card_location_en`: ALL CAPS, format `<LANDMARK NAME> · <CITY>`. Use the
  middle dot `·` (U+00B7) as separator. Diacritics may be dropped if they
  would prevent the chosen IG card font from rendering correctly.
- `card_city_ch`: exactly one Traditional Chinese character. Pick the
  character most representative of the city (e.g. Paris → 巴, Tokyo → 東,
  Rome → 羅).
- `card_city_en`: city only (no country), ALL CAPS, ASCII where possible.
- `latitude` / `longitude`: decimal degrees, signed (north / east positive,
  south / west negative). 4 decimal places is the convention from the Eiffel
  demo (≈11 m accuracy).

## Verifying

After the update, re-run the listing query — expected output is empty (all
active rows have the five columns populated).
