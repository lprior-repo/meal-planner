-- Migration 018: Update audit triggers to capture session context
-- Enables application-level tracking of changed_by and change_reason

-- Update INSERT trigger to capture session context
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
        new_updated_at,
        changed_by,
        change_reason
    ) VALUES (
        'INSERT',
        NEW.id,
        NEW.name,
        NEW.type,
        NEW.config,
        NEW.enabled,
        NEW.created_at,
        NEW.updated_at,
        NULLIF(current_setting('audit.changed_by', true), ''),
        NULLIF(current_setting('audit.change_reason', true), '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update UPDATE trigger to capture session context
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
        new_updated_at,
        changed_by,
        change_reason
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
        NEW.updated_at,
        NULLIF(current_setting('audit.changed_by', true), ''),
        NULLIF(current_setting('audit.change_reason', true), '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update DELETE trigger to capture session context
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
        old_updated_at,
        changed_by,
        change_reason
    ) VALUES (
        'DELETE',
        OLD.id,
        OLD.name,
        OLD.type,
        OLD.config,
        OLD.enabled,
        OLD.created_at,
        OLD.updated_at,
        NULLIF(current_setting('audit.changed_by', true), ''),
        NULLIF(current_setting('audit.change_reason', true), '')
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
