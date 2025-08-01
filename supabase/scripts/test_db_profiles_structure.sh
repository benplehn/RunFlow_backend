#!/bin/bash
set -e

PGHOST="localhost"
PGPORT="54322"
PGUSER="postgres"
PGDATABASE="postgres"

fail() {
    echo "❌ $1"
    exit 1
}
ok() {
    echo "✅ $1"
}

echo "⏳ Vérification de la table 'profiles'..."
table_result=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc "SELECT to_regclass('public.profiles');" | tr -d ' ')
[[ "$table_result" == "profiles" ]] || fail "Table 'profiles' absente !"
ok "Table 'profiles' présente."

echo "⏳ Vérification des colonnes attendues..."
columns=(id username avatar_url preferences created_at updated_at)
for col in "${columns[@]}"; do
    res=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc "SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='$col'")
    [[ "$res" == "1" ]] || fail "Colonne '$col' absente !"
done
ok "Toutes les colonnes présentes."

echo "⏳ Test contrainte UNIQUE sur username..."
is_unique=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='public' AND table_name='profiles' AND constraint_type='UNIQUE';")
[[ "$is_unique" -ge 1 ]] || fail "Pas de contrainte UNIQUE sur username !"
ok "Contrainte UNIQUE sur username présente."

echo "⏳ Test clé primaire sur id..."
pk_exists=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='public' AND table_name='profiles' AND constraint_type='PRIMARY KEY';")
[[ "$pk_exists" -ge 1 ]] || fail "Pas de clé primaire sur id !"
ok "Clé primaire sur id présente."

echo "⏳ Test du type de la colonne preferences..."
type_pref=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles' AND column_name='preferences';" | tr -d ' ')
[[ "$type_pref" == "jsonb" ]] || fail "La colonne preferences n'est pas de type jsonb !"
ok "Type JSONB sur preferences."

echo "⏳ Vérification du trigger 'on_profile_update'..."
trigger_count=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'on_profile_update';")
[[ "$trigger_count" -ge 1 ]] || fail "Trigger 'on_profile_update' absent !"
ok "Trigger 'on_profile_update' présent."

echo "⏳ Vérification de la fonction 'handle_updated_at'..."
function_count=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT COUNT(*) FROM pg_proc WHERE proname = 'handle_updated_at';")
[[ "$function_count" -ge 1 ]] || fail "Fonction 'handle_updated_at' absente !"
ok "Fonction 'handle_updated_at' présente."

echo "⏳ Vérification de la policy RLS sur profiles..."
policy_count=$(psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -tAc \
"SELECT COUNT(*) FROM pg_policies WHERE tablename='profiles' AND policyname='Users can manage their own profile';")
[[ "$policy_count" -ge 1 ]] || fail "Policy RLS absente ou mal nommée !"
ok "Policy RLS 'Users can manage their own profile' présente."

echo
echo "🎉 Tous les tests STRUCTURE sont PASSÉS !"
exit 0
