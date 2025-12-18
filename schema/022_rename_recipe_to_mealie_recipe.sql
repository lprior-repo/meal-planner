-- ============================================================================
-- Schema change: Rename source_type 'recipe' to 'mealie_recipe'
-- ============================================================================
--
-- This schema change updates the food_logs table to rename the source_type value
-- 'recipe' to 'mealie_recipe' to better reflect that these logs come from
-- Mealie recipe sources, not the deprecated local recipes table.
--
-- Changes:
-- 1. Update existing 'recipe' values to 'mealie_recipe'
-- 2. Drop the old constraint
-- 3. Create new constraint with 'mealie_recipe' instead of 'recipe'
--
-- ============================================================================

BEGIN;

-- Step 1: Drop the old constraint first to allow updates
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Step 2: Update existing data
-- Change all 'recipe' source_type values to 'mealie_recipe'
UPDATE food_logs
SET source_type = 'mealie_recipe'
WHERE source_type = 'recipe';

-- Step 3: Create new constraint with 'mealie_recipe' instead of 'recipe'
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type = ANY (ARRAY['mealie_recipe'::text, 'custom_food'::text, 'usda_food'::text]));

COMMIT;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON CONSTRAINT food_logs_source_type_check ON food_logs IS
'Ensures source_type is one of: mealie_recipe (from Mealie API), custom_food (user-created), usda_food (USDA database)';

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- This schema change is safe to run on production:
-- - UPDATE is fast (should be 0 rows if 'recipe' was never used)
-- - Constraint changes are quick
-- - No data loss
-- - No downtime required
--
-- Rollback strategy:
-- If needed, reverse with:
--   UPDATE food_logs SET source_type = 'recipe' WHERE source_type = 'mealie_recipe';
--   ALTER TABLE food_logs DROP CONSTRAINT food_logs_source_type_check;
--   ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
--     CHECK (source_type = ANY (ARRAY['recipe'::text, 'custom_food'::text, 'usda_food'::text]));
--
-- ============================================================================
