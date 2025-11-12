export type Language = 'tr' | 'en' | 'auto';
export type Channel = 'Etsy' | 'Amazon' | 'Shopify' | 'Generic';

export interface SeoAttributes {
  type?: string;
  material?: string;
  color?: string;
  style?: string[];
  audience?: string[];
}

export interface Dimensions {
  width_cm: number | null;
  height_cm: number | null;
  depth_cm: number | null;
}

export interface SeoPayload {
  attributes: SeoAttributes;
  seo: {
    primary_title: string;
    alt_titles: string[];
    keywords: string[];
    hashtags: string[];
    bullets: string[];
    category_path: string[];
    materials: string[];
    colors: string[];
    dimensions: Dimensions;
  };
  etl: {
    channel: Channel;
    lang: Language;
    confidence: number;
  };
}

export interface CompetitorItemInput {
  analysis_id: string;
  source: string;
  title: string;
  url: string;
  image_url?: string;
  price?: number;
  similarity_score?: number;
  meta?: Record<string, unknown>;
}
