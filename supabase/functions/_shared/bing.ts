import { env } from "./env.ts";

const VISUAL_SEARCH_ENDPOINT = "https://api.bing.microsoft.com/v7.0/images/visualsearch";
const WEB_SEARCH_ENDPOINT = "https://api.bing.microsoft.com/v7.0/search";

export interface BingVisualItem {
  name: string;
  hostPageUrl?: string;
  contentUrl?: string;
  thumbnailUrl?: string;
  price?: number;
  category?: string;
}

export async function bingVisualSearch(imageUrl: string): Promise<BingVisualItem[]> {
  const res = await fetch(VISUAL_SEARCH_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'multipart/form-data; boundary=---visualsearch',
      'Ocp-Apim-Subscription-Key': env.bingKey,
    },
    body: `-----visualsearch\r\nContent-Disposition: form-data; name="knowledgeRequest"\r\n\r\n{"imageInfo":{"url":"${imageUrl}"}}\r\n-----visualsearch--`,
  });
  if (!res.ok) {
    throw new Error(`Bing Visual Search failed: ${res.status} ${await res.text()}`);
  }
  const json = await res.json();
  const tags = json?.tags ?? [];
  const actions = tags.flatMap((tag: any) => tag.actions ?? []);
  const items = actions.flatMap((action: any) => action.data?.value ?? []);
  return items.map((item: any) => ({
    name: item.name,
    hostPageUrl: item.hostPageUrl,
    contentUrl: item.contentUrl,
    thumbnailUrl: item.thumbnailUrl,
    price: item.offers?.[0]?.price ?? item.price,
    category: item.category,
  }));
}

export async function bingWebSearch(query: string): Promise<BingVisualItem[]> {
  const url = new URL(WEB_SEARCH_ENDPOINT);
  url.searchParams.set('q', query);
  url.searchParams.set('count', '10');
  const res = await fetch(url, {
    headers: { 'Ocp-Apim-Subscription-Key': env.bingKey },
  });
  if (!res.ok) {
    throw new Error(`Bing Web Search failed: ${res.status} ${await res.text()}`);
  }
  const json = await res.json();
  const webPages = json?.webPages?.value ?? [];
  return webPages.map((page: any) => ({
    name: page.name,
    hostPageUrl: page.url,
    contentUrl: page.url,
    thumbnailUrl: page.thumbnailUrl?.contentUrl,
    price: undefined,
    category: page.id,
  }));
}
