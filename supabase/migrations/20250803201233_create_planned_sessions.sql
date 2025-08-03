-- 5️⃣ Séances détaillées (jour, date, détails JSON, statut)

create table if not exists public.planned_sessions (
  id uuid primary key default gen_random_uuid(),
  week_id uuid not null references public.planned_weeks(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  scheduled_date date not null,
  workout_details jsonb not null,  -- tout ce qu’il faut : type, distance, structure…
  status text not null default 'planned'
    check (status in ('planned','completed','skipped','modified')),
  unique(week_id, day_of_week)
);

-- 🔐 RLS : lecture uniquement si appartient à un plan utilisateur
alter table public.planned_sessions enable row level security;
create policy "Users can read their planned_sessions"
  on public.planned_sessions
  for select
  to authenticated
  using (
    exists (
      select 1 from public.planned_weeks w
      join public.user_training_plans p on p.id = w.plan_id
      where w.id = planned_sessions.week_id
        and p.user_id = (select auth.uid())
    )
  );
-- (écriture via service_role uniquement)
