-- ============================================================================
-- Migration: Rename source_type 'mealie_recipe' to 'tandoor_recipe'
-- ============================================================================
--
-- This migration updates the food_logs table to rename the source_type value
-- 'mealie_recipe' to 'tandoor_recipe' to reflect the migration from Mealie to
-- Tandoor as the recipe management system.
--
-- Changes:
-- 1. Drop the existing constraint
-- 2. Update existing 'mealie_recipe' values to 'tandoor_recipe'
-- 3. Create new constraint with 'tandoor_recipe' instead of 'mealie_recipe'
--
-- ============================================================================

BEGIN;

-- Step 1: Drop the old constraint first to allow updates
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Step 2: Update existing data
-- Change all 'mealie_recipe' source_type values to 'tandoor_recipe'
UPDATE food_logs
SET source_type = 'tandoor_recipe'
WHERE source_type = 'mealie_recipe';

-- Step 3: Create new constraint with 'tandoor_recipe' instead of 'mealie_recipe'
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type = ANY (ARRAY['tandoor_recipe'::text, 'custom_food'::text, 'usda_food'::text]));

COMMIT;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON CONSTRAINT food_logs_source_type_check ON food_logs IS
'Ensures source_type is one of: tandoor_recipe (from Tandoor API), custom_food (user-created), usda_food (USDA database)';

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- This migration is safe to run on production:
-- - UPDATE may affect existing rows with 'mealie_recipe' values
-- - Constraint changes are quick
-- - No data loss
-- - No downtime required
--
-- Rollback strategy:
-- If needed, reverse with:
--   ALTER TABLE food_logs DROP CONSTRAINT food_logs_source_type_check;
--   UPDATE food_logs SET source_type = 'mealie_recipe' WHERE source_type = 'tandoor_recipe';
--   ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
--     CHECK (source_type = ANY (ARRAY['mealie_recipe'::text, 'custom_food'::text, 'usda_food'::text]));
--
-- ============================================================================
