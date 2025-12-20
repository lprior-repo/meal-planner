//// Scheduler database operations
////
//// Provides database queries for scheduled jobs and job executions

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/id
import meal_planner/scheduler/errors.{type AppError, DatabaseError}
import meal_planner/scheduler/types.{
  type JobExecution, type JobFrequency, type JobPriority, type JobStatus,
  type JobType, type RetryPolicy, type ScheduledJob, type TriggerSource,
  AutoSync, Completed, Critical, Daily, DailyAdvisor, Dependent, EveryNHours,
  Failed, High, JobExecution, Low, Manual, Medium, Once, Pending, RetryPolicy,
  Retry, Running, Scheduled, ScheduledJob, Weekly, WeeklyGeneration,
  WeeklyTrends,
}
import pog

// ============================================================================
// Job Queries
// ============================================================================

/// List all scheduled jobs
pub fn list_jobs(conn: pog.Connection) -> Result(List(ScheduledJob), AppError) {
  let sql =
    "
    SELECT
      id, job_type, frequency_type, frequency_config,
      priority, user_id, parameters,
      status, retry_max_attempts, retry_backoff_seconds, retry_on_failure,
      error_count, last_error,
      scheduled_for, started_at, completed_at,
      enabled, created_at, updated_at, created_by
    FROM scheduled_jobs
    ORDER BY
      CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
      END DESC,
      scheduled_for ASC NULLS FIRST
  "

  pog.query(sql)
  |> pog.returning(decode_scheduled_job())
  |> pog.execute(conn)
  |> result.map(fn(response) { response.rows })
  |> result.map_error(fn(err) {
    DatabaseError("Failed to list jobs: " <> pog_error_to_string(err))
  })
}

/// Get jobs by status
pub fn list_jobs_by_status(
  conn: pog.Connection,
  status: JobStatus,
) -> Result(List(ScheduledJob), AppError) {
  let sql =
    "
    SELECT
      id, job_type, frequency_type, frequency_config,
      priority, user_id, parameters,
      status, retry_max_attempts, retry_backoff_seconds, retry_on_failure,
      error_count, last_error,
      scheduled_for, started_at, completed_at,
      enabled, created_at, updated_at, created_by
    FROM scheduled_jobs
    WHERE status = $1
    ORDER BY
      CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
      END DESC,
      scheduled_for ASC NULLS FIRST
  "

  pog.query(sql)
  |> pog.parameter(pog.text(types.job_status_to_string(status)))
  |> pog.returning(decode_scheduled_job())
  |> pog.execute(conn)
  |> result.map(fn(response) { response.rows })
  |> result.map_error(fn(err) {
    DatabaseError("Failed to list jobs by status: " <> pog_error_to_string(err))
  })
}

/// Get job by ID
pub fn get_job(
  conn: pog.Connection,
  job_id: id.JobId,
) -> Result(ScheduledJob, AppError) {
  let sql =
    "
    SELECT
      id, job_type, frequency_type, frequency_config,
      priority, user_id, parameters,
      status, retry_max_attempts, retry_backoff_seconds, retry_on_failure,
      error_count, last_error,
      scheduled_for, started_at, completed_at,
      enabled, created_at, updated_at, created_by
    FROM scheduled_jobs
    WHERE id = $1
  "

  pog.query(sql)
  |> pog.parameter(pog.text(id.job_id_to_string(job_id)))
  |> pog.returning(decode_scheduled_job())
  |> pog.execute(conn)
  |> result.map(fn(response) {
    case response.rows {
      [job] -> Ok(job)
      [] -> Error(errors.NotFound("Job not found"))
      _ -> Error(errors.DatabaseError("Multiple jobs found with same ID"))
    }
  })
  |> result.flatten
}

/// Get job executions for a specific job
pub fn list_job_executions(
  conn: pog.Connection,
  job_id: id.JobId,
  limit: Int,
) -> Result(List(JobExecution), AppError) {
  let sql =
    "
    SELECT
      id, job_id, started_at, completed_at,
      status, error_message, attempt_number,
      duration_ms, output, trigger_type, parent_job_id
    FROM job_executions
    WHERE job_id = $1
    ORDER BY started_at DESC
    LIMIT $2
  "

  pog.query(sql)
  |> pog.parameter(pog.text(id.job_id_to_string(job_id)))
  |> pog.parameter(pog.int(limit))
  |> pog.returning(decode_job_execution())
  |> pog.execute(conn)
  |> result.map(fn(response) { response.rows })
  |> result.map_error(fn(err) {
    DatabaseError(
      "Failed to list job executions: " <> pog_error_to_string(err),
    )
  })
}

// ============================================================================
// Decoders
// ============================================================================

fn decode_scheduled_job() -> decode.Decoder(ScheduledJob) {
  use id <- decode.field("id", decode.string)
  use job_type <- decode.field("job_type", decode.string)
  use frequency_type <- decode.field("frequency_type", decode.string)
  use frequency_config <- decode.field("frequency_config", decode.string)
  use priority <- decode.field("priority", decode.string)
  use user_id <- decode.field("user_id", decode.optional(decode.string))
  use parameters <- decode.field("parameters", decode.optional(decode.string))
  use status <- decode.field("status", decode.string)
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

  // Parse job type
  let job_type_parsed = case job_type {
    "weekly_generation" -> WeeklyGeneration
    "auto_sync" -> AutoSync
    "daily_advisor" -> DailyAdvisor
    "weekly_trends" -> WeeklyTrends
    _ -> WeeklyGeneration
  }

  // Parse frequency from JSON config
  let frequency_parsed = parse_frequency(frequency_type, frequency_config)

  // Parse status
  let status_parsed = case status {
    "pending" -> Pending
    "running" -> Running
    "completed" -> Completed
    "failed" -> Failed
    _ -> Pending
  }

  // Parse priority
  let priority_parsed = case priority {
    "low" -> Low
    "medium" -> Medium
    "high" -> High
    "critical" -> Critical
    _ -> Medium
  }

  // Build retry policy
  let retry_policy =
    RetryPolicy(
      max_attempts: retry_max_attempts,
      backoff_seconds: retry_backoff_seconds,
      retry_on_failure: retry_on_failure,
    )

  // Parse parameters
  let parameters_parsed = case parameters {
    Some(json_str) ->
      case json.decode(json_str, decode.dynamic) {
        Ok(value) -> Some(value)
        Error(_) -> None
      }
    None -> None
  }

  // Parse user_id
  let user_id_parsed = case user_id {
    Some(uid) -> Some(id.user_id(uid))
    None -> None
  }

  // Parse created_by
  let created_by_parsed = case created_by {
    Some(uid) -> Some(id.user_id(uid))
    None -> None
  }

  decode.success(ScheduledJob(
    id: id.job_id(id),
    job_type: job_type_parsed,
    frequency: frequency_parsed,
    status: status_parsed,
    priority: priority_parsed,
    user_id: user_id_parsed,
    retry_policy: retry_policy,
    parameters: parameters_parsed,
    scheduled_for: scheduled_for,
    started_at: started_at,
    completed_at: completed_at,
    last_error: last_error,
    error_count: error_count,
    created_at: created_at,
    updated_at: updated_at,
    created_by: created_by_parsed,
    enabled: enabled,
  ))
}

fn decode_job_execution() -> decode.Decoder(JobExecution) {
  use exec_id <- decode.field("id", decode.int)
  use job_id <- decode.field("job_id", decode.string)
  use started_at <- decode.field("started_at", decode.string)
  use completed_at <- decode.field("completed_at", decode.optional(decode.string))
  use status <- decode.field("status", decode.string)
  use error_message <- decode.field(
    "error_message",
    decode.optional(decode.string),
  )
  use attempt_number <- decode.field("attempt_number", decode.int)
  use duration_ms <- decode.field("duration_ms", decode.optional(decode.int))
  use output <- decode.field("output", decode.optional(decode.string))
  use trigger_type <- decode.field("trigger_type", decode.string)
  use parent_job_id <- decode.field(
    "parent_job_id",
    decode.optional(decode.string),
  )

  // Parse status
  let status_parsed = case status {
    "running" -> Running
    "completed" -> Completed
    "failed" -> Failed
    _ -> Running
  }

  // Parse trigger type
  let trigger_parsed = case trigger_type {
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

  // Parse output
  let output_parsed = case output {
    Some(json_str) ->
      case json.decode(json_str, decode.dynamic) {
        Ok(value) -> Some(value)
        Error(_) -> None
      }
    None -> None
  }

  decode.success(JobExecution(
    id: exec_id,
    job_id: id.job_id(job_id),
    started_at: started_at,
    completed_at: completed_at,
    status: status_parsed,
    error_message: error_message,
    attempt_number: attempt_number,
    duration_ms: duration_ms,
    output: output_parsed,
    triggered_by: trigger_parsed,
  ))
}

// ============================================================================
// Helper Functions
// ============================================================================

fn parse_frequency(frequency_type: String, config_json: String) -> JobFrequency {
  case frequency_type {
    "weekly" -> {
      // Parse {"day": 5, "hour": 6, "minute": 0}
      let decoder = {
        use day <- decode.field("day", decode.int)
        use hour <- decode.field("hour", decode.int)
        use minute <- decode.field("minute", decode.int)
        decode.success(Weekly(day: day, hour: hour, minute: minute))
      }
      case json.decode(config_json, decoder) {
        Ok(freq) -> freq
        Error(_) -> Once
      }
    }
    "daily" -> {
      // Parse {"hour": 20, "minute": 0}
      let decoder = {
        use hour <- decode.field("hour", decode.int)
        use minute <- decode.field("minute", decode.int)
        decode.success(Daily(hour: hour, minute: minute))
      }
      case json.decode(config_json, decoder) {
        Ok(freq) -> freq
        Error(_) -> Once
      }
    }
    "every_n_hours" -> {
      // Parse {"hours": 4}
      let decoder = {
        use hours <- decode.field("hours", decode.int)
        decode.success(EveryNHours(hours: hours))
      }
      case json.decode(config_json, decoder) {
        Ok(freq) -> freq
        Error(_) -> Once
      }
    }
    "once" -> Once
    _ -> Once
  }
}

fn pog_error_to_string(err: pog.QueryError) -> String {
  case err {
    pog.ConstraintViolated(message, ..) -> "Constraint violated: " <> message
    pog.PostgresqlError(code, name, message) ->
      "PostgreSQL error " <> code <> " (" <> name <> "): " <> message
    pog.UnexpectedArgumentCount(expected, got) ->
      "Expected "
      <> int_to_string(expected)
      <> " arguments, got "
      <> int_to_string(got)
    pog.UnexpectedArgumentType(expected, got) ->
      "Expected argument type " <> expected <> ", got " <> got
    pog.UnexpectedResultType(decode_errors) ->
      "Failed to decode result: "
      <> list.fold(decode_errors, "", fn(acc, err) {
        acc <> decode_error_to_string(err) <> "; "
      })
    pog.ConnectionUnavailable -> "Database connection unavailable"
  }
}

fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ ->
      case i < 0 {
        True -> "-" <> int_to_string(-i)
        False -> {
          let digit = i % 10
          let rest = i / 10
          int_to_string(rest) <> int_to_string(digit)
        }
      }
  }
}

fn decode_error_to_string(err: decode.DecodeError) -> String {
  case err {
    decode.UnexpectedFormat(errors) ->
      "Unexpected format: "
      <> list.fold(errors, "", fn(acc, e) {
        acc <> decode_error_to_string(e) <> "; "
      })
    decode.UnexpectedByte(byte) -> "Unexpected byte: " <> int_to_string(byte)
    decode.UnexpectedEndOfInput -> "Unexpected end of input"
    decode.UnexpectedSequence(expected, found) ->
      "Expected " <> expected <> ", found " <> found
  }
}
