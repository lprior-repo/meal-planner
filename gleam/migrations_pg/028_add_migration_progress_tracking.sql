-- Add migration progress tracking table
-- Tracks the progress of recipe migrations showing "X of Y recipes migrated"

CREATE TABLE IF NOT EXISTS migration_progress (
  id SERIAL PRIMARY KEY,
  migration_id VARCHAR(255) NOT NULL UNIQUE,
  total_recipes INTEGER NOT NULL DEFAULT 0,
  migrated_count INTEGER NOT NULL DEFAULT 0,
  failed_count INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,

  CONSTRAINT valid_status CHECK (status IN ('in_progress', 'completed', 'failed'))
);

-- Create index for fast lookups by migration_id
CREATE INDEX IF NOT EXISTS idx_migration_progress_id ON migration_progress(migration_id);

-- Create index for filtering by status
CREATE INDEX IF NOT EXISTS idx_migration_progress_status ON migration_progress(status);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_migration_progress_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS migration_progress_update_timestamp ON migration_progress;

CREATE TRIGGER migration_progress_update_timestamp
BEFORE UPDATE ON migration_progress
FOR EACH ROW
EXECUTE FUNCTION update_migration_progress_timestamp();
