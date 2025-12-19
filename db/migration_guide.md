# Database Migration Guide

## Overview

This guide documents the database migration strategy for the Generation Engine and Scheduler system in the meal-planner application.

**Migration File:** `db/migrations/001_initial_schema.sql`

**Status:** Phase 3 - Database Infrastructure

**Purpose:** Establish foundational schema for automated meal plan generation, job scheduling, and recipe rotation enforcement.

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Migration Dependencies](#migration-dependencies)
3. [Migration Order](#migration-order)
4. [Rollback Procedure](#rollback-procedure)
5. [Testing Strategy](#testing-strategy)
6. [Production Deployment Checklist](#production-deployment-checklist)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting](#troubleshooting)

---

## Schema Overview

### Tables Created

#### 1. `scheduled_jobs`
**Purpose:** Core job scheduling table for all automated tasks.

**Key Features:**
- Priority-based execution (critical → high → medium → low)
- Flexible frequency types (weekly, daily, every_n_hours, once)
- User-specific and system-wide job support
- Exponential backoff retry logic
- JSONB configuration for job parameters

**Job Types:**
- `weekly_generation` - Friday 6 AM meal plan generation
- `auto_sync` - Every 2-4 hours sync with Tandoor/FatSecret
- `daily_advisor` - 8 PM nutritional guidance emails
- `weekly_trends` - Thursday 8 PM trend analysis

**Indexes:**
- `idx_scheduled_jobs_status_priority` - Optimizes job queue polling (partial index)
- `idx_scheduled_jobs_user_id` - User-specific job queries (partial index)
- `idx_scheduled_jobs_type` - Filter by job type
- `idx_scheduled_jobs_scheduled_for` - Find jobs ready to execute
- `idx_scheduled_jobs_parameters` - GIN index for JSONB queries
- `idx_scheduled_jobs_frequency_config` - GIN index for schedule queries

**Foreign Keys:**
- `user_id → users(id)` ON DELETE CASCADE

---

#### 2. `job_executions`
**Purpose:** Execution history and audit trail for all scheduled jobs.

**Key Features:**
- Performance metrics (duration_ms)
- Retry attempt tracking
- JSONB output storage
- Trigger type classification (scheduled, manual, retry, dependent)
- Parent job tracking for dependent triggers

**Indexes:**
- `idx_job_executions_job_id` - Execution history per job
- `idx_job_executions_started_at` - Recent executions query
- `idx_job_executions_status` - Failed/completed execution analysis
- `idx_job_executions_output` - GIN index for JSONB output queries

**Foreign Keys:**
- `job_id → scheduled_jobs(id)` ON DELETE CASCADE
- `parent_job_id → scheduled_jobs(id)` ON DELETE SET NULL

---

#### 3. `scheduler_config`
**Purpose:** Global scheduler configuration (singleton table).

**Key Features:**
- Single-row enforcement via CHECK(id = 1)
- Master kill switch (enabled)
- Concurrency limits (max_concurrent_jobs)
- Timezone support for schedule calculations
- Default retry policy configuration

**Default Values:**
```sql
enabled = true
max_concurrent_jobs = 5
check_interval_seconds = 60
timezone = 'UTC'
default_retry_max_attempts = 3
default_retry_backoff_seconds = 60
```

---

#### 4. `recipe_rotation`
**Purpose:** Enforces 30-day rotation rule for meal variety.

**Key Features:**
- Tracks recipe usage by user, meal type, and date
- Prevents recipe reuse within configurable cooldown period
- Use count statistics
- Composite uniqueness constraint (user_id, recipe_id, meal_type)

**Meal Types:**
- `breakfast`
- `lunch`
- `dinner`
- `snack`

**Indexes:**
- `idx_recipe_rotation_user_meal` - Cooldown queries by user and meal type
- `idx_recipe_rotation_user_recipe` - Recipe usage history per user
- `idx_recipe_rotation_last_used` - Partial index for recent usage (30 days)

**Foreign Keys:**
- `user_id → users(id)` ON DELETE CASCADE

---

### Helper Functions

#### `get_next_pending_job()`
**Returns:** `TEXT` (job_id)

**Purpose:** Atomically fetch next pending job with priority ordering.

**Concurrency:** Uses `FOR UPDATE SKIP LOCKED` to prevent race conditions.

**Query Logic:**
1. Filter: `status = 'pending'`, `enabled = true`, `scheduled_for <= NOW()`
2. Order: Priority DESC, scheduled_for ASC
3. Lock: FOR UPDATE SKIP LOCKED (prevents duplicate processing)

---

#### `start_job(job_id, trigger_type)`
**Returns:** `INTEGER` (execution_id)

**Purpose:** Mark job as running and create execution record.

**Side Effects:**
- Updates `scheduled_jobs.status = 'running'`
- Sets `scheduled_jobs.started_at`
- Inserts `job_executions` record with attempt_number

---

#### `complete_job(job_id, execution_id, output)`
**Returns:** `VOID`

**Purpose:** Mark job as completed with performance metrics.

**Side Effects:**
- Updates `scheduled_jobs.status = 'completed'`
- Resets `error_count = 0`, clears `last_error`
- Calculates `duration_ms` and stores in `job_executions`
- Stores optional JSONB output

---

#### `fail_job(job_id, execution_id, error_message)`
**Returns:** `VOID`

**Purpose:** Mark job as failed with exponential backoff retry.

**Retry Logic:**
- If `retry_on_failure = true` and `error_count < retry_max_attempts`:
  - Status → `pending`
  - Schedule next attempt: `NOW() + (retry_backoff_seconds * 2^(error_count - 1))`
- Else:
  - Status → `failed`

**Backoff Example:** (base = 60s)
- Attempt 1 fails → retry in 60s
- Attempt 2 fails → retry in 120s
- Attempt 3 fails → retry in 240s

---

#### `calculate_next_schedule(frequency_type, frequency_config, from_time)`
**Returns:** `TIMESTAMP WITH TIME ZONE`

**Purpose:** Calculate next scheduled time for recurring jobs.

**Supported Frequencies:**
- `weekly`: `{day: 5, hour: 6, minute: 0}` → Every Friday at 6:00 AM
- `daily`: `{hour: 20, minute: 0}` → Every day at 8:00 PM
- `every_n_hours`: `{hours: 2}` → Every 2 hours
- `once`: Returns NULL (one-time execution)

---

#### `update_recipe_rotation(user_id, recipe_id, meal_type, used_date)`
**Returns:** `VOID`

**Purpose:** Upsert recipe rotation record on meal plan generation.

**Logic:**
- If record exists: Update `last_used_date`, increment `use_count`
- If new: Insert with `use_count = 1`

---

#### `get_recipes_on_cooldown(user_id, meal_type, cooldown_days)`
**Returns:** `TABLE(recipe_id TEXT, last_used_date DATE, days_since_use INTEGER)`

**Purpose:** Query recipes within cooldown period for generation engine.

**Use Case:**
```gleam
// Filter out recipes on cooldown when generating meal plan
let cooldown_recipes = get_recipes_on_cooldown(user_id, "dinner", 30)
let available_recipes = all_recipes
  |> list.filter(fn(r) { !list.contains(cooldown_recipes, r.id) })
```

---

## Migration Dependencies

### Prerequisites

The migration requires these existing database objects:

#### 1. **users table** (from `003_app_tables.sql`)
Foreign key constraint: `scheduled_jobs.user_id → users.id`

**Required Columns:**
- `id TEXT PRIMARY KEY`

#### 2. **auto_meal_plans table** (from `009_auto_meal_planner.sql`)
Used by generation engine to store created meal plans.

**Required Columns:**
- `id SERIAL PRIMARY KEY`
- `user_id INTEGER NOT NULL`
- `generated_at TIMESTAMP`
- `diet_principles JSONB`
- `recipe_ids JSONB`
- `macro_targets JSONB`
- `status TEXT`

#### 3. **update_updated_at_column() function** (from `009_auto_meal_planner.sql`)
Trigger function for automatic timestamp updates.

**Function Signature:**
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Migration Chain

```
001_schema_migrations.sql
    ↓
003_app_tables.sql (creates users table)
    ↓
009_auto_meal_planner.sql (creates auto_meal_plans, update_updated_at_column)
    ↓
030_fatsecret_oauth.sql
    ↓
[THIS MIGRATION: 001_initial_schema.sql] ← YOU ARE HERE
    ↓
[Application Code: Generation Engine, Scheduler]
```

---

## Migration Order

### Step-by-Step Execution

#### 1. **Pre-Migration Checks**

```sql
-- Verify users table exists
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'users';
-- Expected: 1

-- Verify auto_meal_plans table exists
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'auto_meal_plans';
-- Expected: 1

-- Verify update_updated_at_column function exists
SELECT COUNT(*) FROM pg_proc
WHERE proname = 'update_updated_at_column';
-- Expected: 1
```

#### 2. **Run Migration**

**Development/Staging:**
```bash
psql -U meal_planner_user -d meal_planner_db -f db/migrations/001_initial_schema.sql
```

**Production:**
```bash
# Use transaction wrapper for safety
psql -U meal_planner_user -d meal_planner_db <<EOF
BEGIN;
\i db/migrations/001_initial_schema.sql
-- Manual validation
SELECT COUNT(*) FROM scheduled_jobs; -- Should be 0 (empty)
SELECT COUNT(*) FROM job_executions; -- Should be 0 (empty)
SELECT COUNT(*) FROM scheduler_config; -- Should be 1 (default config)
SELECT COUNT(*) FROM recipe_rotation; -- Should be 0 (empty)
COMMIT;
EOF
```

#### 3. **Post-Migration Validation**

The migration includes automatic validation. Look for this output:

```
NOTICE:  ========================================
NOTICE:  Migration 001: Validation Report
NOTICE:  ========================================
NOTICE:  Tables created: 4 (expected: 4)
NOTICE:  Indexes created: 13 (expected: 13+)
NOTICE:  Functions created: 7 (expected: 7)
NOTICE:  ========================================
```

**Manual Validation:**
```sql
-- Check table creation
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('scheduled_jobs', 'job_executions', 'scheduler_config', 'recipe_rotation');

-- Check indexes
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('scheduled_jobs', 'job_executions', 'recipe_rotation')
ORDER BY indexname;

-- Check functions
SELECT proname FROM pg_proc
WHERE proname IN ('get_next_pending_job', 'start_job', 'complete_job', 'fail_job',
                  'calculate_next_schedule', 'update_recipe_rotation', 'get_recipes_on_cooldown');

-- Check foreign keys
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name IN ('scheduled_jobs', 'job_executions', 'recipe_rotation');
```

---

## Rollback Procedure

### Complete Rollback

If migration must be reversed:

```sql
BEGIN;

-- Drop functions
DROP FUNCTION IF EXISTS get_recipes_on_cooldown(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS update_recipe_rotation(TEXT, TEXT, TEXT, DATE);
DROP FUNCTION IF EXISTS calculate_next_schedule(TEXT, JSONB, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS fail_job(TEXT, INTEGER, TEXT);
DROP FUNCTION IF EXISTS complete_job(TEXT, INTEGER, JSONB);
DROP FUNCTION IF EXISTS start_job(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_next_pending_job();

-- Drop tables (CASCADE removes dependent objects)
DROP TABLE IF EXISTS recipe_rotation CASCADE;
DROP TABLE IF EXISTS job_executions CASCADE;
DROP TABLE IF EXISTS scheduler_config CASCADE;
DROP TABLE IF EXISTS scheduled_jobs CASCADE;

COMMIT;
```

### Partial Rollback (Keep Scheduler, Remove Recipe Rotation)

```sql
BEGIN;

DROP FUNCTION IF EXISTS get_recipes_on_cooldown(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS update_recipe_rotation(TEXT, TEXT, TEXT, DATE);
DROP TABLE IF EXISTS recipe_rotation CASCADE;

COMMIT;
```

### Validation After Rollback

```sql
-- Verify tables removed
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('scheduled_jobs', 'job_executions', 'scheduler_config', 'recipe_rotation');
-- Expected: 0
```

---

## Testing Strategy

### Phase 1: Schema Validation (Automated)

The migration includes built-in validation. Run migration and verify:
- 4 tables created
- 13+ indexes created
- 7 functions created
- No errors or warnings

### Phase 2: Unit Tests (Per Function)

#### Test: `get_next_pending_job()`

```sql
-- Setup: Create test jobs
INSERT INTO scheduled_jobs (id, job_type, frequency_type, frequency_config, priority, status, enabled)
VALUES
  ('test_job_1', 'weekly_generation', 'once', '{}', 'low', 'pending', true),
  ('test_job_2', 'auto_sync', 'once', '{}', 'high', 'pending', true),
  ('test_job_3', 'daily_advisor', 'once', '{}', 'critical', 'pending', true);

-- Test: Priority ordering
SELECT get_next_pending_job();
-- Expected: test_job_3 (critical priority)

-- Cleanup
DELETE FROM scheduled_jobs WHERE id LIKE 'test_job_%';
```

#### Test: `start_job()` → `complete_job()`

```sql
-- Setup
INSERT INTO scheduled_jobs (id, job_type, frequency_type, frequency_config, status)
VALUES ('test_complete', 'weekly_generation', 'once', '{}', 'pending');

-- Execute job lifecycle
SELECT start_job('test_complete', 'manual') AS exec_id \gset
SELECT pg_sleep(0.1); -- Simulate work
SELECT complete_job('test_complete', :exec_id, '{"recipes": 4}'::JSONB);

-- Validate
SELECT status, error_count, completed_at IS NOT NULL AS completed
FROM scheduled_jobs WHERE id = 'test_complete';
-- Expected: status = 'completed', error_count = 0, completed = true

SELECT status, duration_ms > 0 AS has_duration, output->>'recipes' AS recipe_count
FROM job_executions WHERE job_id = 'test_complete';
-- Expected: status = 'completed', has_duration = true, recipe_count = '4'

-- Cleanup
DELETE FROM scheduled_jobs WHERE id = 'test_complete';
```

#### Test: `fail_job()` Retry Logic

```sql
-- Setup: Job with retry enabled
INSERT INTO scheduled_jobs (id, job_type, frequency_type, frequency_config, status,
                           retry_on_failure, retry_max_attempts, retry_backoff_seconds)
VALUES ('test_fail', 'auto_sync', 'once', '{}', 'pending', true, 3, 60);

-- Attempt 1: Fail
SELECT start_job('test_fail', 'scheduled') AS exec_id \gset
SELECT fail_job('test_fail', :exec_id, 'Test error 1');

-- Validate: Should be pending with scheduled_for in future
SELECT status, error_count, scheduled_for > NOW() AS has_backoff
FROM scheduled_jobs WHERE id = 'test_fail';
-- Expected: status = 'pending', error_count = 1, has_backoff = true

-- Attempt 2: Fail
UPDATE scheduled_jobs SET scheduled_for = NOW() WHERE id = 'test_fail';
SELECT start_job('test_fail', 'retry') AS exec_id \gset
SELECT fail_job('test_fail', :exec_id, 'Test error 2');

-- Validate: error_count incremented
SELECT error_count FROM scheduled_jobs WHERE id = 'test_fail';
-- Expected: 2

-- Cleanup
DELETE FROM scheduled_jobs WHERE id = 'test_fail';
```

#### Test: `update_recipe_rotation()`

```sql
-- Assumes test user exists
INSERT INTO users (id) VALUES ('test_user') ON CONFLICT DO NOTHING;

-- First use
SELECT update_recipe_rotation('test_user', 'recipe_123', 'dinner', '2025-01-01');

-- Validate
SELECT use_count, last_used_date FROM recipe_rotation
WHERE user_id = 'test_user' AND recipe_id = 'recipe_123' AND meal_type = 'dinner';
-- Expected: use_count = 1, last_used_date = '2025-01-01'

-- Second use (upsert)
SELECT update_recipe_rotation('test_user', 'recipe_123', 'dinner', '2025-02-01');

-- Validate
SELECT use_count, last_used_date FROM recipe_rotation
WHERE user_id = 'test_user' AND recipe_id = 'recipe_123' AND meal_type = 'dinner';
-- Expected: use_count = 2, last_used_date = '2025-02-01'

-- Cleanup
DELETE FROM recipe_rotation WHERE user_id = 'test_user';
DELETE FROM users WHERE id = 'test_user';
```

#### Test: `get_recipes_on_cooldown()`

```sql
-- Setup
INSERT INTO users (id) VALUES ('test_user') ON CONFLICT DO NOTHING;
INSERT INTO recipe_rotation (user_id, recipe_id, meal_type, last_used_date)
VALUES
  ('test_user', 'recipe_1', 'dinner', CURRENT_DATE - 5),  -- Within 30 days
  ('test_user', 'recipe_2', 'dinner', CURRENT_DATE - 15), -- Within 30 days
  ('test_user', 'recipe_3', 'dinner', CURRENT_DATE - 40); -- Outside 30 days

-- Test
SELECT recipe_id, days_since_use FROM get_recipes_on_cooldown('test_user', 'dinner', 30)
ORDER BY recipe_id;
-- Expected: recipe_1 (5 days), recipe_2 (15 days)
-- NOT recipe_3 (40 days > cooldown)

-- Cleanup
DELETE FROM recipe_rotation WHERE user_id = 'test_user';
DELETE FROM users WHERE id = 'test_user';
```

### Phase 3: Integration Tests

#### Test: Job Queue Processing

```sql
-- Setup: Multiple jobs with different priorities
INSERT INTO scheduled_jobs (id, job_type, frequency_type, frequency_config, priority, status, scheduled_for)
VALUES
  ('job_low', 'auto_sync', 'once', '{}', 'low', 'pending', NOW()),
  ('job_medium', 'weekly_generation', 'once', '{}', 'medium', 'pending', NOW()),
  ('job_high', 'daily_advisor', 'once', '{}', 'high', 'pending', NOW()),
  ('job_future', 'weekly_trends', 'once', '{}', 'critical', 'pending', NOW() + INTERVAL '1 hour');

-- Test: Get next job (should be highest priority that's ready)
SELECT get_next_pending_job();
-- Expected: job_high (highest priority, ready now)

-- Cleanup
DELETE FROM scheduled_jobs WHERE id LIKE 'job_%';
```

#### Test: Weekly Schedule Calculation

```sql
-- Test: Calculate next Friday 6 AM from Monday
SELECT calculate_next_schedule(
  'weekly',
  '{"day": 5, "hour": 6, "minute": 0}'::JSONB,
  '2025-01-06 10:00:00-06'::TIMESTAMPTZ -- Monday
);
-- Expected: 2025-01-10 06:00:00 (Friday)

-- Test: Calculate from Friday afternoon (should be next week)
SELECT calculate_next_schedule(
  'weekly',
  '{"day": 5, "hour": 6, "minute": 0}'::JSONB,
  '2025-01-10 14:00:00-06'::TIMESTAMPTZ -- Friday 2 PM
);
-- Expected: 2025-01-17 06:00:00 (next Friday)
```

### Phase 4: Performance Tests

#### Test: Index Usage (EXPLAIN ANALYZE)

```sql
-- Create test data
INSERT INTO scheduled_jobs
  SELECT
    'perf_job_' || generate_series,
    'auto_sync',
    'once',
    '{}'::JSONB,
    CASE (random() * 3)::INT
      WHEN 0 THEN 'low'
      WHEN 1 THEN 'medium'
      WHEN 2 THEN 'high'
      ELSE 'critical'
    END,
    'pending',
    true
  FROM generate_series(1, 10000);

-- Test: Index on status + priority
EXPLAIN ANALYZE
SELECT * FROM scheduled_jobs
WHERE status = 'pending' AND enabled = true
ORDER BY priority DESC, scheduled_for ASC
LIMIT 1;
-- Expected: "Index Scan using idx_scheduled_jobs_status_priority"

-- Cleanup
DELETE FROM scheduled_jobs WHERE id LIKE 'perf_job_%';
```

---

## Production Deployment Checklist

### Pre-Deployment

- [ ] **Backup Database**
  ```bash
  pg_dump -U meal_planner_user -d meal_planner_db \
    -F c -f meal_planner_backup_$(date +%Y%m%d_%H%M%S).dump
  ```

- [ ] **Verify Dependencies**
  ```sql
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') AS users_exists,
         EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auto_meal_plans') AS plans_exists,
         EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') AS func_exists;
  ```

- [ ] **Test on Staging Environment**
  - Run migration
  - Run all unit tests
  - Run integration tests
  - Verify performance (EXPLAIN ANALYZE)

- [ ] **Review Migration SQL**
  - No hardcoded user data
  - All DROP statements are IF EXISTS
  - All CREATE statements are IF NOT EXISTS
  - Idempotent (can be run multiple times safely)

- [ ] **Communication Plan**
  - Notify stakeholders of maintenance window
  - Prepare rollback announcement (if needed)
  - Document expected downtime (if any)

### Deployment

- [ ] **Maintenance Mode** (if required)
  ```sql
  UPDATE scheduler_config SET enabled = false WHERE id = 1;
  ```

- [ ] **Run Migration in Transaction**
  ```bash
  psql -U meal_planner_user -d meal_planner_db <<EOF
  BEGIN;
  \timing on
  \i db/migrations/001_initial_schema.sql
  -- Validation
  SELECT COUNT(*) FROM scheduled_jobs;
  SELECT COUNT(*) FROM scheduler_config;
  COMMIT;
  EOF
  ```

- [ ] **Verify Migration Success**
  - Check for NOTICE messages (validation report)
  - Verify no ERROR messages
  - Run manual validation queries

- [ ] **Deploy Application Code**
  - Deploy generation engine code
  - Deploy scheduler executor code
  - Restart application services

### Post-Deployment

- [ ] **Enable Scheduler**
  ```sql
  UPDATE scheduler_config SET enabled = true WHERE id = 1;
  ```

- [ ] **Smoke Tests**
  - Create test job manually
  - Verify job executes
  - Check job_executions table for entry
  - Verify recipe_rotation updates

- [ ] **Monitor for 24 Hours**
  - Check error logs
  - Monitor query performance
  - Verify scheduled jobs execute on time
  - Check retry logic for failed jobs

- [ ] **Performance Baseline**
  ```sql
  -- Capture performance metrics
  SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    idx_scan,
    seq_scan
  FROM pg_stat_user_tables
  WHERE tablename IN ('scheduled_jobs', 'job_executions', 'recipe_rotation');
  ```

---

## Performance Considerations

### Index Strategy

#### Partial Indexes
- `idx_scheduled_jobs_status_priority` only indexes `enabled = true` jobs
- `idx_scheduled_jobs_user_id` only indexes `user_id IS NOT NULL`
- `idx_recipe_rotation_last_used` only indexes recent 30 days

**Benefits:**
- Smaller index size (faster scans)
- Faster writes (fewer index updates)
- Targeted for specific query patterns

#### GIN Indexes (JSONB)
- `idx_scheduled_jobs_parameters`
- `idx_scheduled_jobs_frequency_config`
- `idx_job_executions_output`

**Use Cases:**
```sql
-- Containment queries
SELECT * FROM scheduled_jobs
WHERE parameters @> '{"sync_type": "fatsecret"}';

-- Existence queries
SELECT * FROM job_executions
WHERE output ? 'error_code';
```

### Query Optimization

#### get_next_pending_job() Performance

**Key Optimization:** `FOR UPDATE SKIP LOCKED`

- Prevents lock contention when multiple workers poll queue
- Workers never wait for each other
- Each worker gets a different job atomically

**Without SKIP LOCKED:**
```
Worker A locks job_1
Worker B waits for Worker A
Worker C waits for Worker A
→ Sequential processing
```

**With SKIP LOCKED:**
```
Worker A locks job_1
Worker B skips job_1, locks job_2
Worker C skips job_1 & job_2, locks job_3
→ Parallel processing
```

### Recommended Maintenance

#### Weekly Cleanup (Old Executions)

```sql
-- Archive executions older than 90 days
DELETE FROM job_executions
WHERE started_at < NOW() - INTERVAL '90 days';
```

#### Monthly Vacuum

```sql
VACUUM ANALYZE scheduled_jobs;
VACUUM ANALYZE job_executions;
VACUUM ANALYZE recipe_rotation;
```

#### Index Monitoring

```sql
-- Check for unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
  AND tablename IN ('scheduled_jobs', 'job_executions', 'recipe_rotation')
ORDER BY idx_scan ASC;
-- If idx_scan = 0 for extended period, consider dropping index
```

---

## Troubleshooting

### Issue: Migration Fails with "users table does not exist"

**Cause:** Missing dependency table.

**Solution:**
```bash
# Run prerequisite migrations first
psql -U meal_planner_user -d meal_planner_db -f schema/003_app_tables.sql
psql -U meal_planner_user -d meal_planner_db -f schema/009_auto_meal_planner.sql
# Then retry this migration
psql -U meal_planner_user -d meal_planner_db -f db/migrations/001_initial_schema.sql
```

---

### Issue: Function "update_updated_at_column" does not exist

**Cause:** Missing trigger function.

**Solution:**
```sql
-- Manually create function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Retry migration
\i db/migrations/001_initial_schema.sql
```

---

### Issue: Validation Reports Wrong Count

**Example:**
```
NOTICE:  Tables created: 3 (expected: 4)
```

**Cause:** Table creation failed silently.

**Solution:**
```sql
-- Check for errors in PostgreSQL log
SHOW log_destination;

-- Manually verify each table
SELECT COUNT(*) FROM information_schema.tables
WHERE table_name = 'scheduled_jobs';
-- If 0, check CREATE TABLE statement for syntax errors
```

---

### Issue: get_next_pending_job() Always Returns NULL

**Cause:** No pending jobs or all jobs scheduled for future.

**Debug:**
```sql
-- Check for pending jobs
SELECT id, status, scheduled_for, enabled
FROM scheduled_jobs
WHERE status = 'pending';

-- Check scheduler config
SELECT enabled FROM scheduler_config WHERE id = 1;
```

**Solution:**
```sql
-- Enable scheduler
UPDATE scheduler_config SET enabled = true WHERE id = 1;

-- Create test job
INSERT INTO scheduled_jobs (id, job_type, frequency_type, frequency_config, status, scheduled_for)
VALUES ('test_job', 'weekly_generation', 'once', '{}', 'pending', NOW());

-- Retry
SELECT get_next_pending_job();
```

---

### Issue: Recipe Rotation Not Enforcing Cooldown

**Symptom:** Same recipes appearing in consecutive meal plans.

**Debug:**
```sql
-- Check rotation records
SELECT * FROM recipe_rotation
WHERE user_id = 'your_user_id' AND meal_type = 'dinner'
ORDER BY last_used_date DESC;

-- Check cooldown function
SELECT * FROM get_recipes_on_cooldown('your_user_id', 'dinner', 30);
```

**Solution:**
Ensure application calls `update_recipe_rotation()` after generating meal plan:
```gleam
// After meal plan generation
case db.exec("SELECT update_recipe_rotation($1, $2, $3, $4)",
             [user_id, recipe_id, meal_type, used_date]) {
  Ok(_) -> // Continue
  Error(e) -> // Log error
}
```

---

### Issue: Exponential Backoff Not Working

**Symptom:** Failed jobs retry immediately.

**Debug:**
```sql
-- Check retry config
SELECT retry_on_failure, retry_max_attempts, retry_backoff_seconds, error_count, scheduled_for
FROM scheduled_jobs
WHERE id = 'your_job_id';

-- Check execution history
SELECT attempt_number, status, error_message
FROM job_executions
WHERE job_id = 'your_job_id'
ORDER BY started_at DESC;
```

**Expected Behavior:**
- Attempt 1 fails → scheduled_for = NOW() + 60s
- Attempt 2 fails → scheduled_for = NOW() + 120s
- Attempt 3 fails → scheduled_for = NOW() + 240s

**Solution:**
Verify `fail_job()` function is used correctly:
```gleam
// Correct usage
case job_result {
  Ok(output) -> complete_job(job_id, exec_id, output)
  Error(e) -> fail_job(job_id, exec_id, error_to_string(e))
}
```

---

## Additional Resources

### Related Documentation
- **Generation Engine:** See `src/meal_planner/generation_engine.gleam`
- **Scheduler Executor:** See `src/meal_planner/scheduler/executor.gleam`
- **API Contracts:** See `docs/API_CONTRACTS.md`

### Database Schema Diagram

```
┌─────────────────┐
│     users       │
│  (from 003)     │
└────────┬────────┘
         │
         │ FK
         ▼
┌─────────────────────────────────┐
│      scheduled_jobs             │
│  ┌──────────────────────────┐   │
│  │ id (PK)                  │   │
│  │ job_type                 │   │
│  │ frequency_type           │   │
│  │ frequency_config (JSONB) │   │
│  │ priority                 │   │
│  │ status                   │   │
│  │ user_id (FK → users)     │   │
│  │ retry_max_attempts       │   │
│  │ error_count              │   │
│  │ scheduled_for            │   │
│  └──────────────────────────┘   │
└──────────┬──────────────────────┘
           │
           │ FK
           ▼
┌─────────────────────────────────┐
│      job_executions             │
│  ┌──────────────────────────┐   │
│  │ id (PK, SERIAL)          │   │
│  │ job_id (FK)              │   │
│  │ started_at               │   │
│  │ completed_at             │   │
│  │ status                   │   │
│  │ error_message            │   │
│  │ duration_ms              │   │
│  │ output (JSONB)           │   │
│  │ trigger_type             │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│      recipe_rotation            │
│  ┌──────────────────────────┐   │
│  │ id (PK, BIGSERIAL)       │   │
│  │ user_id (FK → users)     │   │
│  │ recipe_id                │   │
│  │ meal_type                │   │
│  │ last_used_date           │   │
│  │ use_count                │   │
│  │ UNIQUE(user,recipe,type) │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│    scheduler_config (Singleton) │
│  ┌──────────────────────────┐   │
│  │ id = 1 (PK, CHECK)       │   │
│  │ enabled                  │   │
│  │ max_concurrent_jobs      │   │
│  │ check_interval_seconds   │   │
│  │ timezone                 │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

### Contact

For migration issues or questions:
- Check PostgreSQL logs: `/var/log/postgresql/`
- Review application logs for database errors
- File issue in project repository

---

**End of Migration Guide**
