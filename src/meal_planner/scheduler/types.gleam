//// Scheduler types for automated job execution
////
//// This module defines types for the weekly scheduler that handles:
//// - Weekly meal plan generation (Friday 6 AM)
//// - Automatic sync jobs (every 2-4 hours)
//// - Daily advisor emails (8 PM)
//// - Weekly trend analysis (Thursday 8 PM)
////
//// Jobs are database-backed with support for manual triggers, retries,
//// and execution history tracking.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/id.{type JobId, type UserId}

// ============================================================================
// Job Types
// ============================================================================

/// Type of scheduled job
pub type JobType {
  /// Weekly meal plan generation (Friday 6 AM)
  WeeklyGeneration
  /// Automatic FatSecret sync (every 2-4 hours)
  AutoSync
  /// Daily advisor email (8 PM)
  DailyAdvisor
  /// Weekly trend analysis email (Thursday 8 PM)
  WeeklyTrends
}

/// Job frequency specification
pub type JobFrequency {
  /// Run once per week on specified day and time
  Weekly(day: Int, hour: Int, minute: Int)
  /// Run once per day at specified time
  Daily(hour: Int, minute: Int)
  /// Run every N hours
  EveryNHours(hours: Int)
  /// One-time execution (manual trigger)
  Once
}

/// Job execution status
pub type JobStatus {
  /// Job is scheduled but not yet running
  Pending
  /// Job is currently executing
  Running
  /// Job completed successfully
  Completed
  /// Job failed with error
  Failed
}

/// Job priority level (higher number = higher priority)
pub type JobPriority {
  Low
  Medium
  High
  Critical
}

/// Retry policy for failed jobs
pub type RetryPolicy {
  RetryPolicy(
    max_attempts: Int,
    // Maximum retry attempts (0 = no retry)
    backoff_seconds: Int,
    // Seconds to wait between retries (exponential)
    retry_on_failure: Bool,
  )
}

/// Job execution context (passed to job handler)
pub type JobContext {
  JobContext(
    job_id: JobId,
    user_id: Option(UserId),
    // None for system-wide jobs
    parameters: Option(Json),
    // Job-specific parameters
    attempt_number: Int,
    // Current attempt (1-indexed)
    triggered_by: TriggerSource,
  )
}

/// Source of job trigger
pub type TriggerSource {
  /// Triggered by scheduler (cron)
  Scheduled
  /// Triggered manually via API
  Manual
  /// Triggered by retry mechanism
  Retry
  /// Triggered by another job
  Dependent(parent_job_id: JobId)
}

// ============================================================================
// Scheduled Job Definition
// ============================================================================

/// A scheduled job with metadata and execution tracking
pub type ScheduledJob {
  ScheduledJob(
    id: JobId,
    job_type: JobType,
    frequency: JobFrequency,
    status: JobStatus,
    priority: JobPriority,
    user_id: Option(UserId),
    // None for system-wide jobs
    retry_policy: RetryPolicy,
    parameters: Option(Json),
    // Job-specific configuration
    // Execution tracking
    scheduled_for: Option(String),
    // ISO8601 timestamp
    started_at: Option(String),
    // ISO8601 timestamp
    completed_at: Option(String),
    // ISO8601 timestamp
    // Error tracking
    last_error: Option(String),
    error_count: Int,
    // Metadata
    created_at: String,
    // ISO8601 timestamp
    updated_at: String,
    // ISO8601 timestamp
    created_by: Option(UserId),
    // User who created job (None for system)
    enabled: Bool,
  )
}

// ============================================================================
// Job Execution History
// ============================================================================

/// Record of a single job execution
pub type JobExecution {
  JobExecution(
    id: Int,
    // Auto-increment primary key
    job_id: JobId,
    started_at: String,
    // ISO8601 timestamp
    completed_at: Option(String),
    // ISO8601 timestamp
    status: JobStatus,
    error_message: Option(String),
    attempt_number: Int,
    duration_ms: Option(Int),
    // Execution time in milliseconds
    output: Option(Json),
    // Job output/result data
    triggered_by: TriggerSource,
  )
}

// ============================================================================
// Scheduler Configuration
// ============================================================================

/// Global scheduler configuration
pub type SchedulerConfig {
  SchedulerConfig(
    enabled: Bool,
    // Master kill switch
    max_concurrent_jobs: Int,
    // Limit concurrent executions
    check_interval_seconds: Int,
    // How often to check for pending jobs
    default_retry_policy: RetryPolicy,
    // Default retry policy for new jobs
    timezone: String,
  )
}

// ============================================================================
// Error Types
// ============================================================================

/// Scheduler-specific errors
pub type SchedulerError {
  /// Job not found in database
  JobNotFound(job_id: JobId)
  /// Job already running
  JobAlreadyRunning(job_id: JobId)
  /// Job execution failed
  ExecutionFailed(job_id: JobId, reason: String)
  /// Maximum retry attempts exceeded
  MaxRetriesExceeded(job_id: JobId)
  /// Invalid job configuration
  InvalidConfiguration(reason: String)
  /// Database error
  DatabaseError(message: String)
  /// Scheduler not enabled
  SchedulerDisabled
  /// Job dependency not met
  DependencyNotMet(job_id: JobId, dependency: JobId)
}

// ============================================================================
// Job Queue Operations
// ============================================================================

/// Request to create a new scheduled job
pub type CreateJobRequest {
  CreateJobRequest(
    job_type: JobType,
    frequency: JobFrequency,
    priority: JobPriority,
    user_id: Option(UserId),
    parameters: Option(Json),
    retry_policy: Option(RetryPolicy),
    // Use default if None
    scheduled_for: Option(String),
    // Schedule for specific time
    enabled: Bool,
  )
}

/// Request to update an existing job
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

/// Result of job execution
pub type JobExecutionResult {
  JobExecutionResult(
    success: Bool,
    output: Option(Json),
    error_message: Option(String),
    duration_ms: Int,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get priority as integer (for sorting)
pub fn priority_to_int(p: JobPriority) -> Int {
  case p {
    Low -> 1
    Medium -> 2
    High -> 3
    Critical -> 4
  }
}

/// Create default retry policy (3 attempts, 60s backoff)
pub fn default_retry_policy() -> RetryPolicy {
  RetryPolicy(max_attempts: 3, backoff_seconds: 60, retry_on_failure: True)
}

/// Create no-retry policy
pub fn no_retry_policy() -> RetryPolicy {
  RetryPolicy(max_attempts: 0, backoff_seconds: 0, retry_on_failure: False)
}

/// Check if job should retry based on policy
pub fn should_retry(job: ScheduledJob) -> Bool {
  job.retry_policy.retry_on_failure
  && job.error_count < job.retry_policy.max_attempts
}

/// Calculate next retry backoff in seconds (exponential)
pub fn calculate_backoff(job: ScheduledJob) -> Int {
  let base = job.retry_policy.backoff_seconds
  // Exponential backoff: base * 2^(error_count)
  base * power_of_2(job.error_count)
}

// Helper for 2^n calculation
fn power_of_2(n: Int) -> Int {
  case n {
    0 -> 1
    1 -> 2
    2 -> 4
    3 -> 8
    4 -> 16
    _ -> 32
    // Cap at 32x backoff
  }
}

// ============================================================================
// JSON Encoders
// ============================================================================

pub fn job_type_to_string(jt: JobType) -> String {
  case jt {
    WeeklyGeneration -> "weekly_generation"
    AutoSync -> "auto_sync"
    DailyAdvisor -> "daily_advisor"
    WeeklyTrends -> "weekly_trends"
  }
}

pub fn job_status_to_string(js: JobStatus) -> String {
  case js {
    Pending -> "pending"
    Running -> "running"
    Completed -> "completed"
    Failed -> "failed"
  }
}

pub fn job_priority_to_string(jp: JobPriority) -> String {
  case jp {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
    Critical -> "critical"
  }
}

pub fn trigger_source_to_json(ts: TriggerSource) -> Json {
  case ts {
    Scheduled -> json.object([#("type", json.string("scheduled"))])
    Manual -> json.object([#("type", json.string("manual"))])
    Retry -> json.object([#("type", json.string("retry"))])
    Dependent(parent_id) ->
      json.object([
        #("type", json.string("dependent")),
        #("parent_job_id", id.job_id_to_json(parent_id)),
      ])
  }
}

pub fn retry_policy_to_json(rp: RetryPolicy) -> Json {
  json.object([
    #("max_attempts", json.int(rp.max_attempts)),
    #("backoff_seconds", json.int(rp.backoff_seconds)),
    #("retry_on_failure", json.bool(rp.retry_on_failure)),
  ])
}

pub fn job_frequency_to_json(jf: JobFrequency) -> Json {
  case jf {
    Weekly(day, hour, minute) ->
      json.object([
        #("type", json.string("weekly")),
        #("day", json.int(day)),
        #("hour", json.int(hour)),
        #("minute", json.int(minute)),
      ])
    Daily(hour, minute) ->
      json.object([
        #("type", json.string("daily")),
        #("hour", json.int(hour)),
        #("minute", json.int(minute)),
      ])
    EveryNHours(hours) ->
      json.object([
        #("type", json.string("every_n_hours")),
        #("hours", json.int(hours)),
      ])
    Once -> json.object([#("type", json.string("once"))])
  }
}

pub fn scheduled_job_to_json(job: ScheduledJob) -> Json {
  let base_fields = [
    #("id", id.job_id_to_json(job.id)),
    #("job_type", json.string(job_type_to_string(job.job_type))),
    #("frequency", job_frequency_to_json(job.frequency)),
    #("status", json.string(job_status_to_string(job.status))),
    #("priority", json.string(job_priority_to_string(job.priority))),
    #("retry_policy", retry_policy_to_json(job.retry_policy)),
    #("error_count", json.int(job.error_count)),
    #("created_at", json.string(job.created_at)),
    #("updated_at", json.string(job.updated_at)),
    #("enabled", json.bool(job.enabled)),
  ]

  let fields = case job.user_id {
    Some(uid) -> [#("user_id", id.user_id_to_json(uid)), ..base_fields]
    None -> base_fields
  }

  let fields = case job.parameters {
    Some(params) -> [#("parameters", params), ..fields]
    None -> fields
  }

  let fields = case job.scheduled_for {
    Some(ts) -> [#("scheduled_for", json.string(ts)), ..fields]
    None -> fields
  }

  let fields = case job.started_at {
    Some(ts) -> [#("started_at", json.string(ts)), ..fields]
    None -> fields
  }

  let fields = case job.completed_at {
    Some(ts) -> [#("completed_at", json.string(ts)), ..fields]
    None -> fields
  }

  let fields = case job.last_error {
    Some(err) -> [#("last_error", json.string(err)), ..fields]
    None -> fields
  }

  let fields = case job.created_by {
    Some(uid) -> [#("created_by", id.user_id_to_json(uid)), ..fields]
    None -> fields
  }

  json.object(fields)
}

pub fn job_execution_to_json(exec: JobExecution) -> Json {
  let base_fields = [
    #("id", json.int(exec.id)),
    #("job_id", id.job_id_to_json(exec.job_id)),
    #("started_at", json.string(exec.started_at)),
    #("status", json.string(job_status_to_string(exec.status))),
    #("attempt_number", json.int(exec.attempt_number)),
    #("triggered_by", trigger_source_to_json(exec.triggered_by)),
  ]

  let fields = case exec.completed_at {
    Some(ts) -> [#("completed_at", json.string(ts)), ..base_fields]
    None -> base_fields
  }

  let fields = case exec.error_message {
    Some(err) -> [#("error_message", json.string(err)), ..fields]
    None -> fields
  }

  let fields = case exec.duration_ms {
    Some(ms) -> [#("duration_ms", json.int(ms)), ..fields]
    None -> fields
  }

  let fields = case exec.output {
    Some(out) -> [#("output", out), ..fields]
    None -> fields
  }

  json.object(fields)
}

pub fn job_execution_result_to_json(result: JobExecutionResult) -> Json {
  let base_fields = [
    #("success", json.bool(result.success)),
    #("duration_ms", json.int(result.duration_ms)),
  ]

  let fields = case result.output {
    Some(out) -> [#("output", out), ..base_fields]
    None -> base_fields
  }

  let fields = case result.error_message {
    Some(err) -> [#("error_message", json.string(err)), ..fields]
    None -> fields
  }

  json.object(fields)
}

// ============================================================================
// JSON Decoders
// ============================================================================

pub fn job_type_decoder() -> Decoder(JobType) {
  use s <- decode.then(decode.string)
  case s {
    "weekly_generation" -> decode.success(WeeklyGeneration)
    "auto_sync" -> decode.success(AutoSync)
    "daily_advisor" -> decode.success(DailyAdvisor)
    "weekly_trends" -> decode.success(WeeklyTrends)
    _ -> decode.failure(WeeklyGeneration, "JobType")
  }
}

pub fn job_status_decoder() -> Decoder(JobStatus) {
  use s <- decode.then(decode.string)
  case s {
    "pending" -> decode.success(Pending)
    "running" -> decode.success(Running)
    "completed" -> decode.success(Completed)
    "failed" -> decode.success(Failed)
    _ -> decode.failure(Pending, "JobStatus")
  }
}

pub fn job_priority_decoder() -> Decoder(JobPriority) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    "critical" -> decode.success(Critical)
    _ -> decode.failure(Medium, "JobPriority")
  }
}

pub fn retry_policy_decoder() -> Decoder(RetryPolicy) {
  use max_attempts <- decode.field("max_attempts", decode.int)
  use backoff_seconds <- decode.field("backoff_seconds", decode.int)
  use retry_on_failure <- decode.field("retry_on_failure", decode.bool)
  decode.success(RetryPolicy(
    max_attempts: max_attempts,
    backoff_seconds: backoff_seconds,
    retry_on_failure: retry_on_failure,
  ))
}
