import type { WeeklyPlan, SessionPlan } from "../types.ts";
import type { WorkoutRules } from "../services/readWorkoutRules.ts";

/**
 * Construit la liste des séances détaillées à partir des semaines planifiées
 * @param weeklyPlans - Liste des semaines planifiées
 * @param rules - Règles d'entraînement
 * @returns Liste des séances planifiées jour par jour
 */
export function buildPlannedSessions(
  weeklyPlans: WeeklyPlan[],
  rules: WorkoutRules
): SessionPlan[] {
  const sessions: SessionPlan[] = [];
  
  // TODO: Pour chaque semaine
  //   - Répartir les keyWorkouts sur les jours
  //   - Ajouter les séances de récupération
  //   - Respecter le nombre de sessionsPerWeek
  //   - Calculer les dates exactes
  
  // Implémentation temporaire pour la structure
  for (const week of weeklyPlans) {
    // Exemple: 3 séances par semaine (mardi, jeudi, dimanche)
    const sessionDays = [2, 4, 7]; // TODO: rendre dynamique selon sessionsPerWeek
    
    for (const dayOfWeek of sessionDays) {
      sessions.push({
        weekNumber: week.weekNumber,
        dayOfWeek,
        scheduledDate: week.startDate, // TODO: calculer la vraie date
        workoutDetails: {
          type: "easy_run",
          distance: 10,
          description: "Course facile"
        }
      });
    }
  }
  
  return sessions;
}