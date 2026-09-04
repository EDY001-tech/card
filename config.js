// ============================================================
// CONFIG — fill these in once you've created your Supabase project
// (Supabase Dashboard → Project Settings → API)
// ============================================================
// Example placeholders — replace with your real Supabase values before deploying
const SUPABASE_URL = "https://example-project-ref.supabase.co";
const SUPABASE_ANON_KEY = "anon-public-example-key";

// The "anon" key is safe to expose in frontend code — it only allows
// what your Row Level Security policies (in schema.sql) permit.
// NEVER put your Anthropic API key or Supabase "service_role" key here.

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Edge Function URL for the AI assistant (filled in after you deploy it — Step 4 in README)
const AI_ASSISTANT_URL = `${SUPABASE_URL}/functions/v1/ai-assistant`;
