-- Schema change 024: Populate recipe_json for existing auto_meal_plans
-- This schema change populates the recipe_json column in auto_meal_plans
-- by aggregating recipe data from the recipes table based on recipe_ids
--
-- Strategy:
-- 1. Extract recipe IDs from the recipe_ids JSONB column
-- 2. Join with recipes table to get full recipe data
-- 3. Aggregate results into a JSON array
-- 4. Store in recipe_json column
--
-- Note: This is a data population schema change that runs once to hydrate
-- existing meal plans with denormalized recipe data for performance.

BEGIN;

-- Step 1: Create temporary function to extract recipes for a meal plan
-- This function takes a JSON array of recipe IDs and returns aggregated recipe data
CREATE OR REPLACE FUNCTION build_recipe_json(recipe_ids JSONB)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Convert JSON array of recipe IDs to a table, join with recipes table,
  -- and aggregate back into a JSON array of recipe objects
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', r.id,
      'name', r.name,
      'ingredients', r.ingredients,
      'instructions', r.instructions,
      'protein', r.protein,
      'fat', r.fat,
      'carbs', r.carbs,
      'servings', r.servings,
      'category', r.category,
      'fodmap_level', r.fodmap_level,
      'vertical_compliant', r.vertical_compliant
    ) ORDER BY r.id
  ), '[]'::jsonb)
  INTO result
  FROM recipes r
  WHERE r.id = ANY(
    SELECT jsonb_array_elements_text(recipe_ids)::TEXT
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 2: Update recipe_json column for all existing meal plans
-- that have recipe_ids but empty recipe_json
UPDATE auto_meal_plans
SET recipe_json = build_recipe_json(recipe_ids)
WHERE recipe_json IS NULL
  AND recipe_ids IS NOT NULL
  AND jsonb_array_length(recipe_ids) > 0;

-- Step 3: Verify the update
-- This query shows how many meal plans were updated
DO $$
DECLARE
  updated_count INT;
  total_with_recipes INT;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM auto_meal_plans
  WHERE recipe_json IS NOT NULL;

  SELECT COUNT(*) INTO total_with_recipes
  FROM auto_meal_plans
  WHERE recipe_ids IS NOT NULL
    AND jsonb_array_length(recipe_ids) > 0;

  RAISE NOTICE 'Recipe JSON population complete: % meal plans updated out of % with recipe IDs',
    updated_count, total_with_recipes;
END $$;

-- Step 4: Drop the temporary function (it was only needed for the update)
DROP FUNCTION IF EXISTS build_recipe_json(jsonb);

COMMIT;
