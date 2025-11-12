import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";
import { env, assertEnv } from "./env.ts";

assertEnv();

export const supabaseAdmin = createClient(env.supabaseUrl, env.supabaseServiceKey, {
  auth: { persistSession: false },
});
