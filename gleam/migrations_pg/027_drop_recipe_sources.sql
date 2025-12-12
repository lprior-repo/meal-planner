-- Migration 027: Drop recipe_sources table
-- This migration drops the recipe_sources table and all its related objects.
-- The recipe_sources table was created in migration 009 for managing recipe API/scraper sources,
-- but the functionality is no longer needed and nothing in the codebase depends on it.
--
-- Objects to be dropped:
-- 1. The recipe_sources table itself
-- 2. All indexes on the table
-- 3. All triggers on the table
-- 4. The trigger functions
--
-- Note: The recipe_sources_audit table and related objects were dropped in migration 021.
-- This migration is safe because:
-- - No Gleam code imports or uses the storage functions
-- - No views depend on the table
-- - No other tables have foreign keys referencing it
-- - The table contains no critical data needed by the application

BEGIN;

-- Drop the trigger first (it depends on the function)
DROP TRIGGER IF EXISTS update_recipe_sources_timestamp ON recipe_sources;

-- Drop the trigger function
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Drop the table with all its indexes and constraints
DROP TABLE IF EXISTS recipe_sources CASCADE;

COMMIT;

-- ============================================================================
-- Comments
-- ============================================================================

-- COMMIT SUCCESSFUL
-- This migration safely removes the recipe_sources table which was no longer
-- used by the application.
--
-- Rollback strategy:
-- If needed, the table and its indexes can be recreated using the schema
-- from migration 009 and the trigger setup.
--
-- ============================================================================
