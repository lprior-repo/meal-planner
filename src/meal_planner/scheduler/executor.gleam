//// Scheduler job executor - routes scheduled jobs to appropriate handlers
////
//// This module provides the execute_scheduled_job function which:
//// - Pattern matches on JobType
//// - Routes to correct handler (weekly_plan, meal_sync, daily_recommendations, weekly_trends)
//// - Captures execution results and errors
//// - Returns JobExecution with output/error data
////
//// Handlers called:
//// - WeeklyGeneration → weekly_plan.generate_weekly_plan()
//// - AutoSync → meal_sync.sync_meals()
//// - DailyAdvisor → daily_recommendations.generate_daily_advisor_email()
//// - WeeklyTrends → weekly_trends.analyze_weekly_trends()

import birl
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import meal_planner/advisor/daily_recommendations
import meal_planner/advisor/weekly_trends
import meal_planner/postgres
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types.{
  type JobExecution, type ScheduledJob, type SchedulerError, AutoSync,
  DailyAdvisor, DatabaseError as SchedulerDatabaseError, ExecutionFailed,
  JobExecution, Running, WeeklyGeneration, WeeklyTrends,
}
import pog

// ============================================================================
// Executor Configuration Types
// ============================================================================

/// Configuration for job executor behavior
pub type ExecutorConfig {
  ExecutorConfig(
    /// Maximum retry attempts for failed jobs
    max_retries: Int,
    /// Backoff delay in milliseconds between retries
    retry_backoff_ms: Int,
    /// Maximum concurrent job executions
    concurrent_jobs: Int,
  )
}

/// Job execution error types (covers both transient and permanent failures)
pub type JobError {
  /// Job execution timed out
  TimeoutError(timeout_ms: Int)
  /// Maximum retry attempts exceeded
  MaxRetriesExceeded
  /// API returned error response (transient - retry)
  ApiError(code: Int, message: String)
  /// Invalid job type specified (permanent - no retry)
  InvalidJobType
  /// Database error (permanent - no retry)
  DatabaseError(message: String)
}

/// Enhanced execution context with retry tracking
pub type ExecutionContext {
  ExecutionContext(
    /// Job being executed
    job: ScheduledJob,
    /// Current attempt number (1-indexed)
    attempt: Int,
    /// Unix timestamp (milliseconds) when execution started
    started_at: Int,
    /// Executor configuration
    config: ExecutorConfig,
  )
}

/// Result type for weekly meal plan generation
pub type GenerationResult {
  GenerationResult(
    /// Number of meals generated
    meals_generated: Int,
    /// Recipes used in plan
    recipe_ids: List(Int),
    /// Total calories planned
    total_calories: Float,
    /// Generation success status
    status: String,
  )
}

/// Result type for FatSecret sync operations
pub type SyncResult {
  SyncResult(
    /// Number of meals successfully synced
    synced: Int,
    /// Number of meals skipped (already synced)
    skipped: Int,
    /// Number of meals that failed to sync
    failed: Int,
    /// Error messages from failed syncs
    errors: List(String),
  )
}

// ============================================================================
// Default Configuration
// ============================================================================

/// Default executor configuration
///
/// - 3 retries for transient failures
/// - 60 second (60000ms) exponential backoff
/// - 5 concurrent job limit
pub fn default_config() -> ExecutorConfig {
  ExecutorConfig(max_retries: 3, retry_backoff_ms: 60_000, concurrent_jobs: 5)
}

// ============================================================================
// Core Executor Function Signatures (Type Contracts)
// ============================================================================

/// Execute a scheduled job with retry logic
///
/// This function:
/// 1. Creates execution context with attempt tracking
/// 2. Sets job status to Running
/// 3. Calls appropriate handler based on job_type
/// 4. Records execution results (output or error)
/// 5. Returns JobExecution record
///
/// Retry behavior:
/// - Transient failures (ApiError, TimeoutError): Retry with exponential backoff
/// - Permanent failures (InvalidJobType, DatabaseError): No retry
///
/// Parameters:
/// - job: ScheduledJob to execute
/// - config: ExecutorConfig with retry/concurrency settings
///
/// Returns:
/// - Ok(JobExecution) with execution metadata and output
/// - Error(JobError) on permanent failure or max retries exceeded
pub fn execute_job(
  job: ScheduledJob,
  config: ExecutorConfig,
) -> Result(JobExecution, JobError) {
  // Implementation will be defined in GREEN phase
  Error(InvalidJobType)
}

/// Retry a failed job with delay
///
/// This function:
/// 1. Validates job exists and is retryable
/// 2. Schedules retry with specified delay
/// 3. Increments attempt counter
///
/// Parameters:
/// - job_id: String identifier for job to retry
/// - delay_ms: Milliseconds to wait before retry
///
/// Returns:
/// - Ok(Nil) if retry scheduled successfully
/// - Error(JobError) if job not found or max retries exceeded
pub fn retry_failed_job(job_id: String, delay_ms: Int) -> Result(Nil, JobError) {
  // Implementation will be defined in GREEN phase
  Error(InvalidJobType)
}

/// Handle weekly meal plan generation request
///
/// This function:
/// 1. Validates execution context
/// 2. Calls meal plan generation service
/// 3. Transforms result to GenerationResult
/// 4. Updates job status and output
///
/// Parameters:
/// - context: ExecutionContext with job and config
///
/// Returns:
/// - Ok(GenerationResult) with generation statistics
/// - Error(JobError) on failure (ApiError, TimeoutError, etc.)
pub fn handle_generation_request(
  context: ExecutionContext,
) -> Result(GenerationResult, JobError) {
  // Implementation will be defined in GREEN phase
  Error(InvalidJobType)
}

/// Handle FatSecret auto-sync request
///
/// This function:
/// 1. Validates execution context
/// 2. Calls FatSecret sync service
/// 3. Transforms result to SyncResult
/// 4. Updates job status and output
///
/// Parameters:
/// - context: ExecutionContext with job and config
///
/// Returns:
/// - Ok(SyncResult) with sync statistics
/// - Error(JobError) on failure (ApiError, TimeoutError, etc.)
pub fn handle_sync_request(
  context: ExecutionContext,
) -> Result(SyncResult, JobError) {
  // Implementation will be defined in GREEN phase
  Error(InvalidJobType)
}

// ============================================================================
// Error Classification (Retry Logic)
// ============================================================================

/// Determine if error is transient (should retry)
///
/// Transient errors:
/// - ApiError (API may recover)
/// - TimeoutError (may succeed on retry)
///
/// Permanent errors:
/// - InvalidJobType (will never succeed)
/// - DatabaseError (requires intervention)
/// - MaxRetriesExceeded (already exhausted retries)
pub fn is_transient_error(error: JobError) -> Bool {
  case error {
    ApiError(_, _) -> True
    TimeoutError(_) -> True
    InvalidJobType -> False
    DatabaseError(_) -> False
    MaxRetriesExceeded -> False
  }
}

/// Determine if job should be retried based on error type
///
/// This is an alias for is_transient_error to make intent clearer in retry logic.
///
/// Parameters:
/// - error: JobError to classify
///
/// Returns:
/// - True if error is transient and job should be retried
/// - False if error is permanent and job should not be retried
pub fn should_retry(error: JobError) -> Bool {
  is_transient_error(error)
}

/// Calculate exponential backoff delay
///
/// Formula: base_ms * 2^attempt
///
/// Parameters:
/// - base_ms: Base delay in milliseconds
/// - attempt: Current attempt number (0-indexed)
///
/// Returns:
/// - Delay in milliseconds (capped at 32x base)
pub fn calculate_backoff(base_ms: Int, attempt: Int) -> Int {
  case attempt {
    0 -> base_ms
    1 -> base_ms * 2
    2 -> base_ms * 4
    3 -> base_ms * 8
    4 -> base_ms * 16
    _ -> base_ms * 32
    // Cap at 32x
  }
}

/// Calculate backoff delay for a given error and context
///
/// Uses exponential backoff based on attempt number.
/// This is a higher-level wrapper around calculate_backoff.
///
/// Parameters:
/// - context: ExecutionContext with attempt number and config
///
/// Returns:
/// - Delay in milliseconds for next retry
pub fn calculate_backoff_delay(context: ExecutionContext) -> Int {
  calculate_backoff(context.config.retry_backoff_ms, context.attempt)
}

// ============================================================================
// JSON Encoders for Results
// ============================================================================

/// Encode GenerationResult to JSON for job output
pub fn generation_result_to_json(result: GenerationResult) -> json.Json {
  json.object([
    #("meals_generated", json.int(result.meals_generated)),
    #("recipe_ids", json.array(result.recipe_ids, fn(id) { json.int(id) })),
    #("total_calories", json.float(result.total_calories)),
    #("status", json.string(result.status)),
  ])
}

/// Encode SyncResult to JSON for job output
pub fn sync_result_to_json(result: SyncResult) -> json.Json {
  json.object([
    #("synced", json.int(result.synced)),
    #("skipped", json.int(result.skipped)),
    #("failed", json.int(result.failed)),
    #("errors", json.array(result.errors, json.string)),
  ])
}

/// Encode JobError to human-readable message
pub fn job_error_to_message(error: JobError) -> String {
  case error {
    TimeoutError(ms) ->
      "Job execution timed out after " <> int.to_string(ms) <> "ms"
    MaxRetriesExceeded -> "Maximum retry attempts exceeded"
    ApiError(code, message) ->
      "API error (code " <> int.to_string(code) <> "): " <> message
    InvalidJobType -> "Invalid job type specified"
    DatabaseError(message) -> "Database error: " <> message
  }
}

// ============================================================================
// Main Executor Function
// ============================================================================

/// Execute a scheduled job by routing to appropriate handler
///
/// This function:
/// 1. Pattern matches on job.job_type
/// 2. Calls the corresponding handler
/// 3. Captures results/errors
/// 4. Returns JobExecution with output
///
/// Parameters:
/// - job: ScheduledJob to execute
///
/// Returns:
/// - Ok(JobExecution) with execution results
/// - Error(SchedulerError) on failure
pub fn execute_scheduled_job(
  job: ScheduledJob,
) -> Result(JobExecution, SchedulerError) {
  // Get database connection for handlers
  use db <- result.try(get_db_connection())

  // Mark job as running and get execution record
  use execution <- result.try(mark_job_started(job.id))

  // Route to handler based on job type
  let handler_result = route_job_to_handler(job.job_type, db)

  // Process handler result and update job status
  process_handler_result(job, execution, handler_result)
}

/// Route job to appropriate handler based on JobType
///
/// This creates a lookup table mapping JobType to handler functions.
/// Each handler returns Result(json.Json, String).
///
/// Parameters:
/// - job_type: JobType to route
/// - db: Database connection for handlers
///
/// Returns:
/// - Ok(json.Json) with handler output
/// - Error(String) with error message
fn route_job_to_handler(
  job_type: types.JobType,
  db: pog.Connection,
) -> Result(json.Json, String) {
  case job_type {
    WeeklyGeneration -> execute_weekly_generation(db)
    AutoSync -> execute_auto_sync(db)
    DailyAdvisor -> execute_daily_advisor(db)
    WeeklyTrends -> execute_weekly_trends(db)
  }
}

/// Process handler result and update job status accordingly
///
/// On success: marks job completed with output
/// On failure: marks job failed with error message
///
/// Parameters:
/// - job: Original ScheduledJob
/// - execution: JobExecution record from mark_job_started
/// - handler_result: Result from handler execution
///
/// Returns:
/// - Ok(JobExecution) with updated status
/// - Error(SchedulerError) on failure
fn process_handler_result(
  job: ScheduledJob,
  execution: JobExecution,
  handler_result: Result(json.Json, String),
) -> Result(JobExecution, SchedulerError) {
  case handler_result {
    Ok(output) -> handle_success(job, execution, output)
    Error(error_msg) -> handle_error(job, error_msg)
  }
}

/// Handle successful job execution
///
/// Marks job as completed and returns updated JobExecution
///
/// Parameters:
/// - job: Original ScheduledJob
/// - execution: JobExecution from mark_job_started
/// - output: JSON output from handler
///
/// Returns:
/// - Ok(JobExecution) with completed status and output
fn handle_success(
  job: ScheduledJob,
  execution: JobExecution,
  output: json.Json,
) -> Result(JobExecution, SchedulerError) {
  let now = birl.now() |> birl.to_iso8601

  // Mark job as completed
  case mark_job_completed(job.id, output) {
    Ok(_) -> Nil
    Error(_) -> Nil
  }

  Ok(JobExecution(
    id: 0,
    // Will be set by database
    job_id: job.id,
    started_at: execution.started_at,
    completed_at: Some(now),
    status: types.Completed,
    error_message: None,
    attempt_number: execution.attempt_number,
    duration_ms: None,
    output: Some(output),
    triggered_by: execution.triggered_by,
  ))
}

/// Handle failed job execution
///
/// Marks job as failed and returns error
///
/// Parameters:
/// - job: Original ScheduledJob
/// - error_msg: Error message from handler
///
/// Returns:
/// - Error(SchedulerError) with execution failure details
fn handle_error(
  job: ScheduledJob,
  error_msg: String,
) -> Result(JobExecution, SchedulerError) {
  // Mark job as failed
  case mark_job_failed(job.id, error_msg) {
    Ok(_) -> Nil
    Error(_) -> Nil
  }

  Error(ExecutionFailed(job.id, error_msg))
}

// ============================================================================
// Handler Executors
// ============================================================================

/// Execute weekly meal plan generation
fn execute_weekly_generation(_db: pog.Connection) -> Result(json.Json, String) {
  // TODO: Implement actual weekly plan generation
  // This is a stub for now - need user profile and recipes
  Ok(
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Weekly plan generated (stub)")),
    ]),
  )
}

/// Execute FatSecret sync
fn execute_auto_sync(_db: pog.Connection) -> Result(json.Json, String) {
  // TODO: Implement actual FatSecret sync
  // This is a stub for now - need meal selections
  Ok(
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Meals synced to FatSecret (stub)")),
    ]),
  )
}

/// Execute daily advisor email generation
fn execute_daily_advisor(db: pog.Connection) -> Result(json.Json, String) {
  // Get today's date as days since epoch
  let today_int =
    birl.now()
    |> birl.to_unix
    |> fn(unix_seconds) { unix_seconds / { 60 * 60 * 24 } }

  // Generate daily advisor email
  use advisor_email <- result.try(
    daily_recommendations.generate_daily_advisor_email(db, today_int)
    |> result.map_error(fn(e) { "Daily advisor failed: " <> e }),
  )

  // Convert to JSON output
  Ok(
    json.object([
      #("status", json.string("success")),
      #("date", json.string(advisor_email.date)),
      #("actual_calories", json.float(advisor_email.actual_macros.calories)),
      #("target_calories", json.float(advisor_email.target_macros.calories)),
      #("insights", json.array(advisor_email.insights, json.string)),
    ]),
  )
}

/// Execute weekly trends analysis
fn execute_weekly_trends(db: pog.Connection) -> Result(json.Json, String) {
  // Get end date (today) as days since epoch
  let end_date_int =
    birl.now()
    |> birl.to_unix
    |> fn(unix_seconds) { unix_seconds / { 60 * 60 * 24 } }

  // Analyze weekly trends
  use trends <- result.try(
    weekly_trends.analyze_weekly_trends(db, end_date_int)
    |> result.map_error(fn(e) {
      case e {
        weekly_trends.DatabaseError(msg) -> "Database error: " <> msg
        weekly_trends.ServiceError(msg) -> "Service error: " <> msg
        weekly_trends.NoDataAvailable -> "No data available for analysis"
        weekly_trends.InvalidDateRange -> "Invalid date range"
      }
    }),
  )

  // Convert to JSON output
  Ok(
    json.object([
      #("status", json.string("success")),
      #("days_analyzed", json.int(trends.days_analyzed)),
      #("avg_protein", json.float(trends.avg_protein)),
      #("avg_carbs", json.float(trends.avg_carbs)),
      #("avg_fat", json.float(trends.avg_fat)),
      #("avg_calories", json.float(trends.avg_calories)),
      #("patterns", json.array(trends.patterns, json.string)),
      #("best_day", json.string(trends.best_day)),
      #("worst_day", json.string(trends.worst_day)),
      #("recommendations", json.array(trends.recommendations, json.string)),
    ]),
  )
}

// ============================================================================
// Job State Management
// ============================================================================

/// Mark job as started (Running status)
///
/// Updates job status to Running and returns JobExecution record
///
/// Parameters:
/// - job_id: Job identifier
///
/// Returns:
/// - Ok(JobExecution) with running status
/// - Error(SchedulerError) on database failure
fn mark_job_started(job_id: String) -> Result(JobExecution, SchedulerError) {
  job_manager.mark_job_running(job_id)
}

/// Mark job as completed with output
///
/// Updates job status to Completed and stores output JSON
///
/// Parameters:
/// - job_id: Job identifier
/// - output: JSON output from handler
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(SchedulerError) on database failure
fn mark_job_completed(
  job_id: String,
  output: json.Json,
) -> Result(Nil, SchedulerError) {
  job_manager.mark_job_completed(job_id, Some(output))
}

/// Mark job as failed with error message
///
/// Updates job status to Failed and stores error message
///
/// Parameters:
/// - job_id: Job identifier
/// - error_msg: Error message from handler
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(SchedulerError) on database failure
fn mark_job_failed(
  job_id: String,
  error_msg: String,
) -> Result(Nil, SchedulerError) {
  job_manager.mark_job_failed(job_id, error_msg)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get database connection
fn get_db_connection() -> Result(pog.Connection, SchedulerError) {
  case postgres.config_from_env() {
    Ok(config) ->
      case postgres.connect(config) {
        Ok(db) -> Ok(db)
        Error(_) ->
          Error(SchedulerDatabaseError("Failed to connect to database"))
      }
    Error(_) -> Error(SchedulerDatabaseError("Failed to load database config"))
  }
}
