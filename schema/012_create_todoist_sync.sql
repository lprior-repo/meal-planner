-- Todoist synchronization state table
-- Tracks last sync timestamp and API credentials for each user

CREATE TABLE IF NOT EXISTS todoist_sync (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    last_sync_ts TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    api_token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index on user_id is implicitly created via PRIMARY KEY constraint
-- Additional metadata columns (created_at, updated_at) enable audit trail

-- TODO: Implement encryption for api_token column (security hardening for future)
-- Consider using pgcrypto extension with encrypt/decrypt functions
-- or application-level encryption before storing sensitive credentials
