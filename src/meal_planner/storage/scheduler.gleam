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
  type JobExecution, type JobFrequency, type JobPriority, type JobStatus,
  type JobType, type ScheduledJob, AutoSync, Completed, Critical, Daily,
  DailyAdvisor, Dependent, EveryNHours, Failed, High, JobExecution, Low, Manual,
  Medium, Once, Pending, Retry, RetryPolicy, Running, Scheduled, ScheduledJob,
  Weekly, WeeklyGeneration, WeeklyTrends,
}
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import pog

// ============================================================================
// Decoders (Must be defined before use)
// ============================================================================

/// Decode JobType from database string
fn job_type_decoder() -> decode.Decoder(JobType) {
  use s <- decode.then(decode.string)
  case s {
    "weekly_generation" -> decode.success(WeeklyGeneration)
    "auto_sync" -> decode.success(AutoSync)
    "daily_advisor" -> decode.success(DailyAdvisor)
    "weekly_trends" -> decode.success(WeeklyTrends)
    _ -> decode.failure(WeeklyGeneration, "JobType")
  }
}

/// Decode JobStatus from database string
fn job_status_decoder() -> decode.Decoder(JobStatus) {
  use s <- decode.then(decode.string)
  case s {
    "pending" -> decode.success(Pending)
    "running" -> decode.success(Running)
    "completed" -> decode.success(Completed)
    "failed" -> decode.success(Failed)
    _ -> decode.failure(Pending, "JobStatus")
  }
}

/// Decode JobPriority from database string
fn job_priority_decoder() -> decode.Decoder(JobPriority) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    "critical" -> decode.success(Critical)
    _ -> decode.failure(Medium, "JobPriority")
  }
}

/// Decode JobFrequency from database frequency_config
fn job_frequency_from_config_decoder() -> decode.Decoder(JobFrequency) {
  use day <- decode.field("day", decode.optional(decode.int))
  use hour <- decode.field("hour", decode.optional(decode.int))
  use minute <- decode.field("minute", decode.optional(decode.int))
  use hours <- decode.field("hours", decode.optional(decode.int))

  case day, hour, minute, hours {
    Some(d), Some(h), Some(m), None -> decode.success(Weekly(d, h, m))
    None, Some(h), Some(m), None -> decode.success(Daily(h, m))
    None, None, None, Some(hrs) -> decode.success(EveryNHours(hrs))
    _, _, _, _ -> decode.success(Once)
  }
}

/// Decode ScheduledJob from database row
fn scheduled_job_decoder() -> decode.Decoder(ScheduledJob) {
  use job_id <- decode.field("id", decode.string)
  use job_type <- decode.field("job_type", job_type_decoder())
  use _frequency_type <- decode.field("frequency_type", decode.string)
  use frequency_config <- decode.field("frequency_config", decode.dynamic)
  use priority <- decode.field("priority", job_priority_decoder())
  use user_id <- decode.field("user_id", decode.optional(decode.string))
  use _parameters <- decode.field("parameters", decode.optional(decode.dynamic))
  use status <- decode.field("status", job_status_decoder())
  use retry_max_attempts <- decode.field("retry_max_attempts", decode.int)
  use retry_backoff_seconds <- decode.field("retry_backoff_seconds", decode.int)
  use retry_on_failure <- decode.field("retry_on_failure", decode.bool)
  use error_count <- decode.field("error_count", decode.int)
  use last_error <- decode.field("last_error", decode.optional(decode.string))
  use scheduled_for <- decode.field(
    "scheduled_for",
    decode.optional(decode.string),
  )
  use started_at <- decode.field("started_at", decode.optional(decode.string))
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )
  use enabled <- decode.field("enabled", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use created_by <- decode.field("created_by", decode.optional(decode.string))

  // Decode frequency from config
  let frequency = case
    decode.run(frequency_config, job_frequency_from_config_decoder())
  {
    Ok(freq) -> freq
    Error(_) -> Once
  }

  decode.success(ScheduledJob(
    id: id.job_id(job_id),
    job_type: job_type,
    frequency: frequency,
    status: status,
    priority: priority,
    user_id: case user_id {
      Some(uid) -> Some(id.user_id(uid))
      None -> None
    },
    retry_policy: RetryPolicy(
      max_attempts: retry_max_attempts,
      backoff_seconds: retry_backoff_seconds,
      retry_on_failure: retry_on_failure,
    ),
    parameters: None,
    scheduled_for: scheduled_for,
    started_at: started_at,
    completed_at: completed_at,
    last_error: last_error,
    error_count: error_count,
    created_at: created_at,
    updated_at: updated_at,
    created_by: case created_by {
      Some(uid) -> Some(id.user_id(uid))
      None -> None
    },
    enabled: enabled,
  ))
}

/// Decode JobExecution from database row
fn job_execution_decoder() -> decode.Decoder(JobExecution) {
  use exec_id <- decode.field("id", decode.int)
  use job_id <- decode.field("job_id", decode.string)
  use started_at <- decode.field("started_at", decode.string)
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )
  use status <- decode.field("status", job_status_decoder())
  use error_message <- decode.field(
    "error_message",
    decode.optional(decode.string),
  )
  use attempt_number <- decode.field("attempt_number", decode.int)
  use duration_ms <- decode.field("duration_ms", decode.optional(decode.int))
  use _output <- decode.field("output", decode.optional(decode.dynamic))
  use trigger_type <- decode.field("trigger_type", decode.string)
  use parent_job_id <- decode.field(
    "parent_job_id",
    decode.optional(decode.string),
  )

  let triggered_by = case trigger_type {
    "scheduled" -> Scheduled
    "manual" -> Manual
    "retry" -> Retry
    "dependent" ->
      case parent_job_id {
        Some(pid) -> Dependent(id.job_id(pid))
        None -> Scheduled
      }
    _ -> Scheduled
  }

  decode.success(JobExecution(
    id: exec_id,
    job_id: id.job_id(job_id),
    started_at: started_at,
    completed_at: completed_at,
    status: status,
    error_message: error_message,
    attempt_number: attempt_number,
    duration_ms: duration_ms,
    output: None,
    triggered_by: triggered_by,
  ))
}

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
