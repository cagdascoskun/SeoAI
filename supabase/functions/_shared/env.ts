export const env = {
  supabaseUrl: Deno.env.get('SUPABASE_URL') ?? '',
  supabaseServiceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  openaiKey: Deno.env.get('OPENAI_API_KEY') ?? '',
  bingKey: Deno.env.get('BING_SEARCH_API_KEY') ?? '',
  lemonSqueezyKey: Deno.env.get('LEMON_SQUEEZY_API_KEY') ?? '',
  lemonSqueezySigningSecret: Deno.env.get('LEMON_SQUEEZY_SIGNING_SECRET') ?? '',
  batchConcurrency: Number(Deno.env.get('BATCH_CONCURRENCY_LIMIT') ?? '5'),
};

export function assertEnv() {
  if (!env.supabaseUrl || !env.supabaseServiceKey) {
    throw new Error('Supabase environment variables missing');
  }
}
