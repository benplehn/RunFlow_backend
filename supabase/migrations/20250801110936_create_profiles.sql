create table public.profiles (
  id uuid primary key,
  username text unique not null,
  avatar_url text,
  preferences jsonb,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);


-- Fonction trigger pour updated_at
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Trigger : avant chaque UPDATE, met à jour updated_at
create trigger on_profile_update
before update on public.profiles
for each row execute procedure public.handle_updated_at();

alter table public.profiles enable row level security;

-- Policy : seul l'utilisateur connecté peut voir/modifier SON profil
create policy "Users can manage their own profile"
on public.profiles
for all
using (auth.uid() = id);

