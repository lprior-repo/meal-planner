-- ============================================================================
-- Migration 001: Initial Schema for Generation Engine and Scheduler
-- ============================================================================
--
-- This migration establishes the foundational database schema for the
-- automated meal planning system, including:
--
-- 1. Scheduled Jobs System (weekly generation, sync jobs, email triggers)
-- 2. Job Execution History (tracking, retry logic, performance metrics)
-- 3. Scheduler Configuration (global settings, timezone, concurrency)
-- 4. Recipe Rotation Enforcement (30-day rule for meal variety)
--
-- Dependencies:
-- - Requires existing users table (from 003_app_tables.sql)
-- - Requires existing auto_meal_plans table (from 009_auto_meal_planner.sql)
-- - Requires update_updated_at_column() function (from 009_auto_meal_planner.sql)
--
-- Migration Order:
-- - Run AFTER: 030_fatsecret_oauth.sql
-- - Run BEFORE: Any generation engine application code deployment
--
-- ============================================================================

-- ============================================================================
-- TABLE 1: scheduled_jobs
-- ============================================================================
--
-- Core job scheduling table that manages all automated tasks:
-- - weekly_generation: Friday 6 AM meal plan generation
-- - auto_sync: Every 2-4 hours sync with Tandoor/FatSecret
-- - daily_advisor: 8 PM nutritional guidance emails
-- - weekly_trends: Thursday 8 PM trend analysis
--
-- Features:
-- - Priority-based execution (critical > high > medium > low)
-- - Exponential backoff retry logic
-- - User-specific and system-wide job support
-- - Flexible frequency configuration (weekly, daily, every_n_hours, once)
--
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

-- ============================================================================
-- TABLE 2: job_executions
-- ============================================================================
--
-- Execution history and audit trail for all scheduled jobs.
-- Tracks performance metrics, errors, and retry attempts.
--
-- Key metrics:
-- - Duration (milliseconds) for performance monitoring
-- - Attempt number for retry analysis
-- - Output (JSONB) for job-specific results
--
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

-- ============================================================================
-- TABLE 3: scheduler_config
-- ============================================================================
--
-- Global scheduler configuration (singleton table).
-- Controls scheduler behavior, concurrency limits, and timezone settings.
--
-- Single-row enforcement via CHECK constraint (id = 1).
--
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

COMMENT ON TABLE scheduler_config IS 'Global scheduler configuration (single row)';
COMMENT ON COLUMN scheduler_config.enabled IS 'Master kill switch for entire scheduler';
COMMENT ON COLUMN scheduler_config.max_concurrent_jobs IS 'Maximum concurrent job executions';
COMMENT ON COLUMN scheduler_config.check_interval_seconds IS 'How often to check for pending jobs';
COMMENT ON COLUMN scheduler_config.timezone IS 'Timezone for schedule calculations (e.g., America/Chicago)';

-- Insert default configuration
INSERT INTO scheduler_config (id, enabled, max_concurrent_jobs, check_interval_seconds, timezone)
VALUES (1, true, 5, 60, 'UTC')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- TABLE 4: recipe_rotation
-- ============================================================================
--
-- Enforces 30-day rotation rule for meal variety.
-- Tracks when each recipe was last used per user and meal type.
--
-- Business Logic:
-- - Track recipe usage by user, meal type (breakfast/lunch/dinner/snack)
-- - Prevent recipe reuse within 30 days for same meal type
-- - Enable "cooldown period" queries for generation engine
--
-- Example query:
--   SELECT recipe_id FROM recipe_rotation
--   WHERE user_id = ? AND meal_type = 'dinner'
--   AND last_used_date > NOW() - INTERVAL '30 days';
--
CREATE TABLE IF NOT EXISTS recipe_rotation (
    -- Primary key (composite ensures one record per user/recipe/meal_type)
    id BIGSERIAL PRIMARY KEY,

    -- User and recipe association
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,

    -- Meal type classification
    meal_type TEXT NOT NULL CHECK(meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),

    -- Rotation tracking
    last_used_date DATE NOT NULL,
    use_count INTEGER NOT NULL DEFAULT 1,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Uniqueness constraint
    UNIQUE(user_id, recipe_id, meal_type)
);

COMMENT ON TABLE recipe_rotation IS 'Tracks recipe usage for 30-day rotation enforcement';
COMMENT ON COLUMN recipe_rotation.user_id IS 'User who consumed the recipe';
COMMENT ON COLUMN recipe_rotation.recipe_id IS 'Tandoor recipe ID';
COMMENT ON COLUMN recipe_rotation.meal_type IS 'Meal classification: breakfast, lunch, dinner, snack';
COMMENT ON COLUMN recipe_rotation.last_used_date IS 'Most recent date recipe was used for this meal type';
COMMENT ON COLUMN recipe_rotation.use_count IS 'Total number of times recipe used for this meal type';

-- ============================================================================
-- INDEXES: Performance Optimization
-- ============================================================================

-- Indexes for scheduled_jobs
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_status_priority
ON scheduled_jobs(status, priority DESC, scheduled_for ASC)
WHERE enabled = true;

CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_user_id
ON scheduled_jobs(user_id)
WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_type
ON scheduled_jobs(job_type);

CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_scheduled_for
ON scheduled_jobs(scheduled_for)
WHERE status = 'pending' AND enabled = true;

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_parameters
ON scheduled_jobs USING GIN (parameters);

CREATE INDEX IF NOT EXISTS idx_scheduled_jobs_frequency_config
ON scheduled_jobs USING GIN (frequency_config);

-- Indexes for job_executions
CREATE INDEX IF NOT EXISTS idx_job_executions_job_id
ON job_executions(job_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_executions_started_at
ON job_executions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_executions_status
ON job_executions(status, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_executions_output
ON job_executions USING GIN (output);

-- Indexes for recipe_rotation
CREATE INDEX IF NOT EXISTS idx_recipe_rotation_user_meal
ON recipe_rotation(user_id, meal_type, last_used_date DESC);

CREATE INDEX IF NOT EXISTS idx_recipe_rotation_user_recipe
ON recipe_rotation(user_id, recipe_id);

CREATE INDEX IF NOT EXISTS idx_recipe_rotation_last_used
ON recipe_rotation(last_used_date)
WHERE last_used_date > NOW() - INTERVAL '30 days';

-- ============================================================================
-- TRIGGERS: Timestamp Management
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

-- Update updated_at on recipe_rotation
DROP TRIGGER IF EXISTS update_recipe_rotation_timestamp ON recipe_rotation;
CREATE TRIGGER update_recipe_rotation_timestamp
    BEFORE UPDATE ON recipe_rotation
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- HELPER FUNCTIONS
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

COMMENT ON FUNCTION get_next_pending_job IS 'Atomically get next pending job with FOR UPDATE SKIP LOCKED';

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

COMMENT ON FUNCTION start_job IS 'Mark job as running and create execution record';

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

COMMENT ON FUNCTION complete_job IS 'Mark job as completed with performance metrics';

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

COMMENT ON FUNCTION fail_job IS 'Mark job as failed with exponential backoff retry';

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

COMMENT ON FUNCTION calculate_next_schedule IS 'Calculate next scheduled time for recurring jobs';

-- Function to update recipe rotation on meal plan generation
CREATE OR REPLACE FUNCTION update_recipe_rotation(
    user_id_param TEXT,
    recipe_id_param TEXT,
    meal_type_param TEXT,
    used_date_param DATE DEFAULT CURRENT_DATE
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO recipe_rotation (user_id, recipe_id, meal_type, last_used_date, use_count)
    VALUES (user_id_param, recipe_id_param, meal_type_param, used_date_param, 1)
    ON CONFLICT (user_id, recipe_id, meal_type)
    DO UPDATE SET
        last_used_date = EXCLUDED.last_used_date,
        use_count = recipe_rotation.use_count + 1,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_recipe_rotation IS 'Update or insert recipe rotation record';

-- Function to get recipes on cooldown (within 30 days)
CREATE OR REPLACE FUNCTION get_recipes_on_cooldown(
    user_id_param TEXT,
    meal_type_param TEXT,
    cooldown_days INTEGER DEFAULT 30
)
RETURNS TABLE(recipe_id TEXT, last_used_date DATE, days_since_use INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT
        rr.recipe_id,
        rr.last_used_date,
        (CURRENT_DATE - rr.last_used_date)::INTEGER AS days_since_use
    FROM recipe_rotation rr
    WHERE rr.user_id = user_id_param
      AND rr.meal_type = meal_type_param
      AND rr.last_used_date > CURRENT_DATE - (cooldown_days || ' days')::INTERVAL
    ORDER BY rr.last_used_date DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_recipes_on_cooldown IS 'Get recipes that are within cooldown period (default 30 days)';

-- ============================================================================
-- MIGRATION VALIDATION
-- ============================================================================

DO $$
DECLARE
    tables_count INTEGER;
    indexes_count INTEGER;
    functions_count INTEGER;
BEGIN
    -- Count created tables
    SELECT COUNT(*) INTO tables_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('scheduled_jobs', 'job_executions', 'scheduler_config', 'recipe_rotation');

    -- Count created indexes
    SELECT COUNT(*) INTO indexes_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname LIKE 'idx_%'
      AND tablename IN ('scheduled_jobs', 'job_executions', 'recipe_rotation');

    -- Count created functions
    SELECT COUNT(*) INTO functions_count
    FROM pg_proc
    WHERE proname IN ('get_next_pending_job', 'start_job', 'complete_job', 'fail_job',
                      'calculate_next_schedule', 'update_recipe_rotation', 'get_recipes_on_cooldown');

    -- Validation report
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 001: Validation Report';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables created: % (expected: 4)', tables_count;
    RAISE NOTICE 'Indexes created: % (expected: 13+)', indexes_count;
    RAISE NOTICE 'Functions created: % (expected: 7)', functions_count;
    RAISE NOTICE '========================================';

    -- Fail if validation doesn't pass
    IF tables_count < 4 THEN
        RAISE EXCEPTION 'Migration validation failed: Expected 4 tables, found %', tables_count;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- END OF MIGRATION 001
-- ============================================================================
