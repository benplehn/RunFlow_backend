BEGIN;

SELECT plan(1);  -- On prévoit 1 test

-- Ce test passe toujours (utilisé pour vérifier l’intégration GitHub Actions)
SELECT pass('health test passes');

ROLLBACK;
