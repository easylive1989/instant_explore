-- Sync tables for opt-in cross-device sync of user data (Journey entries,
-- Quick Guide entries, Trips, Saved Locations). All tables are owned by
-- a Supabase auth user and protected by row-level security.

-- ----------------------------------------------------------------------------
-- journey_entries: narration-based journey entries.
-- ----------------------------------------------------------------------------
create table if not exists public.journey_entries (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id text not null,
  place_name text not null,
  place_address text not null,
  place_image_url text,
  narration_text text not null,
  narration_styles text[] not null default array[]::text[],
  language text not null default 'zh-TW',
  trip_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.journey_entries enable row level security;

create policy "Users can read their own journey entries"
  on public.journey_entries for select using (auth.uid() = user_id);
create policy "Users can insert their own journey entries"
  on public.journey_entries for insert with check (auth.uid() = user_id);
create policy "Users can update their own journey entries"
  on public.journey_entries for update using (auth.uid() = user_id);
create policy "Users can delete their own journey entries"
  on public.journey_entries for delete using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- quick_guide_entries: photo-based quick guide entries. Images stored as
-- base64 text for simplicity in this initial sync milestone.
-- ----------------------------------------------------------------------------
create table if not exists public.quick_guide_entries (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  image_base64 text not null,
  ai_description text not null,
  language text not null default 'zh-TW',
  trip_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.quick_guide_entries enable row level security;

create policy "Users can read their own quick guide entries"
  on public.quick_guide_entries for select using (auth.uid() = user_id);
create policy "Users can insert their own quick guide entries"
  on public.quick_guide_entries for insert with check (auth.uid() = user_id);
create policy "Users can update their own quick guide entries"
  on public.quick_guide_entries for update using (auth.uid() = user_id);
create policy "Users can delete their own quick guide entries"
  on public.quick_guide_entries for delete using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- trips: user-created trips that group journey entries.
-- ----------------------------------------------------------------------------
create table if not exists public.trips (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  start_date timestamptz,
  end_date timestamptz,
  cover_image_url text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.trips enable row level security;

create policy "Users can read their own trips"
  on public.trips for select using (auth.uid() = user_id);
create policy "Users can insert their own trips"
  on public.trips for insert with check (auth.uid() = user_id);
create policy "Users can update their own trips"
  on public.trips for update using (auth.uid() = user_id);
create policy "Users can delete their own trips"
  on public.trips for delete using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- saved_locations: locations bookmarked by the user.
-- ----------------------------------------------------------------------------
create table if not exists public.saved_locations (
  place_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  formatted_address text not null,
  latitude double precision not null,
  longitude double precision not null,
  types text[] not null default array[]::text[],
  photos jsonb not null default '[]'::jsonb,
  category_key text not null,
  saved_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, place_id)
);

alter table public.saved_locations enable row level security;

create policy "Users can read their own saved locations"
  on public.saved_locations for select using (auth.uid() = user_id);
create policy "Users can insert their own saved locations"
  on public.saved_locations for insert with check (auth.uid() = user_id);
create policy "Users can update their own saved locations"
  on public.saved_locations for update using (auth.uid() = user_id);
create policy "Users can delete their own saved locations"
  on public.saved_locations for delete using (auth.uid() = user_id);
