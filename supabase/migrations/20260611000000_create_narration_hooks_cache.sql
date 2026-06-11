-- Cache for /narration/hooks results.
--
-- Hooks are free and unlimited for every signed-in user, and each
-- generation costs a grounded Gemini call. The first request for a
-- (place, language) pair pays that cost; every later request is served
-- from this table.
--
-- Written and read ONLY by the backend (service role). place_key is the
-- Wikidata Q-id for the modern request path, or "title:<wikipedia_title>"
-- for the deprecated title-only path. Only successful generations are
-- cached (never insufficient_source / empty results), so a place that
-- failed once can succeed later.
CREATE TABLE IF NOT EXISTS public.narration_hooks_cache (
  place_key TEXT NOT NULL,
  language TEXT NOT NULL,
  hooks JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (place_key, language)
);

-- Backend-only table: enable RLS with no policies so anon/authenticated
-- clients can do nothing; the service role bypasses RLS.
ALTER TABLE public.narration_hooks_cache ENABLE ROW LEVEL SECURITY;
