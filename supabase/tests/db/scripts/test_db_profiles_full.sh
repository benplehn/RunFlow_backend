#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Vérifie la structure + un test fonctionnel du trigger updated_at
# Requiert : DATABASE_URL (ou DB_URL) ex. postgres://postgres:postgres@127.0.0.1:54322/postgres
# ---------------------------------------------------------------------------
set -euo pipefail

# ─── compatibilité CLI : si DB_URL existe uniquement, on le réutilise ───
if [[ -z "${DATABASE_URL:-}" && -n "${DB_URL:-}" ]]; then
  export DATABASE_URL="$DB_URL"
fi
: "${DATABASE_URL:?DATABASE_URL (ou DB_URL) non défini}"

# psql_cmd "SQL…"  ➜ retourne la 1ʳᵉ colonne, 1ʳᵉ ligne (-At)
psql_cmd() { command psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -At -c "$1"; }

fail() { echo "❌  $1"; exit 1; }
ok()   { echo "✅  $1"; }

# ───────────────────────────────────────── Structure
echo "⏳  Vérification table…"
[[ "$(psql_cmd "SELECT to_regclass('profiles');")" == "profiles" ]] || fail "Table 'profiles' absente"
ok "Table présente."

echo "⏳  Vérification profils seedés…"
for u in alice bob; do
  [[ "$(psql_cmd "SELECT username FROM public.profiles WHERE username='${u}';")" == "$u" ]] \
    || fail "Profil '${u}' absent"
done
ok "Profils seedés OK."

echo "⏳  Vérification colonnes…"
cols=(id username avatar_url preferences created_at updated_at)
for c in "${cols[@]}"; do
  psql_cmd "SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name='profiles' AND column_name='${c}';" | grep -q 1 \
            || fail "Colonne '${c}' absente"
done
ok "Colonnes OK."

echo "⏳  Vérification contraintes…"
psql_cmd "SELECT 1 FROM pg_constraint WHERE conrelid='public.profiles'::regclass AND contype='p';" | grep -q 1 \
  || fail "Clé primaire manquante"
psql_cmd "SELECT 1 FROM pg_constraint
            WHERE conrelid='public.profiles'::regclass
              AND contype='u'
              AND conkey = ARRAY[
                    (SELECT attnum FROM pg_attribute
                     WHERE attrelid='public.profiles'::regclass AND attname='username')
                  ];" | grep -q 1 \
  || fail "UNIQUE(username) manquante"
[[ "$(psql_cmd "SELECT data_type
                 FROM information_schema.columns
                 WHERE table_schema='public' AND table_name='profiles' AND column_name='preferences';")" == "jsonb" ]] \
  || fail "preferences n'est pas jsonb"
ok "Contraintes OK."

echo "⏳  Vérification fonction / trigger / policy…"
psql_cmd "SELECT 1 FROM pg_proc    WHERE proname='handle_updated_at';" | grep -q 1 || fail "Fonction manquante"
psql_cmd "SELECT 1 FROM pg_trigger WHERE tgname='on_profile_update';"   | grep -q 1 || fail "Trigger manquant"
psql_cmd "SELECT 1 FROM pg_policies
          WHERE tablename='profiles' AND policyname='Users can manage their own profile';" | grep -q 1 \
          || fail "Policy RLS manquante"
ok "Objets complémentaires OK."

# ───────────────────────────────────────── Test fonctionnel trigger updated_at
echo "⏳  Test fonctionnel du trigger updated_at…"

# 1) Génère un id puis insère le profil temporaire
tmp_id="$(psql_cmd "SELECT gen_random_uuid();")"
psql_cmd "INSERT INTO public.profiles (id, username, avatar_url, preferences)
          VALUES ('$tmp_id', 'tmp_testuser', 'http://example.com/a.png', '{}'::jsonb);"

# 2) Timestamp avant update
before_update="$(psql_cmd "SELECT updated_at FROM public.profiles WHERE id = '$tmp_id';")"

# 3) Pause puis update
sleep 1
psql_cmd "UPDATE public.profiles
          SET avatar_url = 'http://example.com/b.png'
          WHERE id = '$tmp_id';"

# 4) Timestamp après update
after_update="$(psql_cmd "SELECT updated_at FROM public.profiles WHERE id = '$tmp_id';")"

if [[ "$before_update" == "$after_update" ]]; then
  fail "Trigger updated_at ne fonctionne pas (timestamp identique)"
else
  ok "Trigger updated_at OK."
fi

# 5) Nettoyage
psql_cmd "DELETE FROM public.profiles WHERE id = '$tmp_id';"

echo -e "\n🎉  Tous les tests STRUCTURE + FONCTIONNELS sont PASSÉS."
