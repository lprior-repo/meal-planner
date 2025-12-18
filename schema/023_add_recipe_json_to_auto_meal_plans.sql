-- Schema change 023: Add recipe_json column to auto_meal_plans
-- Stores full recipe data as JSONB for faster loading without joins

-- Add recipe_json column
ALTER TABLE auto_meal_plans ADD COLUMN IF NOT EXISTS recipe_json JSONB;

-- Create GIN index for recipe_json JSONB queries
CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_recipe_json ON auto_meal_plans USING GIN (recipe_json);

-- Add comment for documentation
COMMENT ON COLUMN auto_meal_plans.recipe_json IS 'Full recipe data serialized as JSON array for fast access without joins';
