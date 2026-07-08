import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Public config — the anon key is safe to ship in the client bundle.
// Set these as build-time env vars (VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY).
// When absent, the app runs fully local-first with no cloud sync.
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anon = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export const isCloudConfigured = Boolean(url && anon);
export const supabase: SupabaseClient | null = isCloudConfigured ? createClient(url!, anon!) : null;
