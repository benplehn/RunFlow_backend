-- Limitations des tests Auth en local

SELECT plan(0);


-- ⚠️ Les tests pgTAP sur le schéma `auth` (table `auth.users`) **ne fonctionnent PAS en local** via Supabase CLI, car ce schéma n’est pas répliqué en dev local.  
-- ➡️ Ces tests doivent être lancés uniquement en environnement cloud/staging Supabase.
-- ➡️ En local, ne tester que les modules métiers custom (ex : profiles, groups, etc.).
