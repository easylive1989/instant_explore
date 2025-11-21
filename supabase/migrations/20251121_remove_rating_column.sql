-- Remove rating column from diary_entries table
ALTER TABLE public.diary_entries
DROP COLUMN IF EXISTS rating;
