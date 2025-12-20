-- ============================================================================
-- Schema change 034: FatSecret Upload Queue
-- ============================================================================
--
-- Creates tables for queuing and tracking food entries to be uploaded to
-- FatSecret's food diary via their API. Handles:
-- - Upload queue for food_logs entries
-- - Retry logic with exponential backoff
-- - Status tracking (pending, uploading, completed, failed)
-- - Deduplication to prevent duplicate uploads
-- - Error tracking and debugging
--
-- Features:
-- - Automatic retry on transient failures
-- - Configurable max retry attempts
-- - Tracks FatSecret's food_entry_id after successful upload
-- - Supports batch processing
-- - Dead-letter queue for permanently failed items
-- ============================================================================

-- ============================================================================
-- 1. Upload Queue Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS fatsecret_upload_queue (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Reference to food_logs table
    food_log_id TEXT NOT NULL UNIQUE REFERENCES food_logs(id) ON DELETE CASCADE,

    -- Upload status
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'uploading', 'completed', 'failed', 'dead_letter')),

    -- Retry tracking
    retry_count INTEGER NOT NULL DEFAULT 0,
    retry_max_attempts INTEGER NOT NULL DEFAULT 3,
    retry_backoff_seconds INTEGER NOT NULL DEFAULT 60,

    -- Error tracking
    last_error TEXT,
    last_error_at TIMESTAMP WITH TIME ZONE,

    -- FatSecret response
    fatsecret_food_entry_id TEXT, -- FatSecret's ID for the uploaded entry
    fatsecret_response JSONB, -- Full API response for debugging

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- When to retry
    started_at TIMESTAMP WITH TIME ZONE, -- When upload started
    completed_at TIMESTAMP WITH TIME ZONE -- When upload completed/failed permanently
);

-- ============================================================================
-- 2. Upload History Table (Audit Trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fatsecret_upload_history (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Reference to queue item
    queue_id INTEGER NOT NULL REFERENCES fatsecret_upload_queue(id) ON DELETE CASCADE,

    -- Attempt tracking
    attempt_number INTEGER NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Result
    status TEXT NOT NULL CHECK(status IN ('uploading', 'completed', 'failed')),
    error_message TEXT,

    -- Performance metrics
    duration_ms INTEGER, -- Upload duration in milliseconds

    -- API interaction
    request_payload JSONB, -- What we sent to FatSecret
    response_payload JSONB, -- What FatSecret returned
    http_status_code INTEGER
);

-- ============================================================================
-- 3. Indexes for Performance
-- ============================================================================

-- Index for finding pending items to upload
CREATE INDEX IF NOT EXISTS idx_fatsecret_queue_status_scheduled
ON fatsecret_upload_queue(status, scheduled_for ASC)
WHERE status IN ('pending', 'uploading');

-- Index for finding items by food_log_id (deduplication)
-- Already created by UNIQUE constraint on food_log_id

-- Index for finding failed items
CREATE INDEX IF NOT EXISTS idx_fatsecret_queue_failed
ON fatsecret_upload_queue(status, last_error_at DESC)
WHERE status IN ('failed', 'dead_letter');

-- Index for history by queue item
CREATE INDEX IF NOT EXISTS idx_fatsecret_history_queue_id
ON fatsecret_upload_history(queue_id, started_at DESC);

-- Index for recent upload attempts
CREATE INDEX IF NOT EXISTS idx_fatsecret_history_started_at
ON fatsecret_upload_history(started_at DESC);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_fatsecret_queue_response
ON fatsecret_upload_queue USING GIN (fatsecret_response);

CREATE INDEX IF NOT EXISTS idx_fatsecret_history_request
ON fatsecret_upload_history USING GIN (request_payload);

CREATE INDEX IF NOT EXISTS idx_fatsecret_history_response
ON fatsecret_upload_history USING GIN (response_payload);

-- ============================================================================
-- 4. Triggers for Timestamp Management
-- ============================================================================

-- Update updated_at on fatsecret_upload_queue
DROP TRIGGER IF EXISTS update_fatsecret_queue_timestamp ON fatsecret_upload_queue;
CREATE TRIGGER update_fatsecret_queue_timestamp
    BEFORE UPDATE ON fatsecret_upload_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. Helper Functions
-- ============================================================================

-- Function to enqueue a food log for upload
CREATE OR REPLACE FUNCTION enqueue_fatsecret_upload(
    food_log_id_param TEXT,
    retry_max_attempts_param INTEGER DEFAULT 3,
    retry_backoff_seconds_param INTEGER DEFAULT 60
)
RETURNS INTEGER AS $$
DECLARE
    queue_id INTEGER;
BEGIN
    INSERT INTO fatsecret_upload_queue (
        food_log_id,
        status,
        retry_max_attempts,
        retry_backoff_seconds,
        scheduled_for
    )
    VALUES (
        food_log_id_param,
        'pending',
        retry_max_attempts_param,
        retry_backoff_seconds_param,
        NOW()
    )
    ON CONFLICT (food_log_id) DO UPDATE
    SET status = CASE
            WHEN fatsecret_upload_queue.status IN ('completed')
            THEN fatsecret_upload_queue.status -- Don't re-enqueue completed items
            ELSE 'pending' -- Reset to pending for retry
        END,
        retry_count = 0,
        scheduled_for = NOW(),
        last_error = NULL,
        updated_at = NOW()
    RETURNING id INTO queue_id;

    RETURN queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get next pending upload
CREATE OR REPLACE FUNCTION get_next_pending_upload()
RETURNS INTEGER AS $$
DECLARE
    next_queue_id INTEGER;
BEGIN
    SELECT id INTO next_queue_id
    FROM fatsecret_upload_queue
    WHERE status = 'pending'
      AND (scheduled_for IS NULL OR scheduled_for <= NOW())
    ORDER BY scheduled_for ASC NULLS FIRST, created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Prevent race conditions

    RETURN next_queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to start an upload attempt
CREATE OR REPLACE FUNCTION start_fatsecret_upload(queue_id_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    history_id INTEGER;
    current_retry_count INTEGER;
BEGIN
    -- Get current retry count
    SELECT retry_count INTO current_retry_count
    FROM fatsecret_upload_queue
    WHERE id = queue_id_param;

    -- Update queue status
    UPDATE fatsecret_upload_queue
    SET status = 'uploading',
        started_at = NOW(),
        updated_at = NOW()
    WHERE id = queue_id_param;

    -- Create history record
    INSERT INTO fatsecret_upload_history (
        queue_id,
        attempt_number,
        started_at,
        status
    )
    VALUES (
        queue_id_param,
        current_retry_count + 1,
        NOW(),
        'uploading'
    )
    RETURNING id INTO history_id;

    RETURN history_id;
END;
$$ LANGUAGE plpgsql;

-- Function to mark upload as completed
CREATE OR REPLACE FUNCTION complete_fatsecret_upload(
    queue_id_param INTEGER,
    history_id_param INTEGER,
    fatsecret_food_entry_id_param TEXT,
    response_payload_param JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE;
    duration INTEGER;
BEGIN
    -- Get start time
    SELECT started_at INTO start_time
    FROM fatsecret_upload_history
    WHERE id = history_id_param;

    -- Calculate duration in milliseconds
    duration := EXTRACT(EPOCH FROM (NOW() - start_time)) * 1000;

    -- Update queue status
    UPDATE fatsecret_upload_queue
    SET status = 'completed',
        fatsecret_food_entry_id = fatsecret_food_entry_id_param,
        fatsecret_response = response_payload_param,
        completed_at = NOW(),
        retry_count = 0,
        last_error = NULL,
        updated_at = NOW()
    WHERE id = queue_id_param;

    -- Update history record
    UPDATE fatsecret_upload_history
    SET status = 'completed',
        completed_at = NOW(),
        duration_ms = duration,
        response_payload = response_payload_param,
        http_status_code = 200
    WHERE id = history_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to mark upload as failed
CREATE OR REPLACE FUNCTION fail_fatsecret_upload(
    queue_id_param INTEGER,
    history_id_param INTEGER,
    error_message_param TEXT,
    http_status_code_param INTEGER DEFAULT NULL,
    response_payload_param JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE;
    duration INTEGER;
    current_retry_count INTEGER;
    max_attempts INTEGER;
    backoff_seconds INTEGER;
BEGIN
    -- Get start time
    SELECT started_at INTO start_time
    FROM fatsecret_upload_history
    WHERE id = history_id_param;

    -- Calculate duration in milliseconds
    duration := EXTRACT(EPOCH FROM (NOW() - start_time)) * 1000;

    -- Get retry policy
    SELECT retry_count + 1, retry_max_attempts, retry_backoff_seconds
    INTO current_retry_count, max_attempts, backoff_seconds
    FROM fatsecret_upload_queue
    WHERE id = queue_id_param;

    -- Update queue status
    UPDATE fatsecret_upload_queue
    SET status = CASE
            WHEN current_retry_count >= max_attempts THEN 'dead_letter'
            ELSE 'failed'
        END,
        retry_count = current_retry_count,
        last_error = error_message_param,
        last_error_at = NOW(),
        completed_at = CASE
            WHEN current_retry_count >= max_attempts THEN NOW()
            ELSE NULL
        END,
        -- Schedule retry with exponential backoff
        scheduled_for = CASE
            WHEN current_retry_count < max_attempts
            THEN NOW() + (backoff_seconds * POWER(2, current_retry_count - 1) || ' seconds')::INTERVAL
            ELSE NULL
        END,
        updated_at = NOW()
    WHERE id = queue_id_param;

    -- Update history record
    UPDATE fatsecret_upload_history
    SET status = 'failed',
        completed_at = NOW(),
        duration_ms = duration,
        error_message = error_message_param,
        response_payload = response_payload_param,
        http_status_code = http_status_code_param
    WHERE id = history_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to retry a failed upload immediately (manual intervention)
CREATE OR REPLACE FUNCTION retry_fatsecret_upload(queue_id_param INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE fatsecret_upload_queue
    SET status = 'pending',
        scheduled_for = NOW(),
        retry_count = 0,
        last_error = NULL,
        updated_at = NOW()
    WHERE id = queue_id_param
      AND status IN ('failed', 'dead_letter');
END;
$$ LANGUAGE plpgsql;

-- Function to get upload statistics
CREATE OR REPLACE FUNCTION get_fatsecret_upload_stats()
RETURNS TABLE(
    total_queued BIGINT,
    pending BIGINT,
    uploading BIGINT,
    completed BIGINT,
    failed BIGINT,
    dead_letter BIGINT,
    avg_upload_time_ms NUMERIC,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT AS total_queued,
        COUNT(*) FILTER (WHERE status = 'pending')::BIGINT AS pending,
        COUNT(*) FILTER (WHERE status = 'uploading')::BIGINT AS uploading,
        COUNT(*) FILTER (WHERE status = 'completed')::BIGINT AS completed,
        COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed,
        COUNT(*) FILTER (WHERE status = 'dead_letter')::BIGINT AS dead_letter,
        (SELECT AVG(duration_ms) FROM fatsecret_upload_history WHERE status = 'completed') AS avg_upload_time_ms,
        CASE
            WHEN COUNT(*) > 0 THEN
                (COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)::NUMERIC) * 100
            ELSE 0
        END AS success_rate
    FROM fatsecret_upload_queue;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 6. Comments on Tables and Columns
-- ============================================================================

COMMENT ON TABLE fatsecret_upload_queue IS 'Queue for uploading food_logs entries to FatSecret API';
COMMENT ON COLUMN fatsecret_upload_queue.id IS 'Auto-incrementing queue item ID';
COMMENT ON COLUMN fatsecret_upload_queue.food_log_id IS 'Reference to food_logs.id (unique to prevent duplicates)';
COMMENT ON COLUMN fatsecret_upload_queue.status IS 'Upload status: pending, uploading, completed, failed, dead_letter';
COMMENT ON COLUMN fatsecret_upload_queue.retry_count IS 'Number of upload attempts so far';
COMMENT ON COLUMN fatsecret_upload_queue.retry_max_attempts IS 'Maximum retry attempts before moving to dead_letter';
COMMENT ON COLUMN fatsecret_upload_queue.retry_backoff_seconds IS 'Base seconds to wait between retries (exponential backoff)';
COMMENT ON COLUMN fatsecret_upload_queue.last_error IS 'Last error message from failed upload attempt';
COMMENT ON COLUMN fatsecret_upload_queue.last_error_at IS 'Timestamp of last error';
COMMENT ON COLUMN fatsecret_upload_queue.fatsecret_food_entry_id IS 'FatSecret food_entry_id after successful upload';
COMMENT ON COLUMN fatsecret_upload_queue.fatsecret_response IS 'Full FatSecret API response for debugging';
COMMENT ON COLUMN fatsecret_upload_queue.scheduled_for IS 'Next scheduled upload attempt time';
COMMENT ON COLUMN fatsecret_upload_queue.started_at IS 'When current/last upload attempt started';
COMMENT ON COLUMN fatsecret_upload_queue.completed_at IS 'When upload completed or permanently failed';

COMMENT ON TABLE fatsecret_upload_history IS 'Audit trail of all FatSecret upload attempts';
COMMENT ON COLUMN fatsecret_upload_history.id IS 'Auto-incrementing history ID';
COMMENT ON COLUMN fatsecret_upload_history.queue_id IS 'Reference to upload queue item';
COMMENT ON COLUMN fatsecret_upload_history.attempt_number IS 'Attempt number (1-indexed)';
COMMENT ON COLUMN fatsecret_upload_history.started_at IS 'When this attempt started';
COMMENT ON COLUMN fatsecret_upload_history.completed_at IS 'When this attempt completed';
COMMENT ON COLUMN fatsecret_upload_history.status IS 'Attempt status: uploading, completed, failed';
COMMENT ON COLUMN fatsecret_upload_history.error_message IS 'Error message if attempt failed';
COMMENT ON COLUMN fatsecret_upload_history.duration_ms IS 'Upload duration in milliseconds';
COMMENT ON COLUMN fatsecret_upload_history.request_payload IS 'JSON payload sent to FatSecret API';
COMMENT ON COLUMN fatsecret_upload_history.response_payload IS 'JSON response from FatSecret API';
COMMENT ON COLUMN fatsecret_upload_history.http_status_code IS 'HTTP status code from FatSecret API';

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. idx_fatsecret_queue_status_scheduled: Optimizes queue polling
--    - Filters by status (pending/uploading)
--    - Sorts by scheduled_for ASC for FIFO processing
--    - Partial index reduces index size
--
-- 2. UNIQUE constraint on food_log_id: Prevents duplicate uploads
--    - Automatically creates index for fast lookups
--    - Supports: SELECT * FROM fatsecret_upload_queue WHERE food_log_id = ?
--
-- 3. idx_fatsecret_history_queue_id: Audit trail per queue item
--    - Supports: SELECT * FROM fatsecret_upload_history WHERE queue_id = ?
--
-- 4. GIN indexes on JSONB: Fast containment queries
--    - Supports: WHERE fatsecret_response @> '{"status": "success"}'
--
-- Concurrency:
-- - get_next_pending_upload() uses FOR UPDATE SKIP LOCKED
--   to prevent race conditions when multiple workers poll
--
-- Retry Logic:
-- - Exponential backoff: base_seconds * 2^(retry_count - 1)
-- - Example: 60s, 120s, 240s for backoff_seconds=60
-- - After max_attempts, items move to 'dead_letter' status
--
-- Deduplication:
-- - UNIQUE constraint on food_log_id prevents duplicate queue entries
-- - enqueue_fatsecret_upload() uses ON CONFLICT to handle re-queueing
--
-- Dead Letter Queue:
-- - Items that exceed max_attempts move to 'dead_letter' status
-- - Can be manually retried using retry_fatsecret_upload()
--
-- ============================================================================
