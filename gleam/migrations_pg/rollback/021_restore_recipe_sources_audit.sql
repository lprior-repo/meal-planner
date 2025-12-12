-- Rollback for 021_drop_recipe_sources_audit.sql
-- Restores the recipe_sources_audit table and related audit infrastructure

BEGIN;

-- Recreate the audit table
CREATE TABLE IF NOT EXISTS recipe_sources_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    recipe_source_id INT NOT NULL,
    action VARCHAR(10) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    changed_by TEXT,
    old_values JSONB,
    new_values JSONB
);

-- Create indexes on the audit table for performance
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_recipe_id ON recipe_sources_audit(recipe_source_id);
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_action ON recipe_sources_audit(action);
CREATE INDEX IF NOT EXISTS idx_recipe_sources_audit_changed_at ON recipe_sources_audit(changed_at);

-- Recreate audit trigger functions
CREATE OR REPLACE FUNCTION audit_recipe_sources_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (recipe_source_id, action, changed_at, new_values)
    VALUES (NEW.id, 'INSERT', NOW(), row_to_json(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_recipe_sources_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (recipe_source_id, action, changed_at, old_values, new_values)
    VALUES (NEW.id, 'UPDATE', NOW(), row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_recipe_sources_delete()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO recipe_sources_audit (recipe_source_id, action, changed_at, old_values)
    VALUES (OLD.id, 'DELETE', NOW(), row_to_json(OLD));
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers
CREATE TRIGGER recipe_sources_audit_insert_trigger
AFTER INSERT ON recipe_sources
FOR EACH ROW
EXECUTE FUNCTION audit_recipe_sources_insert();

CREATE TRIGGER recipe_sources_audit_update_trigger
AFTER UPDATE ON recipe_sources
FOR EACH ROW
EXECUTE FUNCTION audit_recipe_sources_update();

CREATE TRIGGER recipe_sources_audit_delete_trigger
AFTER DELETE ON recipe_sources
FOR EACH ROW
EXECUTE FUNCTION audit_recipe_sources_delete();

-- Recreate audit changes view
CREATE OR REPLACE VIEW recipe_sources_audit_changes AS
SELECT
    audit_id,
    recipe_source_id,
    action,
    changed_at,
    changed_by,
    old_values,
    new_values
FROM recipe_sources_audit
ORDER BY changed_at DESC;

COMMIT;

-- Note: Original audit data is not restored. This only recreates the schema and structures.
-- To restore audit data, you would need to recover from a backup.
