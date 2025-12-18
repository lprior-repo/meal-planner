-- Migration 021: Drop recipe_sources_audit table and related objects
-- Removes the audit logging system for recipe_sources table

-- Drop triggers first (they depend on functions)
DROP TRIGGER IF EXISTS recipe_sources_audit_insert_trigger ON recipe_sources;
DROP TRIGGER IF EXISTS recipe_sources_audit_update_trigger ON recipe_sources;
DROP TRIGGER IF EXISTS recipe_sources_audit_delete_trigger ON recipe_sources;

-- Drop the view (it depends on the table)
DROP VIEW IF EXISTS recipe_sources_audit_changes;

-- Drop trigger functions (they depend on the table)
DROP FUNCTION IF EXISTS audit_recipe_sources_insert();
DROP FUNCTION IF EXISTS audit_recipe_sources_update();
DROP FUNCTION IF EXISTS audit_recipe_sources_delete();

-- Finally, drop the audit table and its indexes
DROP TABLE IF EXISTS recipe_sources_audit CASCADE;
