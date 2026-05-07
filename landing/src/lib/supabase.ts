import { createClient, SupabaseClient } from "@supabase/supabase-js";

let cachedClient: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (cachedClient) return cachedClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error(
      "Supabase env vars missing. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY."
    );
  }

  cachedClient = createClient(url, anonKey, {
    auth: { persistSession: false },
  });
  return cachedClient;
}

export type SharedJourney = {
  id: string;
  place_id: string;
  place_name: string;
  place_address: string;
  place_image_url: string | null;
  narration_text: string;
  narration_styles: string[] | null;
  language: string;
  visited_at: string;
  created_at: string;
};

export async function fetchSharedJourney(
  id: string
): Promise<SharedJourney | null> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from("shared_journeys")
    .select(
      "id, place_id, place_name, place_address, place_image_url, narration_text, narration_styles, language, visited_at, created_at"
    )
    .eq("id", id)
    .maybeSingle();

  if (error) {
    console.error("Failed to fetch shared journey", error);
    return null;
  }
  return (data as SharedJourney | null) ?? null;
}
