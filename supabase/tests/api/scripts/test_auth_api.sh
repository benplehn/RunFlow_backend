#!/bin/bash

set -e

echo "🔐 Test API Auth Supabase..."

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_API_URL/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"email":"ciuser@example.com","password":"ci-password"}')

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 400 ]; then
  echo "✅ Signup test réussi (code $RESPONSE)"
else
  echo "❌ Échec du test signup (code $RESPONSE)"
  exit 1
fi

RESPONSE=$(curl -s -X POST "$SUPABASE_API_URL/auth/v1/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -d '{"email":"ciuser@example.com","password":"ci-password"}')

JWT=$(echo "$RESPONSE" | jq -r '.access_token')

if [ "$JWT" == "null" ] || [ -z "$JWT" ]; then
  echo "❌ Échec de la récupération du JWT"
  exit 1
else
  echo "✅ JWT récupéré"
fi
