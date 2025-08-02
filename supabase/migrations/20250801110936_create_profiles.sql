-- Extension pour UUID (obligatoire pour gen_random_uuid)
create extension if not exists "pgcrypto" with schema public;

-- Table des profils utilisateur
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  username text unique not null check (length(username) >= 3 and length(username) <= 30),
  display_name text check (length(display_name) <= 50), -- Nom d'affichage (optionnel)
  avatar_url text check (avatar_url ~ '^https?://.*'),   -- Validation URL basique
  bio text check (length(bio) <= 500),                   -- Courte bio utilisateur
  preferences jsonb default '{}'::jsonb not null,        -- NOT NULL explicite
  is_active boolean default true not null,               -- Désactivation soft delete
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Index performant pour la recherche/auto-complétion sur le pseudo
create index if not exists profiles_username_idx on public.profiles (username);
create index if not exists profiles_display_name_idx on public.profiles (display_name) where display_name is not null;
create index if not exists profiles_active_idx on public.profiles (is_active) where is_active = true;

-- Fonction de trigger pour MAJ automatique du updated_at
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer -- Sécurité renforcée
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Sécurise la migration : on efface d'abord l'ancien trigger si existant
drop trigger if exists on_profile_update on public.profiles;
create trigger on_profile_update
  before update on public.profiles
  for each row
  execute procedure public.handle_updated_at();

-- Active la Row Level Security (obligatoire pour Supabase Auth)
alter table public.profiles enable row level security;

-- Policies RLS plus granulaires
drop policy if exists "Users can manage their own profile" on public.profiles;
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;

-- Policy 1: Utilisateurs authentifiés peuvent voir les profils actifs
create policy "Public profiles are viewable by everyone"
  on public.profiles
  for select
  using (is_active = true);

-- Policy 2: Seul le propriétaire peut modifier/supprimer son profil
create policy "Users can manage their own profile"
  on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Droits d'accès API
grant select on table public.profiles to anon, authenticated;
grant all on table public.profiles to service_role;

-- Contrainte check pour valider les préférences JSON (structure basique)
alter table public.profiles add constraint preferences_valid_json 
  check (jsonb_typeof(preferences) = 'object');