-- Migration 006: Add source tracking to food_logs (PostgreSQL version)
-- Allows tracking whether a logged food came from:
-- - 'recipe': From recipes table
-- - 'custom_food': From custom_foods table
-- - 'usda_food': From USDA database (foods/food_nutrients tables)

-- Add source_type column with CHECK constraint
ALTER TABLE food_logs ADD COLUMN source_type TEXT
    CHECK (source_type IN ('recipe', 'custom_food', 'usda_food'));

-- Add source_id column (stores ID as TEXT for flexibility)
ALTER TABLE food_logs ADD COLUMN source_id TEXT;

-- Update existing rows: All existing entries are recipes (legacy behavior)
UPDATE food_logs
SET source_type = 'recipe',
    source_id = recipe_id
WHERE source_type IS NULL;

-- Make columns NOT NULL after backfill
ALTER TABLE food_logs ALTER COLUMN source_type SET NOT NULL;
ALTER TABLE food_logs ALTER COLUMN source_id SET NOT NULL;

-- Create composite index for efficient source lookups
CREATE INDEX idx_food_logs_source ON food_logs(source_type, source_id);

-- Create index on date for daily log queries (if not exists)
CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);

-- Add comment for documentation
COMMENT ON COLUMN food_logs.source_type IS 'Source of logged food: recipe, custom_food, or usda_food';
COMMENT ON COLUMN food_logs.source_id IS 'ID of the source food item (recipe_id, custom_food_id, or fdc_id as text)';
