-- Aucun détail métier ici : juste les catégories essentielles
-- RLS non nécessaire sur des types

create type public.training_phase as enum (
  'build', 'intensity', 'specificity', 'peak'
);

create type public.training_goal as enum (
  '5k', '10k', 'half_marathon', 'marathon'
);

create type public.training_level as enum (
  'beginner', 'intermediate', 'advanced'
);