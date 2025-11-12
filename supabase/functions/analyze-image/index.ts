import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { supabaseAdmin } from "../_shared/client.ts";
import { ChatContent, openai } from "../_shared/openai.ts";

serve(async (req) => {
  const payload = await req.json();
  const { analysis_id, image_url, user_id } = payload;
  try {

    const userContent: ChatContent = [
      {
        type: "text",
        text: "Analyze this product image and create SEO metadata."
      },
      {
        type: "image_url",
        image_url: { url: image_url }
      },
    ];

    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are an AI SEO assistant for e-commerce listings.
          You look at product photos and generate SEO-optimized data for Etsy, Amazon and Shopify.
          Focus on materials, style, color, category, and purpose.
          Respond ONLY in valid JSON format with:
          {
            "title": "short optimized product title",
            "seo_keywords": ["keyword1", "keyword2", "keyword3"],
            "etsy_tags": ["tag1", "tag2", "tag3"],
            "description": "1-2 sentences product description."
          }`
        },
        {
          role: "user",
          content: userContent,
        }
      ],
      response_format: { type: "json_object" }
    });

    const seo = response.choices[0].message.content;

    await supabaseAdmin.from("analyses")
      .update({ seo_output: seo, status: "done" })
      .eq("id", analysis_id);

    await supabaseAdmin.rpc("use_credit", { p_user: user_id });

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("analyze-image error:", message);
    if (analysis_id) {
      await supabaseAdmin
        .from("analyses")
        .update({ status: "error" })
        .eq("id", analysis_id);
    }
    return new Response(JSON.stringify({ error: message }), { status: 500 });
  }
});
