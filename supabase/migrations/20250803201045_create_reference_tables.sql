-- 2️⃣ Tables de paramètres et règles, consommées en lecture seule depuis les Edge Functions

-- Génération : paramètres globaux (volume de base, multiplicateur de pic…)
create table if not exists public.generation_parameters (
  id uuid primary key default gen_random_uuid(),
  goal training_goal not null,
  level training_level not null,
  base_weekly_km numeric(5,2) not null,
  peak_multiplier numeric(3,2) not null,
  volume_reduction_peak numeric(3,2) not null default 0.70,
  unique(goal, level)
);

-- Règles génériques, 100% JSON, versionnable et étendu par simple insert
create table if not exists public.workout_rules (
  id uuid primary key default gen_random_uuid(),
  rule_type text not null,
  rule_data jsonb not null,
  created_at timestamptz not null default now()
);

-- 🔐 Row Level Security
alter table public.generation_parameters enable row level security;
create policy "Allow authenticated to read generation_parameters"
  on public.generation_parameters
  for select
  to authenticated
  using (true);

alter table public.workout_rules enable row level security;
create policy "Allow authenticated to read workout_rules"
  on public.workout_rules
  for select
  to authenticated
  using (true);
