-- Fridge Fit Chef: shared room sync (family demo)
-- Run in Supabase SQL Editor

create table if not exists public.fridge_data (
  room_id text primary key,
  inventory jsonb not null default '[]'::jsonb,
  settings jsonb,
  custom_foods jsonb not null default '[]'::jsonb,
  custom_recipes jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.fridge_data enable row level security;

-- Demo policy: anyone who knows room_id can read/write (NOT for production)
create policy "fridge_room_select" on public.fridge_data
  for select using (true);

create policy "fridge_room_insert" on public.fridge_data
  for insert with check (true);

create policy "fridge_room_update" on public.fridge_data
  for update using (true) with check (true);

-- Realtime: enable in Dashboard → Database → Replication for fridge_data

grant select, insert, update on public.fridge_data to anon, authenticated;
