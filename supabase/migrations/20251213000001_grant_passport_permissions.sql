-- Add permissions for authenticated users to the passport_entries table
grant select, insert, update, delete on table public.passport_entries to authenticated;
