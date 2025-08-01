#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Vérifie uniquement la structure de public.profiles
# ---------------------------------------------------------------------------
set -euo pipefail

# ─── compatibilité CLI : si DB_URL existe, on l’emploie comme DATABASE_URL ───
# compatibilité CLI : si DB_URL existe, on l’emploie comme DATABASE_URL
if [[ -z "${DATABASE_URL:-}" && -n "${DB_URL:-}" ]]; then
  export DATABASE_URL="$DB_URL"
fi
: "${DATABASE_URL:?DATABASE_URL (ou DB_URL) non défini}"

psql_cmd() { command psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -At -c "$1"; }

fail(){ echo "❌  $1"; exit 1; }
ok(){   echo "✅  $1"; }

echo "⏳  Vérification table + colonnes…"
[[ "$(psql_cmd "SELECT to_regclass('profiles');")" == "profiles" ]] || fail "Table 'profiles' absente"

need_cols=(id username avatar_url preferences created_at updated_at)
for c in "${need_cols[@]}"; do
  psql_cmd "SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='profiles' AND column_name='${c}';" | grep -q 1 \
            || fail "Colonne '${c}' absente"
done
ok "Table & colonnes OK."

echo "⏳  Vérification contraintes / objets…"
psql_cmd "SELECT 1 FROM pg_constraint WHERE conrelid='public.profiles'::regclass AND contype='p';" | grep -q 1 \
        || fail "PK manquante"
psql_cmd "SELECT 1 FROM pg_constraint
            WHERE conrelid='public.profiles'::regclass
              AND contype='u'
              AND conkey = ARRAY[
                    (SELECT attnum FROM pg_attribute
                     WHERE attrelid='public.profiles'::regclass AND attname='username')
                  ];" | grep -q 1 \
        || fail "UNIQUE(username) manquante"
[[ "$(psql_cmd "SELECT data_type FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='profiles' AND column_name='preferences';")" == "jsonb" ]] \
        || fail "preferences n'est pas jsonb"
psql_cmd "SELECT 1 FROM pg_trigger WHERE tgname='on_profile_update';" | grep -q 1 || fail "Trigger manquant"
psql_cmd "SELECT 1 FROM pg_proc    WHERE proname='handle_updated_at';" | grep -q 1 || fail "Fonction manquante"
psql_cmd "SELECT 1 FROM pg_policies WHERE tablename='profiles'
                             AND policyname='Users can manage their own profile';" | grep -q 1 || fail "Policy RLS manquante"
ok "Contraintes + objets OK."

echo -e "\n🎉  Tous les tests STRUCTURE sont PASSÉS."
