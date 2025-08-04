import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import type { Database } from "#db_types";

// Structure pour les règles d'entraînement
export interface WorkoutRules {
  [ruleType: string]: unknown[];  // Format libre selon rule_type
}

/**
 * Lit toutes les règles d'entraînement depuis la base de données
 * @returns Un dictionnaire des règles groupées par type
 */
export async function readWorkoutRules(): Promise<WorkoutRules> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey);

  const { data, error } = await supabase
    .from("workout_rules")
    .select("*")
    .order("created_at", { ascending: true });

  if (error || !data) {
    throw new Error(
      `Erreur lors de la lecture des règles d'entraînement: ${error?.message || "Aucune donnée"}`
    );
  }

  // Grouper les règles par type
  const rules: WorkoutRules = {};
  
  for (const row of data) {
    if (!rules[row.rule_type]) {
      rules[row.rule_type] = [];
    }
    rules[row.rule_type].push(row.rule_data);
  }

  return rules;
}