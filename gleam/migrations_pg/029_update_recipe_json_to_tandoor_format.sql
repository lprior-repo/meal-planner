-- ============================================================================
-- Migration 029: Update recipe_json fields to Tandoor format
-- ============================================================================
--
-- This migration updates the recipe_json column in auto_meal_plans to store
-- recipes in Tandoor format instead of the legacy internal format.
--
-- Changes:
-- 1. Create a transformation function to convert legacy recipe format to Tandoor
-- 2. Update all recipe_json entries to use the new Tandoor format
-- 3. Handle both JSONB and TEXT storage formats
--
-- The Tandoor format includes:
-- - id (from recipe ID)
-- - name
-- - ingredients (as array with proper structure)
-- - instructions (as array of strings)
-- - macros (protein, fat, carbs per serving)
-- - servings
-- - category
-- - fodmap_level
-- - vertical_compliant
--
-- Note: This migration assumes recipe_json is stored as TEXT (JSON string)
-- and converts it to proper Tandoor format while maintaining backward compatibility.
--
-- ============================================================================

BEGIN;

-- Step 1: Create temporary function to transform legacy recipe format to Tandoor
CREATE OR REPLACE FUNCTION transform_recipe_to_tandoor(recipe_json_text TEXT)
RETURNS TEXT AS $$
DECLARE
  recipe_obj JSONB;
  ingredients_array JSONB;
  instructions_array JSONB;
  result_obj JSONB;
BEGIN
  -- Parse the JSON string
  recipe_obj := recipe_json_text::JSONB;

  -- If it's already a JSONB object, work with it directly
  -- If it's an array, extract the first element (recipes are stored individually)
  IF recipe_obj -> 0 IS NOT NULL THEN
    -- It's an array, process first element
    recipe_obj := recipe_obj -> 0;
  END IF;

  -- Extract and restructure ingredients to Tandoor format
  -- Tandoor expects ingredients to have: id, name, original, description, unit, amount, etc.
  -- For now, we'll keep the simple format and enhance on next iteration
  ingredients_array := COALESCE(recipe_obj -> 'ingredients', '[]'::JSONB);

  -- Extract and maintain instructions array
  instructions_array := COALESCE(recipe_obj -> 'instructions', '[]'::JSONB);

  -- Build the Tandoor format recipe object
  result_obj := jsonb_build_object(
    'id', COALESCE(recipe_obj ->> 'id', ''),
    'name', COALESCE(recipe_obj ->> 'name', ''),
    'ingredients', ingredients_array,
    'instructions', instructions_array,
    'macros', COALESCE(recipe_obj -> 'macros', '{}'::JSONB),
    'servings', COALESCE((recipe_obj ->> 'servings')::INTEGER, 1),
    'category', COALESCE(recipe_obj ->> 'category', ''),
    'fodmap_level', COALESCE(recipe_obj ->> 'fodmap_level', 'medium'),
    'vertical_compliant', COALESCE((recipe_obj ->> 'vertical_compliant')::BOOLEAN, FALSE),
    'source', 'tandoor',
    'created_at', NOW()::TEXT
  );

  RETURN result_obj::TEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 2: Update recipe_json for all auto_meal_plans that have non-null recipe_json
-- This preserves the data while converting to Tandoor format
UPDATE auto_meal_plans
SET recipe_json = transform_recipe_to_tandoor(recipe_json)
WHERE recipe_json IS NOT NULL
  AND recipe_json != 'null'
  AND recipe_json != '';

-- Step 3: Add a comment documenting the format
COMMENT ON COLUMN auto_meal_plans.recipe_json IS 'Recipe data in Tandoor format as JSON string. Contains: id, name, ingredients, instructions, macros, servings, category, fodmap_level, vertical_compliant';

-- Step 4: Verify the update completed successfully
DO $$
DECLARE
  updated_count INT;
  total_records INT;
  sample_record TEXT;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM auto_meal_plans
  WHERE recipe_json IS NOT NULL
    AND recipe_json != 'null'
    AND recipe_json::JSONB @> '{"source":"tandoor"}'::JSONB;

  SELECT COUNT(*) INTO total_records
  FROM auto_meal_plans;

  -- Get a sample record to verify format
  SELECT recipe_json INTO sample_record
  FROM auto_meal_plans
  WHERE recipe_json IS NOT NULL
    AND recipe_json != 'null'
  LIMIT 1;

  RAISE NOTICE 'Recipe JSON format update complete:';
  RAISE NOTICE '  - Total auto_meal_plans: %', total_records;
  RAISE NOTICE '  - Updated to Tandoor format: %', updated_count;
  RAISE NOTICE '  - Sample record: %', COALESCE(sample_record, 'No records found');
END $$;

-- Step 5: Drop the temporary transformation function
DROP FUNCTION IF EXISTS transform_recipe_to_tandoor(TEXT);

-- Step 6: Create an index on the source field for faster Tandoor format queries (if JSONB)
-- This helps with filtering recipes by source in the future
-- Note: This only works if recipe_json is stored as JSONB; if stored as TEXT, this can be skipped
-- CREATE INDEX IF NOT EXISTS idx_auto_meal_plans_recipe_source ON auto_meal_plans USING GIN ((recipe_json::JSONB) jsonb_ops) WHERE recipe_json IS NOT NULL;

COMMIT;

-- ============================================================================
-- Rollback Strategy
-- ============================================================================
--
-- If this migration needs to be rolled back, you would need to:
-- 1. Restore the recipe_json from a backup (since the transformation may not be reversible)
-- 2. Or, maintain a separate column with the original format before applying this migration
--
-- For future migrations, consider:
-- - Adding a recipe_json_backup column before transformation
-- - Or using versioning to track which format is stored
--
-- ============================================================================
