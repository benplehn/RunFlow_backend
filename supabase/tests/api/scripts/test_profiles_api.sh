#!/bin/bash

set -e

echo "👤 Test API /profiles Supabase..."

# Requiert que JWT soit déjà défini dans l'environnement
if [ -z "$JWT" ]; then
  echo "❌ JWT manquant. Lance d'abord test_auth_api.sh"
  exit 1
fi

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$SUPABASE_API_URL/rest/v1/profiles?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $JWT")

if [ "$RESPONSE" -eq 200 ]; then
  echo "✅ Endpoint /profiles accessible avec JWT"
else
  echo "❌ Échec accès /profiles (code $RESPONSE)"
  exit 1
fi
