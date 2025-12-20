/// PostgreSQL storage for scheduler jobs
///
/// This module provides database operations for scheduled jobs:
/// - Listing all scheduled jobs
/// - Enabling/disabling jobs
/// - Querying job status
import gleam/dynamic/decode
import gleam/option.{None, Some}
import meal_planner/id.{type JobId}
import meal_planner/scheduler/types.{
  type JobExecution, type JobFrequency, type JobStatus, type JobType,
  type RetryPolicy, type ScheduledJob, type TriggerSource, AutoSync, Completed,
  Critical, Daily, DailyAdvisor, Dependent, EveryNHours, Failed, High,
  JobExecution, Low, Manual, Medium, Once, Pending, Retry, RetryPolicy, Running,
  Scheduled, ScheduledJob, Weekly, WeeklyGeneration, WeeklyTrends,
}
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import pog

// ============================================================================
// Job Queries
// ============================================================================

/// List all scheduled jobs
pub fn list_scheduled_jobs(
  conn: pog.Connection,
) -> Result(List(ScheduledJob), StorageError) {
  let sql =
    "SELECT id, job_type, frequency_type, frequency_config, priority, user_id,
            parameters, status, retry_max_attempts, retry_backoff_seconds,
            retry_on_failure, error_count, last_error, scheduled_for::text,
            started_at::text, completed_at::text, enabled, created_at::text,
            updated_at::text, created_by
     FROM scheduled_jobs
     ORDER BY
       CASE priority
         WHEN 'critical' THEN 4
         WHEN 'high' THEN 3
         WHEN 'medium' THEN 2
         WHEN 'low' THEN 1
       END DESC,
       scheduled_for ASC NULLS LAST"

  let decoder = scheduled_job_decoder()

  case
    pog.query(sql)
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get a specific scheduled job by ID
pub fn get_scheduled_job(
  conn: pog.Connection,
  job_id: JobId,
) -> Result(ScheduledJob, StorageError) {
  let sql =
    "SELECT id, job_type, frequency_type, frequency_config, priority, user_id,
            parameters, status, retry_max_attempts, retry_backoff_seconds,
            retry_on_failure, error_count, last_error, scheduled_for::text,
            started_at::text, completed_at::text, enabled, created_at::text,
            updated_at::text, created_by
     FROM scheduled_jobs
     WHERE id = $1"

  let decoder = scheduled_job_decoder()

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.job_id_to_string(job_id)))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [])) -> Error(profile.NotFound)
    Ok(pog.Returned(_, [job])) -> Ok(job)
    Ok(pog.Returned(_, _)) -> Error(DatabaseError("Multiple rows returned"))
  }
}

/// Get execution history for a job
pub fn get_job_executions(
  conn: pog.Connection,
  job_id: JobId,
  limit: Int,
) -> Result(List(JobExecution), StorageError) {
  let sql =
    "SELECT id, job_id, started_at::text, completed_at::text, status,
            error_message, attempt_number, duration_ms, output, trigger_type,
            parent_job_id
     FROM job_executions
     WHERE job_id = $1
     ORDER BY started_at DESC
     LIMIT $2"

  let decoder = job_execution_decoder()

  case
    pog.query(sql)
    |> pog.parameter(pog.text(id.job_id_to_string(job_id)))
    |> pog.parameter(pog.int(limit))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

// ============================================================================
// Job Enable/Disable Operations
// ============================================================================

/// Enable a scheduled job by job type name
pub fn enable_job(
  conn: pog.Connection,
  job_type_name: String,
) -> Result(Nil, StorageError) {
  let sql =
    "UPDATE scheduled_jobs
     SET enabled = true, updated_at = NOW()
     WHERE job_type = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(job_type_name))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Disable a scheduled job by job type name
pub fn disable_job(
  conn: pog.Connection,
  job_type_name: String,
) -> Result(Nil, StorageError) {
  let sql =
    "UPDATE scheduled_jobs
     SET enabled = false, updated_at = NOW()
     WHERE job_type = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(job_type_name))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}
