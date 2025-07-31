# 📦 Backend Supabase — RunApp (GPS, Plans, Chat, Clans)

## 🎯 Objectif du projet

Créer un backend complet, sécurisé, modulaire et scalable pour une application mobile de running avec :

* Plans d'entraînement personnalisés
* Séances et feedbacks utilisateurs
* Suivi GPS
* Fonctionnalités sociales : groupes, chats, clans, guerre de clans
* Notifications push/email
* Connexion avec des services externes (Strava, Garmin…)

Ce backend repose à 100% sur **Supabase** (PostgreSQL, Auth, Realtime, Storage, Edge Functions) et est conçu pour être relié à un frontend mobile React Native ou Flutter.

---

## 🗂 Structure du projet

```
runapp-backend/
├── supabase/
│   ├── config.toml               # Configuration CLI Supabase
│   ├── migrations/               # Scripts SQL versionnés par module
│   │   └── YYYYMMDD_xxxxxx.sql
│   ├── functions/                # Edge functions TypeScript (notifications, sync…)
│   ├── seed.sql                  # Données de départ injectées automatiquement
│   └── tests/                    # Tests pgTAP pour la sécurité et les règles métier
│       └── test_health.sql
├── .gitignore                   
├── .github/workflows/ci.yml     # Pipeline CI GitHub Actions
├── requirements.txt             # Dépendances Python (si besoin API/tests)
└── README.md                    # Ce fichier
```

---

## 🔧 Environnement requis

* Node.js ≥ 18
* Supabase CLI ([https://supabase.com/docs/guides/cli](https://supabase.com/docs/guides/cli))
* Docker Desktop (lancé en arrière-plan)
* Git + GitHub (CI/CD)
* VS Code avec plugins : Supabase, SQLTools, Docker

---

## 🚀 Commandes utiles

```bash
supabase start             # Lance Supabase en local (Postgres + Auth + Studio)
supabase status            # Vérifie les ports
supabase db reset          # Reset complet + seed
supabase db push           # Applique les migrations locales
supabase test db           # Exécute les tests pgTAP
supabase functions deploy  # Déploie une edge function (plus tard)
```

---

## ✅ Conventions du projet

* Toutes les **tables ont RLS activé** dès leur création
* Chaque **module = 1 fichier migration** SQL propre (`YYYYMMDD_create_module.sql`)
* Chaque table a ses **policies RLS** (`select`, `insert`, `update`, `delete`)
* Les tests SQL sont faits avec **pgTAP** dans `supabase/tests/`
* Le code est **linté via GitHub Actions** (`sql-formatter` + tests pgTAP)

---

## 🧱 Modules prévus (roadmap)

| Module                 | Fonctionnalités principales              |
| ---------------------- | ---------------------------------------- |
| `auth`                 | Auth Supabase (email, magic link)        |
| `profiles`             | Infos utilisateur, préférences, avatar   |
| `training_templates`   | Plans fixes                              |
| `training_plans`       | Plans personnalisés                      |
| `sessions`             | Séances planifiées et effectuées         |
| `session_points`       | Suivi GPS en temps réel                  |
| `feedback`             | Feedback post-séance                     |
| `stats`                | VO2max, charge, progression              |
| `groups`               | Groupes de coureurs                      |
| `clans`                | Clans + membres                          |
| `clan_events`          | Défis de clan                            |
| `chat`                 | Rooms, messages en temps réel (Realtime) |
| `notifications`        | Envoi de notifications push/email        |
| `external_connections` | Intégration Strava / Garmin              |
| `storage`              | Upload avatars, certificats, etc.        |

---

## 🔐 Sécurité & tests

* RLS activé sur toutes les tables
* Tests pgTAP pour chaque module dans `supabase/tests/`
* Fichier `seed.sql` pour injecter des données de test dès le lancement local
* CI GitHub :

  * ✅ Lint SQL
  * ✅ Exécution des tests pgTAP
  * (à venir) Déploiement staging/production

---

## 📛 Badges

[![CI](https://github.com/benplehn/RunFlow_backend/actions/workflows/ci.yml/badge.svg)](https://github.com/benplehn/RunFlow_backend/actions/workflows/ci.yml)

---

## 🛠 Étapes futures

* Connexion frontend via Supabase JS SDK
* Synchronisation Strava (OAuth 2.0)
* Export API publique REST ou GraphQL
* Interface d’administration (web ou edge function)
* Système de paiement (Stripe ou autre)
