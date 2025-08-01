#!/bin/bash
set -e

echo "🚀 Lancement des tests API..."

# 1. Crée un utilisateur + récupère le JWT
source "$(dirname "$0")/test_auth_api.sh"

# 2. Lance les tests API protégés
export JWT=$JWT
source "$(dirname "$0")/test_profiles_api.sh"

echo "✅ Tous les tests API passés avec succès !"

