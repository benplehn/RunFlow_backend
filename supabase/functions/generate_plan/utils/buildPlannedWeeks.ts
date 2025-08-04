import type { PhaseDistribution, WeeklyPlan } from "../types.ts";
import type { GenerationParams } from "../services/readGenerationParameters.ts";
import type { WorkoutRules } from "../services/readWorkoutRules.ts";

/**
 * Construit la liste des semaines planifiées à partir de la distribution des phases
 * @param distribution - Répartition des phases
 * @param targetDate - Date cible de l'objectif
 * @param sessionsPerWeek - Nombre de séances par semaine
 * @param params - Paramètres de génération
 * @param rules - Règles d'entraînement
 * @returns Liste des semaines planifiées avec tous les détails
 */
export function buildPlannedWeeks(
  distribution: PhaseDistribution,
  targetDate: string,
  sessionsPerWeek: number,
  params: GenerationParams,
  rules: WorkoutRules
): WeeklyPlan[] {
  const weeks: WeeklyPlan[] = [];
  
  // TODO: Calculer la date de début en fonction de targetDate et du nombre total de semaines
  // TODO: Pour chaque phase dans distribution
  //   - Générer le nombre de semaines spécifié
  //   - Calculer le kilométrage avec calcWeeklyKm
  //   - Déterminer la distribution des zones
  //   - Générer les workouts clés
  
  // Implémentation temporaire pour la structure
  let weekNumber = 1;
  
  for (const phaseInfo of distribution) {
    for (let i = 0; i < phaseInfo.weeks; i++) {
      weeks.push({
        weekNumber,
        phase: phaseInfo.phase,
        startDate: targetDate, // TODO: calculer la vraie date
        targetKm: 40, // TODO: utiliser calcWeeklyKm
        zoneDistribution: { // TODO: utiliser determineZoneDistribution
          "Z1": 60,
          "Z2": 25,
          "Z3": 10,
          "Z4": 5
        },
        keyWorkouts: [] // TODO: utiliser generateKeyWorkouts
      });
      weekNumber++;
    }
  }
  
  return weeks;
}