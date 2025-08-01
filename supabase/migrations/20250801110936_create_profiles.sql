-- Extension pour UUID (obligatoire pour gen_random_uuid)
create extension if not exists "pgcrypto" with schema public;

-- Table des profils utilisateur
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),         -- Génération automatique d’UUID (lié à auth.uid())
  username text unique not null,                         -- Unicité du pseudo
  avatar_url text,                                       -- URL de la photo de profil (optionnelle)
  preferences jsonb default '{}'::jsonb,                 -- Préférences utilisateur (toujours un objet JSON par défaut)
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- Index performant pour la recherche/auto-complétion sur le pseudo
create index if not exists profiles_username_idx on public.profiles (username);

-- Fonction de trigger pour MAJ automatique du updated_at
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
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

-- On drop la policy si elle existe déjà (sécurise les re-migrations)
drop policy if exists "Users can manage their own profile" on public.profiles;

-- Policy : Seul l’utilisateur connecté (auth.uid()) accède à son profil (lecture, modif, suppression, etc.)
create policy "Users can manage their own profile"
  on public.profiles
  for all
  using (auth.uid() = id);

-- Droits d’accès API (à adapter selon tes besoins; ici tous les rôles peuvent accéder via API Supabase)
grant all on table public.profiles to anon, authenticated, service_role;

-- (Optionnel) Pour devs : autorise les inserts dans la colonne id si besoin côté back
alter table public.profiles alter column id drop default;
alter table public.profiles alter column id set default gen_random_uuid();

-- (Optionnel) Seed de profil test pour le dev local (à retirer en prod)
-- insert into public.profiles (username, avatar_url) values ('demo_user', 'https://example.com/avatar.png');
