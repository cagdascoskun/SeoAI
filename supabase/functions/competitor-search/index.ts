import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { jsonResponse, requireJson } from "../_shared/http.ts";
import { supabaseAdmin } from "../_shared/client.ts";
import { bingVisualSearch, bingWebSearch } from "../_shared/bing.ts";
import { cosineSimilarity, embedText } from "../_shared/openai.ts";

type CompetitorPayload = {
  user_id: string;
  analysis_id: string;
  signed_image_url: string;
  title: string;
};

serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const payload = await requireJson<CompetitorPayload>(req);
    if (!payload.analysis_id || !payload.signed_image_url) {
      return jsonResponse({ error: 'Missing identifiers' }, { status: 400 });
    }

    const visualItems = await bingVisualSearch(payload.signed_image_url);
    const textItems = payload.title ? await bingWebSearch(payload.title) : [];
    const combined = [...visualItems, ...textItems]
      .filter((item) => item.name && item.hostPageUrl)
      .slice(0, 10);

    const titles = combined.map((item) => item.name);
    const competitorEmbeddings = titles.length ? await embedText(titles) : [];

    const { data: analysis, error: analysisError } = await supabaseAdmin
      .from('analyses')
      .select('embedding')
      .eq('id', payload.analysis_id)
      .single();

    if (analysisError) throw analysisError;

    const baseEmbedding: number[] | null = analysis?.embedding ?? null;

    const competitorRows = combined.map((item, idx) => {
      const similarity = baseEmbedding && competitorEmbeddings[idx]
        ? cosineSimilarity(baseEmbedding, competitorEmbeddings[idx])
        : null;
      return {
        analysis_id: payload.analysis_id,
        source: item.category ?? 'Bing',
        title: item.name,
        url: item.hostPageUrl ?? item.contentUrl,
        image_url: item.thumbnailUrl ?? item.contentUrl,
        price: item.price ?? null,
        similarity_score: similarity,
        meta: item,
      };
    });

    if (competitorRows.length) {
      await supabaseAdmin.from('competitor_items').delete().eq('analysis_id', payload.analysis_id);
      const { error: insertError } = await supabaseAdmin.from('competitor_items').insert(competitorRows);
      if (insertError) throw insertError;
    }

    const prices = competitorRows.map((c) => c.price).filter((p): p is number => typeof p === 'number');
    const similarities = competitorRows.map((c) => c.similarity_score ?? 0);
    const summary = {
      competitor_count: competitorRows.length,
      avg_price: prices.length ? prices.reduce((a, b) => a + b, 0) / prices.length : null,
      min_price: prices.length ? Math.min(...prices) : null,
      max_price: prices.length ? Math.max(...prices) : null,
      avg_similarity: similarities.length ? similarities.reduce((a, b) => a + b, 0) / similarities.length : null,
      avg_title_length: titles.length ? titles.reduce((a, t) => a + t.length, 0) / titles.length : null,
    };

    await supabaseAdmin
      .from('analyses')
      .update({ competitor_summary: summary })
      .eq('id', payload.analysis_id);

    return jsonResponse({ analysis_id: payload.analysis_id, competitors: competitorRows, summary });
  } catch (error) {
    console.error('competitor-search error', error);
    return jsonResponse({ error: (error as Error).message }, { status: 500 });
  }
});
