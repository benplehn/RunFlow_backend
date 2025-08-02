-- supabase/seed.sql
-- Seeds pour développement local uniquement

-- Créer des utilisateurs de test (auth.users)
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role
) VALUES
  (
    '123e4567-e89b-12d3-a456-426614174000',
    '00000000-0000-0000-0000-000000000000',
    'runner1@test.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    false,
    'authenticated'
  ),
  (
    '987fcdeb-51a2-43d7-9012-345678901234',
    '00000000-0000-0000-0000-000000000000',
    'runner2@test.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    false,
    'authenticated'
  ),
  (
    '456789ab-cdef-1234-5678-90abcdef1234',
    '00000000-0000-0000-0000-000000000000',
    'coach@test.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    false,
    'authenticated'
  )
ON CONFLICT (id) DO NOTHING;

-- Insertion dans auth.identities (CORRIGÉ pour Supabase moderne)
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,  -- AJOUTÉ: obligatoire maintenant
  created_at,
  updated_at
) VALUES
  (
    gen_random_uuid(),
    '123e4567-e89b-12d3-a456-426614174000',
    '{"sub": "123e4567-e89b-12d3-a456-426614174000", "email": "runner1@test.com", "email_verified": true}',
    'email',
    'runner1@test.com',  -- provider_id = email pour provider email
    now(),
    now()
  ),
  (
    gen_random_uuid(),
    '987fcdeb-51a2-43d7-9012-345678901234',
    '{"sub": "987fcdeb-51a2-43d7-9012-345678901234", "email": "runner2@test.com", "email_verified": true}',
    'email',
    'runner2@test.com',
    now(),
    now()
  ),
  (
    gen_random_uuid(),
    '456789ab-cdef-1234-5678-90abcdef1234',
    '{"sub": "456789ab-cdef-1234-5678-90abcdef1234", "email": "coach@test.com", "email_verified": true}',
    'email',
    'coach@test.com',
    now(),
    now()
  )
ON CONFLICT (provider, provider_id) DO NOTHING;

-- Créer les profils correspondants
INSERT INTO public.profiles (
  id,
  username,
  display_name,
  bio,
  avatar_url,
  preferences
) VALUES
  (
    '123e4567-e89b-12d3-a456-426614174000',
    'speedrunner',
    'Alex Speedrunner',
    'Coureur passionné, objectif marathon sub-3h',
    'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=150',
    '{
      "notifications": true,
      "privacy": "public",
      "units": "metric",
      "training_reminders": true,
      "weekly_goals": 50
    }'::jsonb
  ),
  (
    '987fcdeb-51a2-43d7-9012-345678901234',
    'trailmaster',
    'Sarah Trailmaster',
    'Trail running et ultra-distances',
    'https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=150',
    '{
      "notifications": true,
      "privacy": "friends_only",
      "units": "metric",
      "training_reminders": false,
      "weekly_goals": 75
    }'::jsonb
  ),
  (
    '456789ab-cdef-1234-5678-90abcdef1234',
    'coach_pro',
    'Michel Coach Pro',
    'Entraîneur certifié, spécialiste semi-marathon',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=150',
    '{
      "notifications": true,
      "privacy": "public",
      "units": "metric",
      "coach_mode": true,
      "max_trainees": 20
    }'::jsonb
  )
ON CONFLICT (id) DO NOTHING;