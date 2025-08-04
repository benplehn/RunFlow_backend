import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import type { Database } from "../../_shared/database.types.ts";
import type { WeeklyPlan } from "../types.ts";

/**
 * Persiste les semaines planifiées en base de données
 * @param planId - ID du plan d'entraînement parent
 * @param weeklyPlans - Liste des semaines à persister
 */
export async function writePlannedWeeks(
  planId: string,
  weeklyPlans: WeeklyPlan[]
): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey);

  // Préparer les données pour l'insertion
  const weekRecords = weeklyPlans.map(week => ({
    plan_id: planId,
    week_number: week.weekNumber,
    phase: week.phase,
    start_date: week.startDate,
    target_km: week.targetKm,
    zone_distribution: week.zoneDistribution,
    key_workouts: week.keyWorkouts
  }));

  // Insertion en batch
  const { error } = await supabase
    .from("planned_weeks")
    .insert(weekRecords);

  if (error) {
    throw new Error(
      `Erreur lors de l'écriture des semaines planifiées: ${error.message}`
    );
  }
}