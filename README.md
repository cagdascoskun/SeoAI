# AI SEO Tagger & Competitor Scout

Flutter + Supabase + OpenAI + Bing + Lemon Squeezy monorepo that scores e-commerce product photos, produces SEO metadata, and benchmarks similar listings. The project ships a multi-platform Flutter client, Supabase SQL schema, Edge Functions, and shared models for type-safe contracts.

## Monorepo Yapısı

```
ai-seo-scout/
  app/                     # Flutter (iOS/Android/Web/Desktop)
  packages/shared_models/  # Dart veri sözleşmeleri
  supabase/                # SQL şema + Edge Functions (Deno)
  docs/edge-functions.http # Örnek HTTP istekleri
  .env.example             # Gerekli değişkenler
```

## Ön Koşullar

- Flutter 3.24+
- Supabase CLI (`npm i -g supabase`)
- Deno 1.41+
- An OpenAI API key (Vision + Embedding yetkili)
- Bing Visual Search API anahtarı (Azure Cognitive Services)
- Lemon Squeezy mağazası ve kredi ürünleri

## Kurulum Adımları

1. **Env dosyasını güncelleyin**
   ```bash
   cp .env.example .env
   # SUPABASE_URL, SUPABASE_ANON_KEY, ... değerlerini doldurun
   ```

2. **Supabase projesini başlatın**
   ```bash
   supabase link --project-ref <project-ref>
   supabase db push --file supabase/schema.sql
   ```

3. **Storage bucket izinleri** – SQL dosyası `product-images` ve `batch-imports` bucket’larını ve RLS politikalarını otomatik oluşturur. CLI ile tekrar oluşturmaya gerek yoktur.

4. **Edge Functions**
   ```bash
   cd supabase/functions
   supabase functions deploy credit-debit
   supabase functions deploy analyze-image
   supabase functions deploy competitor-search
   supabase functions deploy batch-dispatcher
   supabase functions deploy lemonsqueezy-webhooks
   ```
   > `OPENAI_API_KEY`, `BING_SEARCH_API_KEY`, `LEMON_SQUEEZY_*` değişkenlerini `supabase secrets set` ile yüklemeyi unutmayın.

5. **Flutter istemcisi**
   ```bash
   cd app
   flutter pub get
   flutter run \
     --dart-define=SUPABASE_URL=$SUPABASE_URL \
     --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
     --dart-define=LEMON_SQUEEZY_STORE_ID=$LEMON_SQUEEZY_STORE_ID \
     --dart-define=LEMON_SQUEEZY_RETURN_URL=https://yourdomain.com/thanks
   ```

## Lemon Squeezy Entegrasyonu

1. Mağazanızda `CREDIT_50`, `CREDIT_250`, `CREDIT_1000` varyantlarını oluşturun (veya var olan ID’leri kullanın).
2. Webhook URL’si: `https://<project-ref>.functions.supabase.co/lemonsqueezy-webhooks`
3. Events: `order_created`, `subscription_created`, `subscription_payment_succeeded`
4. `LEMON_SQUEEZY_SIGNING_SECRET` değerini Supabase secrets içine yazın. Webhook fonksiyonu HMAC doğrulaması ve idempotent kredi yükleme yapar.

## OpenAI + Bing Kullanımı

- OpenAI `gpt-4o-mini` vision + `text-embedding-3-small` API’leri **yalnızca edge function** içinde çağrılır.
- Bing Visual Search + Web Search anahtarını `BING_SEARCH_API_KEY` ile aktarın.
- Cost optimizasyon ipuçları README sonunda, fonksiyonlar prompts ayarlanmıştır.

## Batch & Kuyruk

- CSV kolonları: `image_url,title,description,channel,lang`
- `batch-dispatcher` fonksiyonu her satırı `jobs` tablosuna (idempotent `unique_key`) yazar, eşzamanlılık `BATCH_CONCURRENCY_LIMIT` ile sınırlandırılır.
- Batch durumu Flutter uygulamasındaki “Toplu Analiz” ekranından izlenebilir.

## .http Örnekleri

`docs/edge-functions.http` dosyası Postman / VS Code Rest Client ile çağırabileceğiniz örnek payload’ları içerir (credit reserve, analyze-image, competitor-search, batch-dispatcher).

## Flutter Özellikleri

- Supabase Auth (magic link) + Riverpod state yönetimi
- Yeni Analiz akışı: görsel yükle → kredi rezervasyonu → Edge Function tetikleri
- Rakip tablosu, SEO çıktıları, CSV/JSON dışa aktarım
- Batch CSV yükleme & durum takibi
- Lemon Squeezy kredi paket ekranı (checkout redirect)
- TR varsayılan UI + EN desteği (basit yerelleştirme katmanı)

## Test & Kabul Kontrol Listesi

- [ ] Kredisi olmayan kullanıcıya `credit-debit` hata döndürür, Flutter toast gösterir.
- [ ] Supabase Functions <30 sn içinde `analyses.status = done` günceller.
- [ ] `competitor_items` tablosu 10 sonuç ve 0–1 arası benzerlik puanı üretir.
- [ ] 1000 satırlık batch CSV, `jobs` kuyruğuna idempotent yazılır.
- [ ] Lemon Squeezy webhook’u tetiklendiğinde `credits.balance` artar, `billing_events` kayıt tutar.
- [ ] RLS politikaları nedeniyle kullanıcılar birbirlerinin verilerini göremez.
- [ ] Flutter uygulaması iOS/Android/Web’de giriş → analiz → özet akışını tamamlar.

## Maliyet ve Dayanıklılık Notları

- Vision çağrıları `gpt-4o-mini` ile tutulur; embedding modeli `text-embedding-3-small` seçildi.
- `credit-debit` fonksiyonu idempotent `credit_transactions` tablosu ile çift harcamayı engeller.
- `jobs` tablosu `unique_key` indeksine sahip olduğu için batch tekrar denemeleri güvenlidir.
- Uzun süreli iş hatalarında `credit-debit` refund endpoint’i çağrılarak kredi iadesi yapılır.
