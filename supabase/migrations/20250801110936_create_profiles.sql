-- ============================================
-- MIGRATION UNIVERSELLE POUR TOUS LES ENVIRONNEMENTS
-- ============================================

-- Extension pour UUID (obligatoire pour gen_random_uuid)
create extension if not exists "pgcrypto" with schema public;

-- Table des profils utilisateur
create table if not exists public.profiles (
    id uuid primary key default gen_random_uuid(),
    username text unique not null check (length(username) >= 3 and length(username) <= 30),
    display_name text check (length(display_name) <= 50),
    avatar_url text check (avatar_url ~ '^https?://.*'),
    bio text check (length(bio) <= 500),
    preferences jsonb default '{}'::jsonb not null check (jsonb_typeof(preferences) = 'object'),
    is_active boolean default true not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);

-- Index performant pour la recherche/auto-complétion sur le pseudo
create index if not exists profiles_username_idx on public.profiles (username);
create index if not exists profiles_display_name_idx on public.profiles (display_name) where display_name is not null;
create index if not exists profiles_active_idx on public.profiles (is_active) where is_active = true;

-- Fonction de trigger pour MAJ automatique du updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Trigger pour updated_at
drop trigger if exists on_profile_update on public.profiles;
create trigger on_profile_update
    before update on public.profiles
    for each row
    execute procedure public.handle_updated_at();

-- Active la Row Level Security
alter table public.profiles enable row level security;

-- ============================================
-- SUPPRESSION DE TOUTES LES ANCIENNES POLITIQUES
-- ============================================
-- Supprimer explicitement les anciennes politiques problématiques
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists "Users can manage their own profile" on public.profiles;

-- Liste exhaustive de tous les noms de politiques possibles (au cas où)
drop policy if exists "Profiles are viewable" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can delete their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Profiles read access" on public.profiles;
drop policy if exists "Profile owner update" on public.profiles;
drop policy if exists "Profile owner delete" on public.profiles;
drop policy if exists "Authenticated users insert" on public.profiles;

-- ============================================
-- CRÉATION DES NOUVELLES POLITIQUES OPTIMISÉES
-- ============================================

-- Policy 1: Lecture (optimisée avec une seule évaluation)
create policy "profiles_select_policy"
    on public.profiles
    for select
    using (
        is_active = true 
        OR 
        id = (select auth.uid())
    );

-- Policy 2: Mise à jour (propriétaire uniquement)
create policy "profiles_update_policy"
    on public.profiles
    for update
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

-- Policy 3: Suppression (propriétaire uniquement)
create policy "profiles_delete_policy"
    on public.profiles
    for delete
    using (id = (select auth.uid()));

-- Policy 4: Insertion (utilisateurs authentifiés)
create policy "profiles_insert_policy"
    on public.profiles
    for insert
    with check (id = (select auth.uid()));

-- ============================================
-- PERMISSIONS
-- ============================================
grant select on table public.profiles to anon, authenticated;
grant all on table public.profiles to service_role;