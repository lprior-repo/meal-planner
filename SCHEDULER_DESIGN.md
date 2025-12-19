# Scheduler & Automation System - Type Specification

## Overview

Complete type-safe scheduler system for automated task execution in the meal planner application.

## Architecture

### Core Components

1. **Type Definitions** (`src/meal_planner/scheduler/types.gleam`)
   - Opaque `JobId` type (added to `id.gleam`)
   - Job types, statuses, frequencies, priorities
   - Retry policies with exponential backoff
   - Execution tracking and history

2. **Database Schema** (`schema/031_scheduler_tables.sql`)
   - `scheduled_jobs` table (job definitions and state)
   - `job_executions` table (execution history)
   - `scheduler_config` table (global settings)
   - Helper functions for job lifecycle
   - Performance-optimized indexes

3. **Test Fixtures** (`test/fixtures/scheduler_job.json`)
   - 10+ comprehensive test scenarios
   - Valid job configurations for all types
   - Execution history examples
   - Request/response examples

## Job Types

### 1. Weekly Generation (`WeeklyGeneration`)
- **Schedule**: Friday 6:00 AM
- **Purpose**: Generate weekly meal plans
- **Parameters**: `diet_principles`, `exclude_ingredients`
- **Priority**: High
- **Retry**: 3 attempts, 60s backoff

### 2. Auto Sync (`AutoSync`)
- **Schedule**: Every 2-4 hours
- **Purpose**: Sync FatSecret/Tandoor data
- **Parameters**: `sync_type`, `full_sync`
- **Priority**: Medium/Critical
- **Retry**: 5 attempts, 120s backoff

### 3. Daily Advisor (`DailyAdvisor`)
- **Schedule**: Daily 8:00 PM
- **Purpose**: Send daily nutrition advisor email
- **Parameters**: `email_template`, `include_macros`, `include_suggestions`
- **Priority**: Medium
- **Retry**: 3 attempts, 60s backoff

### 4. Weekly Trends (`WeeklyTrends`)
- **Schedule**: Thursday 8:00 PM
- **Purpose**: Send weekly trend analysis email
- **Parameters**: `analysis_days`, `include_charts`, `email_format`
- **Priority**: Low
- **Retry**: 2 attempts, 300s backoff

## Job Frequencies

```gleam
pub type JobFrequency {
  Weekly(day: Int, hour: Int, minute: Int)     // 0=Monday, 6=Sunday
  Daily(hour: Int, minute: Int)                // 24-hour format
  EveryNHours(hours: Int)                      // Interval-based
  Once                                         // One-time execution
}
```

## Job Lifecycle

### State Machine

```
Pending → Running → Completed
           ↓
        Failed → Pending (retry)
                  ↓
               Failed (max retries exceeded)
```

### Status Transitions

1. **Pending** → **Running**: `start_job(job_id, trigger_type)`
2. **Running** → **Completed**: `complete_job(job_id, execution_id, output)`
3. **Running** → **Failed**: `fail_job(job_id, execution_id, error_message)`
4. **Failed** → **Pending**: Automatic retry with exponential backoff

## Retry Policy

### Configuration
```gleam
pub type RetryPolicy {
  RetryPolicy(
    max_attempts: Int,           // 0 = no retry
    backoff_seconds: Int,        // Base backoff time
    retry_on_failure: Bool,      // Master switch
  )
}
```

### Exponential Backoff
- **Formula**: `base_seconds * 2^(error_count - 1)`
- **Example** (60s base):
  - Attempt 1: Immediate
  - Attempt 2: 60s delay (60 * 2^0)
  - Attempt 3: 120s delay (60 * 2^1)
  - Attempt 4: 240s delay (60 * 2^2)
- **Cap**: 32x maximum backoff multiplier

### Helper Functions
```gleam
should_retry(job: ScheduledJob) -> Bool
calculate_backoff(job: ScheduledJob) -> Int
```

## Job Queue Operations

### Create Job
```gleam
pub type CreateJobRequest {
  CreateJobRequest(
    job_type: JobType,
    frequency: JobFrequency,
    priority: JobPriority,
    user_id: Option(UserId),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    scheduled_for: Option(String),
    enabled: Bool,
  )
}
```

### Update Job
```gleam
pub type UpdateJobRequest {
  UpdateJobRequest(
    frequency: Option(JobFrequency),
    priority: Option(JobPriority),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    scheduled_for: Option(String),
    enabled: Option(Bool),
  )
}
```

### Execute Job
```gleam
pub type JobContext {
  JobContext(
    job_id: JobId,
    user_id: Option(UserId),
    parameters: Option(Json),
    attempt_number: Int,
    triggered_by: TriggerSource,
  )
}

pub type TriggerSource {
  Scheduled                           // Cron trigger
  Manual                              // API/user trigger
  Retry                               // Automatic retry
  Dependent(parent_job_id: JobId)     // Triggered by another job
}
```

## Database Schema

### Tables

#### `scheduled_jobs`
- **Primary Key**: `id` (TEXT)
- **Job Config**: `job_type`, `frequency_type`, `frequency_config`
- **Status**: `status`, `priority`, `enabled`
- **Retry**: `retry_max_attempts`, `retry_backoff_seconds`, `retry_on_failure`
- **Error Tracking**: `error_count`, `last_error`
- **Timestamps**: `scheduled_for`, `started_at`, `completed_at`, `created_at`, `updated_at`
- **User**: `user_id` (NULL for system jobs), `created_by`

#### `job_executions`
- **Primary Key**: `id` (SERIAL)
- **Job Reference**: `job_id`
- **Execution**: `started_at`, `completed_at`, `status`
- **Error**: `error_message`, `attempt_number`
- **Metrics**: `duration_ms`
- **Output**: `output` (JSONB)
- **Trigger**: `trigger_type`, `parent_job_id`

#### `scheduler_config`
- **Single Row**: `id = 1` (enforced by CHECK constraint)
- **Global**: `enabled`, `max_concurrent_jobs`, `check_interval_seconds`, `timezone`
- **Defaults**: `default_retry_max_attempts`, `default_retry_backoff_seconds`

### Indexes

#### Performance Indexes
- `idx_scheduled_jobs_status_priority`: Job queue polling (status, priority DESC, scheduled_for ASC)
- `idx_scheduled_jobs_user_id`: User-specific jobs
- `idx_scheduled_jobs_type`: Job type queries
- `idx_scheduled_jobs_scheduled_for`: Pending jobs to schedule
- `idx_job_executions_job_id`: Execution history per job
- `idx_job_executions_started_at`: Recent executions
- `idx_job_executions_status`: Failed executions

#### JSONB Indexes (GIN)
- `idx_scheduled_jobs_parameters`: Parameter queries
- `idx_scheduled_jobs_frequency_config`: Frequency queries
- `idx_job_executions_output`: Output queries

### Helper Functions

#### `get_next_pending_job() -> TEXT`
- Returns next job ID to execute
- Priority-based ordering
- Uses `FOR UPDATE SKIP LOCKED` for concurrency

#### `start_job(job_id, trigger_type) -> INTEGER`
- Marks job as running
- Creates execution record
- Returns execution ID

#### `complete_job(job_id, execution_id, output)`
- Marks job and execution as completed
- Resets error count
- Calculates execution duration

#### `fail_job(job_id, execution_id, error_message)`
- Marks execution as failed
- Increments error count
- Schedules retry with exponential backoff (if applicable)
- Marks job as failed if max retries exceeded

#### `calculate_next_schedule(frequency_type, frequency_config, from_time) -> TIMESTAMP`
- Calculates next execution time for recurring jobs
- Handles weekly, daily, and hourly schedules
- Timezone-aware (uses scheduler_config.timezone)

## Error Types

```gleam
pub type SchedulerError {
  JobNotFound(job_id: JobId)
  JobAlreadyRunning(job_id: JobId)
  ExecutionFailed(job_id: JobId, reason: String)
  MaxRetriesExceeded(job_id: JobId)
  InvalidConfiguration(reason: String)
  DatabaseError(message: String)
  SchedulerDisabled
  DependencyNotMet(job_id: JobId, dependency: JobId)
}
```

## JSON Encoding/Decoding

All types have complete JSON encoders and decoders:
- `job_type_to_string` / `job_type_decoder`
- `job_status_to_string` / `job_status_decoder`
- `job_priority_to_string` / `job_priority_decoder`
- `retry_policy_to_json` / `retry_policy_decoder`
- `job_frequency_to_json`
- `trigger_source_to_json`
- `scheduled_job_to_json`
- `job_execution_to_json`
- `job_execution_result_to_json`

## Example Usage

### Create Weekly Generation Job
```gleam
let request = CreateJobRequest(
  job_type: WeeklyGeneration,
  frequency: Weekly(day: 5, hour: 6, minute: 0), // Friday 6 AM
  priority: High,
  user_id: Some(user_id("user_001")),
  parameters: Some(json.object([
    #("diet_principles", json.array(["vertical_diet"], json.string)),
    #("exclude_ingredients", json.array(["peanuts"], json.string)),
  ])),
  retry_policy: None, // Use default
  scheduled_for: Some("2025-12-27T06:00:00Z"),
  enabled: True,
)
```

### Execute Job Handler
```gleam
fn handle_weekly_generation(ctx: JobContext) -> Result(JobExecutionResult, SchedulerError) {
  // 1. Extract parameters
  let params = ctx.parameters |> option.unwrap(json.object([]))

  // 2. Perform work
  let result = generate_weekly_meal_plan(ctx.user_id, params)

  // 3. Return result
  case result {
    Ok(plan) -> Ok(JobExecutionResult(
      success: True,
      output: Some(meal_plan_to_json(plan)),
      error_message: None,
      duration_ms: 150000,
    ))
    Error(e) -> Error(ExecutionFailed(ctx.job_id, error_to_string(e)))
  }
}
```

## Next Steps for Implementation

### Phase 1: Core Scheduler (TESTER)
- Test fixtures validation
- Job creation and retrieval
- Status transitions
- Basic execution tracking

### Phase 2: Job Handlers (CODER)
- Implement job type handlers
- Weekly generation logic
- Auto sync logic
- Email sending logic

### Phase 3: Scheduler Engine (REFACTORER)
- Job polling loop
- Concurrency management
- Retry mechanism
- Dependency resolution

### Phase 4: API & UI (Next Iteration)
- HTTP handlers for job management
- Job monitoring dashboard
- Manual trigger endpoints
- Execution history API

## Files Created

1. `/home/lewis/src/meal-planner/src/meal_planner/scheduler/types.gleam` (500+ lines)
   - Complete type definitions
   - Helper functions
   - JSON encoders/decoders

2. `/home/lewis/src/meal-planner/src/meal_planner/id.gleam` (updated)
   - Added `JobId` opaque type
   - Constructors, accessors, JSON encoding/decoding

3. `/home/lewis/src/meal-planner/schema/031_scheduler_tables.sql` (400+ lines)
   - 3 tables (scheduled_jobs, job_executions, scheduler_config)
   - 10+ indexes (including GIN for JSONB)
   - 5 helper functions
   - Comprehensive comments

4. `/home/lewis/src/meal-planner/test/fixtures/scheduler_job.json` (300+ lines)
   - 10+ test scenarios
   - All job types covered
   - Success/failure cases
   - Request/response examples

## Design Decisions

### Why Database-Backed?
- **Persistence**: Jobs survive application restarts
- **Concurrency**: Multiple workers can poll queue safely
- **History**: Complete audit trail of all executions
- **Reliability**: Transactional job state management

### Why Exponential Backoff?
- **Load Relief**: Prevents hammering failing external services
- **Recovery Time**: Gives systems time to recover
- **Fair Distribution**: Spreads retries over time

### Why Priority-Based Queue?
- **Critical Jobs**: Auto-sync failures need immediate retry
- **Best Effort**: Trend analysis can wait
- **User Experience**: User-triggered jobs take precedence

### Why JSONB for Parameters?
- **Flexibility**: Each job type has different config needs
- **Queryability**: GIN indexes allow parameter-based queries
- **Schema Evolution**: Easy to add new parameters without migrations

### Why Separate Execution History?
- **Scalability**: Main job table stays small
- **Analytics**: Query execution patterns without job metadata
- **Retention**: Archive old executions without losing job definitions

## Compliance with Gleam Commandments

✅ **IMMUTABILITY_ABSOLUTE**: All types are immutable records
✅ **NO_NULLS_EVER**: Using `Option(T)` for all optional fields
✅ **PIPE_EVERYTHING**: Ready for pipeline-based job processing
✅ **EXHAUSTIVE_MATCHING**: All case expressions cover all variants
✅ **LABELED_ARGUMENTS**: Complex functions use labeled args
✅ **TYPE_SAFETY_FIRST**: Opaque `JobId`, no `dynamic` usage
✅ **FORMAT_OR_DEATH**: Code is `gleam format` compliant

## Ready for TESTER

All type definitions, database schema, and test fixtures are complete and ready for the TESTER agent to write failing tests.

The ARCHITECT phase is complete.
