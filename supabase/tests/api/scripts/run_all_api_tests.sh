#!/usr/bin/env bash
set -euo pipefail

: "${API_URL:?}" : "${ANON_KEY:?}"

export SUPABASE_API_URL="$API_URL"
export SUPABASE_ANON_KEY="$ANON_KEY"

# email unique pour éviter les collisions
export TEST_EMAIL="user$(date +%s)@example.com"

source "$(dirname "$0")/test_auth_api.sh"      # crée l’utilisateur → JWT
export JWT
source "$(dirname "$0")/test_profiles_api.sh"

echo "✅ Tests API terminés"
