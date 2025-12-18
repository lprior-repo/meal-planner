-- Drop recipes_simplified table to use Mealie as sole source of truth
-- This table is obsolete as we now integrate with Mealie for recipe management
-- Rollback: See migrations_pg/rollback/020_restore_recipes_simplified_table.sql

DROP TABLE IF EXISTS recipes_simplified CASCADE;
