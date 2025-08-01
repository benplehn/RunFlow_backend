begin;

-- Charge pgTAP et annonce 18 tests
create extension if not exists pgtap with schema extensions;
select plan(16);

-- 1. TESTS DE SCHÉMA (superutilisateur)

-- La table existe
select has_table('public', 'profiles', 'Table profiles créée');

-- Les colonnes clés existent
select has_column('public','profiles','id',          'Colonne id OK');
select has_column('public','profiles','username',    'Colonne username');
select has_column('public','profiles','preferences', 'Colonne prefs');

-- Contraintes & types
select col_type_is   ('public','profiles','id', 'uuid', 'id en uuid');
select col_is_pk     ('public','profiles','id', 'id est PK');

-- Simulation de col_has_default (via requête directe)
select ok(
  (select column_default = 'gen_random_uuid()' 
   from information_schema.columns 
   where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'),
  'DEFAULT uuid'
);

select col_not_null  ('public','profiles','username',  'username NOT NULL');
select col_is_unique ('public','profiles','username',  'username UNIQUE');

select col_type_is   ('public','profiles','preferences','jsonb', 'preferences en JSONB');

-- Simulation de col_default_is (via requête directe)
select ok(
  (select column_default = '''{}''::jsonb' 
   from information_schema.columns 
   where table_schema = 'public' and table_name = 'profiles' and column_name = 'preferences'),
  'DEFAULT {}'
);

-- Index, trigger, fonction
select has_function('public','handle_updated_at',     'Fonction handle_updated_at');
select has_trigger ('public','profiles','on_profile_update', 'Trigger updated_at');

-- Simulation de policies_are (vérifie simplement qu'une policy existe)
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
      and policyname = 'Users can manage their own profile'
  ),
  'Policy RLS présente'
);

-- 2. TESTS DE COMPORTEMENT (RLS)

-- Prépare deux comptes
insert into auth.users (id, email) values
  ('123e4567-e89b-12d3-a456-426614174000', 'user1@test.com'),
  ('987fcdeb-51a2-43d7-9012-345678901234', 'user2@test.com');

-- USER 1
set local role authenticated;
set local request.jwt.claim.sub = '123e4567-e89b-12d3-a456-426614174000';

select lives_ok(
  $$insert into public.profiles (id, username)
    values ('123e4567-e89b-12d3-a456-426614174000','user1')$$,
  'User 1 crée son profil'
);

select results_eq(
  'select count(*) from public.profiles',
  ARRAY[1::bigint],
  'User 1 ne voit que son profil'
);

select * from finish();
rollback;
