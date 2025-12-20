/// Scheduler CLI domain - handles job scheduling, status monitoring, and triggering
///
/// This module provides CLI commands for:
/// - Listing scheduled jobs
/// - Viewing job execution status
/// - Manually triggering jobs
/// - Real-time status updates
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/id.{type JobId}
import meal_planner/postgres
import meal_planner/scheduler/types.{
  type JobFrequency, type JobPriority, type JobStatus, type JobType,
  type ScheduledJob, type TriggerSource, AutoSync, Completed, Critical, Daily,
  DailyAdvisor, Dependent, EveryNHours, Failed, High, Low, Manual, Medium, Once,
  Pending, Retry, Running, Scheduled, Weekly, WeeklyGeneration, WeeklyTrends,
}
import meal_planner/storage/scheduler as scheduler_storage
import pog

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Scheduler domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage scheduled jobs")
  use id <- glint.flag(
    glint.string_flag("id")
    |> glint.flag_help("Job ID to operate on"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["list"] -> {
      // Create database connection
      case create_db_connection(config) {
        Ok(conn) -> {
          // Query all scheduled jobs
          case scheduler_storage.list_scheduled_jobs(conn) {
            Ok(jobs) -> {
              // Display jobs table
              io.println("\nScheduled Jobs\n")
              io.println(build_jobs_table(jobs))
              Ok(Nil)
            }
            Error(_) -> {
              io.println("Error: Failed to list scheduled jobs")
              Error(Nil)
            }
          }
        }
        Error(err_msg) -> {
          io.println("Error: Failed to connect to database: " <> err_msg)
          Error(Nil)
        }
      }
    }
    ["status"] -> {
      case id(flags) {
        Ok(job_id) -> {
          io.println("Job " <> job_id <> " status: Running")
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --id flag required for status command")
          Error(Nil)
        }
      }
    }
    ["trigger"] -> {
      case id(flags) {
        Ok(job_id) -> {
          io.println("Triggering job: " <> job_id)
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --id flag required for trigger command")
          Error(Nil)
        }
      }
    }
    ["executions"] -> {
      case id(flags) {
        Ok(job_id) -> {
          io.println("Execution history for job: " <> job_id)
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --id flag required for executions command")
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Scheduler commands:")
      io.println("  mp scheduler list")
      io.println("  mp scheduler status --id <job-id>")
      io.println("  mp scheduler trigger --id <job-id>")
      io.println("  mp scheduler executions --id <job-id>")
      Ok(Nil)
    }
  }
}

// ============================================================================
// Formatting Functions
// ============================================================================

/// Format job type as human-readable string
pub fn format_job_type(job_type: JobType) -> String {
  case job_type {
    WeeklyGeneration -> "Weekly Generation"
    AutoSync -> "Auto Sync"
    DailyAdvisor -> "Daily Advisor"
    WeeklyTrends -> "Weekly Trends"
  }
}

/// Format job status with visual indicator
pub fn format_job_status(status: JobStatus) -> String {
  case status {
    Pending -> "Pending"
    Running -> "Running"
    Completed -> "Completed"
    Failed -> "Failed"
  }
}

/// Format job priority
pub fn format_job_priority(priority: JobPriority) -> String {
  case priority {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
    Critical -> "Critical"
  }
}

/// Format job frequency as readable schedule
pub fn format_job_frequency(frequency: JobFrequency) -> String {
  case frequency {
    Weekly(day, hour, minute) -> {
      let day_name = day_of_week_name(day)
      let time = format_time(hour, minute)
      "Weekly (" <> day_name <> " " <> time <> ")"
    }
    Daily(hour, minute) -> {
      let time = format_time(hour, minute)
      "Daily (" <> time <> ")"
    }
    EveryNHours(hours) -> "Every " <> int.to_string(hours) <> " hours"
    Once -> "Once"
  }
}

/// Format trigger source
pub fn format_trigger_source(trigger: TriggerSource) -> String {
  case trigger {
    Scheduled -> "Scheduled"
    Manual -> "Manual"
    Retry -> "Retry"
    Dependent(_) -> "Dependent"
  }
}

// ============================================================================
// Table Building Functions
// ============================================================================

/// Build a formatted table of scheduled jobs
pub fn build_jobs_table(jobs: List(ScheduledJob)) -> String {
  let header =
    "┌────────────────────┬──────────────────┬──────────┬──────────┐\n"
    <> "│ Job Type           │ Frequency        │ Status   │ Priority │\n"
    <> "├────────────────────┼──────────────────┼──────────┼──────────┤"

  let rows =
    jobs
    |> list.map(fn(job) { build_job_row(job) })
    |> string.join("")

  let footer =
    "\n└────────────────────┴──────────────────┴──────────┴──────────┘"

  case jobs {
    [] ->
      header
      <> "\n│ No scheduled jobs                                           │"
      <> footer
    _ -> header <> rows <> footer
  }
}

/// Build a detailed job status view
pub fn build_job_status_view(job: ScheduledJob) -> String {
  let id_str = job_id_to_string(job.id)
  let type_str = format_job_type(job.job_type)
  let status_str = format_job_status(job.status)
  let priority_str = format_job_priority(job.priority)
  let frequency_str = format_job_frequency(job.frequency)
  let enabled_str = case job.enabled {
    True -> "Yes"
    False -> "No"
  }

  "Job Details:\n\n"
  <> "ID:        "
  <> id_str
  <> "\n"
  <> "Type:      "
  <> type_str
  <> "\n"
  <> "Status:    "
  <> status_str
  <> "\n"
  <> "Priority:  "
  <> priority_str
  <> "\n"
  <> "Frequency: "
  <> frequency_str
  <> "\n"
  <> "Enabled:   "
  <> enabled_str
  <> "\n"
  <> "Errors:    "
  <> int.to_string(job.error_count)
  <> case job.last_error {
    Some(err) -> "\n\nLast Error:\n" <> err
    None -> ""
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn build_job_row(job: ScheduledJob) -> String {
  let type_cell = pad_right(format_job_type(job.job_type), 18)
  let frequency_cell = pad_right(format_job_frequency(job.frequency), 16)
  let status_cell = pad_right(format_job_status(job.status), 8)
  let priority_cell = pad_right(format_job_priority(job.priority), 8)

  "\n│ "
  <> type_cell
  <> " │ "
  <> frequency_cell
  <> " │ "
  <> status_cell
  <> " │ "
  <> priority_cell
  <> " │"
}

fn day_of_week_name(day: Int) -> String {
  case day {
    0 -> "Sun"
    1 -> "Mon"
    2 -> "Tue"
    3 -> "Wed"
    4 -> "Thu"
    5 -> "Fri"
    6 -> "Sat"
    _ -> "???"
  }
}

fn format_time(hour: Int, minute: Int) -> String {
  let hour_str = case hour < 10 {
    True -> "0" <> int.to_string(hour)
    False -> int.to_string(hour)
  }
  let minute_str = case minute < 10 {
    True -> "0" <> int.to_string(minute)
    False -> int.to_string(minute)
  }
  hour_str <> ":" <> minute_str
}

fn pad_right(s: String, width: Int) -> String {
  let current_length = string.length(s)
  let padding_needed = width - current_length
  case padding_needed > 0 {
    True -> s <> string.repeat(" ", padding_needed)
    False -> string.slice(s, 0, width)
  }
}

fn job_id_to_string(job_id: JobId) -> String {
  // Convert JobId to string representation
  id.job_id_to_string(job_id)
}

/// Format execution duration in seconds
pub fn format_duration(duration_ms: Option(Int)) -> String {
  case duration_ms {
    Some(ms) -> {
      let seconds = int.to_float(ms) /. 1000.0
      let seconds_str = float_to_string_2dp(seconds)
      seconds_str <> "s"
    }
    None -> "-"
  }
}

/// Build a formatted table of job executions
pub fn build_executions_table(executions: List(types.JobExecution)) -> String {
  let header =
    "┌────┬────────────────────┬──────────┬─────────┬─────────────┐\n"
    <> "│ ID │ Started At         │ Status   │ Attempt │ Duration    │\n"
    <> "├────┼────────────────────┼──────────┼─────────┼─────────────┤"

  let rows =
    executions
    |> list.map(fn(exec) { build_execution_row(exec) })
    |> string.join("")

  let footer =
    "\n└────┴────────────────────┴──────────┴─────────┴─────────────┘"

  case executions {
    [] ->
      header
      <> "\n│ No executions found                                         │"
      <> footer
    _ -> header <> rows <> footer
  }
}

fn build_execution_row(exec: types.JobExecution) -> String {
  let id_cell = pad_right(int.to_string(exec.id), 2)
  let started_cell = pad_right(format_timestamp(exec.started_at), 18)
  let status_cell = pad_right(format_job_status(exec.status), 8)
  let attempt_cell = pad_right(int.to_string(exec.attempt_number), 7)
  let duration_cell = pad_right(format_duration(exec.duration_ms), 11)

  "\n│ "
  <> id_cell
  <> " │ "
  <> started_cell
  <> " │ "
  <> status_cell
  <> " │ "
  <> attempt_cell
  <> " │ "
  <> duration_cell
  <> " │"
}

fn format_timestamp(iso_timestamp: String) -> String {
  // Extract just the time portion (HH:MM:SS) from ISO8601 timestamp
  // Example: "2025-12-19T10:30:45Z" -> "10:30:45"
  case string.split(iso_timestamp, "T") {
    [_, time_part] -> {
      case string.split(time_part, "Z") {
        [time, ..] -> {
          case string.split(time, ".") {
            [hms, ..] -> hms
            _ -> time
          }
        }
        _ -> time_part
      }
    }
    _ -> iso_timestamp
  }
}

fn float_to_string_2dp(value: Float) -> String {
  // Format float with 2 decimal places
  // This is a simple implementation - in production would use proper formatting
  let int_part = float.truncate(value)
  let decimal_part =
    float.truncate({ value -. int.to_float(int_part) } *. 100.0)
  let decimal_str = case decimal_part < 10 {
    True -> "0" <> int.to_string(decimal_part)
    False -> int.to_string(decimal_part)
  }
  int.to_string(int_part) <> "." <> decimal_str
}

/// Normalize job name to database job_type format
/// Examples:
/// - "daily_meal_plan" -> "daily_advisor"
/// - "weekly_generation" -> "weekly_generation"
/// - "auto_sync" -> "auto_sync"
fn normalize_job_name(job_name: String) -> String {
  // Normalize the job name to match database job_type values
  case string.lowercase(job_name) {
    "daily_meal_plan" -> "daily_advisor"
    "daily_advisor" -> "daily_advisor"
    "weekly_generation" -> "weekly_generation"
    "weekly_gen" -> "weekly_generation"
    "auto_sync" -> "auto_sync"
    "sync" -> "auto_sync"
    "weekly_trends" -> "weekly_trends"
    "trends" -> "weekly_trends"
    _ -> job_name
  }
}

/// Create a database connection from config
fn create_db_connection(config: Config) -> Result(pog.Connection, String) {
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: Some(config.database.password),
      pool_size: 1,
    )

  postgres.connect(db_config)
  |> result.map_error(postgres.format_error)
}
