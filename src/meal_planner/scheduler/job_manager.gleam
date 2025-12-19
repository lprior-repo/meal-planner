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

/// Mark job as running and create execution record
pub fn mark_job_running(job_id: JobId) -> Result(JobExecution, AppError) {
  // Get current timestamp
  let now = birl.now() |> birl.to_iso8601

  // Return a minimal JobExecution (stub implementation for GREEN phase)
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

/// Mark job as completed
pub fn mark_job_completed(
  job_id: JobId,
  output output: option.Option(json.Json),
) -> Result(Nil, AppError) {
  // Stub implementation for GREEN phase
  let _ = job_id
  let _ = output
  Ok(Nil)
}

/// Mark job as failed and schedule retry if applicable
pub fn mark_job_failed(
  job_id: JobId,
  error error: String,
) -> Result(Nil, AppError) {
  // Stub implementation for GREEN phase
  let _ = job_id
  let _ = error
  Ok(Nil)
}

// ============================================================================
// Job Queue Queries
// ============================================================================

/// Get next pending jobs by priority
pub fn get_next_pending_jobs(
  limit limit: Int,
) -> Result(List(ScheduledJob), AppError) {
  // Stub implementation for GREEN phase - return empty list
  let _ = limit
  Ok([])
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
