-- Daily story places: master list (admin-curated via Supabase Dashboard)
create table public.daily_story_places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  wikipedia_title_en text not null,
  country text not null,
  is_active boolean not null default true,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

-- Index for picking next unused active place
create index daily_story_places_pickable_idx
  on public.daily_story_places (is_active, used_at nulls first, created_at);

-- Daily stories: server writes one row per (date, language)
create table public.daily_stories (
  id uuid primary key default gen_random_uuid(),
  publish_date date not null,
  language text not null,
  place_id uuid not null references public.daily_story_places(id),
  place_name text not null,
  place_location text not null,
  era text not null,
  story text not null,
  image_url text,
  image_attribution text,
  wikipedia_url text not null,
  created_at timestamptz not null default now(),
  unique (publish_date, language)
);

create index daily_stories_publish_date_lang_idx
  on public.daily_stories (publish_date desc, language);

-- RLS
alter table public.daily_story_places enable row level security;
alter table public.daily_stories enable row level security;

-- daily_stories: anon and authenticated can read stories whose publish_date
-- has reached today in Asia/Taipei (so future-dated rows stay hidden)
create policy "anon can read published stories"
  on public.daily_stories for select to anon, authenticated
  using (publish_date <= ((now() at time zone 'Asia/Taipei')::date));

-- daily_story_places: no policy = no anon access. Service role bypasses RLS.
