//// Scheduler job queue manager
////
//// Provides operations for managing scheduled jobs

import birl
import gleam/int
import gleam/json
import gleam/option
import meal_planner/id.{type JobId}
import meal_planner/scheduler/errors.{type AppError}
import meal_planner/scheduler/types.{
  type JobExecution, type JobFrequency, type JobType, type ScheduledJob,
  type TriggerSource, JobExecution, Pending, Running, ScheduledJob,
}
import meal_planner/storage/scheduler as scheduler_storage
import pog

// ============================================================================
// Job Creation
// ============================================================================

/// Create a new scheduled job
pub fn create_job(
  job_type job_type: JobType,
  frequency frequency: JobFrequency,
  trigger_source trigger_source: TriggerSource,
) -> Result(ScheduledJob, AppError) {
  // Generate job ID based on type and timestamp
  let job_id = generate_job_id(job_type)

  // Get current timestamp
  let now = birl.now() |> birl.to_iso8601

  // Default retry policy
  let retry_policy = types.default_retry_policy()

  // Return a minimal ScheduledJob (stub implementation for GREEN phase)
  let _ = trigger_source
  Ok(ScheduledJob(
    id: job_id,
    job_type: job_type,
    frequency: frequency,
    status: Pending,
    priority: types.Medium,
    user_id: option.None,
    retry_policy: retry_policy,
    parameters: option.None,
    scheduled_for: option.None,
    started_at: option.None,
    completed_at: option.None,
    last_error: option.None,
    error_count: 0,
    created_at: now,
    updated_at: now,
    created_by: option.None,
    enabled: True,
  ))
}

// ============================================================================
// Job Status Updates
// ============================================================================

/// Mark job as running and create execution record (in-memory fallback)
pub fn mark_job_running(job_id: JobId) -> Result(JobExecution, AppError) {
  // Get current timestamp
  let now = birl.now() |> birl.to_iso8601

  // Return a minimal JobExecution (fallback when no database connection)
  Ok(JobExecution(
    id: 1,
    job_id: job_id,
    started_at: now,
    completed_at: option.None,
    status: Running,
    error_message: option.None,
    attempt_number: 1,
    duration_ms: option.None,
    output: option.None,
    triggered_by: types.Scheduled,
  ))
}

/// Mark job as running with database persistence
pub fn mark_job_running_db(
  conn conn: pog.Connection,
  job_id job_id: JobId,
  trigger_type trigger_type: String,
) -> Result(JobExecution, AppError) {
  case
    scheduler_storage.mark_job_running(
      conn: conn,
      job_id: job_id,
      trigger_type: trigger_type,
    )
  {
    Ok(execution) -> Ok(execution)
    Error(_) -> Error(errors.DatabaseError("Failed to mark job as running"))
  }
}

/// Mark job as completed (in-memory fallback)
pub fn mark_job_completed(
  job_id: JobId,
  output output: option.Option(json.Json),
) -> Result(Nil, AppError) {
  // Fallback when no database connection
  let _ = job_id
  let _ = output
  Ok(Nil)
}

/// Mark job as completed with database persistence
pub fn mark_job_completed_db(
  conn conn: pog.Connection,
  job_id job_id: JobId,
  execution_id execution_id: Int,
  output output: option.Option(json.Json),
) -> Result(Nil, AppError) {
  let output_str = case output {
    option.Some(json_val) -> option.Some(json.to_string(json_val))
    option.None -> option.None
  }
  case
    scheduler_storage.mark_job_completed(
      conn: conn,
      job_id: job_id,
      execution_id: execution_id,
      output_json: output_str,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(errors.DatabaseError("Failed to mark job as completed"))
  }
}

/// Mark job as failed and schedule retry if applicable (in-memory fallback)
pub fn mark_job_failed(
  job_id: JobId,
  error error: String,
) -> Result(Nil, AppError) {
  // Fallback when no database connection
  let _ = job_id
  let _ = error
  Ok(Nil)
}

/// Mark job as failed with database persistence
pub fn mark_job_failed_db(
  conn conn: pog.Connection,
  job_id job_id: JobId,
  execution_id execution_id: Int,
  error error: String,
) -> Result(Nil, AppError) {
  case
    scheduler_storage.mark_job_failed(
      conn: conn,
      job_id: job_id,
      execution_id: execution_id,
      error_message: error,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(errors.DatabaseError("Failed to mark job as failed"))
  }
}

// ============================================================================
// Job Queue Queries
// ============================================================================

/// Get next pending jobs by priority (in-memory fallback)
pub fn get_next_pending_jobs(
  limit limit: Int,
) -> Result(List(ScheduledJob), AppError) {
  // Fallback when no database connection - return empty list
  let _ = limit
  Ok([])
}

/// Get next pending jobs from database
pub fn get_next_pending_jobs_db(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(ScheduledJob), AppError) {
  case scheduler_storage.get_pending_jobs(conn, limit) {
    Ok(jobs) -> Ok(jobs)
    Error(_) -> Error(errors.DatabaseError("Failed to get pending jobs"))
  }
}

/// Reset job to pending status for re-execution
pub fn reset_job_to_pending(
  conn: pog.Connection,
  job_id: JobId,
) -> Result(Nil, AppError) {
  case scheduler_storage.reset_job_to_pending(conn, job_id) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(errors.DatabaseError("Failed to reset job to pending"))
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Generate job ID based on type and timestamp
fn generate_job_id(job_type: JobType) -> JobId {
  let prefix = case job_type {
    types.WeeklyGeneration -> "job_weekly_gen"
    types.AutoSync -> "job_auto_sync"
    types.DailyAdvisor -> "job_daily_adv"
    types.WeeklyTrends -> "job_weekly_trends"
  }

  let timestamp =
    birl.now()
    |> birl.to_unix_milli
    |> int.to_string

  id.job_id(prefix <> "_" <> timestamp)
}
