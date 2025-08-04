import type { PhaseDistribution } from "../types.ts";

/**
 * Répartit les semaines d'un plan d'entraînement selon les phases
 * avec la distribution suivante :
 * - Build: 45%
 * - Intensity: 30%
 * - Specificity: 15%
 * - Peak: 10%
 * 
 * @param totalWeeks - Nombre total de semaines du plan
 * @returns La distribution des phases avec le nombre de semaines pour chaque phase
 */
export function splitPhases(totalWeeks: number): PhaseDistribution {
  // Validation de l'entrée
  if (totalWeeks < 4) {
    throw new Error("Un plan d'entraînement doit durer au moins 4 semaines");
  }
  
  if (totalWeeks > 52) {
    throw new Error("Un plan d'entraînement ne peut pas dépasser 52 semaines");
  }

  // Calcul initial des semaines par phase (avec décimales)
  const buildWeeks = totalWeeks * 0.45;
  const intensityWeeks = totalWeeks * 0.30;
  const specificityWeeks = totalWeeks * 0.15;
  const peakWeeks = totalWeeks * 0.10;

  // Arrondi initial à l'entier le plus proche
  let distribution = {
    build: Math.round(buildWeeks),
    intensity: Math.round(intensityWeeks),
    specificity: Math.round(specificityWeeks),
    peak: Math.round(peakWeeks)
  };

  // Vérification et ajustement si nécessaire
  let totalAllocated = distribution.build + distribution.intensity + 
                      distribution.specificity + distribution.peak;
  
  // Si le total ne correspond pas, ajuster
  while (totalAllocated !== totalWeeks) {
    if (totalAllocated < totalWeeks) {
      // Ajouter les semaines manquantes en priorité à build, puis intensity
      if (buildWeeks - distribution.build > -0.5) {
        distribution.build++;
      } else if (intensityWeeks - distribution.intensity > -0.5) {
        distribution.intensity++;
      } else if (specificityWeeks - distribution.specificity > -0.5) {
        distribution.specificity++;
      } else {
        distribution.peak++;
      }
    } else {
      // Retirer les semaines en trop en priorité de peak, puis specificity
      if (distribution.peak > 1 && peakWeeks - distribution.peak < 0.5) {
        distribution.peak--;
      } else if (distribution.specificity > 1 && specificityWeeks - distribution.specificity < 0.5) {
        distribution.specificity--;
      } else if (distribution.intensity > 1) {
        distribution.intensity--;
      } else {
        distribution.build--;
      }
    }
    
    totalAllocated = distribution.build + distribution.intensity + 
                    distribution.specificity + distribution.peak;
  }

  // S'assurer qu'aucune phase n'est à 0 semaine (minimum 1 semaine par phase)
  const phases = ['build', 'intensity', 'specificity', 'peak'] as const;
  for (const phase of phases) {
    if (distribution[phase] === 0) {
      distribution[phase] = 1;
      // Retirer une semaine de la phase la plus importante
      const maxPhase = phases.reduce((max, p) => 
        distribution[p] > distribution[max] ? p : max
      );
      if (distribution[maxPhase] > 1) {
        distribution[maxPhase]--;
      }
    }
  }

  // Retourner la distribution au format attendu
  return [
    { phase: 'build', weeks: distribution.build },
    { phase: 'intensity', weeks: distribution.intensity },
    { phase: 'specificity', weeks: distribution.specificity },
    { phase: 'peak', weeks: distribution.peak }
  ];
}