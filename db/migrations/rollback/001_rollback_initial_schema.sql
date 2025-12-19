-- ============================================================================
-- Rollback Script for Migration 001: Initial Schema
-- ============================================================================
--
-- This script completely reverses migration 001, removing all tables,
-- indexes, and functions created for the Generation Engine and Scheduler.
--
-- WARNING: This is a DESTRUCTIVE operation. All data in the following tables
-- will be permanently deleted:
-- - scheduled_jobs
-- - job_executions
-- - scheduler_config
-- - recipe_rotation
--
-- PREREQUISITES:
-- 1. Backup database before running this script
-- 2. Stop scheduler executor to prevent new jobs from being created
-- 3. Verify no active jobs are running
--
-- ============================================================================

BEGIN;

-- ============================================================================
-- Step 1: Stop Scheduler (Prevent New Jobs)
-- ============================================================================

UPDATE scheduler_config SET enabled = false WHERE id = 1;

RAISE NOTICE 'Scheduler disabled. Waiting 5 seconds for running jobs...';
SELECT pg_sleep(5);

-- ============================================================================
-- Step 2: Verify No Running Jobs
-- ============================================================================

DO $$
DECLARE
    running_jobs_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO running_jobs_count
    FROM scheduled_jobs
    WHERE status = 'running';

    IF running_jobs_count > 0 THEN
        RAISE WARNING 'WARNING: % jobs are still running. Consider waiting or aborting.', running_jobs_count;
        RAISE NOTICE 'Running jobs:';
        FOR r IN (SELECT id, job_type, started_at FROM scheduled_jobs WHERE status = 'running') LOOP
            RAISE NOTICE '  - Job ID: %, Type: %, Started: %', r.id, r.job_type, r.started_at;
        END LOOP;
    ELSE
        RAISE NOTICE 'No running jobs detected. Safe to proceed.';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Step 3: Backup Data (Optional)
-- ============================================================================

-- Create backup tables (commented out by default)
-- Uncomment if you want to preserve data before rollback

-- CREATE TABLE scheduled_jobs_backup AS SELECT * FROM scheduled_jobs;
-- CREATE TABLE job_executions_backup AS SELECT * FROM job_executions;
-- CREATE TABLE scheduler_config_backup AS SELECT * FROM scheduler_config;
-- CREATE TABLE recipe_rotation_backup AS SELECT * FROM recipe_rotation;

-- RAISE NOTICE 'Data backed up to *_backup tables';

-- ============================================================================
-- Step 4: Drop Helper Functions
-- ============================================================================

RAISE NOTICE 'Dropping helper functions...';

DROP FUNCTION IF EXISTS get_recipes_on_cooldown(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS update_recipe_rotation(TEXT, TEXT, TEXT, DATE);
DROP FUNCTION IF EXISTS calculate_next_schedule(TEXT, JSONB, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS fail_job(TEXT, INTEGER, TEXT);
DROP FUNCTION IF EXISTS complete_job(TEXT, INTEGER, JSONB);
DROP FUNCTION IF EXISTS start_job(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_next_pending_job();

RAISE NOTICE 'Functions dropped.';

-- ============================================================================
-- Step 5: Drop Tables (CASCADE removes dependent objects)
-- ============================================================================

RAISE NOTICE 'Dropping tables...';

-- Drop in dependency order (child tables first)
DROP TABLE IF EXISTS recipe_rotation CASCADE;
DROP TABLE IF EXISTS job_executions CASCADE;
DROP TABLE IF EXISTS scheduler_config CASCADE;
DROP TABLE IF EXISTS scheduled_jobs CASCADE;

RAISE NOTICE 'Tables dropped.';

-- ============================================================================
-- Step 6: Verify Rollback Success
-- ============================================================================

DO $$
DECLARE
    remaining_tables INTEGER;
    remaining_functions INTEGER;
BEGIN
    -- Count remaining tables
    SELECT COUNT(*) INTO remaining_tables
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('scheduled_jobs', 'job_executions', 'scheduler_config', 'recipe_rotation');

    -- Count remaining functions
    SELECT COUNT(*) INTO remaining_functions
    FROM pg_proc
    WHERE proname IN ('get_next_pending_job', 'start_job', 'complete_job', 'fail_job',
                      'calculate_next_schedule', 'update_recipe_rotation', 'get_recipes_on_cooldown');

    -- Validation report
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Rollback Validation Report';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables remaining: % (expected: 0)', remaining_tables;
    RAISE NOTICE 'Functions remaining: % (expected: 0)', remaining_functions;
    RAISE NOTICE '========================================';

    IF remaining_tables > 0 THEN
        RAISE WARNING 'Rollback incomplete: % tables still exist', remaining_tables;
    END IF;

    IF remaining_functions > 0 THEN
        RAISE WARNING 'Rollback incomplete: % functions still exist', remaining_functions;
    END IF;

    IF remaining_tables = 0 AND remaining_functions = 0 THEN
        RAISE NOTICE 'Rollback successful. All migration 001 objects removed.';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Step 7: Commit or Rollback
-- ============================================================================

-- Manual decision point
-- If validation passed, run: COMMIT;
-- If validation failed, run: ROLLBACK;

RAISE NOTICE '';
RAISE NOTICE 'Rollback script complete. Review validation report above.';
RAISE NOTICE 'To finalize, run: COMMIT';
RAISE NOTICE 'To abort, run: ROLLBACK';

-- Automatic commit (comment out if you want manual control)
COMMIT;

-- ============================================================================
-- END OF ROLLBACK SCRIPT
-- ============================================================================
