-- Vérifie que la DB tourne
BEGIN;

SELECT plan(1);

SELECT ok(true, 'Le test minimal passe');

ROLLBACK;
