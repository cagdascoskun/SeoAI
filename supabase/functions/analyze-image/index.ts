import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { supabaseAdmin } from "../_shared/client.ts";
import { ChatContent, openai } from "../_shared/openai.ts";
import { encodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";

serve(async (req) => {
  const payload = await req.json();
  const { analysis_id, image_url, user_id } = payload;
  try {

    const imageResponse = await fetch(image_url);
    if (!imageResponse.ok) {
      throw new Error(`Failed to download image: ${imageResponse.status}`);
    }
    const imageBuffer = await imageResponse.arrayBuffer();
    const imageMime = imageResponse.headers.get("content-type") ?? "image/jpeg";
    const base64Image = encodeBase64(new Uint8Array(imageBuffer));
    const dataUrl = `data:${imageMime};base64,${base64Image}`;

    const userContent: ChatContent = [
      {
        type: "text",
        text: "Analyze this product image and create SEO metadata."
      },
      {
        type: "image_url",
        image_url: { url: dataUrl }
      },
    ];

    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are a senior e-commerce SEO strategist specializing in Etsy, Amazon, and Shopify listings.
Your job is to deeply analyze the provided product image and generate a *maximally optimized* SEO metadata set.

Goals:
- Maximize search visibility (focus on relevant long-tail keywords)
- Improve CTR with persuasive wording
- Ensure high relevance between tags, title, and description
- Output must remain concise, professional, and marketplace-appropriate.

Return ONLY valid JSON (no markdown, no explanations), structured as:
{
  "title": "Compelling, descriptive, keyword-rich title (minimum 15 words, natural sentence style)",
  "seo_keywords": ["20-25 unique, high-volume, long-tail keywords"],
  "etsy_tags": ["20 optimized short tags (2–3 words each, no duplicates, lowercase)"],
  "description": "A rich 200–300 word description covering materials, emotional appeal, use cases, and SEO phrases naturally embedded."
}

Use natural English phrasing. Never repeat words unnecessarily.
Ensure all outputs are consistent, detailed, and tailored to the analyzed image.`
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
