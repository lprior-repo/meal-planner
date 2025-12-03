-- Migration 006: Add source tracking to food_logs
-- Allows tracking whether a logged food came from:
-- - 'recipe': From recipes table
-- - 'custom_food': From custom_foods table
-- - 'usda_food': From USDA database (foods/food_nutrients tables)

-- Add source_type column (TEXT with CHECK constraint for type safety)
ALTER TABLE food_logs ADD COLUMN source_type TEXT;

-- Add source_id column (stores ID as TEXT for flexibility)
ALTER TABLE food_logs ADD COLUMN source_id TEXT;

-- Update existing rows: All existing entries are recipes (legacy behavior)
UPDATE food_logs
SET source_type = 'recipe',
    source_id = recipe_id
WHERE source_type IS NULL;

-- Make columns NOT NULL after backfill
-- SQLite doesn't support ALTER COLUMN, so we check constraints instead
-- The application layer enforces NOT NULL for new inserts

-- Add CHECK constraint to validate source_type values
-- Note: SQLite supports CHECK constraints in CREATE TABLE but not ALTER TABLE with CHECK
-- We'll rely on application-level validation

-- Create composite index for efficient source lookups
CREATE INDEX idx_food_logs_source ON food_logs(source_type, source_id);

-- Create index on date for daily log queries (if not exists)
CREATE INDEX IF NOT EXISTS idx_food_logs_date ON food_logs(date);
