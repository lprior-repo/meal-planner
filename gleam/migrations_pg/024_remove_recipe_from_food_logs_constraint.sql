-- ============================================================================
-- Migration: Remove 'recipe' option from food_logs source_type constraint
-- ============================================================================
--
-- This migration removes the 'recipe' source_type option from food_logs since
-- we've migrated away from the local recipes table to using Mealie as the sole
-- source of truth for recipes.
--
-- Changes:
-- 1. Drop the existing constraint that includes 'recipe'
-- 2. Create new constraint with only 'mealie_recipe', 'custom_food', 'usda_food'
--
-- Note: This is needed before applying migration 022 which renames 'recipe' to
-- 'mealie_recipe', but can also stand alone if no 'recipe' entries exist.
--
-- ============================================================================

BEGIN;

-- Step 1: Drop the old constraint that allows 'recipe'
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Step 2: Create new constraint without 'recipe' option
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
-- Rollback strategy
-- ============================================================================
--
-- If needed, reverse with:
--   ALTER TABLE food_logs DROP CONSTRAINT food_logs_source_type_check;
--   ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
--     CHECK (source_type = ANY (ARRAY['recipe'::text, 'custom_food'::text, 'usda_food'::text]));
--
-- ============================================================================
