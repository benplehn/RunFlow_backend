-- 3️⃣ Stockage des plans utilisateur (uniquement métadonnées et répartition de phase)

-- Étape 1 : création de la table sans la contrainte unique conditionnelle
CREATE TABLE IF NOT EXISTS public.user_training_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  goal training_goal NOT NULL,
  level training_level NOT NULL,
  duration_weeks smallint NOT NULL CHECK (duration_weeks IN (8,10,12,14)),
  sessions_per_week smallint NOT NULL CHECK (sessions_per_week BETWEEN 3 AND 7),
  target_date date NOT NULL,
  user_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  phase_distribution jsonb NOT NULL,
  peak_weekly_km numeric(5,2) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Étape 2 : index unique partiel
CREATE UNIQUE INDEX IF NOT EXISTS one_active_plan_per_user
ON public.user_training_plans (user_id)
WHERE is_active = true;


-- 🔐 RLS : chaque utilisateur ne peut voir et modifier que ses propres plans
alter table public.user_training_plans enable row level security;
create policy "Users can manage their own plans"
  on public.user_training_plans
  for all
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );
