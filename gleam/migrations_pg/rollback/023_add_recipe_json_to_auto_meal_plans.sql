-- Rollback Migration 023: Remove recipe_json column from auto_meal_plans

-- Drop GIN index
DROP INDEX IF EXISTS idx_auto_meal_plans_recipe_json;

-- Remove recipe_json column
ALTER TABLE auto_meal_plans DROP COLUMN IF EXISTS recipe_json;
