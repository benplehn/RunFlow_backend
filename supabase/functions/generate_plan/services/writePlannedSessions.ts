import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import type { Database } from "#db_types";
import type { SessionPlan } from "../types.ts";

/**
 * Persiste les séances planifiées en base de données
 * @param planId - ID du plan d'entraînement parent
 * @param sessionPlans - Liste des séances à persister
 */
export async function writePlannedSessions(
  planId: string,
  sessionPlans: SessionPlan[]
): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey);

  // D'abord, récupérer les IDs des semaines pour ce plan
  const { data: weeks, error: weeksError } = await supabase
    .from("planned_weeks")
    .select("id, week_number")
    .eq("plan_id", planId);

  if (weeksError || !weeks) {
    throw new Error(
      `Erreur lors de la récupération des semaines: ${weeksError?.message || "Aucune donnée"}`
    );
  }

  // Créer un mapping weekNumber -> weekId
  const weekIdMap = new Map(
    weeks.map(w => [w.week_number, w.id])
  );

  // Préparer les données pour l'insertion
  const sessionRecords = sessionPlans.map(session => {
    const weekId = weekIdMap.get(session.weekNumber);
    if (!weekId) {
      throw new Error(`Week ID non trouvé pour la semaine ${session.weekNumber}`);
    }

    return {
      week_id: weekId,
      day_of_week: session.dayOfWeek,
      scheduled_date: session.scheduledDate,
      workout_details: session.workoutDetails,
      status: "planned" as const
    };
  });

  // Insertion en batch
  const { error } = await supabase
    .from("planned_sessions")
    .insert(sessionRecords);

  if (error) {
    throw new Error(
      `Erreur lors de l'écriture des séances planifiées: ${error.message}`
    );
  }
}