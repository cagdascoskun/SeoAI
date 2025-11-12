import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { jsonResponse } from "../_shared/http.ts";
import { env } from "../_shared/env.ts";
import { supabaseAdmin } from "../_shared/client.ts";

const variantCreditsEntries = [
  [Deno.env.get('LEMON_SQUEEZY_CREDIT50_VARIANT_ID'), 50],
  [Deno.env.get('LEMON_SQUEEZY_CREDIT250_VARIANT_ID'), 250],
  [Deno.env.get('LEMON_SQUEEZY_CREDIT1000_VARIANT_ID'), 1000],
].filter((entry): entry is [string, number] => Boolean(entry[0]));

const variantCredits = Object.fromEntries(variantCreditsEntries) as Record<string, number>;

async function verifySignature(rawBody: string, signature: string | null): Promise<boolean> {
  if (!signature) return false;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(env.lemonSqueezySigningSecret);
  const key = await crypto.subtle.importKey('raw', keyData, { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  const bodyData = encoder.encode(rawBody);
  const sigBytes = Uint8Array.from(signature.match(/.{2}/g)?.map((byte) => parseInt(byte, 16)) ?? []);
  return crypto.subtle.verify('HMAC', key, sigBytes, bodyData);
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
  }

  const raw = await req.text();
  const signature = req.headers.get('X-Signature');
  const isValid = await verifySignature(raw, signature);
  if (!isValid) {
    return jsonResponse({ error: 'Invalid signature' }, { status: 401 });
  }

  try {
    const event = JSON.parse(raw);
    const eventId = event.meta?.event_id ?? crypto.randomUUID();
    const eventType = event.meta?.event_name ?? event.type;
    const variantId = String(event.data?.attributes?.variant_id ?? '');
    const email = event.data?.attributes?.user_email ?? event.data?.attributes?.email;

    if (!email) throw new Error('Email missing from event');

    const credits = variantCredits[variantId];
    if (!credits) {
      return jsonResponse({ message: 'Variant ignored' });
    }

    const { data: profile, error } = await supabaseAdmin
      .from('profiles')
      .select('user_id')
      .eq('email', email)
      .single();

    if (error || !profile) {
      throw new Error('Profile not found for email');
    }

    await supabaseAdmin.rpc('grant_credits', {
      p_user: profile.user_id,
      p_unique_key: eventId,
      p_amount: credits,
    });

    await supabaseAdmin.from('billing_events').insert({
      user_id: profile.user_id,
      event_id: eventId,
      event_type: eventType,
      payload: event,
    });

    return jsonResponse({ success: true });
  } catch (error) {
    console.error('lemonsqueezy-webhooks error', error);
    return jsonResponse({ error: (error as Error).message }, { status: 500 });
  }
});
