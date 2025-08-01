-- supabase/seed.sql

-- Nettoyage (utile en dev/staging, pas en prod)
delete from public.profiles;

-- Ajoute plusieurs profils réalistes
insert into public.profiles (id, username, avatar_url, preferences, created_at, updated_at)
values
  (
    '8aa13fda-b5d1-44c3-afe1-d6fdcb6d8f07', -- UUID fixe pour tests API
    'alice', 
    'https://randomuser.me/api/portraits/women/1.jpg', 
    '{"theme": "light", "lang": "fr"}', 
    now() - interval '10 days',
    now() - interval '2 days'
  ),
  (
    'f3d3a184-30d8-4316-becd-172c92a00e88',
    'bob', 
    'https://randomuser.me/api/portraits/men/2.jpg', 
    '{"theme": "dark", "lang": "en"}', 
    now() - interval '12 days',
    now() - interval '1 day'
  ),
  (
    '7333e765-701e-4423-bc43-b00c2acfcf57',
    'carol',
    'https://randomuser.me/api/portraits/women/3.jpg',
    '{"theme": "dark", "lang": "es"}',
    now() - interval '7 days',
    now()
  );
