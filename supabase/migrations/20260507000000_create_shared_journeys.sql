create table if not exists public.shared_journeys (
  id text not null primary key,
  user_id uuid references auth.users(id) on delete set null,
  place_id text not null,
  place_name text not null,
  place_address text not null default '',
  place_image_url text,
  narration_text text not null,
  narration_styles text[] not null default '{}',
  language text not null default 'zh-TW',
  visited_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists shared_journeys_user_id_idx
  on public.shared_journeys (user_id);

create index if not exists shared_journeys_created_at_idx
  on public.shared_journeys (created_at desc);

alter table public.shared_journeys enable row level security;

create policy "Anyone can read shared journeys"
  on public.shared_journeys
  for select
  using (true);

create policy "Anyone can create shared journeys"
  on public.shared_journeys
  for insert
  with check (
    user_id is null or auth.uid() = user_id
  );

create policy "Owners can delete their shared journeys"
  on public.shared_journeys
  for delete
  using (auth.uid() = user_id);

grant select on public.shared_journeys to anon, authenticated;
grant insert on public.shared_journeys to anon, authenticated;
grant delete on public.shared_journeys to authenticated;

-- Public bucket for shared journey images (e.g. quick-guide camera shots).
insert into storage.buckets (id, name, public)
values ('shared_journey_images', 'shared_journey_images', true)
on conflict (id) do nothing;

create policy "Anyone can read shared journey images"
  on storage.objects
  for select
  using (bucket_id = 'shared_journey_images');

create policy "Anyone can upload shared journey images"
  on storage.objects
  for insert
  with check (bucket_id = 'shared_journey_images');
