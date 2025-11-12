create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;
create extension if not exists vector;

create type analysis_status as enum ('queued','processing','done','error');
create type batch_status as enum ('queued','processing','done','error');
create type job_status as enum ('queued','processing','done','error');

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  name text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.credits (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  balance integer not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.billing_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(user_id) on delete cascade,
  event_id text not null,
  event_type text not null,
  payload jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique(event_id)
);

create table if not exists public.analyses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  status analysis_status not null default 'queued',
  image_url text not null,
  input_title text,
  input_desc text,
  channel text default 'Generic',
  lang text default 'tr',
  output jsonb,
  competitor_summary jsonb,
  embedding vector(1536),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  cost_credits integer not null default 1
);

create index if not exists analyses_user_created_idx on public.analyses(user_id, created_at desc);

create table if not exists public.competitor_items (
  id uuid primary key default uuid_generate_v4(),
  analysis_id uuid not null references public.analyses(id) on delete cascade,
  source text,
  title text,
  url text,
  image_url text,
  price numeric,
  similarity_score numeric,
  meta jsonb default '{}'::jsonb
);

create table if not exists public.batches (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  status batch_status not null default 'queued',
  file_url text not null,
  stats jsonb default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.jobs (
  id uuid primary key default uuid_generate_v4(),
  type text not null,
  payload jsonb not null,
  status job_status not null default 'queued',
  retry_count int not null default 0,
  user_id uuid references public.profiles(user_id) on delete cascade,
  unique_key text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (unique_key)
);

create table if not exists public.api_usage (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(user_id) on delete cascade,
  func text not null,
  tokens_in int,
  tokens_out int,
  cost_usd numeric,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.credit_transactions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  unique_key text not null,
  amount integer not null,
  direction text not null check (direction in ('debit','refund','grant')),
  created_at timestamptz not null default timezone('utc', now()),
  constraint credit_transactions_user_unique unique (user_id, unique_key)
);

create or replace function public.trigger_set_timestamp()
returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

create trigger set_timestamp before update on public.analyses
for each row execute procedure public.trigger_set_timestamp();

create trigger set_timestamp_jobs before update on public.jobs
for each row execute procedure public.trigger_set_timestamp();

create or replace function public.ensure_profile()
returns trigger as $$
begin
  if new.raw_user_meta_data is null then
    return new;
  end if;
  insert into public.profiles(user_id, email, name)
  values(new.id, new.email, new.raw_user_meta_data->> 'full_name')
  on conflict(user_id) do update
    set email = excluded.email,
        name = coalesce(excluded.name, public.profiles.name);
  insert into public.credits(user_id, balance)
  values(new.id, 0)
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update of email on auth.users
  for each row execute procedure public.ensure_profile();

create or replace function public.debit_credits(p_user uuid, p_unique_key text, p_amount int default 1)
returns credits as $$
declare result credits;
begin
  perform 1 from public.credit_transactions where user_id = p_user and unique_key = p_unique_key;
  if found then
    select * into result from public.credits where user_id = p_user;
    return result;
  end if;

  update public.credits
    set balance = balance - p_amount,
        updated_at = timezone('utc', now())
  where user_id = p_user and balance >= p_amount
  returning * into result;

  if not found then
    raise exception 'INSUFFICIENT_CREDITS';
  end if;

  insert into public.credit_transactions(user_id, unique_key, amount, direction)
    values(p_user, p_unique_key, p_amount, 'debit');

  return result;
end;
$$ language plpgsql security definer;

create or replace function public.refund_credits(p_user uuid, p_unique_key text, p_amount int default 1)
returns credits as $$
declare result credits;
begin
  perform 1 from public.credit_transactions where user_id = p_user and unique_key = p_unique_key and direction = 'refund';
  if found then
    select * into result from public.credits where user_id = p_user;
    return result;
  end if;

  update public.credits
    set balance = balance + p_amount,
        updated_at = timezone('utc', now())
  where user_id = p_user
  returning * into result;

  insert into public.credit_transactions(user_id, unique_key, amount, direction)
    values(p_user, p_unique_key, p_amount, 'refund');

  return result;
end;
$$ language plpgsql security definer;

create or replace function public.grant_credits(p_user uuid, p_unique_key text, p_amount int)
returns credits as $$
declare result credits;
begin
  perform 1 from public.credit_transactions where user_id = p_user and unique_key = p_unique_key and direction = 'grant';
  if found then
    select * into result from public.credits where user_id = p_user;
    return result;
  end if;

  insert into public.credits(user_id, balance)
  values(p_user, 0)
  on conflict (user_id) do nothing;

  update public.credits
    set balance = balance + p_amount,
        updated_at = timezone('utc', now())
  where user_id = p_user
  returning * into result;

  insert into public.credit_transactions(user_id, unique_key, amount, direction)
    values(p_user, p_unique_key, p_amount, 'grant');

  return result;
end;
$$ language plpgsql security definer;

alter table public.profiles enable row level security;
alter table public.credits enable row level security;
alter table public.billing_events enable row level security;
alter table public.analyses enable row level security;
alter table public.competitor_items enable row level security;
alter table public.batches enable row level security;
alter table public.jobs enable row level security;
alter table public.api_usage enable row level security;
alter table public.credit_transactions enable row level security;

create policy "Profiles are self only" on public.profiles
  for select using (auth.uid() = user_id);

create policy "Credits readable by owner" on public.credits
  for select using (auth.uid() = user_id);

create policy "Credits maintainable by owner" on public.credits
  for update using (auth.uid() = user_id);

create policy "Analyses readable" on public.analyses
  for select using (auth.uid() = user_id);

create policy "Analyses insert" on public.analyses
  for insert with check (auth.uid() = user_id);

create policy "Analyses update" on public.analyses
  for update using (auth.uid() = user_id);

create policy "Competitors readable" on public.competitor_items
  for select using (exists (select 1 from public.analyses where id = analysis_id and user_id = auth.uid()));

create policy "Competitors insert" on public.competitor_items
  for insert with check (exists (select 1 from public.analyses where id = analysis_id and user_id = auth.uid()));

create policy "Batches readable" on public.batches
  for select using (auth.uid() = user_id);

create policy "Batches insert" on public.batches
  for insert with check (auth.uid() = user_id);

create policy "Jobs readable" on public.jobs
  for select using (auth.uid() = user_id);

create policy "Jobs insert" on public.jobs
  for insert with check (auth.uid() = user_id);

create policy "Api usage readable" on public.api_usage
  for select using (auth.uid() = user_id);

create policy "Credit transactions readable" on public.credit_transactions
  for select using (auth.uid() = user_id);

-- Storage buckets
insert into storage.buckets(id, name, public)
values('product-images','product-images', false)
on conflict do nothing;

insert into storage.buckets(id, name, public)
values('batch-imports','batch-imports', false)
on conflict do nothing;

create policy "Product images owner read" on storage.objects
  for select using (bucket_id = 'product-images' and owner = auth.uid());

create policy "Product images insert" on storage.objects
  for insert with check (bucket_id = 'product-images' and owner = auth.uid());

create policy "Batch imports owner read" on storage.objects
  for select using (bucket_id = 'batch-imports' and owner = auth.uid());

create policy "Batch imports insert" on storage.objects
  for insert with check (bucket_id = 'batch-imports' and owner = auth.uid());
