-- Add long-form `paragraphs` column to daily_stories.
--
-- Context: the Gemini story prompt now produces two parallel narrations:
--   - `paragraphs`        — long form (3 × 200-300 zh chars / 80-130 en
--                           words) used for the App story view and TTS
--   - `card_paragraphs`   — short form (3 × 60-100 chars/words) sized
--                           for the Instagram card layout
--
-- The existing `story` text column remains the joined card_paragraphs for
-- backward compatibility; the new column is rendered alongside it by the
-- App once available.

alter table public.daily_stories
  add column if not exists paragraphs jsonb;

comment on column public.daily_stories.paragraphs is
  'Long-form 3-paragraph narration (JSON array of 3 strings). '
  'Distinct from card_paragraphs, which is sized for the IG card.';
