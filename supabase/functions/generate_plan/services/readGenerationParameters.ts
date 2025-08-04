import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import type { Database } from "#db_types";
import type { Goal, Level } from "../types.ts";

// Structure complète des paramètres de génération
export interface GenerationParams {
  [key: string]: {  // key = "goal_level" ex: "5k_beginner"
    goal: Goal;
    level: Level;
    baseWeeklyKm: number;
    peakMultiplier: number;
    volumeReductionPeak: number;
  };
}

/**
 * Lit TOUS les paramètres de génération depuis la base de données
 * @returns Un dictionnaire de tous les paramètres indexés par "goal_level"
 */
export async function readGenerationParameters(): Promise<GenerationParams> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey);

  const { data, error } = await supabase
    .from("generation_parameters")
    .select("*");

  if (error || !data) {
    throw new Error(
      `Erreur lors de la lecture des paramètres de génération: ${error?.message || "Aucune donnée"}`
    );
  }

  // Transformer le tableau en dictionnaire indexé par "goal_level"
  const params: GenerationParams = {};
  
  for (const row of data) {
    const key = `${row.goal}_${row.level}`;
    params[key] = {
      goal: row.goal,
      level: row.level,
      baseWeeklyKm: Number(row.base_weekly_km),
      peakMultiplier: Number(row.peak_multiplier),
      volumeReductionPeak: Number(row.volume_reduction_peak)
    };
  }

  return params;
}