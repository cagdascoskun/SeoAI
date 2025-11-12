import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { jsonResponse, requireJson } from "../_shared/http.ts";
import { supabaseAdmin } from "../_shared/client.ts";

type Payload = {
  action: 'reserve' | 'refund';
  user_id: string;
  unique_key: string;
  amount?: number;
};

serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const body = await requireJson<Payload>(req);
    if (!body.user_id || !body.unique_key) {
      return jsonResponse({ error: 'user_id and unique_key required' }, { status: 400 });
    }

    const amount = body.amount ?? 1;
    const rpcName = body.action === 'refund' ? 'refund_credits' : 'debit_credits';
    const { data, error } = await supabaseAdmin.rpc(rpcName, {
      p_user: body.user_id,
      p_unique_key: body.unique_key,
      p_amount: amount,
    });

    if (error) {
      return jsonResponse({ error: error.message }, { status: 400 });
    }

    return jsonResponse({ balance: data?.balance ?? null });
  } catch (error) {
    console.error('credit-debit error', error);
    return jsonResponse({ error: (error as Error).message }, { status: 500 });
  }
});
