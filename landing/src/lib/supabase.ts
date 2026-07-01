import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/// Server-side Supabase client using the public anon key.
///
/// Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from the environment. The anon
/// key is safe to use server-side; RLS on `daily_stories` limits reads to
/// past publish dates. Throws a clear error if the env is not configured so
/// misconfiguration fails loudly at request time rather than silently.
export function getSupabaseClient(): SupabaseClient {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_ANON_KEY;
  if (!url || !key) {
    throw new Error(
      "SUPABASE_URL and SUPABASE_ANON_KEY must be set for story pages",
    );
  }
  return createClient(url, key, { auth: { persistSession: false } });
}
