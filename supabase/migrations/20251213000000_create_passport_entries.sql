create table if not exists public.passport_entries (
  id uuid not null primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id text not null,
  place_name text not null,
  place_address text not null,
  place_image_url text,
  narration_text text not null,
  narration_style text not null,
  created_at timestamptz not null default now()
);

alter table public.passport_entries enable row level security;

create policy "Users can view their own passport entries"
  on public.passport_entries
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own passport entries"
  on public.passport_entries
  for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own passport entries"
  on public.passport_entries
  for delete
  using (auth.uid() = user_id);