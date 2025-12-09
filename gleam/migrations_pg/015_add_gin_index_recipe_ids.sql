-- Add JSONB GIN index on auto_meal_plans.recipe_ids for efficient containment queries
CREATE INDEX idx_auto_meal_plans_recipe_ids_gin ON auto_meal_plans USING gin(recipe_ids);
