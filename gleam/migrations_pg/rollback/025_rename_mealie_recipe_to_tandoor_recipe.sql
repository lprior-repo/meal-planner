-- ============================================================================
-- Rollback Migration: Restore 'mealie_recipe' from 'tandoor_recipe'
-- ============================================================================
--
-- This rollback migration reverses the changes made by
-- 025_rename_mealie_recipe_to_tandoor_recipe.sql
--
-- Changes:
-- 1. Drop the constraint with 'tandoor_recipe'
-- 2. Update 'tandoor_recipe' values back to 'mealie_recipe'
-- 3. Recreate constraint with 'mealie_recipe'
--
-- ============================================================================

BEGIN;

-- Step 1: Drop the constraint with 'tandoor_recipe'
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Step 2: Update data back to 'mealie_recipe'
UPDATE food_logs
SET source_type = 'mealie_recipe'
WHERE source_type = 'tandoor_recipe';

-- Step 3: Recreate constraint with 'mealie_recipe'
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type = ANY (ARRAY['mealie_recipe'::text, 'custom_food'::text, 'usda_food'::text]));

COMMIT;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON CONSTRAINT food_logs_source_type_check ON food_logs IS
'Ensures source_type is one of: mealie_recipe (from Mealie API), custom_food (user-created), usda_food (USDA database)';
