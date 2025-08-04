import { assertEquals, assertThrows } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { splitPhases } from "../utils/splitPhases.ts";
import type { PhaseDistribution } from "../types.ts";

Deno.test("splitPhases - Plan de 8 semaines", () => {
  const result = splitPhases(8);
  
  // Vérifier que le total fait bien 8 semaines
  const total = result.reduce((sum, phase) => sum + phase.weeks, 0);
  assertEquals(total, 8);
  
  // Vérifier l'ordre des phases
  assertEquals(result[0].phase, "build");
  assertEquals(result[1].phase, "intensity");
  assertEquals(result[2].phase, "specificity");
  assertEquals(result[3].phase, "peak");
  
  // Vérifier approximativement la distribution
  // 8 semaines: ~3.6 build, ~2.4 intensity, ~1.2 specificity, ~0.8 peak
  assertEquals(result[0].weeks, 4); // build arrondi
  assertEquals(result[1].weeks, 2); // intensity
  assertEquals(result[2].weeks, 1); // specificity
  assertEquals(result[3].weeks, 1); // peak
});

Deno.test("splitPhases - Plan de 12 semaines", () => {
  const result = splitPhases(12);
  
  const total = result.reduce((sum, phase) => sum + phase.weeks, 0);
  assertEquals(total, 12);
  
  // 12 semaines: ~5.4 build, ~3.6 intensity, ~1.8 specificity, ~1.2 peak
  assertEquals(result[0].weeks, 5); // build
  assertEquals(result[1].weeks, 4); // intensity
  assertEquals(result[2].weeks, 2); // specificity
  assertEquals(result[3].weeks, 1); // peak
});

Deno.test("splitPhases - Plan de 16 semaines", () => {
  const result = splitPhases(16);
  
  const total = result.reduce((sum, phase) => sum + phase.weeks, 0);
  assertEquals(total, 16);
  
  // 16 semaines: ~7.2 build, ~4.8 intensity, ~2.4 specificity, ~1.6 peak
  assertEquals(result[0].weeks, 7); // build
  assertEquals(result[1].weeks, 5); // intensity
  assertEquals(result[2].weeks, 2); // specificity
  assertEquals(result[3].weeks, 2); // peak
});

Deno.test("splitPhases - Plan de 10 semaines (test d'arrondi)", () => {
  const result = splitPhases(10);
  
  const total = result.reduce((sum, phase) => sum + phase.weeks, 0);
  assertEquals(total, 10);
  
  // 10 semaines: ~4.5 build, ~3 intensity, ~1.5 specificity, ~1 peak
  assertEquals(result[0].weeks, 5); // build arrondi vers le haut
  assertEquals(result[1].weeks, 3); // intensity
  assertEquals(result[2].weeks, 1); // specificity arrondi vers le bas
  assertEquals(result[3].weeks, 1); // peak
});

Deno.test("splitPhases - Aucune phase ne doit avoir 0 semaine", () => {
  // Tester avec différentes durées
  const durations = [4, 5, 6, 7, 8, 10, 12, 14, 16];
  
  for (const weeks of durations) {
    const result = splitPhases(weeks);
    
    // Vérifier qu'aucune phase n'a 0 semaine
    for (const phase of result) {
      assertEquals(phase.weeks >= 1, true, 
        `Phase ${phase.phase} a ${phase.weeks} semaines pour un plan de ${weeks} semaines`);
    }
  }
});

Deno.test("splitPhases - Erreur si moins de 4 semaines", () => {
  assertThrows(
    () => splitPhases(3),
    Error,
    "Un plan d'entraînement doit durer au moins 4 semaines"
  );
  
  assertThrows(
    () => splitPhases(0),
    Error,
    "Un plan d'entraînement doit durer au moins 4 semaines"
  );
  
  assertThrows(
    () => splitPhases(-5),
    Error,
    "Un plan d'entraînement doit durer au moins 4 semaines"
  );
});

Deno.test("splitPhases - Erreur si plus de 52 semaines", () => {
  assertThrows(
    () => splitPhases(53),
    Error,
    "Un plan d'entraînement ne peut pas dépasser 52 semaines"
  );
  
  assertThrows(
    () => splitPhases(100),
    Error,
    "Un plan d'entraînement ne peut pas dépasser 52 semaines"
  );
});

Deno.test("splitPhases - Distribution cohérente pour toutes les durées valides", () => {
  // Tester toutes les durées de 4 à 52 semaines
  for (let weeks = 4; weeks <= 52; weeks++) {
    const result = splitPhases(weeks);
    
    // Le total doit toujours correspondre
    const total = result.reduce((sum, phase) => sum + phase.weeks, 0);
    assertEquals(total, weeks, `Erreur pour ${weeks} semaines`);
    
    // Les phases doivent être dans le bon ordre
    assertEquals(result.length, 4);
    assertEquals(result[0].phase, "build");
    assertEquals(result[1].phase, "intensity");
    assertEquals(result[2].phase, "specificity");
    assertEquals(result[3].phase, "peak");
    
    // Vérifier que la distribution respecte approximativement les pourcentages
    // avec une tolérance de ±15% due aux arrondis
    const buildPercent = (result[0].weeks / weeks) * 100;
    const intensityPercent = (result[1].weeks / weeks) * 100;
    const specificityPercent = (result[2].weeks / weeks) * 100;
    const peakPercent = (result[3].weeks / weeks) * 100;
    
    // Vérifier que les pourcentages sont dans des plages raisonnables
    assertEquals(buildPercent >= 30 && buildPercent <= 60, true, 
      `Build: ${buildPercent}% pour ${weeks} semaines`);
    assertEquals(intensityPercent >= 15 && intensityPercent <= 45, true,
      `Intensity: ${intensityPercent}% pour ${weeks} semaines`);
    assertEquals(specificityPercent >= 5 && specificityPercent <= 30, true,
      `Specificity: ${specificityPercent}% pour ${weeks} semaines`);
    assertEquals(peakPercent >= 5 && peakPercent <= 25, true,
      `Peak: ${peakPercent}% pour ${weeks} semaines`);
  }
});

// Pour exécuter les tests: deno test tests/splitPhases.test.ts