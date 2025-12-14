-- FatSecret OAuth token storage for 3-legged authentication
--
-- This migration creates tables for storing OAuth tokens used to access
-- FatSecret user data (food diary entries, profile, etc.)

-- Pending OAuth requests (temporary, for request tokens during auth flow)
-- These are short-lived and cleaned up after successful auth or timeout
CREATE TABLE IF NOT EXISTS fatsecret_oauth_pending (
    oauth_token TEXT PRIMARY KEY,
    oauth_token_secret TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes')
);

CREATE INDEX IF NOT EXISTS idx_fatsecret_pending_expires
    ON fatsecret_oauth_pending(expires_at);

-- Connected FatSecret account (singleton - single user app)
-- Stores the access token after successful OAuth flow
CREATE TABLE IF NOT EXISTS fatsecret_oauth_token (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    oauth_token TEXT NOT NULL,
    oauth_token_secret TEXT NOT NULL,
    connected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE
);

-- Function to cleanup expired pending tokens
CREATE OR REPLACE FUNCTION cleanup_fatsecret_pending_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM fatsecret_oauth_pending
    WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
