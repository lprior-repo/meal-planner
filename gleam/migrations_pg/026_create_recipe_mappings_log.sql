-- ============================================================================
-- Migration: Create Recipe Mappings Log Table
-- ============================================================================
--
-- This migration creates a recipe_mappings table to track the mapping between
-- Mealie recipe slugs and Tandoor recipe IDs.
--
-- Purpose:
-- - Log all recipe imports from Mealie to Tandoor
-- - Track which Mealie recipes have been migrated to Tandoor
-- - Enable debugging and reconciliation between recipe sources
-- - Audit trail for recipe data transformations
--
-- Table Structure:
-- - mapping_id: Auto-incrementing unique identifier for each mapping
-- - mealie_slug: The slug identifier from Mealie recipe (unique)
-- - tandoor_id: The numeric ID from Tandoor recipe
-- - mealie_name: Original recipe name from Mealie (for reference)
-- - tandoor_name: Recipe name in Tandoor after import
-- - mapped_at: Timestamp when the mapping was created
-- - notes: Optional field for additional context (e.g., modification details)
-- - status: Current state of the mapping (active, deprecated, error)
--
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS recipe_mappings (
    mapping_id SERIAL PRIMARY KEY,
    mealie_slug TEXT NOT NULL UNIQUE,
    tandoor_id INTEGER NOT NULL,
    mealie_name TEXT NOT NULL,
    tandoor_name TEXT NOT NULL,
    mapped_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deprecated', 'error'))
);

-- Indexes for efficient querying
-- Primary lookup: by Mealie slug (unique index already created for UNIQUE constraint)
CREATE INDEX IF NOT EXISTS idx_recipe_mappings_mealie_slug
ON recipe_mappings(mealie_slug);

-- Secondary lookup: by Tandoor ID
CREATE INDEX IF NOT EXISTS idx_recipe_mappings_tandoor_id
ON recipe_mappings(tandoor_id);

-- For auditing: find mappings by date
CREATE INDEX IF NOT EXISTS idx_recipe_mappings_mapped_at
ON recipe_mappings(mapped_at);

-- For status queries: find active vs deprecated mappings
CREATE INDEX IF NOT EXISTS idx_recipe_mappings_status
ON recipe_mappings(status);

-- Composite index for common queries (status + mapped_at)
CREATE INDEX IF NOT EXISTS idx_recipe_mappings_status_date
ON recipe_mappings(status, mapped_at DESC);

-- Add table comments for documentation
COMMENT ON TABLE recipe_mappings IS
'Audit log for recipe migrations from Mealie to Tandoor. Tracks mapping between Mealie slugs and Tandoor IDs.';

COMMENT ON COLUMN recipe_mappings.mapping_id IS
'Auto-incrementing primary key for each mapping record';

COMMENT ON COLUMN recipe_mappings.mealie_slug IS
'Unique slug identifier from Mealie recipe system';

COMMENT ON COLUMN recipe_mappings.tandoor_id IS
'Numeric recipe ID from Tandoor recipe system';

COMMENT ON COLUMN recipe_mappings.mealie_name IS
'Original recipe name from Mealie (for reference and debugging)';

COMMENT ON COLUMN recipe_mappings.tandoor_name IS
'Recipe name in Tandoor after import (may differ from Mealie name)';

COMMENT ON COLUMN recipe_mappings.mapped_at IS
'Timestamp when the mapping was created (UTC timezone)';

COMMENT ON COLUMN recipe_mappings.notes IS
'Optional notes about the mapping (modifications, issues, special handling)';

COMMENT ON COLUMN recipe_mappings.status IS
'Current status: active (in use), deprecated (superseded), error (failed import)';

COMMIT;

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. mealie_slug: UNIQUE constraint provides primary lookup path
--    - Supports: SELECT * FROM recipe_mappings WHERE mealie_slug = ?
--    - Fast reverse lookups for deduplication
--
-- 2. tandoor_id: Secondary index for Tandoor-centric queries
--    - Supports: SELECT * FROM recipe_mappings WHERE tandoor_id = ?
--    - Useful for finding which Mealie recipe created a given Tandoor recipe
--
-- 3. mapped_at: For time-range queries and debugging
--    - Supports: SELECT * FROM recipe_mappings WHERE mapped_at BETWEEN ? AND ?
--    - Useful for auditing recent migrations
--
-- 4. status: For filtering active vs deprecated mappings
--    - Supports: SELECT * FROM recipe_mappings WHERE status = 'active'
--
-- 5. status + mapped_at: Composite index for common queries
--    - Supports: SELECT * FROM recipe_mappings WHERE status = 'active' ORDER BY mapped_at DESC
--    - Useful for viewing recent active mappings
--
-- ============================================================================
-- Example Usage
-- ============================================================================
--
-- Insert a new mapping:
-- INSERT INTO recipe_mappings (mealie_slug, tandoor_id, mealie_name, tandoor_name, notes)
-- VALUES ('tiramisu-classic', 42, 'Tiramisu Classic', 'Tiramisu', 'Imported from Mealie');
--
-- Find mapping by Mealie slug:
-- SELECT * FROM recipe_mappings WHERE mealie_slug = 'tiramisu-classic';
--
-- Find all active mappings:
-- SELECT * FROM recipe_mappings WHERE status = 'active' ORDER BY mapped_at DESC;
--
-- Mark a mapping as deprecated (when recipe is removed):
-- UPDATE recipe_mappings SET status = 'deprecated' WHERE mealie_slug = 'old-recipe';
--
-- ============================================================================
-- Rollback Strategy
-- ============================================================================
--
-- If needed, drop the table with:
-- DROP TABLE IF EXISTS recipe_mappings CASCADE;
--
-- ============================================================================
