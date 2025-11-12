import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { parse } from "https://deno.land/std@0.224.0/csv/mod.ts";
import { jsonResponse, requireJson } from "../_shared/http.ts";
import { supabaseAdmin } from "../_shared/client.ts";
import { env } from "../_shared/env.ts";

type BatchPayload = {
  user_id: string;
  batch_id: string;
  file_url: string;
};

type CsvRow = {
  image_url?: string;
  title?: string;
  description?: string;
  channel?: string;
  lang?: string;
  [key: string]: string | undefined;
};

async function sha(input: string): Promise<string> {
  const buffer = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', buffer);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const payload = await requireJson<BatchPayload>(req);
    const csvRes = await fetch(payload.file_url);
    if (!csvRes.ok) throw new Error(`CSV download failed ${csvRes.status}`);
    const csvText = await csvRes.text();
    const rows = parse(csvText, { skipFirstRow: true }) as CsvRow[];

    const jobs: Array<Record<string, unknown>> = [];
    for (const row of rows) {
      const imageUrl = row.image_url;
      if (!imageUrl) continue;
      const uniqueKey = await sha(`${payload.user_id}:${imageUrl}:${row.title ?? ''}:${row.description ?? ''}`);
      jobs.push({
        type: 'analysisJob',
        payload: {
          user_id: payload.user_id,
          image_url: imageUrl,
          title: row.title,
          description: row.description,
          channel: row.channel || 'Generic',
          lang: row.lang || 'auto',
          unique_key: uniqueKey,
        },
        status: 'queued',
        retry_count: 0,
        user_id: payload.user_id,
        unique_key: uniqueKey,
      });
    }

    const limitedJobs = jobs.slice(0, env.batchConcurrency * 200);
    if (!limitedJobs.length) {
      return jsonResponse({ error: 'No valid CSV rows found' }, { status: 400 });
    }

    const { error } = await supabaseAdmin.from('jobs').insert(limitedJobs);
    if (error) throw error;

    await supabaseAdmin.from('batches').update({
      status: 'processing',
      stats: {
        total: rows.length,
        queued: limitedJobs.length,
        skipped: rows.length - limitedJobs.length,
      },
    }).eq('id', payload.batch_id);

    return jsonResponse({ queued: limitedJobs.length });
  } catch (error) {
    console.error('batch-dispatcher error', error);
    return jsonResponse({ error: (error as Error).message }, { status: 500 });
  }
});
