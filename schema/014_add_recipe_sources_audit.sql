-- OBSOLETE: This schema change is no longer used.
-- Schema change 014: Audit Logging for recipe_sources (PostgreSQL)
-- Adds comprehensive audit trail for INSERT/UPDATE/DELETE operations on recipe_sources table

-- Create audit table to track all changes to recipe_sources
CREATE TABLE IF NOT EXISTS recipe_sources_audit (
    audit_id SERIAL PRIMARY KEY,
    operation TEXT NOT NULL CHECK(operation IN ('INSERT', 'UPDATE', 'DELETE')),
    operation_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Record ID and old/new values
    record_id INTEGER NOT NULL,
    old_name TEXT,
    new_name TEXT,
    old_type TEXT,
    new_type TEXT,
    old_config JSONB,
    new_config JSONB,
    old_enabled BOOLEAN,
    new_enabled BOOLEAN,
    old_created_at TIMESTAMP,
    new_created_at TIMESTAMP,
    old_updated_at TIMESTAMP,
    new_updated_at TIMESTAMP,

    -- Optional metadata
    changed_by TEXT, -- Can be set via application context
    change_reason TEXT -- Can be set via application context
);

-- Index for efficient querying by record_id
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_record_id
    ON recipe_sources_audit(record_id);

-- Index for time-based queries
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_operation_time
    ON recipe_sources_audit(operation_time);

-- Index for operation type filtering
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_operation
    ON recipe_sources_audit(operation);

-- Trigger function to capture INSERT operations
CREATE OR REPLACE FUNCTION audit_recipe_sources_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (
        operation,
        record_id,
        new_name,
        new_type,
        new_config,
        new_enabled,
        new_created_at,
        new_updated_at
    ) VALUES (
        'INSERT',
        NEW.id,
        NEW.name,
        NEW.type,
        NEW.config,
        NEW.enabled,
        NEW.created_at,
        NEW.updated_at
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to capture UPDATE operations
CREATE OR REPLACE FUNCTION audit_recipe_sources_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (
        operation,
        record_id,
        old_name,
        new_name,
        old_type,
        new_type,
        old_config,
        new_config,
        old_enabled,
        new_enabled,
        old_created_at,
        new_created_at,
        old_updated_at,
        new_updated_at
    ) VALUES (
        'UPDATE',
        NEW.id,
        OLD.name,
        NEW.name,
        OLD.type,
        NEW.type,
        OLD.config,
        NEW.config,
        OLD.enabled,
        NEW.enabled,
        OLD.created_at,
        NEW.created_at,
        OLD.updated_at,
        NEW.updated_at
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to capture DELETE operations
CREATE OR REPLACE FUNCTION audit_recipe_sources_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (
        operation,
        record_id,
        old_name,
        old_type,
        old_config,
        old_enabled,
        old_created_at,
        old_updated_at
    ) VALUES (
        'DELETE',
        OLD.id,
        OLD.name,
        OLD.type,
        OLD.config,
        OLD.enabled,
        OLD.created_at,
        OLD.updated_at
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for INSERT, UPDATE, DELETE operations
DROP TRIGGER IF EXISTS recipe_sources_audit_insert_trigger ON recipe_sources;
CREATE TRIGGER recipe_sources_audit_insert_trigger
    AFTER INSERT ON recipe_sources
    FOR EACH ROW
    EXECUTE FUNCTION audit_recipe_sources_insert();

DROP TRIGGER IF EXISTS recipe_sources_audit_update_trigger ON recipe_sources;
CREATE TRIGGER recipe_sources_audit_update_trigger
    AFTER UPDATE ON recipe_sources
    FOR EACH ROW
    EXECUTE FUNCTION audit_recipe_sources_update();

DROP TRIGGER IF EXISTS recipe_sources_audit_delete_trigger ON recipe_sources;
CREATE TRIGGER recipe_sources_audit_delete_trigger
    AFTER DELETE ON recipe_sources
    FOR EACH ROW
    EXECUTE FUNCTION audit_recipe_sources_delete();

-- Helpful view to show only changed fields in updates
CREATE OR REPLACE VIEW recipe_sources_audit_changes AS
SELECT
    audit_id,
    operation,
    operation_time,
    record_id,
    CASE
        WHEN operation = 'INSERT' THEN new_name
        WHEN operation = 'DELETE' THEN old_name
        ELSE COALESCE(new_name, old_name)
    END AS record_name,
    CASE WHEN old_name IS DISTINCT FROM new_name THEN
        jsonb_build_object('old', old_name, 'new', new_name)
    END AS name_change,
    CASE WHEN old_type IS DISTINCT FROM new_type THEN
        jsonb_build_object('old', old_type, 'new', new_type)
    END AS type_change,
    CASE WHEN old_config IS DISTINCT FROM new_config THEN
        jsonb_build_object('old', old_config, 'new', new_config)
    END AS config_change,
    CASE WHEN old_enabled IS DISTINCT FROM new_enabled THEN
        jsonb_build_object('old', old_enabled, 'new', new_enabled)
    END AS enabled_change,
    changed_by,
    change_reason
FROM recipe_sources_audit
ORDER BY operation_time DESC;
