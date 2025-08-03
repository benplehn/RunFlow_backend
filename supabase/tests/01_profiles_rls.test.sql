begin;

-- Charge pgTAP et annonce le nombre de tests
create extension if not exists pgtap with schema extensions;
select plan(32);

-- ========================================
-- 1. TESTS DE SCHÉMA (conservés)
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

-- Vérification que toutes les politiques existent
select policies_are(
  'public',
  'profiles',
  ARRAY[
    'profiles_select_policy',
    'profiles_update_policy',
    'profiles_delete_policy',
    'profiles_insert_policy'
  ],
  'Toutes les 4 politiques RLS présentes'
);

-- ========================================
-- 2. TESTS DE CONTRAINTES (conservés)
-- ========================================

set local role service_role;

select throws_ok(
  $$insert into public.profiles (id, username)
    values (gen_random_uuid(),'ab')$$,
  '23514',
  null,
  'Username trop court rejeté'
);

select throws_ok(
  $$insert into public.profiles (id, username)
    values (gen_random_uuid(),'username_vraiment_trop_long_pour_la_contrainte_de_30_caracteres')$$,
  '23514',
  null,
  'Username trop long rejeté'
);

select throws_ok(
  $$insert into public.profiles (id, username, preferences)
    values (gen_random_uuid(),'test_json_user', '"string_au_lieu_objet"'::jsonb)$$,
  '23514',
  null,
  'Preferences non-objet rejetées'
);

select lives_ok(
  $$insert into public.profiles (id, username, display_name, preferences)
    values (gen_random_uuid(), 'test_user_valid', 'Test User', '{"notifications": true}'::jsonb)$$,
  'Insertion profil valide réussit'
);

select throws_ok(
  $$insert into public.profiles (id, username, avatar_url)
    values (gen_random_uuid(), 'test_url_user', 'pas_une_url_valide')$$,
  '23514',
  null,
  'URL avatar invalide rejetée'
);

select throws_ok(
  $$insert into public.profiles (id, username, bio)
    values (gen_random_uuid(), 'test_bio_user', repeat('a', 501))$$,
  '23514',
  null,
  'Bio trop longue rejetée'
);

-- ========================================
-- 3. TESTS RLS AVEC DONNÉES DU SEED
-- ========================================

-- Test SELECT : anonyme voit tous les profils actifs du seed
set local role anon;
select is(
  (select count(*) from public.profiles where username in ('speedrunner', 'trailmaster', 'coach_pro')),
  3::bigint,
  'Anonyme voit les 3 profils actifs du seed'
);

-- Test UPDATE : runner1 peut modifier son profil
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"123e4567-e89b-12d3-a456-426614174000"}';

select lives_ok(
  $$update public.profiles 
    set bio = 'Nouveau objectif: marathon sub-2h45' 
    where id = '123e4567-e89b-12d3-a456-426614174000'$$,
  'runner1 peut modifier son propre profil'
);

-- Test UPDATE : runner1 ne peut pas modifier le profil de runner2
-- D'abord on essaie de modifier
update public.profiles 
  set bio = 'Hack!' 
  where id = '987fcdeb-51a2-43d7-9012-345678901234';

-- Puis on vérifie que ça n'a pas marché
select is(
  (select count(*) from public.profiles 
   where id = '987fcdeb-51a2-43d7-9012-345678901234' 
   and bio = 'Hack!'),
  0::bigint,
  'runner1 ne peut pas modifier le profil de runner2'
);

-- Test DELETE : coach peut supprimer son profil (mais on fait rollback)
set local "request.jwt.claims" to '{"sub":"456789ab-cdef-1234-5678-90abcdef1234"}';
select lives_ok(
  $$delete from public.profiles where id = '456789ab-cdef-1234-5678-90abcdef1234'$$,
  'coach peut supprimer son propre profil'
);

-- Test INSERT : seul un utilisateur authentifié avec le bon ID peut créer
set local role anon;
select throws_ok(
  $$insert into public.profiles (id, username) 
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'test_anon')$$,
  '42501',
  null,
  'Anonyme ne peut pas créer de profil'
);

-- Test INSERT avec mauvais ID
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}';
select throws_ok(
  $$insert into public.profiles (id, username) 
    values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'wrong_id')$$,
  '42501',
  null,
  'INSERT échoue si ID ne correspond pas à auth.uid()'
);

-- ========================================
-- 4. TESTS AVANCÉS
-- ========================================

-- Test profil inactif (créons-en un temporairement)
set local role service_role;
update public.profiles 
set is_active = false 
where id = '987fcdeb-51a2-43d7-9012-345678901234';

-- Anonyme ne voit pas le profil inactif
set local role anon;
select is(
  (select count(*) from public.profiles 
   where id = '987fcdeb-51a2-43d7-9012-345678901234'),
  0::bigint,
  'Anonyme ne voit pas les profils inactifs'
);

-- Mais le propriétaire voit son profil même inactif
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"987fcdeb-51a2-43d7-9012-345678901234"}';
select is(
  (select count(*) from public.profiles 
   where id = '987fcdeb-51a2-43d7-9012-345678901234'),
  1::bigint,
  'Propriétaire voit son profil même inactif'
);

-- Test du trigger updated_at
set local role service_role;
select ok(
  (select updated_at > created_at 
   from public.profiles 
   where id = '123e4567-e89b-12d3-a456-426614174000'),
  'Trigger updated_at fonctionne (après notre update)'
);

select * from finish();
rollback;