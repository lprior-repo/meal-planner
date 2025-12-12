-- Drop recipes table to use Mealie as sole source of truth
-- Rollback: See migrations_pg/rollback/019_restore_recipes_table.sql

DROP TABLE IF EXISTS recipes CASCADE;
