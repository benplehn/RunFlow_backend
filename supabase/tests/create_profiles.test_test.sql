begin;

-- Charge pgTAP et annonce le nombre de tests
create extension if not exists pgtap with schema extensions;
select plan(22);

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
-- 2. TESTS DE COMPORTEMENT
-- ========================================

-- Prépare deux comptes auth
insert into auth.users (id, email) values
  ('123e4567-e89b-12d3-a456-426614174000', 'user1@test.com'),
  ('987fcdeb-51a2-43d7-9012-345678901234', 'user2@test.com');

-- Test User 1 : création profil
set local role authenticated;
set local request.jwt.claim.sub = '123e4567-e89b-12d3-a456-426614174000';

select lives_ok(
  $$insert into public.profiles (id, username, display_name)
    values ('123e4567-e89b-12d3-a456-426614174000','user1_test', 'User One')$$,
  'User 1 crée son profil'
);

-- Test User 2 : création son propre profil
set local request.jwt.claim.sub = '987fcdeb-51a2-43d7-9012-345678901234';

select lives_ok(
  $$insert into public.profiles (id, username)
    values ('987fcdeb-51a2-43d7-9012-345678901234','user2_test')$$,
  'User 2 crée son profil'
);

-- Test lecture : User 2 peut voir les profils publics (is_active=true)
select results_eq(
  'select count(*) from public.profiles where is_active = true',
  ARRAY[2::bigint],
  'User 2 voit tous les profils actifs'
);

-- Test contrainte : username trop court
select throws_ok(
  $$insert into public.profiles (id, username)
    values ('111e1111-e11b-11d1-a111-111111111111','ab')$$,
  '23514', -- check constraint violation
  null,
  'Username trop court rejeté'
);

-- Test trigger updated_at
select ok(
  (select updated_at > created_at from public.profiles 
   where id = '987fcdeb-51a2-43d7-9012-345678901234'
   limit 1) is false,
  'updated_at = created_at à la création'
);

select * from finish();
rollback;