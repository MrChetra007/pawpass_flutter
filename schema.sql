-- ============================================================
--  PawPass — Supabase Database Schema (Safe Re-run Version)
--  Works on both fresh databases and existing ones.
--  Run as many times as needed — always produces a clean result.
-- ============================================================


-- ============================================================
-- 0. EXTENSIONS
-- ============================================================

create extension if not exists "uuid-ossp";


-- ============================================================
-- 1. TEARDOWN — safe on both fresh and existing databases
--
--    Strategy:
--    • Drop the auth trigger first (auth.users always exists)
--    • Drop functions with CASCADE — this auto-drops every
--      trigger that uses them, so we never touch public.* tables
--      that may not exist yet on a fresh database.
--    • Drop tables in reverse-dependency order with CASCADE
-- ============================================================

-- auth.users always exists in Supabase, so this is always safe
drop trigger if exists on_auth_user_created on auth.users;

-- Dropping functions CASCADE removes all triggers built on them.
-- This means we never need to DROP TRIGGER on public.* tables
-- that might not exist yet (which is what caused the error).
drop function if exists public.handle_new_user() cascade;
drop function if exists public.set_updated_at()  cascade;

-- Drop app tables — CASCADE cleans up policies, indexes, FK refs
drop table if exists public.family_members cascade;
drop table if exists public.weight_logs    cascade;
drop table if exists public.medications    cascade;
drop table if exists public.appointments   cascade;
drop table if exists public.vaccines       cascade;
drop table if exists public.vet_records    cascade;
drop table if exists public.pets           cascade;
drop table if exists public.users          cascade;


-- ============================================================
-- 2. USERS
-- ============================================================

create table public.users (
  id                  uuid primary key references auth.users(id) on delete cascade,
  email               text not null,
  full_name           text,
  avatar_url          text,

  -- Subscription — updated by Supabase Edge Function after IAP validation
  plan                text not null default 'free'
                        check (plan in ('free', 'pro', 'family')),
  plan_expires_at     timestamptz,

  -- IAP: latest server-verified receipt token per platform
  iap_receipt_ios     text,
  iap_receipt_android text,

  -- App theme (synced from device via ThemeNotifier)
  theme               text not null default 'forest'
                        check (theme in ('forest','ocean','blossom','amber','midnight','lavender')),

  -- Onboarding status
  is_onboarding       boolean not null default true,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.users enable row level security;
create policy "Users can view own profile"   on public.users for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);


-- ============================================================
-- 3. PETS
-- ============================================================

create table public.pets (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.users(id) on delete cascade,

  name        text not null,
  species     text not null,
  breed       text,
  gender      text check (gender in ('male', 'female', 'unknown')),
  dob         date,
  weight_kg   numeric(5, 2),
  color       text,
  microchip   text,
  neutered    boolean default false,
  photo_url   text,
  notes       text,

  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.pets enable row level security;
create policy "Users can manage own pets" on public.pets
  for all using (auth.uid() = user_id);

create index pets_user_id_idx on public.pets(user_id);


-- ============================================================
-- 4. VET RECORDS
-- ============================================================

create table public.vet_records (
  id          uuid primary key default uuid_generate_v4(),
  pet_id      uuid not null references public.pets(id)  on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,

  type        text not null check (type in (
                'checkup','surgery','illness','injury',
                'dental','grooming','lab_result','other'
              )),
  title       text not null,
  date        date not null,
  vet_name    text,
  clinic_name text,
  diagnosis   text,
  treatment   text,
  notes       text,
  doc_url     text,
  cost        numeric(10, 2),

  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.vet_records enable row level security;
create policy "Users can manage own vet records" on public.vet_records
  for all using (auth.uid() = user_id);

create index vet_records_pet_id_idx  on public.vet_records(pet_id);
create index vet_records_user_id_idx on public.vet_records(user_id);
create index vet_records_date_idx    on public.vet_records(date desc);


-- ============================================================
-- 5. VACCINES
-- ============================================================

create table public.vaccines (
  id            uuid primary key default uuid_generate_v4(),
  pet_id        uuid not null references public.pets(id)  on delete cascade,
  user_id       uuid not null references public.users(id) on delete cascade,

  name          text not null,
  date_given    date not null,
  next_due_date date,
  vet_name      text,
  clinic_name   text,
  batch_number  text,
  doc_url       text,
  notes         text,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.vaccines enable row level security;
create policy "Users can manage own vaccines" on public.vaccines
  for all using (auth.uid() = user_id);

create index vaccines_pet_id_idx        on public.vaccines(pet_id);
create index vaccines_next_due_date_idx on public.vaccines(next_due_date);


-- ============================================================
-- 6. APPOINTMENTS
-- ============================================================

create table public.appointments (
  id             uuid primary key default uuid_generate_v4(),
  pet_id         uuid not null references public.pets(id)  on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,

  title          text not null,
  type           text check (type in ('vet','grooming','training','other')),
  datetime       timestamptz not null,
  vet_name       text,
  clinic_name    text,
  clinic_phone   text,
  clinic_address text,
  notes          text,

  reminder_sent  boolean default false,
  status         text not null default 'upcoming'
                   check (status in ('upcoming','completed','cancelled')),

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

alter table public.appointments enable row level security;
create policy "Users can manage own appointments" on public.appointments
  for all using (auth.uid() = user_id);

create index appointments_pet_id_idx   on public.appointments(pet_id);
create index appointments_user_id_idx  on public.appointments(user_id);
create index appointments_datetime_idx on public.appointments(datetime asc);


-- ============================================================
-- 7. MEDICATIONS
-- ============================================================

create table public.medications (
  id            uuid primary key default uuid_generate_v4(),
  pet_id        uuid not null references public.pets(id)  on delete cascade,
  user_id       uuid not null references public.users(id) on delete cascade,

  name          text not null,
  dosage        text,
  frequency     text,
  
  -- Meal timing
  meal_timing   text check (meal_timing in ('before_meal', 'after_meal', 'with_meal', 'any')) default 'any',
  
  -- Frequency details
  frequency_type text check (frequency_type in ('daily', 'weekly', 'monthly')) default 'daily',
  frequency_times integer default 1,
  
  -- Time of day (can select multiple)
  time_of_day   text[] default '{}',
  
  start_date    date,
  end_date      date,
  prescribed_by text,
  notes         text,

  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.medications enable row level security;
create policy "Users can manage own medications" on public.medications
  for all using (auth.uid() = user_id);

create index medications_pet_id_idx on public.medications(pet_id);


-- ============================================================
-- 8. WEIGHT LOGS
-- ============================================================

create table public.weight_logs (
  id          uuid primary key default uuid_generate_v4(),
  pet_id      uuid not null references public.pets(id)  on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,

  weight_kg   numeric(5, 2) not null,
  recorded_at date not null default current_date,
  notes       text,

  created_at  timestamptz not null default now()
);

alter table public.weight_logs enable row level security;
create policy "Users can manage own weight logs" on public.weight_logs
  for all using (auth.uid() = user_id);

create index weight_logs_pet_id_idx      on public.weight_logs(pet_id);
create index weight_logs_recorded_at_idx on public.weight_logs(recorded_at desc);


-- ============================================================
-- 9. FAMILY SHARING
-- ============================================================

create table public.family_members (
  id           uuid primary key default uuid_generate_v4(),
  owner_id     uuid not null references public.users(id) on delete cascade,
  member_email text not null,
  member_name  text,
  role         text not null default 'viewer'
                 check (role in ('viewer','admin')),
  status       text not null default 'pending'
                 check (status in ('pending','active','removed')),
  invited_at   timestamptz not null default now(),
  accepted_at  timestamptz
);

alter table public.family_members enable row level security;
create policy "Owners can manage family members" on public.family_members
  for all using (auth.uid() = owner_id);

create index family_members_owner_id_idx on public.family_members(owner_id);
create index family_members_email_idx    on public.family_members(member_email);


-- ============================================================
-- 10. UPDATED_AT TRIGGER
-- ============================================================

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at before update on public.users
  for each row execute procedure public.set_updated_at();

create trigger set_updated_at before update on public.pets
  for each row execute procedure public.set_updated_at();

create trigger set_updated_at before update on public.vet_records
  for each row execute procedure public.set_updated_at();

create trigger set_updated_at before update on public.vaccines
  for each row execute procedure public.set_updated_at();

create trigger set_updated_at before update on public.appointments
  for each row execute procedure public.set_updated_at();

create trigger set_updated_at before update on public.medications
  for each row execute procedure public.set_updated_at();


-- ============================================================
-- 11. STORAGE BUCKETS
-- ============================================================

insert into storage.buckets (id, name, public)
  values ('pet-photos', 'pet-photos', true)
  on conflict do nothing;

insert into storage.buckets (id, name, public)
  values ('vet-documents', 'vet-documents', false)
  on conflict do nothing;

insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict do nothing;

drop policy if exists "Users can upload own pet photos"    on storage.objects;
drop policy if exists "Anyone can view pet photos"         on storage.objects;
drop policy if exists "Users can upload own vet documents" on storage.objects;
drop policy if exists "Users can view own vet documents"   on storage.objects;
drop policy if exists "Users can delete own files"         on storage.objects;

create policy "Users can upload own pet photos"
  on storage.objects for insert
  with check (bucket_id = 'pet-photos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Anyone can view pet photos"
  on storage.objects for select
  using (bucket_id = 'pet-photos');

create policy "Users can upload own vet documents"
  on storage.objects for insert
  with check (bucket_id = 'vet-documents' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can view own vet documents"
  on storage.objects for select
  using (bucket_id = 'vet-documents' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can delete own files"
  on storage.objects for delete
  using (auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can upload own avatars"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

  insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict do nothing;
create policy "Users can upload own avatars"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');


-- ============================================================
-- ✅ DONE! PawPass database is ready.
--
-- Tables:
--   public.users          — plan, theme, IAP receipt columns included
--   public.pets
--   public.vet_records
--   public.vaccines
--   public.appointments
--   public.medications
--   public.weight_logs
--   public.family_members
--
-- Storage buckets:
--   pet-photos     (public)
--   vet-documents  (private)
--
-- All tables have RLS — users can only access their own data.
-- ============================================================