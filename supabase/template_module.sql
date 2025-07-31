-- MODULE : NOM_DU_MODULE

-- 1. Table
create table NOM_DU_MODULE (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade,
  -- autres colonnes métier ici
  created_at timestamptz default now()
);

-- 2. Sécurité
alter table NOM_DU_MODULE enable row level security;

-- 3. RLS policies
create policy "select_own"
on NOM_DU_MODULE for select
using (auth.uid() = user_id);

create policy "insert_own"
on NOM_DU_MODULE for insert
with check (auth.uid() = user_id);

create policy "update_own"
on NOM_DU_MODULE for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "delete_own"
on NOM_DU_MODULE for delete
using (auth.uid() = user_id);
