-- ============================================================
-- NFC Digital Card System — Database Schema
-- Run this in Supabase: Project → SQL Editor → New Query → Run
-- ============================================================

-- 1. PROFILES TABLE
-- One row per user. id is linked to Supabase's built-in auth.users table,
-- so it's automatically tied to whoever signed up.
create table public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  username    text unique not null,        -- used in the public URL: card.html?u=username
  full_name   text not null,
  role        text,                        -- e.g. "Data Analyst & AI Data Specialist"
  bio         text,
  email       text,
  phone       text,
  website     text,
  cv_url      text,                        -- path to uploaded CV in storage
  avatar_url  text,
  theme       text default 'obsidian',     -- 'obsidian' | 'ledger' | 'terminal'
  socials     jsonb default '{}'::jsonb,   -- { "linkedin": "...", "github": "...", ... }
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- 2. ROW LEVEL SECURITY
-- Anyone can VIEW a profile (that's the point — it's a public card).
-- Only the owner can create/edit their own row.
alter table public.profiles enable row level security;

create policy "Profiles are publicly viewable"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 3. AUTO-UPDATE updated_at ON EDIT
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();

-- 4. STORAGE BUCKETS (for CVs and avatar photos)
insert into storage.buckets (id, name, public) values ('cvs', 'cvs', true);
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

-- Anyone can read (so the public card page can display the CV/photo)
create policy "CV files are publicly readable"
  on storage.objects for select
  using (bucket_id = 'cvs');

create policy "Avatar files are publicly readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Only the owner can upload to their own folder (folder name = their user id)
create policy "Users can upload their own CV"
  on storage.objects for insert
  with check (bucket_id = 'cvs' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can update their own CV"
  on storage.objects for update
  using (bucket_id = 'cvs' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can update their own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
