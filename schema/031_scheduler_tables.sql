-- ============================================================================
-- Schema change 031: Scheduler & Automation System
-- ============================================================================
--
-- Creates tables for the scheduler system that handles:
-- - Weekly meal plan generation (Friday 6 AM)
-- - Automatic sync jobs (every 2-4 hours)
-- - Daily advisor emails (8 PM)
-- - Weekly trend analysis (Thursday 8 PM)
--
-- Features:
-- - Database-backed job queue
-- - Manual trigger support
-- - Retry failed jobs with exponential backoff
-- - Execution history tracking
-- - Job dependencies
-- - Priority-based execution
-- ============================================================================

-- ============================================================================
-- 1. Scheduled Jobs Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS scheduled_jobs (
    -- Primary key
    id TEXT PRIMARY KEY,

    -- Job configuration
    job_type TEXT NOT NULL CHECK(job_type IN ('weekly_generation', 'auto_sync', 'daily_advisor', 'weekly_trends')),
    frequency_type TEXT NOT NULL CHECK(frequency_type IN ('weekly', 'daily', 'every_n_hours', 'once')),
    frequency_config JSONB NOT NULL, -- Day/hour/minute for weekly/daily, hours for every_n_hours
    priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high', 'critical')),

    -- User association (NULL for system-wide jobs)
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,

    -- Job parameters (job-specific configuration as JSON)
    parameters JSONB,

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'running', 'completed', 'failed')),

    -- Retry policy
    retry_max_attempts INTEGER NOT NULL DEFAULT 3,
    retry_backoff_seconds INTEGER NOT NULL DEFAULT 60,
    retry_on_failure BOOLEAN NOT NULL DEFAULT true,
    error_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,

    -- Execution timestamps
    scheduled_for TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by TEXT -- User ID or 'system'
);

-- ============================================================================
-- 2. Job Execution History Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS job_executions (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Reference to scheduled job
    job_id TEXT NOT NULL REFERENCES scheduled_jobs(id) ON DELETE CASCADE,

    -- Execution tracking
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL CHECK(status IN ('running', 'completed', 'failed')),

    -- Error handling
    error_message TEXT,
    attempt_number INTEGER NOT NULL DEFAULT 1,

    -- Performance metrics
    duration_ms INTEGER, -- Execution time in milliseconds

    -- Output data (job-specific results as JSON)
    output JSONB,

    -- Trigger source
    trigger_type TEXT NOT NULL CHECK(trigger_type IN ('scheduled', 'manual', 'retry', 'dependent')),
    parent_job_id TEXT REFERENCES scheduled_jobs(id) ON DELETE SET NULL -- For dependent triggers
);

-- ============================================================================
-- 3. Scheduler Configuration Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS scheduler_config (
    -- Single-row configuration (enforced by CHECK constraint)
    id INTEGER PRIMARY KEY CHECK(id = 1),

    -- Global settings
    enabled BOOLEAN NOT NULL DEFAULT true,
    max_concurrent_jobs INTEGER NOT NULL DEFAULT 5,
    check_interval_seconds INTEGER NOT NULL DEFAULT 60,
    timezone TEXT NOT NULL DEFAULT 'UTC',

    -- Default retry policy
    default_retry_max_attempts INTEGER NOT NULL DEFAULT 3,
    default_retry_backoff_seconds INTEGER NOT NULL DEFAULT 60,

    -- Metadata
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Insert default configuration
INSERT INTO scheduler_config (id, enabled, max_concurrent_jobs, check_interval_seconds, timezone)
VALUES (1, true, 5, 60, 'UTC')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 4. Indexes for Performance
-- ============================================================================

-- Index for finding pending jobs by priority
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_status_priority
ON scheduled_jobs(status, priority DESC, scheduled_for ASC)
WHERE enabled = true;

-- Index for user-specific jobs
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_user_id
ON scheduled_jobs(user_id)
WHERE user_id IS NOT NULL;

-- Index for job type queries
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_type
ON scheduled_jobs(job_type);

-- Index for finding jobs to schedule
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_scheduled_for
ON scheduled_jobs(scheduled_for)
WHERE status = 'pending' AND enabled = true;

-- Index for execution history by job
CREATE INDEX IF NOT EXISTS idx_job_executions_job_id
ON job_executions(job_id, started_at DESC);

-- Index for recent executions
CREATE INDEX IF NOT EXISTS idx_job_executions_started_at
ON job_executions(started_at DESC);

-- Index for failed executions
CREATE INDEX IF NOT EXISTS idx_job_executions_status
ON job_executions(status, started_at DESC);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_parameters
ON scheduled_jobs USING GIN (parameters);

CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_frequency_config
ON scheduled_jobs USING GIN (frequency_config);

CREATE INDEX IF NOT EXISTS idx_job_executions_output
ON job_executions USING GIN (output);

-- ============================================================================
-- 5. Triggers for Timestamp Management
-- ============================================================================

-- Update updated_at on scheduled_jobs
DROP TRIGGER IF EXISTS update_scheduled_jobs_timestamp ON scheduled_jobs;
CREATE TRIGGER update_scheduled_jobs_timestamp
    BEFORE UPDATE ON scheduled_jobs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Update updated_at on scheduler_config
DROP TRIGGER IF EXISTS update_scheduler_config_timestamp ON scheduler_config;
CREATE TRIGGER update_scheduler_config_timestamp
    BEFORE UPDATE ON scheduler_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. Helper Functions
-- ============================================================================

-- Function to get next pending job
CREATE OR REPLACE FUNCTION get_next_pending_job()
RETURNS TEXT AS $$
DECLARE
    next_job_id TEXT;
BEGIN
    SELECT id INTO next_job_id
    FROM scheduled_jobs
    WHERE status = 'pending'
      AND enabled = true
      AND (scheduled_for IS NULL OR scheduled_for <= NOW())
    ORDER BY
        CASE priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
        END DESC,
        scheduled_for ASC NULLS FIRST
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Prevent race conditions

    RETURN next_job_id;
END;
$$ LANGUAGE plpgsql;

-- Function to mark job as running
CREATE OR REPLACE FUNCTION start_job(job_id_param TEXT, trigger_type_param TEXT DEFAULT 'scheduled')
RETURNS INTEGER AS $$
DECLARE
    execution_id INTEGER;
    current_error_count INTEGER;
BEGIN
    -- Get current error count
    SELECT error_count INTO current_error_count
    FROM scheduled_jobs
    WHERE id = job_id_param;

    -- Update job status
    UPDATE scheduled_jobs
    SET status = 'running',
        started_at = NOW(),
        updated_at = NOW()
    WHERE id = job_id_param;

    -- Create execution record
    INSERT INTO job_executions (job_id, started_at, status, attempt_number, trigger_type)
    VALUES (job_id_param, NOW(), 'running', current_error_count + 1, trigger_type_param)
    RETURNING id INTO execution_id;

    RETURN execution_id;
END;
$$ LANGUAGE plpgsql;

-- Function to mark job as completed
CREATE OR REPLACE FUNCTION complete_job(
    job_id_param TEXT,
    execution_id_param INTEGER,
    output_param JSONB DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE;
    duration INTEGER;
BEGIN
    -- Get start time
    SELECT started_at INTO start_time
    FROM job_executions
    WHERE id = execution_id_param;

    -- Calculate duration in milliseconds
    duration := EXTRACT(EPOCH FROM (NOW() - start_time)) * 1000;

    -- Update job status
    UPDATE scheduled_jobs
    SET status = 'completed',
        completed_at = NOW(),
        error_count = 0,
        last_error = NULL,
        updated_at = NOW()
    WHERE id = job_id_param;

    -- Update execution record
    UPDATE job_executions
    SET status = 'completed',
        completed_at = NOW(),
        duration_ms = duration,
        output = output_param
    WHERE id = execution_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to mark job as failed
CREATE OR REPLACE FUNCTION fail_job(
    job_id_param TEXT,
    execution_id_param INTEGER,
    error_message_param TEXT
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE;
    duration INTEGER;
    current_error_count INTEGER;
    max_attempts INTEGER;
    should_retry BOOLEAN;
BEGIN
    -- Get start time
    SELECT started_at INTO start_time
    FROM job_executions
    WHERE id = execution_id_param;

    -- Calculate duration in milliseconds
    duration := EXTRACT(EPOCH FROM (NOW() - start_time)) * 1000;

    -- Get retry policy
    SELECT error_count + 1, retry_max_attempts, retry_on_failure
    INTO current_error_count, max_attempts, should_retry
    FROM scheduled_jobs
    WHERE id = job_id_param;

    -- Update job status
    UPDATE scheduled_jobs
    SET status = CASE
            WHEN should_retry AND current_error_count < max_attempts THEN 'pending'
            ELSE 'failed'
        END,
        error_count = current_error_count,
        last_error = error_message_param,
        completed_at = NOW(),
        -- Schedule retry with exponential backoff if applicable
        scheduled_for = CASE
            WHEN should_retry AND current_error_count < max_attempts
            THEN NOW() + (retry_backoff_seconds * POWER(2, current_error_count - 1) || ' seconds')::INTERVAL
            ELSE scheduled_for
        END,
        updated_at = NOW()
    WHERE id = job_id_param;

    -- Update execution record
    UPDATE job_executions
    SET status = 'failed',
        completed_at = NOW(),
        duration_ms = duration,
        error_message = error_message_param
    WHERE id = execution_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate next scheduled time for recurring jobs
CREATE OR REPLACE FUNCTION calculate_next_schedule(
    frequency_type_param TEXT,
    frequency_config_param JSONB,
    from_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
    next_time TIMESTAMP WITH TIME ZONE;
    target_day INTEGER;
    target_hour INTEGER;
    target_minute INTEGER;
    hours_interval INTEGER;
BEGIN
    CASE frequency_type_param
        WHEN 'weekly' THEN
            target_day := (frequency_config_param->>'day')::INTEGER;
            target_hour := (frequency_config_param->>'hour')::INTEGER;
            target_minute := (frequency_config_param->>'minute')::INTEGER;

            -- Calculate next occurrence of day/time
            next_time := date_trunc('week', from_time)
                + ((target_day - 1) || ' days')::INTERVAL
                + (target_hour || ' hours')::INTERVAL
                + (target_minute || ' minutes')::INTERVAL;

            -- If calculated time is in the past, add one week
            IF next_time <= from_time THEN
                next_time := next_time + INTERVAL '1 week';
            END IF;

        WHEN 'daily' THEN
            target_hour := (frequency_config_param->>'hour')::INTEGER;
            target_minute := (frequency_config_param->>'minute')::INTEGER;

            next_time := date_trunc('day', from_time)
                + (target_hour || ' hours')::INTERVAL
                + (target_minute || ' minutes')::INTERVAL;

            -- If calculated time is in the past, add one day
            IF next_time <= from_time THEN
                next_time := next_time + INTERVAL '1 day';
            END IF;

        WHEN 'every_n_hours' THEN
            hours_interval := (frequency_config_param->>'hours')::INTEGER;
            next_time := from_time + (hours_interval || ' hours')::INTERVAL;

        WHEN 'once' THEN
            next_time := NULL; -- One-time jobs don't reschedule

        ELSE
            RAISE EXCEPTION 'Unknown frequency type: %', frequency_type_param;
    END CASE;

    RETURN next_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. Comments on Tables and Columns
-- ============================================================================

COMMENT ON TABLE scheduled_jobs IS 'Scheduled jobs for automated tasks (meal generation, sync, emails, analytics)';
COMMENT ON COLUMN scheduled_jobs.id IS 'Unique job identifier (e.g., job_weekly_gen_001)';
COMMENT ON COLUMN scheduled_jobs.job_type IS 'Type of job: weekly_generation, auto_sync, daily_advisor, weekly_trends';
COMMENT ON COLUMN scheduled_jobs.frequency_type IS 'Schedule type: weekly, daily, every_n_hours, once';
COMMENT ON COLUMN scheduled_jobs.frequency_config IS 'JSON config for schedule (day/hour/minute or hours)';
COMMENT ON COLUMN scheduled_jobs.priority IS 'Execution priority: low, medium, high, critical';
COMMENT ON COLUMN scheduled_jobs.user_id IS 'User ID for user-specific jobs (NULL for system-wide)';
COMMENT ON COLUMN scheduled_jobs.parameters IS 'Job-specific configuration as JSON';
COMMENT ON COLUMN scheduled_jobs.status IS 'Current job status: pending, running, completed, failed';
COMMENT ON COLUMN scheduled_jobs.retry_max_attempts IS 'Maximum retry attempts on failure';
COMMENT ON COLUMN scheduled_jobs.retry_backoff_seconds IS 'Base seconds to wait between retries (exponential)';
COMMENT ON COLUMN scheduled_jobs.retry_on_failure IS 'Whether to retry failed jobs';
COMMENT ON COLUMN scheduled_jobs.error_count IS 'Number of consecutive failures';
COMMENT ON COLUMN scheduled_jobs.last_error IS 'Last error message from failed execution';
COMMENT ON COLUMN scheduled_jobs.scheduled_for IS 'Next scheduled execution time';
COMMENT ON COLUMN scheduled_jobs.started_at IS 'When job execution started';
COMMENT ON COLUMN scheduled_jobs.completed_at IS 'When job execution completed';
COMMENT ON COLUMN scheduled_jobs.enabled IS 'Whether job is enabled (master switch)';

COMMENT ON TABLE job_executions IS 'Execution history for all scheduled jobs';
COMMENT ON COLUMN job_executions.id IS 'Auto-incrementing execution ID';
COMMENT ON COLUMN job_executions.job_id IS 'Reference to scheduled job';
COMMENT ON COLUMN job_executions.started_at IS 'Execution start timestamp';
COMMENT ON COLUMN job_executions.completed_at IS 'Execution completion timestamp';
COMMENT ON COLUMN job_executions.status IS 'Execution status: running, completed, failed';
COMMENT ON COLUMN job_executions.error_message IS 'Error message if execution failed';
COMMENT ON COLUMN job_executions.attempt_number IS 'Attempt number (1-indexed, increments on retry)';
COMMENT ON COLUMN job_executions.duration_ms IS 'Execution duration in milliseconds';
COMMENT ON COLUMN job_executions.output IS 'Job output/result data as JSON';
COMMENT ON COLUMN job_executions.trigger_type IS 'How job was triggered: scheduled, manual, retry, dependent';
COMMENT ON COLUMN job_executions.parent_job_id IS 'Parent job ID for dependent triggers';

COMMENT ON TABLE scheduler_config IS 'Global scheduler configuration (single row)';
COMMENT ON COLUMN scheduler_config.enabled IS 'Master kill switch for entire scheduler';
COMMENT ON COLUMN scheduler_config.max_concurrent_jobs IS 'Maximum concurrent job executions';
COMMENT ON COLUMN scheduler_config.check_interval_seconds IS 'How often to check for pending jobs';
COMMENT ON COLUMN scheduler_config.timezone IS 'Timezone for schedule calculations (e.g., America/Chicago)';

-- ============================================================================
-- Performance Notes
-- ============================================================================
--
-- Index Strategy:
-- 1. idx_scheduled_jobs_status_priority: Optimizes job queue polling
--    - Filters enabled jobs by status
--    - Sorts by priority DESC, scheduled_for ASC
--    - Partial index (enabled = true) reduces index size
--
-- 2. idx_scheduled_jobs_user_id: User-specific job queries
--    - Supports: SELECT * FROM scheduled_jobs WHERE user_id = ?
--    - Partial index (user_id IS NOT NULL) excludes system jobs
--
-- 3. idx_job_executions_job_id: Execution history per job
--    - Supports: SELECT * FROM job_executions WHERE job_id = ? ORDER BY started_at DESC
--
-- 4. GIN indexes on JSONB: Fast containment queries
--    - Supports: WHERE parameters @> '{"sync_type": "fatsecret"}'
--
-- Concurrency:
-- - get_next_pending_job() uses FOR UPDATE SKIP LOCKED
--   to prevent race conditions when multiple workers poll
--
-- Retry Logic:
-- - Exponential backoff: base_seconds * 2^(error_count - 1)
-- - Example: 60s, 120s, 240s, 480s for backoff_seconds=60
--
-- ============================================================================
