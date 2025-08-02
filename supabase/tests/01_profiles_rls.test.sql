begin;

-- Charge pgTAP et annonce le nombre de tests
create extension if not exists pgtap with schema extensions;
select plan(24);

-- ========================================
-- 1. TESTS DE SCHÉMA
-- ========================================

-- Existence table et colonnes
select has_table('public', 'profiles', 'Table profiles créée');
select has_column('public','profiles','id', 'Colonne id OK');
select has_column('public','profiles','username', 'Colonne username');
select has_column('public','profiles','display_name', 'Colonne display_name');
select has_column('public','profiles','bio', 'Colonne bio');
select has_column('public','profiles','is_active', 'Colonne is_active');

-- Types et contraintes
select col_type_is('public','profiles','id', 'uuid', 'id en uuid');
select col_is_pk('public','profiles','id', 'id est PK');
select col_not_null('public','profiles','username', 'username NOT NULL');
select col_is_unique('public','profiles','username', 'username UNIQUE');
select col_type_is('public','profiles','preferences','jsonb', 'preferences en JSONB');

-- Valeurs par défaut
select ok(
  (select column_default = 'gen_random_uuid()'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'),
  'DEFAULT uuid pour id'
);

select ok(
  (select column_default = 'true'
   from information_schema.columns
   where table_schema = 'public' and table_name = 'profiles' and column_name = 'is_active'),
  'DEFAULT true pour is_active'
);

-- Index
select has_index('public','profiles','profiles_username_idx', 'Index username');

-- Fonction et trigger
select has_function('public','handle_updated_at', 'Fonction handle_updated_at');
select has_trigger('public','profiles','on_profile_update', 'Trigger updated_at');

-- Policies RLS
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
    and policyname = 'Users can manage their own profile'
  ),
  'Policy propriétaire présente'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
    and policyname = 'Public profiles are viewable by everyone'
  ),
  'Policy lecture publique présente'
);

-- ========================================
-- 2. TESTS DE COMPORTEMENT (SANS RLS)
-- ========================================

-- Teste en tant que service_role pour bypasser RLS
set local role service_role;

-- Test contrainte : username trop court
select throws_ok(
  $$insert into public.profiles (id, username)
    values (gen_random_uuid(),'ab')$$,
  '23514', -- check constraint violation
  null,
  'Username trop court rejeté'
);

-- Test contrainte : username trop long
select throws_ok(
  $$insert into public.profiles (id, username)
    values (gen_random_uuid(),'username_vraiment_trop_long_pour_la_contrainte_de_30_caracteres')$$,
  '23514', -- check constraint violation
  null,
  'Username trop long rejeté'
);

-- Test contrainte JSON preferences (doit être un objet)
select throws_ok(
  $$insert into public.profiles (id, username, preferences)
    values (gen_random_uuid(),'test_json_user', '"string_au_lieu_objet"'::jsonb)$$,
  '23514', -- check constraint violation
  null,
  'Preferences non-objet rejetées'
);

-- Test insertion valide
select lives_ok(
  $$insert into public.profiles (id, username, display_name, preferences)
    values (gen_random_uuid(), 'test_user_valid', 'Test User', '{"notifications": true}'::jsonb)$$,
  'Insertion profil valide réussit'
);

-- Test contrainte URL (si URL fournie, doit être valide)
select throws_ok(
  $$insert into public.profiles (id, username, avatar_url)
    values (gen_random_uuid(), 'test_url_user', 'pas_une_url_valide')$$,
  '23514', -- check constraint violation
  null,
  'URL avatar invalide rejetée'
);

-- Test contrainte bio (max 500 caractères)
select throws_ok(
  $$insert into public.profiles (id, username, bio)
    values (gen_random_uuid(), 'test_bio_user', repeat('a', 501))$$,
  '23514', -- check constraint violation
  null,
  'Bio trop longue rejetée'
);

select * from finish();
rollback;