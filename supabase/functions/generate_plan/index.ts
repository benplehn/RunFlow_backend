// Point d'entrée de l'Edge Function generatePlan

// ---------------------- IMPORTS ----------------------
// Client Supabase pour interagir avec la base de données
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
// Types générés par Supabase pour le typage strict
import type { Database } from "#db_types";
// Types métier définis localement
import type {
  GeneratePlanPayload,
  GeneratePlanResult
} from "./types.ts";

// Utilitaires de calcul de plan
import { splitPhases } from "./utils/splitPhases.ts";
import { buildPlannedWeeks } from "./utils/buildPlannedWeeks.ts";
import { buildPlannedSessions } from "./utils/buildPlannedSessions.ts";

// Services I/O pour lire/écrire en base
import { readGenerationParameters } from "./services/readGenerationParameters.ts";
import { readWorkoutRules } from "./services/readWorkoutRules.ts";
import { writePlannedWeeks } from "./services/writePlannedWeeks.ts";
import { writePlannedSessions } from "./services/writePlannedSessions.ts";

// Initialisation du client Supabase avec typage
const supabase = createClient<Database>(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

// ---------------------- HANDLER ----------------------
export default async function handler(req: Request): Promise<Response> {
  // En-têtes CORS pour autoriser les appels depuis n'importe quelle origine
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    // Autorise les en-têtes custom nécessaires (auth, apikey, content-type)
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  // Répondre aux requêtes OPTIONS pour le CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // N'autoriser que la méthode POST
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  try {
    // Parser le payload JSON en utilisant le type métier
    const payload: GeneratePlanPayload = await req.json();

    // Validation basique des champs obligatoires
    if (
      !payload.userId ||
      !payload.goal ||
      !payload.level ||
      !payload.durationWeeks ||
      !payload.sessionsPerWeek ||
      !payload.targetDate
    ) {
      throw new Error("Données manquantes dans la requête");
    }

    // 1️⃣ Lecture des paramètres de génération (génération_parameters)
    const params = await readGenerationParameters();
    // 2️⃣ Lecture des règles d'entraînement (workout_rules)
    const rules = await readWorkoutRules();

    // 3️⃣ Calcul de la distribution des phases
    const distribution = splitPhases(payload.durationWeeks);

    // 4️⃣ Génération des plans hebdomadaires à partir de la distribution
    const weeklyPlans = buildPlannedWeeks(
      distribution,
      payload.targetDate,
      payload.sessionsPerWeek,
      params,
      rules
    );

    // 5️⃣ Génération des plans de séances détaillées
    const sessionPlans = buildPlannedSessions(weeklyPlans, rules);

    // 6️⃣ Création du plan principal en base (user_training_plans)
    const planKey = `${payload.goal}_${payload.level}`;
    const genParams = params[planKey];
    if (!genParams) {
      throw new Error(`Paramètres non trouvés pour ${planKey}`);
    }
    // Calcul du pic de km hebdo à partir des paramètres générés
    const peakWeeklyKm = genParams.baseWeeklyKm * genParams.peakMultiplier;

    // Insertion du plan principal et récupération de l'enregistrement créé
    const { data: newPlan, error: planError } = await supabase
      .from("user_training_plans")
      .insert({
        user_id: payload.userId,
        goal: payload.goal,
        level: payload.level,
        duration_weeks: payload.durationWeeks,
        sessions_per_week: payload.sessionsPerWeek,
        target_date: payload.targetDate,
        user_data: payload.userData || {},
        phase_distribution: distribution,
        peak_weekly_km: peakWeeklyKm,
        is_active: true
      })
      .select()
      .single();

    if (planError || !newPlan) {
      throw new Error(`Erreur création plan: ${planError?.message}`);
    }

    // 7️⃣ Persistance des semaines et séances liées au nouveau plan
    await writePlannedWeeks(newPlan.id, weeklyPlans);
    await writePlannedSessions(newPlan.id, sessionPlans);

    // 8️⃣ Préparation du résultat à renvoyer au client
    const result: GeneratePlanResult = {
      distribution,
      plannedWeeks: weeklyPlans,
      plannedSessions: sessionPlans,
    };

    // Réponse HTTP 200 avec payload JSON et headers CORS
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    // En cas d'erreur, log server et retour d'un message client
    console.error("Erreur dans generate_plan:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Erreur inconnue"
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
}

// Deno.serve définit le handler pour la plateforme Deno Deploy ou Supabase Edge
Deno.serve(handler);
