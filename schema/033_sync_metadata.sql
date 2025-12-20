-- ============================================================================
-- Schema change 033: Sync Metadata - FatSecret & Tandoor Synchronization
-- ============================================================================
--
-- Creates tables for tracking synchronization state between external services:
-- - FatSecret API sync (food diary entries, nutrition data)
-- - Tandoor API sync (recipes, meal plans, shopping lists)
-- - Sync queue management (pending operations)
-- - Sync history tracking (audit trail)
--
-- Features:
-- - Per-service sync timestamps
-- - Sync status tracking (idle, syncing, error)
-- - Queue-based sync operations with priority
-- - Retry logic with exponential backoff
-- - Conflict resolution tracking
-- - Performance metrics
-- ============================================================================

-- ============================================================================
-- 1. Sync Service State Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_service_state (
    -- Service identifier
    service_name TEXT PRIMARY KEY CHECK (service_name IN ('fatsecret', 'tandoor')),

    -- Sync status
    status TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'syncing', 'error', 'paused')),

    -- Timestamps for tracking sync windows
    last_sync_started_at TIMESTAMP WITH TIME ZONE,
    last_sync_completed_at TIMESTAMP WITH TIME ZONE,
    last_successful_sync_at TIMESTAMP WITH TIME ZONE,
    next_scheduled_sync_at TIMESTAMP WITH TIME ZONE,

    -- Sync configuration
    sync_enabled BOOLEAN NOT NULL DEFAULT true,
    sync_interval_minutes INTEGER NOT NULL DEFAULT 120, -- Default: 2 hours
    auto_sync_enabled BOOLEAN NOT NULL DEFAULT true,

    -- Error tracking
    consecutive_failures INTEGER NOT NULL DEFAULT 0,
    last_error_message TEXT,
    last_error_at TIMESTAMP WITH TIME ZONE,

    -- Sync statistics
    total_syncs_completed INTEGER NOT NULL DEFAULT 0,
    total_items_synced INTEGER NOT NULL DEFAULT 0,
    total_conflicts_resolved INTEGER NOT NULL DEFAULT 0,

    -- Performance metrics
    average_sync_duration_ms INTEGER,
    last_sync_duration_ms INTEGER,

    -- Service-specific metadata (API versions, cursor tokens, etc.)
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,

    -- Audit timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Insert default service states
INSERT INTO sync_service_state (service_name, sync_interval_minutes)
VALUES
    ('fatsecret', 120),  -- Sync every 2 hours
    ('tandoor', 240)     -- Sync every 4 hours
ON CONFLICT (service_name) DO NOTHING;

-- ============================================================================
-- 2. Sync Queue Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_queue (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Service association
    service_name TEXT NOT NULL CHECK (service_name IN ('fatsecret', 'tandoor')),

    -- Operation details
    operation_type TEXT NOT NULL CHECK (operation_type IN (
        'fetch', 'push', 'delete', 'update', 'batch_fetch', 'batch_push'
    )),
    entity_type TEXT NOT NULL, -- e.g., 'food_log', 'recipe', 'meal_plan'
    entity_id TEXT, -- External ID (if applicable)

    -- Priority and scheduling
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),

    -- Retry policy
    max_retries INTEGER NOT NULL DEFAULT 3,
    retry_count INTEGER NOT NULL DEFAULT 0,
    retry_backoff_seconds INTEGER NOT NULL DEFAULT 60,

    -- Payload and result
    payload JSONB, -- Operation-specific data
    result JSONB, -- Operation result data
    error_message TEXT,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Dependency tracking (for ordered operations)
    depends_on_queue_id INTEGER REFERENCES sync_queue(id) ON DELETE SET NULL,

    -- Idempotency key (prevent duplicate operations)
    idempotency_key TEXT UNIQUE,

    CONSTRAINT fk_sync_queue_service
        FOREIGN KEY (service_name)
        REFERENCES sync_service_state(service_name)
        ON DELETE CASCADE
);

-- ============================================================================
-- 3. Sync History Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_history (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Service association
    service_name TEXT NOT NULL CHECK (service_name IN ('fatsecret', 'tandoor')),

    -- Sync session tracking
    sync_session_id UUID NOT NULL DEFAULT gen_random_uuid(),

    -- Sync metadata
    sync_type TEXT NOT NULL CHECK (sync_type IN ('manual', 'scheduled', 'retry', 'triggered')),
    trigger_source TEXT, -- What triggered this sync (e.g., 'scheduler', 'user_action', 'webhook')

    -- Timestamps
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Results
    status TEXT NOT NULL CHECK (status IN ('success', 'partial_success', 'failed')),
    items_processed INTEGER NOT NULL DEFAULT 0,
    items_succeeded INTEGER NOT NULL DEFAULT 0,
    items_failed INTEGER NOT NULL DEFAULT 0,
    conflicts_detected INTEGER NOT NULL DEFAULT 0,
    conflicts_resolved INTEGER NOT NULL DEFAULT 0,

    -- Performance
    duration_ms INTEGER,

    -- Details
    error_summary TEXT,
    details JSONB, -- Detailed sync results, error logs, etc.

    CONSTRAINT fk_sync_history_service
        FOREIGN KEY (service_name)
        REFERENCES sync_service_state(service_name)
        ON DELETE CASCADE
);

-- ============================================================================
-- 4. Sync Conflict Log Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_conflict_log (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Service association
    service_name TEXT NOT NULL CHECK (service_name IN ('fatsecret', 'tandoor')),
    sync_history_id INTEGER REFERENCES sync_history(id) ON DELETE SET NULL,

    -- Conflict details
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    conflict_type TEXT NOT NULL CHECK (conflict_type IN (
        'update_conflict', 'delete_conflict', 'duplicate', 'version_mismatch'
    )),

    -- Conflict data
    local_data JSONB NOT NULL,
    remote_data JSONB NOT NULL,
    merged_data JSONB, -- Result of conflict resolution

    -- Resolution
    resolution_strategy TEXT CHECK (resolution_strategy IN (
        'prefer_local', 'prefer_remote', 'manual_merge', 'keep_both', 'skip'
    )),
    resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_at TIMESTAMP WITH TIME ZONE,

    -- Timestamps
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sync_conflict_service
        FOREIGN KEY (service_name)
        REFERENCES sync_service_state(service_name)
        ON DELETE CASCADE
);

-- ============================================================================
-- 5. Indexes for Performance
-- ============================================================================

-- Sync queue indexes
CREATE INDEX IF NOT EXISTS idx_sync_queue_service_status
    ON sync_queue(service_name, status);

CREATE INDEX IF NOT EXISTS idx_sync_queue_scheduled
    ON sync_queue(scheduled_for)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_sync_queue_priority
    ON sync_queue(priority DESC, scheduled_for ASC)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_sync_queue_idempotency
    ON sync_queue(idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_queue_entity
    ON sync_queue(service_name, entity_type, entity_id);

-- Sync history indexes
CREATE INDEX IF NOT EXISTS idx_sync_history_service
    ON sync_history(service_name, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_sync_history_session
    ON sync_history(sync_session_id);

CREATE INDEX IF NOT EXISTS idx_sync_history_status
    ON sync_history(status, started_at DESC);

-- Sync conflict log indexes
CREATE INDEX IF NOT EXISTS idx_sync_conflict_service
    ON sync_conflict_log(service_name, detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_sync_conflict_unresolved
    ON sync_conflict_log(service_name, entity_type)
    WHERE resolved = false;

CREATE INDEX IF NOT EXISTS idx_sync_conflict_entity
    ON sync_conflict_log(service_name, entity_type, entity_id);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_sync_service_metadata
    ON sync_service_state USING GIN (metadata);

CREATE INDEX IF NOT EXISTS idx_sync_queue_payload
    ON sync_queue USING GIN (payload);

CREATE INDEX IF NOT EXISTS idx_sync_queue_result
    ON sync_queue USING GIN (result);

CREATE INDEX IF NOT EXISTS idx_sync_history_details
    ON sync_history USING GIN (details);

-- ============================================================================
-- 6. Triggers for Timestamp Management
-- ============================================================================

-- Update updated_at on sync_service_state
DROP TRIGGER IF EXISTS update_sync_service_state_timestamp ON sync_service_state;
CREATE TRIGGER update_sync_service_state_timestamp
    BEFORE UPDATE ON sync_service_state
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on sync_queue
DROP TRIGGER IF EXISTS update_sync_queue_timestamp ON sync_queue;
CREATE TRIGGER update_sync_queue_timestamp
    BEFORE UPDATE ON sync_queue
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. Helper Functions
-- ============================================================================

-- Function to get next pending queue item for a service
CREATE OR REPLACE FUNCTION get_next_sync_queue_item(service TEXT)
RETURNS INTEGER AS $$
DECLARE
    queue_id INTEGER;
BEGIN
    SELECT id INTO queue_id
    FROM sync_queue
    WHERE service_name = service
      AND status = 'pending'
      AND scheduled_for <= NOW()
      AND (depends_on_queue_id IS NULL OR
           depends_on_queue_id IN (
               SELECT id FROM sync_queue WHERE status = 'completed'
           ))
    ORDER BY
        CASE priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
        END DESC,
        scheduled_for ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Prevent race conditions

    RETURN queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to start sync for a service
CREATE OR REPLACE FUNCTION start_sync(service TEXT)
RETURNS UUID AS $$
DECLARE
    session_id UUID;
BEGIN
    -- Generate session ID
    session_id := gen_random_uuid();

    -- Update service state
    UPDATE sync_service_state
    SET status = 'syncing',
        last_sync_started_at = NOW(),
        updated_at = NOW()
    WHERE service_name = service;

    -- Create history record
    INSERT INTO sync_history (service_name, sync_session_id, sync_type, trigger_source, started_at, status)
    VALUES (service, session_id, 'scheduled', 'system', NOW(), 'success');

    RETURN session_id;
END;
$$ LANGUAGE plpgsql;

-- Function to complete sync for a service
CREATE OR REPLACE FUNCTION complete_sync(
    session_id_param UUID,
    status_param TEXT,
    items_processed_param INTEGER DEFAULT 0,
    items_succeeded_param INTEGER DEFAULT 0,
    items_failed_param INTEGER DEFAULT 0,
    error_summary_param TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    service TEXT;
    start_time TIMESTAMP WITH TIME ZONE;
    duration INTEGER;
BEGIN
    -- Get service name and start time
    SELECT service_name, started_at INTO service, start_time
    FROM sync_history
    WHERE sync_session_id = session_id_param;

    -- Calculate duration
    duration := EXTRACT(EPOCH FROM (NOW() - start_time)) * 1000;

    -- Update history record
    UPDATE sync_history
    SET completed_at = NOW(),
        status = status_param,
        items_processed = items_processed_param,
        items_succeeded = items_succeeded_param,
        items_failed = items_failed_param,
        duration_ms = duration,
        error_summary = error_summary_param
    WHERE sync_session_id = session_id_param;

    -- Update service state
    UPDATE sync_service_state
    SET status = CASE
            WHEN status_param = 'success' THEN 'idle'
            WHEN status_param = 'partial_success' THEN 'idle'
            ELSE 'error'
        END,
        last_sync_completed_at = NOW(),
        last_successful_sync_at = CASE
            WHEN status_param IN ('success', 'partial_success') THEN NOW()
            ELSE last_successful_sync_at
        END,
        next_scheduled_sync_at = NOW() + (sync_interval_minutes || ' minutes')::INTERVAL,
        consecutive_failures = CASE
            WHEN status_param = 'success' THEN 0
            ELSE consecutive_failures + 1
        END,
        last_error_message = error_summary_param,
        last_error_at = CASE
            WHEN status_param = 'failed' THEN NOW()
            ELSE last_error_at
        END,
        total_syncs_completed = total_syncs_completed + 1,
        total_items_synced = total_items_synced + items_succeeded_param,
        last_sync_duration_ms = duration,
        average_sync_duration_ms = CASE
            WHEN average_sync_duration_ms IS NULL THEN duration
            ELSE (average_sync_duration_ms + duration) / 2
        END,
        updated_at = NOW()
    WHERE service_name = service;
END;
$$ LANGUAGE plpgsql;

-- Function to enqueue sync operation
CREATE OR REPLACE FUNCTION enqueue_sync_operation(
    service_param TEXT,
    operation_type_param TEXT,
    entity_type_param TEXT,
    entity_id_param TEXT DEFAULT NULL,
    priority_param TEXT DEFAULT 'medium',
    payload_param JSONB DEFAULT NULL,
    idempotency_key_param TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    queue_id INTEGER;
BEGIN
    -- Check for duplicate via idempotency key
    IF idempotency_key_param IS NOT NULL THEN
        SELECT id INTO queue_id
        FROM sync_queue
        WHERE idempotency_key = idempotency_key_param
          AND status IN ('pending', 'processing');

        IF queue_id IS NOT NULL THEN
            RETURN queue_id; -- Already queued
        END IF;
    END IF;

    -- Insert new queue item
    INSERT INTO sync_queue (
        service_name,
        operation_type,
        entity_type,
        entity_id,
        priority,
        payload,
        idempotency_key
    )
    VALUES (
        service_param,
        operation_type_param,
        entity_type_param,
        entity_id_param,
        priority_param,
        payload_param,
        idempotency_key_param
    )
    RETURNING id INTO queue_id;

    RETURN queue_id;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old sync history
CREATE OR REPLACE FUNCTION cleanup_sync_history(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sync_history
    WHERE started_at < NOW() - (days_to_keep || ' days')::INTERVAL
      AND status IN ('success', 'partial_success');

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get sync service health status
CREATE OR REPLACE FUNCTION get_sync_service_health(service TEXT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'service_name', service_name,
        'status', status,
        'sync_enabled', sync_enabled,
        'auto_sync_enabled', auto_sync_enabled,
        'last_successful_sync_at', last_successful_sync_at,
        'next_scheduled_sync_at', next_scheduled_sync_at,
        'consecutive_failures', consecutive_failures,
        'last_error_message', last_error_message,
        'total_syncs_completed', total_syncs_completed,
        'total_items_synced', total_items_synced,
        'average_sync_duration_ms', average_sync_duration_ms,
        'health_status', CASE
            WHEN NOT sync_enabled THEN 'disabled'
            WHEN consecutive_failures >= 3 THEN 'critical'
            WHEN consecutive_failures >= 1 THEN 'degraded'
            WHEN status = 'error' THEN 'error'
            WHEN status = 'syncing' THEN 'syncing'
            ELSE 'healthy'
        END
    )
    INTO result
    FROM sync_service_state
    WHERE service_name = service;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. Comments on Tables and Columns
-- ============================================================================

COMMENT ON TABLE sync_service_state IS 'Sync state for external services (FatSecret, Tandoor)';
COMMENT ON COLUMN sync_service_state.service_name IS 'Service identifier: fatsecret or tandoor';
COMMENT ON COLUMN sync_service_state.status IS 'Current sync status: idle, syncing, error, paused';
COMMENT ON COLUMN sync_service_state.last_sync_started_at IS 'When the last sync attempt started';
COMMENT ON COLUMN sync_service_state.last_sync_completed_at IS 'When the last sync attempt completed (success or failure)';
COMMENT ON COLUMN sync_service_state.last_successful_sync_at IS 'When the last successful sync completed';
COMMENT ON COLUMN sync_service_state.next_scheduled_sync_at IS 'When the next sync is scheduled';
COMMENT ON COLUMN sync_service_state.sync_enabled IS 'Master toggle for sync functionality';
COMMENT ON COLUMN sync_service_state.sync_interval_minutes IS 'How often to sync (in minutes)';
COMMENT ON COLUMN sync_service_state.auto_sync_enabled IS 'Whether automatic syncs are enabled';
COMMENT ON COLUMN sync_service_state.consecutive_failures IS 'Number of consecutive sync failures';
COMMENT ON COLUMN sync_service_state.metadata IS 'Service-specific metadata (API cursors, versions, etc.)';

COMMENT ON TABLE sync_queue IS 'Queue for pending sync operations (fetch, push, delete, update)';
COMMENT ON COLUMN sync_queue.operation_type IS 'Type of sync operation: fetch, push, delete, update, batch_*';
COMMENT ON COLUMN sync_queue.entity_type IS 'Type of entity being synced (e.g., food_log, recipe)';
COMMENT ON COLUMN sync_queue.entity_id IS 'External ID of the entity (if applicable)';
COMMENT ON COLUMN sync_queue.priority IS 'Operation priority: low, medium, high, critical';
COMMENT ON COLUMN sync_queue.status IS 'Queue item status: pending, processing, completed, failed, cancelled';
COMMENT ON COLUMN sync_queue.idempotency_key IS 'Unique key to prevent duplicate operations';
COMMENT ON COLUMN sync_queue.depends_on_queue_id IS 'ID of queue item this depends on (for ordered operations)';

COMMENT ON TABLE sync_history IS 'Historical record of all sync sessions';
COMMENT ON COLUMN sync_history.sync_session_id IS 'Unique identifier for sync session';
COMMENT ON COLUMN sync_history.sync_type IS 'How sync was triggered: manual, scheduled, retry, triggered';
COMMENT ON COLUMN sync_history.trigger_source IS 'What triggered the sync (scheduler, user, webhook, etc.)';
COMMENT ON COLUMN sync_history.items_processed IS 'Total number of items processed';
COMMENT ON COLUMN sync_history.items_succeeded IS 'Number of items successfully synced';
COMMENT ON COLUMN sync_history.items_failed IS 'Number of items that failed to sync';
COMMENT ON COLUMN sync_history.conflicts_detected IS 'Number of conflicts detected';
COMMENT ON COLUMN sync_history.conflicts_resolved IS 'Number of conflicts resolved';

COMMENT ON TABLE sync_conflict_log IS 'Log of sync conflicts and their resolutions';
COMMENT ON COLUMN sync_conflict_log.conflict_type IS 'Type of conflict: update_conflict, delete_conflict, duplicate, version_mismatch';
COMMENT ON COLUMN sync_conflict_log.local_data IS 'Local version of conflicting data';
COMMENT ON COLUMN sync_conflict_log.remote_data IS 'Remote version of conflicting data';
COMMENT ON COLUMN sync_conflict_log.merged_data IS 'Result of conflict resolution';
COMMENT ON COLUMN sync_conflict_log.resolution_strategy IS 'How conflict was resolved: prefer_local, prefer_remote, manual_merge, keep_both, skip';

-- ============================================================================
-- Data Model Examples
-- ============================================================================
--
-- Example sync_service_state.metadata for FatSecret:
-- {
--   "api_version": "v2",
--   "cursor_token": "abc123xyz",
--   "last_diary_date": "2025-12-20",
--   "rate_limit_remaining": 950,
--   "rate_limit_reset_at": "2025-12-20T15:00:00Z"
-- }
--
-- Example sync_service_state.metadata for Tandoor:
-- {
--   "api_version": "1.5.0",
--   "last_recipe_sync": "2025-12-20T14:00:00Z",
--   "recipe_cursor": 12345,
--   "meal_plan_cursor": 67890
-- }
--
-- Example sync_queue.payload for fetch operation:
-- {
--   "date_range": {
--     "start": "2025-12-01",
--     "end": "2025-12-20"
--   },
--   "filters": {
--     "meal_types": ["breakfast", "lunch", "dinner"]
--   }
-- }
--
-- Example sync_history.details:
-- {
--   "food_logs_fetched": 45,
--   "recipes_updated": 12,
--   "conflicts": [
--     {
--       "entity_id": "recipe_123",
--       "conflict_type": "update_conflict",
--       "resolution": "prefer_remote"
--     }
--   ],
--   "errors": [
--     {
--       "entity_id": "food_log_456",
--       "error": "API rate limit exceeded"
--     }
--   ]
-- }
--
-- ============================================================================
-- Usage Examples
-- ============================================================================
--
-- Check service health:
-- SELECT get_sync_service_health('fatsecret');
--
-- Start a sync session:
-- SELECT start_sync('tandoor');
--
-- Get next queue item:
-- SELECT get_next_sync_queue_item('fatsecret');
--
-- Enqueue a sync operation:
-- SELECT enqueue_sync_operation(
--   'fatsecret',
--   'fetch',
--   'food_log',
--   NULL,
--   'high',
--   '{"date": "2025-12-20"}'::JSONB,
--   'fetch_food_log_2025-12-20'
-- );
--
-- Complete a sync:
-- SELECT complete_sync(
--   '123e4567-e89b-12d3-a456-426614174000'::UUID,
--   'success',
--   50,
--   48,
--   2,
--   NULL
-- );
--
-- Cleanup old history:
-- SELECT cleanup_sync_history(30);
--
-- Find unresolved conflicts:
-- SELECT * FROM sync_conflict_log
-- WHERE service_name = 'fatsecret' AND resolved = false
-- ORDER BY detected_at DESC;
--
-- View sync statistics:
-- SELECT
--   service_name,
--   total_syncs_completed,
--   total_items_synced,
--   total_conflicts_resolved,
--   average_sync_duration_ms,
--   consecutive_failures
-- FROM sync_service_state;
--
-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. idx_sync_queue_service_status: Fast queue polling by service
-- 2. idx_sync_queue_priority: Priority-based queue processing
-- 3. idx_sync_queue_idempotency: Prevent duplicate operations
-- 4. GIN indexes on JSONB: Fast containment queries on metadata/payload
--
-- Concurrency:
-- - get_next_sync_queue_item() uses FOR UPDATE SKIP LOCKED
--   to prevent race conditions when multiple workers poll
--
-- Queue Processing:
-- - Priority order: critical > high > medium > low
-- - Within same priority: FIFO (scheduled_for ASC)
-- - Dependency handling: Only process if depends_on is completed
--
-- Cleanup:
-- - cleanup_sync_history() removes old successful syncs
-- - Keeps failed syncs indefinitely for debugging
-- - Recommended: Run weekly via scheduler
--
-- Health Monitoring:
-- - get_sync_service_health() provides single-query health check
-- - Health status: healthy, syncing, degraded, critical, disabled, error
-- - consecutive_failures threshold: 1 = degraded, 3 = critical
--
-- ============================================================================
