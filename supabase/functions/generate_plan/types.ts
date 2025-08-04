// Ce fichier définit les types TypeScript utilisés par la fonction generatePlan.

// Import des types de la base de données générés par Supabase
import type { Database } from "#db_types";

/**
 * Phase
 * Représente une phase d'entraînement telle que définie dans l'enum PostgreSQL `training_phase`.
 * Valeurs possibles : 'build', 'intensity', 'specificity', 'peak'.
 */
export type Phase = Database['public']['Enums']['training_phase'];

/**
 * Goal
 * Représente l'objectif d'entraînement (5k, 10k, semi-marathon, marathon)
 * tel que défini dans l'enum PostgreSQL `training_goal`.
 */
export type Goal  = Database['public']['Enums']['training_goal'];

/**
 * Level
 * Représente le niveau d'entraînement (beginner, intermediate, advanced)
 * tel que défini dans l'enum PostgreSQL `training_level`.
 */
export type Level = Database['public']['Enums']['training_level'];

/**
 * PhaseCount
 * Couple une phase avec le nombre de semaines qui lui est alloué.
 */
export interface PhaseCount {
  /** Nom de la phase */
  phase: Phase;
  /** Nombre de semaines consacrées à cette phase */
  weeks: number;
}

/**
 * PhaseDistribution
 * Tableau listant toutes les phases et leur durée en semaines.
 */
export type PhaseDistribution = PhaseCount[];

/**
 * GeneratePlanPayload
 * Structure du payload JSON reçu par l'Edge Function generatePlan.
 */
export interface GeneratePlanPayload {
  /** Identifiant unique de l'utilisateur (UUID) */
  userId: string;
  /** Objectif d'entraînement choisi par l'utilisateur */
  goal: Goal;
  /** Niveau d'entraînement choisi par l'utilisateur */
  level: Level;
  /** Durée totale du plan en semaines */
  durationWeeks: number;
  /** Nombre de séances hebdomadaires souhaitées */
  sessionsPerWeek: number;
  /** Date cible pour atteindre l'objectif (format ISO) */
  targetDate: string;
  /** Données additionnelles de l'utilisateur (km actuels, jours disponibles, âge, etc.) */
  userData: Record<string, unknown>;
}

/**
 * WeeklyPlan
 * Représente le plan pour une semaine spécifique :
 * - numéro de semaine
 * - phase correspondante
 * - date de début
 * - km cible
 * - répartition des zones d'effort
 * - liste des séances clés
 */
export interface WeeklyPlan {
  /** Numéro de la semaine dans le plan (1-based) */
  weekNumber: number;
  /** Phase associée à cette semaine */
  phase: Phase;
  /** Date de début de la semaine (ISO string) */
  startDate: string;
  /** Objectif kilométrique pour la semaine */
  targetKm: number;
  /** Répartition des zones d'effort (ex. { Z2: 80, Z3: 20 }) */
  zoneDistribution: Record<string, number>;
  /** Séances clés générées pour la semaine */
  keyWorkouts: unknown[];
}

/**
 * SessionPlan
 * Détaille chaque séance planifiée dans la semaine :
 * - numéro de semaine et jour de la semaine
 * - date programmée
 * - détails de la séance
 */
export interface SessionPlan {
  /** Numéro de la semaine dans le plan */
  weekNumber: number;
  /** Jour de la semaine (0 = dimanche, 1 = lundi, etc.) */
  dayOfWeek: number;
  /** Date programmée de la séance (ISO string) */
  scheduledDate: string;
  /** Détails complets de la séance (type, durée, description, etc.) */
  workoutDetails: unknown;
}

/**
 * GeneratePlanResult
 * Structure du résultat renvoyé par l'Edge Function :
 * - distribution des phases
 * - tableau des plans hebdomadaires
 * - tableau des plans de séances
 */
export interface GeneratePlanResult {
  /** Distribution des phases pour la durée totale */
  distribution: PhaseDistribution;
  /** Détails des plans pour chaque semaine */
  plannedWeeks: WeeklyPlan[];
  /** Détails de chaque séance planifiée */
  plannedSessions: SessionPlan[];
}
