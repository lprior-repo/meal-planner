/// Scheduler CLI domain - handles job scheduling, status monitoring, and triggering
///
/// This module provides TUI commands for:
/// - Listing scheduled jobs
/// - Viewing job execution status
/// - Manually triggering jobs
/// - Real-time status updates
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/id.{type JobId}
import meal_planner/scheduler/types.{
  type JobFrequency, type JobPriority, type JobStatus, type JobType,
  type ScheduledJob, type TriggerSource, AutoSync, Completed, Critical, Daily,
  DailyAdvisor, Dependent, EveryNHours, Failed, High, Low, Manual, Medium, Once,
  Pending, Retry, Running, Scheduled, Weekly, WeeklyGeneration, WeeklyTrends,
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
