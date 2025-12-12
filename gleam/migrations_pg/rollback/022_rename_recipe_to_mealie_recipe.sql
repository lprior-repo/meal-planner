-- Rollback for 022_rename_recipe_to_mealie_recipe.sql
-- Reverts the source_type constraint change from 'mealie_recipe' back to 'recipe'

BEGIN;

-- Step 1: Drop the constraint that has 'mealie_recipe'
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Step 2: Revert the data back to 'recipe' from 'mealie_recipe'
UPDATE food_logs
SET source_type = 'recipe'
WHERE source_type = 'mealie_recipe';

-- Step 3: Recreate the original constraint with 'recipe' value
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type = ANY (ARRAY['recipe'::text, 'custom_food'::text, 'usda_food'::text]));

COMMIT;

-- Update comment for documentation
COMMENT ON CONSTRAINT food_logs_source_type_check ON food_logs IS
'Ensures source_type is one of: recipe (deprecated local recipes), custom_food (user-created), usda_food (USDA database)';
