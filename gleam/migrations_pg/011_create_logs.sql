-- OBSOLETE: This migration is no longer used.
-- ============================================================================
-- Migration: Create Logs Table
-- ============================================================================
--
-- Creates the logs table for tracking food item logs with:
-- - user_id: Reference to user
-- - food_id: Reference to food item from USDA database
-- - quantity: Amount consumed (float for precision)
-- - log_date: Date of consumption
-- - macros: JSONB column for flexible macro storage (protein, fat, carbs, calories)
-- - Timestamps: created_at and updated_at for audit trail
-- - Composite index on (user_id, log_date) for fast queries
--
-- ============================================================================

CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    food_id INT NOT NULL,
    quantity FLOAT NOT NULL,
    log_date DATE NOT NULL,
    macros JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Composite index on (user_id, log_date) for fast queries
-- This index supports:
-- - Getting all logs for a user on a specific date
-- - Getting all logs for a user within a date range
-- - Sorting by date for a user
CREATE INDEX IF NOT EXISTS idx_logs_user_date
ON logs(user_id, log_date);

-- Additional index on log_date for date-based queries
CREATE INDEX IF NOT EXISTS idx_logs_date
ON logs(log_date);

-- Additional index on food_id for food-based queries
CREATE INDEX IF NOT EXISTS idx_logs_food_id
ON logs(food_id);

-- Comment on table
COMMENT ON TABLE logs IS 'Food consumption logs with macro tracking';
COMMENT ON COLUMN logs.id IS 'Auto-incrementing primary key';
COMMENT ON COLUMN logs.user_id IS 'Reference to user';
COMMENT ON COLUMN logs.food_id IS 'Reference to food item from USDA database';
COMMENT ON COLUMN logs.quantity IS 'Quantity consumed (float for precision)';
COMMENT ON COLUMN logs.log_date IS 'Date of consumption';
COMMENT ON COLUMN logs.macros IS 'JSONB column storing macro nutrients (protein, fat, carbs, calories)';
COMMENT ON COLUMN logs.created_at IS 'Timestamp when log was created';
COMMENT ON COLUMN logs.updated_at IS 'Timestamp when log was last updated';

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. idx_logs_user_date: Primary composite index for user-centric queries
--    - Supports: SELECT * FROM logs WHERE user_id = ? AND log_date = ?
--    - Supports: SELECT * FROM logs WHERE user_id = ? AND log_date BETWEEN ? AND ?
--
-- 2. idx_logs_date: Secondary index for global date-based queries
--    - Supports: SELECT * FROM logs WHERE log_date = ?
--
-- 3. idx_logs_food_id: Secondary index for food-centric analytics
--    - Supports: SELECT * FROM logs WHERE food_id = ?
--    - Supports: Food popularity analysis
--
-- ============================================================================
