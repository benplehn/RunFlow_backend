-- 4️⃣ Semaines détaillées d’un plan (phase, dates, km, distribution zones, workouts clés)

create table if not exists public.planned_weeks (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.user_training_plans(id) on delete cascade,
  week_number smallint not null,
  phase training_phase not null,
  start_date date not null,
  target_km numeric(5,2) not null,
  zone_distribution jsonb not null,
  key_workouts jsonb not null,  -- format libre, défini par l’Edge Function
  unique(plan_id, week_number)
);

-- 🔐 RLS : lecture uniquement si la semaine appartient à un plan de l’utilisateur
alter table public.planned_weeks enable row level security;
create policy "Users can read their planned_weeks"
  on public.planned_weeks
  for select
  to authenticated
  using (
    exists (
      select 1 from public.user_training_plans p
      where p.id = planned_weeks.plan_id
        and p.user_id = (select auth.uid())
    )
  );
-- (écriture via service_role uniquement, donc pas de policy insert/update/delete)
