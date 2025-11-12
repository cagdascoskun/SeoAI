import { env } from "./env.ts";
import type { SeoPayload } from "./types.ts";

const OPENAI_BASE = "https://api.openai.com/v1";

async function callOpenAI<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${OPENAI_BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${env.openaiKey}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`OpenAI API failed ${res.status}: ${await res.text()}`);
  }
  return res.json() as Promise<T>;
}

export async function generateSeoPayload(args: {
  imageUrl: string;
  title?: string;
  description: string;
  channel: string;
  lang: string;
}): Promise<SeoPayload> {
  const system = `You are an e-commerce SEO assistant. You analyze a product IMAGE + short text and output STRICT JSON according to the provided schema. Focus on concrete, buyer-intent keywords for ${args.channel}. Write titles under ${args.lang}. Prefer 140-150 char titles for Etsy, <= 200 for Amazon. Avoid brand names and competitors. No private data. Do not include prices or claims you can't verify.`;
  const user = `IMAGE: ${args.imageUrl}\nTITLE (optional): ${args.title ?? ''}\nDESCRIPTION: ${args.description}\nTASKS:\n  1) Identify product attributes (type, material, color, style, audience).\n  2) Produce SEO: primary_title, 5 alt_titles, 20-30 keywords, 10-20 hashtags, 5-8 bullets, category_path, materials, colors, dimensions (if visible; else null).\n  3) Output language: ${args.lang}. Channel: ${args.channel}.\nReturn ONLY valid JSON for the schema.`;

  const response = await callOpenAI<{ choices: Array<{ message: { content: string } }> }>("/chat/completions", {
    model: 'gpt-4o-mini',
    temperature: 0.2,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: system },
      {
        role: 'user',
        content: [
          { type: 'input_text', text: user },
          { type: 'input_image', image_url: args.imageUrl },
        ],
      },
    ],
  });

  const choice = response.choices[0]?.message?.content;
  if (!choice) {
    throw new Error('GPT-4o response missing');
  }

  return JSON.parse(choice) as SeoPayload;
}

export async function embedText(texts: string[]): Promise<number[][]> {
  const response = await callOpenAI<{ data: Array<{ embedding: number[] }> }>("/embeddings", {
    model: 'text-embedding-3-small',
    input: texts,
  });
  return response.data.map((item) => item.embedding);
}

export function cosineSimilarity(a: number[], b: number[]): number {
  const dot = a.reduce((sum, ai, idx) => sum + ai * b[idx], 0);
  const normA = Math.sqrt(a.reduce((sum, ai) => sum + ai * ai, 0));
  const normB = Math.sqrt(b.reduce((sum, bi) => sum + bi * bi, 0));
  if (!normA || !normB) return 0;
  return dot / (normA * normB);
}

export type InputText = { type: 'text'; text: string };
export type InputImage = { type: 'image_url'; image_url: { url: string } };
export type ChatContent = string | Array<InputText | InputImage>;

export type ChatMessage = { role: string; content: ChatContent };
export type ChatCompletionRequest = {
  model: string;
  messages: ChatMessage[];
  response_format?: Record<string, unknown>;
};

type ChatCompletionResponse = {
  choices: Array<{ message: { content: string } }>;
};

export const openai = {
  chat: {
    completions: {
      create: (payload: ChatCompletionRequest) =>
        callOpenAI<ChatCompletionResponse>("/chat/completions", payload),
    },
  },
};
