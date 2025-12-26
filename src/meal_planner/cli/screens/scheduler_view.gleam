/// Scheduler View Screen - Complete TUI Implementation
///
/// This module implements the scheduler/job management screen following
/// Shore Framework (Elm Architecture) for viewing and managing scheduled tasks.
///
/// SCREEN FEATURES:
/// - View all scheduled jobs
/// - View job execution history
/// - Enable/disable jobs
/// - Manually trigger job execution
/// - View job logs and results
/// - Configure job schedules
///
/// ARCHITECTURE:
/// - Model: SchedulerModel (state container)
/// - Msg: SchedulerMsg (all possible events)
/// - Update: scheduler_update (state transitions)
/// - View: scheduler_view (rendering)
import birl
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import meal_planner/id
import meal_planner/scheduler/types as scheduler_types
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Root state for the Scheduler TUI screen
pub type SchedulerModel {
  SchedulerModel(
    /// Current view state
    view_state: SchedulerViewState,
    /// List of scheduled jobs
    jobs: List(JobDisplayEntry),
    /// Selected job for details
    selected_job: Option(JobDetails),
    /// Execution history for selected job
    execution_history: List(ExecutionDisplayEntry),
    /// Filter state
    filter: JobFilter,
    /// Loading state
    is_loading: Bool,
    /// Error message
    error_message: Option(String),
    /// Job being configured
    config_state: Option(JobConfigState),
    /// Current time for display
    current_time: Int,
    /// Auto-refresh enabled
    auto_refresh: Bool,
  )
}

/// View state machine
pub type SchedulerViewState {
  /// Job list view
  ListView
  /// Job details view
  DetailsView
  /// Execution history view
  HistoryView
  /// Job configuration view
  ConfigView
  /// Logs view for specific execution
  LogsView(execution_id: String)
  /// Run job confirmation
  RunConfirmView(job_id: String)
  /// Delete job confirmation
  DeleteConfirmView(job_id: String)
}

/// Job display entry
pub type JobDisplayEntry {
  JobDisplayEntry(
    job: scheduler_types.ScheduledJob,
    /// Formatted name
    name_display: String,
    /// Status indicator
    status_display: String,
    /// Next run time display
    next_run_display: String,
    /// Last run display
    last_run_display: String,
    /// Success rate display
    success_rate_display: String,
  )
}

/// Job details
pub type JobDetails {
  JobDetails(
    job: scheduler_types.ScheduledJob,
    /// Execution statistics
    total_executions: Int,
    successful_executions: Int,
    failed_executions: Int,
    average_duration_ms: Int,
    last_error: Option(String),
    /// Configuration
    schedule_expression: String,
    timeout_seconds: Int,
    retry_count: Int,
    /// Metadata
    created_at: Int,
    updated_at: Int,
  )
}

/// Execution display entry
pub type ExecutionDisplayEntry {
  ExecutionDisplayEntry(
    execution: scheduler_types.JobExecution,
    /// Formatted time
    started_at_display: String,
    /// Duration display
    duration_display: String,
    /// Status display
    status_display: String,
    /// Result summary
    result_summary: String,
  )
}

/// Job filter options
pub type JobFilter {
  JobFilter(
    /// Show only enabled jobs
    enabled_only: Bool,
    /// Show only failed jobs
    failed_only: Bool,
    /// Job type filter
    job_type: Option(JobType),
    /// Search query
    search_query: String,
    /// Sort option
    sort_by: JobSortOption,
  )
}

/// Job types
pub type JobType {
  SyncJob
  AnalysisJob
  NotificationJob
  CleanupJob
  ReportJob
}

/// Job sort options
pub type JobSortOption {
  SortByName
  SortByNextRun
  SortByLastRun
  SortByStatus
}

/// Job configuration state
pub type JobConfigState {
  JobConfigState(
    job_id: String,
    /// Schedule expression
    schedule: String,
    /// Timeout in seconds
    timeout: Int,
    /// Retry count
    retries: Int,
    /// Enabled state
    enabled: Bool,
    /// Original values
    original_schedule: String,
    original_timeout: Int,
    original_retries: Int,
  )
}

/// Messages for the scheduler screen
pub type SchedulerMsg {
  // Navigation
  ShowListView
  ShowDetailsView(job_id: String)
  ShowHistoryView(job_id: String)
  ShowConfigView(job_id: String)
  ShowLogsView(execution_id: String)
  ShowRunConfirm(job_id: String)
  ShowDeleteConfirm(job_id: String)
  GoBack

  // Job Actions
  EnableJob(job_id: String)
  DisableJob(job_id: String)
  RunJobNow(job_id: String)
  ConfirmRunJob
  CancelRunJob
  DeleteJob(job_id: String)
  ConfirmDeleteJob
  CancelDeleteJob

  // Configuration
  ConfigScheduleChanged(schedule: String)
  ConfigTimeoutChanged(timeout: Int)
  ConfigRetriesChanged(retries: Int)
  ConfigEnabledChanged(enabled: Bool)
  SaveConfig
  CancelConfig

  // Filtering
  SetEnabledOnly(enabled: Bool)
  SetFailedOnly(failed: Bool)
  SetJobTypeFilter(job_type: Option(JobType))
  SetSearchQuery(query: String)
  SetSortBy(sort: JobSortOption)
  ClearFilters

  // Data Loading
  GotJobs(Result(List(scheduler_types.ScheduledJob), String))
  GotJobDetails(Result(JobDetails, String))
  GotExecutionHistory(Result(List(scheduler_types.JobExecution), String))
  JobEnabled(Result(Nil, String))
  JobDisabled(Result(Nil, String))
  JobTriggered(Result(scheduler_types.JobExecution, String))
  JobDeleted(Result(Nil, String))
  ConfigSaved(Result(Nil, String))

  // UI
  ToggleAutoRefresh
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

/// Effects for the scheduler screen
pub type SchedulerEffect {
  NoEffect
  FetchJobs(filter: JobFilter)
  FetchJobDetails(job_id: String)
  FetchExecutionHistory(job_id: String, limit: Int)
  EnableJobEffect(job_id: String)
  DisableJobEffect(job_id: String)
  TriggerJobEffect(job_id: String)
  DeleteJobEffect(job_id: String)
  SaveConfigEffect(job_id: String, schedule: String, timeout: Int, retries: Int)
  BatchEffects(effects: List(SchedulerEffect))
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial SchedulerModel
pub fn init() -> SchedulerModel {
  SchedulerModel(
    view_state: ListView,
    jobs: [],
    selected_job: None,
    execution_history: [],
    filter: default_filter(),
    is_loading: False,
    error_message: None,
    config_state: None,
    current_time: get_current_time(),
    auto_refresh: False,
  )
}

/// Default filter
fn default_filter() -> JobFilter {
  JobFilter(
    enabled_only: False,
    failed_only: False,
    job_type: None,
    search_query: "",
    sort_by: SortByName,
  )
}

/// Get current time as Unix timestamp
fn get_current_time() -> Int {
  birl.now()
  |> birl.to_unix
}

// ============================================================================
// Update Function
// ============================================================================

/// Main update function for scheduler view
pub fn scheduler_update(
  model: SchedulerModel,
  msg: SchedulerMsg,
) -> #(SchedulerModel, SchedulerEffect) {
  case msg {
    // === Navigation ===
    ShowListView -> {
      let updated = SchedulerModel(..model, view_state: ListView)
      #(updated, FetchJobs(model.filter))
    }

    ShowDetailsView(job_id) -> {
      let updated =
        SchedulerModel(..model, view_state: DetailsView, is_loading: True)
      #(updated, FetchJobDetails(job_id))
    }

    ShowHistoryView(job_id) -> {
      let updated =
        SchedulerModel(..model, view_state: HistoryView, is_loading: True)
      #(updated, FetchExecutionHistory(job_id, 50))
    }

    ShowConfigView(job_id) -> {
      // Find job to initialize config
      let config = case
        list.find(model.jobs, fn(entry) {
          id.job_id_to_string(entry.job.id) == job_id
        })
      {
        Ok(job_entry) -> {
          let schedule = format_frequency(job_entry.job.frequency)
          Some(JobConfigState(
            job_id: job_id,
            schedule: schedule,
            timeout: job_entry.job.retry_policy.backoff_seconds,
            retries: job_entry.job.retry_policy.max_attempts,
            enabled: job_entry.job.enabled,
            original_schedule: schedule,
            original_timeout: job_entry.job.retry_policy.backoff_seconds,
            original_retries: job_entry.job.retry_policy.max_attempts,
          ))
        }
        Error(_) -> None
      }
      let updated =
        SchedulerModel(..model, view_state: ConfigView, config_state: config)
      #(updated, NoEffect)
    }

    ShowLogsView(execution_id) -> {
      let updated = SchedulerModel(..model, view_state: LogsView(execution_id))
      #(updated, NoEffect)
    }

    ShowRunConfirm(job_id) -> {
      let updated = SchedulerModel(..model, view_state: RunConfirmView(job_id))
      #(updated, NoEffect)
    }

    ShowDeleteConfirm(job_id) -> {
      let updated =
        SchedulerModel(..model, view_state: DeleteConfirmView(job_id))
      #(updated, NoEffect)
    }

    GoBack -> {
      case model.view_state {
        ListView -> #(model, NoEffect)
        DetailsView | HistoryView -> {
          let updated =
            SchedulerModel(..model, view_state: ListView, selected_job: None)
          #(updated, NoEffect)
        }
        ConfigView -> {
          let updated =
            SchedulerModel(..model, view_state: DetailsView, config_state: None)
          #(updated, NoEffect)
        }
        LogsView(_) -> {
          let updated = SchedulerModel(..model, view_state: HistoryView)
          #(updated, NoEffect)
        }
        RunConfirmView(_) | DeleteConfirmView(_) -> {
          let updated = SchedulerModel(..model, view_state: DetailsView)
          #(updated, NoEffect)
        }
      }
    }

    // === Job Actions ===
    EnableJob(job_id) -> {
      let updated = SchedulerModel(..model, is_loading: True)
      #(updated, EnableJobEffect(job_id))
    }

    DisableJob(job_id) -> {
      let updated = SchedulerModel(..model, is_loading: True)
      #(updated, DisableJobEffect(job_id))
    }

    RunJobNow(job_id) -> {
      scheduler_update(model, ShowRunConfirm(job_id))
    }

    ConfirmRunJob -> {
      case model.view_state {
        RunConfirmView(job_id) -> {
          let updated =
            SchedulerModel(..model, view_state: DetailsView, is_loading: True)
          #(updated, TriggerJobEffect(job_id))
        }
        _ -> #(model, NoEffect)
      }
    }

    CancelRunJob -> {
      let updated = SchedulerModel(..model, view_state: DetailsView)
      #(updated, NoEffect)
    }

    DeleteJob(job_id) -> {
      scheduler_update(model, ShowDeleteConfirm(job_id))
    }

    ConfirmDeleteJob -> {
      case model.view_state {
        DeleteConfirmView(job_id) -> {
          let updated =
            SchedulerModel(..model, view_state: ListView, is_loading: True)
          #(updated, DeleteJobEffect(job_id))
        }
        _ -> #(model, NoEffect)
      }
    }

    CancelDeleteJob -> {
      let updated = SchedulerModel(..model, view_state: DetailsView)
      #(updated, NoEffect)
    }

    // === Configuration ===
    ConfigScheduleChanged(schedule) -> {
      case model.config_state {
        Some(config) -> {
          let new_config = JobConfigState(..config, schedule: schedule)
          let updated = SchedulerModel(..model, config_state: Some(new_config))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    ConfigTimeoutChanged(timeout) -> {
      case model.config_state {
        Some(config) -> {
          let new_config = JobConfigState(..config, timeout: timeout)
          let updated = SchedulerModel(..model, config_state: Some(new_config))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    ConfigRetriesChanged(retries) -> {
      case model.config_state {
        Some(config) -> {
          let new_config = JobConfigState(..config, retries: retries)
          let updated = SchedulerModel(..model, config_state: Some(new_config))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    ConfigEnabledChanged(enabled) -> {
      case model.config_state {
        Some(config) -> {
          let new_config = JobConfigState(..config, enabled: enabled)
          let updated = SchedulerModel(..model, config_state: Some(new_config))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    SaveConfig -> {
      case model.config_state {
        Some(config) -> {
          let updated =
            SchedulerModel(
              ..model,
              view_state: DetailsView,
              config_state: None,
              is_loading: True,
            )
          let effect =
            SaveConfigEffect(
              config.job_id,
              config.schedule,
              config.timeout,
              config.retries,
            )
          #(updated, effect)
        }
        None -> #(model, NoEffect)
      }
    }

    CancelConfig -> {
      let updated =
        SchedulerModel(..model, view_state: DetailsView, config_state: None)
      #(updated, NoEffect)
    }

    // === Filtering ===
    SetEnabledOnly(enabled) -> {
      let filter = JobFilter(..model.filter, enabled_only: enabled)
      let updated = SchedulerModel(..model, filter: filter, is_loading: True)
      #(updated, FetchJobs(filter))
    }

    SetFailedOnly(failed) -> {
      let filter = JobFilter(..model.filter, failed_only: failed)
      let updated = SchedulerModel(..model, filter: filter, is_loading: True)
      #(updated, FetchJobs(filter))
    }

    SetJobTypeFilter(job_type) -> {
      let filter = JobFilter(..model.filter, job_type: job_type)
      let updated = SchedulerModel(..model, filter: filter, is_loading: True)
      #(updated, FetchJobs(filter))
    }

    SetSearchQuery(query) -> {
      let filter = JobFilter(..model.filter, search_query: query)
      let updated = SchedulerModel(..model, filter: filter)
      // Don't fetch immediately on every keystroke
      #(updated, NoEffect)
    }

    SetSortBy(sort) -> {
      let filter = JobFilter(..model.filter, sort_by: sort)
      let jobs = sort_jobs(model.jobs, sort)
      let updated = SchedulerModel(..model, filter: filter, jobs: jobs)
      #(updated, NoEffect)
    }

    ClearFilters -> {
      let filter = default_filter()
      let updated = SchedulerModel(..model, filter: filter, is_loading: True)
      #(updated, FetchJobs(filter))
    }

    // === Data Loading ===
    GotJobs(result) -> {
      case result {
        Ok(jobs) -> {
          let display_jobs = format_jobs(jobs, model.current_time)
          let sorted = sort_jobs(display_jobs, model.filter.sort_by)
          let updated = SchedulerModel(..model, jobs: sorted, is_loading: False)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    GotJobDetails(result) -> {
      case result {
        Ok(details) -> {
          let updated =
            SchedulerModel(
              ..model,
              selected_job: Some(details),
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    GotExecutionHistory(result) -> {
      case result {
        Ok(executions) -> {
          let display = format_executions(executions)
          let updated =
            SchedulerModel(
              ..model,
              execution_history: display,
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    JobEnabled(result) -> {
      case result {
        Ok(_) -> #(model, FetchJobs(model.filter))
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    JobDisabled(result) -> {
      case result {
        Ok(_) -> #(model, FetchJobs(model.filter))
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    JobTriggered(result) -> {
      case result {
        Ok(_execution) -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              #(model, FetchExecutionHistory(job_id, 50))
            }
            None -> #(model, FetchJobs(model.filter))
          }
        }
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    JobDeleted(result) -> {
      case result {
        Ok(_) -> #(model, FetchJobs(model.filter))
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    ConfigSaved(result) -> {
      case result {
        Ok(_) -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              #(model, FetchJobDetails(job_id))
            }
            None -> #(model, FetchJobs(model.filter))
          }
        }
        Error(err) -> {
          let updated =
            SchedulerModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    // === UI ===
    ToggleAutoRefresh -> {
      let updated = SchedulerModel(..model, auto_refresh: !model.auto_refresh)
      #(updated, NoEffect)
    }

    ClearError -> {
      let updated = SchedulerModel(..model, error_message: None)
      #(updated, NoEffect)
    }

    KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    Refresh -> {
      let updated =
        SchedulerModel(
          ..model,
          is_loading: True,
          current_time: get_current_time(),
        )
      #(updated, FetchJobs(model.filter))
    }

    NoOp -> #(model, NoEffect)
  }
}

/// Handle keyboard input
fn handle_key_press(
  model: SchedulerModel,
  key_str: String,
) -> #(SchedulerModel, SchedulerEffect) {
  case model.view_state {
    ListView -> {
      case key_str {
        "/" -> {
          // Start search
          #(model, NoEffect)
        }
        "f" ->
          scheduler_update(model, SetEnabledOnly(!model.filter.enabled_only))
        "a" -> scheduler_update(model, ToggleAutoRefresh)
        "c" -> scheduler_update(model, ClearFilters)
        "r" -> scheduler_update(model, Refresh)
        _ -> #(model, NoEffect)
      }
    }

    DetailsView -> {
      case key_str {
        "e" -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              case details.job.enabled {
                True -> scheduler_update(model, DisableJob(job_id))
                False -> scheduler_update(model, EnableJob(job_id))
              }
            }
            None -> #(model, NoEffect)
          }
        }
        "r" -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              scheduler_update(model, RunJobNow(job_id))
            }
            None -> #(model, NoEffect)
          }
        }
        "h" -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              scheduler_update(model, ShowHistoryView(job_id))
            }
            None -> #(model, NoEffect)
          }
        }
        "c" -> {
          case model.selected_job {
            Some(details) -> {
              let job_id = id.job_id_to_string(details.job.id)
              scheduler_update(model, ShowConfigView(job_id))
            }
            None -> #(model, NoEffect)
          }
        }
        "\u{001B}" -> scheduler_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }

    ConfigView -> {
      case key_str {
        "\r" -> scheduler_update(model, SaveConfig)
        "\u{001B}" -> scheduler_update(model, CancelConfig)
        _ -> #(model, NoEffect)
      }
    }

    RunConfirmView(_) -> {
      case key_str {
        "y" -> scheduler_update(model, ConfirmRunJob)
        "n" -> scheduler_update(model, CancelRunJob)
        "\u{001B}" -> scheduler_update(model, CancelRunJob)
        _ -> #(model, NoEffect)
      }
    }

    DeleteConfirmView(_) -> {
      case key_str {
        "y" -> scheduler_update(model, ConfirmDeleteJob)
        "n" -> scheduler_update(model, CancelDeleteJob)
        "\u{001B}" -> scheduler_update(model, CancelDeleteJob)
        _ -> #(model, NoEffect)
      }
    }

    _ -> {
      case key_str {
        "\u{001B}" -> scheduler_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Format jobs for display
fn format_jobs(
  jobs: List(scheduler_types.ScheduledJob),
  _current_time: Int,
) -> List(JobDisplayEntry) {
  list.map(jobs, fn(job) {
    let status = case job.enabled {
      True -> "✓ Enabled"
      False -> "○ Disabled"
    }

    let next_run = case job.scheduled_for {
      Some(ts) -> ts
      None -> "Not scheduled"
    }

    let last_run = case job.completed_at {
      Some(ts) -> ts
      None -> "Never"
    }

    // Success rate calculated from error_count (0 errors = 100%)
    let success_rate = case job.error_count {
      0 -> "100%"
      _ -> "Has errors"
    }

    JobDisplayEntry(
      job: job,
      name_display: scheduler_types.job_type_to_string(job.job_type),
      status_display: status,
      next_run_display: next_run,
      last_run_display: last_run,
      success_rate_display: success_rate,
    )
  })
}

/// Format executions for display
fn format_executions(
  executions: List(scheduler_types.JobExecution),
) -> List(ExecutionDisplayEntry) {
  list.map(executions, fn(exec) {
    // started_at is already a String (ISO8601)
    let started = exec.started_at

    let duration = case exec.duration_ms {
      Some(ms) -> int.to_string(ms) <> "ms"
      None -> "Running..."
    }

    let status = case exec.status {
      scheduler_types.Pending -> "⏳ Pending"
      scheduler_types.Running -> "🔄 Running"
      scheduler_types.Completed -> "✓ Completed"
      scheduler_types.Failed -> "✗ Failed"
    }

    let result_summary = option.unwrap(exec.error_message, "")

    ExecutionDisplayEntry(
      execution: exec,
      started_at_display: started,
      duration_display: duration,
      status_display: status,
      result_summary: result_summary,
    )
  })
}

/// Sort jobs by option
fn sort_jobs(
  jobs: List(JobDisplayEntry),
  sort: JobSortOption,
) -> List(JobDisplayEntry) {
  case sort {
    SortByName ->
      list.sort(jobs, fn(a, b) {
        string.compare(a.name_display, b.name_display)
      })
    SortByNextRun -> {
      list.sort(jobs, fn(a, b) {
        case a.job.scheduled_for, b.job.scheduled_for {
          Some(t1), Some(t2) -> string.compare(t1, t2)
          Some(_), None -> order.Lt
          None, Some(_) -> order.Gt
          None, None -> order.Eq
        }
      })
    }
    SortByLastRun -> {
      list.sort(jobs, fn(a, b) {
        case a.job.completed_at, b.job.completed_at {
          Some(t1), Some(t2) -> string.compare(t2, t1)
          Some(_), None -> order.Lt
          None, Some(_) -> order.Gt
          None, None -> order.Eq
        }
      })
    }
    SortByStatus -> {
      list.sort(jobs, fn(a, b) {
        case a.job.enabled, b.job.enabled {
          True, False -> order.Lt
          False, True -> order.Gt
          _, _ -> order.Eq
        }
      })
    }
  }
}

/// Format job frequency for display
fn format_frequency(freq: scheduler_types.JobFrequency) -> String {
  case freq {
    scheduler_types.Weekly(day, hour, minute) ->
      "Weekly (day "
      <> int.to_string(day)
      <> " at "
      <> int.to_string(hour)
      <> ":"
      <> int.to_string(minute)
      <> ")"
    scheduler_types.Daily(hour, minute) ->
      "Daily at " <> int.to_string(hour) <> ":" <> int.to_string(minute)
    scheduler_types.EveryNHours(hours) ->
      "Every " <> int.to_string(hours) <> " hours"
    scheduler_types.Once -> "Once"
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the scheduler view screen
pub fn scheduler_view(model: SchedulerModel) -> shore.Node(SchedulerMsg) {
  case model.view_state {
    ListView -> view_list(model)
    DetailsView -> view_details(model)
    HistoryView -> view_history(model)
    ConfigView -> view_config(model)
    LogsView(execution_id) -> view_logs(model, execution_id)
    RunConfirmView(job_id) -> view_run_confirm(model, job_id)
    DeleteConfirmView(job_id) -> view_delete_confirm(model, job_id)
  }
}

/// Render job list view
fn view_list(model: SchedulerModel) -> shore.Node(SchedulerMsg) {
  let filter_status = case model.filter.enabled_only {
    True -> "Enabled only"
    False -> "All jobs"
  }

  let auto_status = case model.auto_refresh {
    True -> "🔄 Auto-refresh ON"
    False -> "Auto-refresh OFF"
  }

  let error_row = case model.error_message {
    Some(err) -> [ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let loading_row = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let job_rows = case model.jobs {
    [] -> [ui.text("No scheduled jobs found.")]
    jobs -> list.index_map(jobs, fn(job, idx) { render_job_entry(job, idx) })
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📋 Scheduler - Jobs", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
      ],
      error_row,
      [
        ui.br(),
        ui.text_styled(
          "[/] Search  [f] Filter: "
            <> filter_status
            <> "  [a] "
            <> auto_status
            <> "  [r] Refresh",
          Some(style.Cyan),
          None,
        ),
        ui.hr(),
        ui.br(),
      ],
      loading_row,
      job_rows,
      [
        ui.br(),
        ui.text_styled(
          "[Enter] View details  [1-9] Select job",
          Some(style.Cyan),
          None,
        ),
      ],
    ]),
  )
}

/// Render a job entry
fn render_job_entry(
  job: JobDisplayEntry,
  index: Int,
) -> shore.Node(SchedulerMsg) {
  let _ = case job.job.enabled {
    True -> style.Green
    False -> style.Yellow
  }

  ui.text(
    int.to_string(index + 1)
    <> ". "
    <> job.name_display
    <> " | "
    <> job.status_display
    <> " | Next: "
    <> job.next_run_display
    <> " | Success: "
    <> job.success_rate_display,
  )
}

/// Render job details view
fn view_details(model: SchedulerModel) -> shore.Node(SchedulerMsg) {
  case model.selected_job {
    None -> ui.col([ui.text("Loading job details...")])
    Some(details) -> {
      let enable_action = case details.job.enabled {
        True -> "[e] Disable"
        False -> "[e] Enable"
      }

      let job_name = scheduler_types.job_type_to_string(details.job.job_type)

      let error_rows = case details.last_error {
        Some(err) -> [
          ui.text_styled("Last Error:", Some(style.Red), None),
          ui.text("  " <> err),
        ]
        None -> []
      }

      ui.col(
        list.flatten([
          [
            ui.br(),
            ui.align(
              style.Center,
              ui.text_styled("📋 Job Details", Some(style.Green), None),
            ),
            ui.hr_styled(style.Green),
            ui.br(),
            ui.text("Name: " <> job_name),
            ui.text(
              "Status: "
              <> case details.job.enabled {
                True -> "✓ Enabled"
                False -> "○ Disabled"
              },
            ),
            ui.text("Schedule: " <> details.schedule_expression),
            ui.br(),
            ui.text_styled("Statistics:", Some(style.Yellow), None),
            ui.text(
              "  Total Executions: " <> int.to_string(details.total_executions),
            ),
            ui.text(
              "  Successful: " <> int.to_string(details.successful_executions),
            ),
            ui.text("  Failed: " <> int.to_string(details.failed_executions)),
            ui.text(
              "  Avg Duration: "
              <> int.to_string(details.average_duration_ms)
              <> "ms",
            ),
            ui.br(),
          ],
          error_rows,
          [
            ui.br(),
            ui.text_styled("Configuration:", Some(style.Yellow), None),
            ui.text(
              "  Timeout: " <> int.to_string(details.timeout_seconds) <> "s",
            ),
            ui.text("  Retries: " <> int.to_string(details.retry_count)),
            ui.br(),
            ui.hr(),
            ui.text_styled(
              enable_action
                <> "  [r] Run Now  [h] History  [c] Config  [Esc] Back",
              Some(style.Cyan),
              None,
            ),
          ],
        ]),
      )
    }
  }
}

/// Render execution history view
fn view_history(model: SchedulerModel) -> shore.Node(SchedulerMsg) {
  let loading_row = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let history_rows = case model.execution_history {
    [] -> [ui.text("No execution history.")]
    history ->
      list.map(history, fn(exec) {
        ui.text(
          "  "
          <> exec.started_at_display
          <> " | "
          <> exec.status_display
          <> " | "
          <> exec.duration_display,
        )
      })
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📜 Execution History", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
      ],
      loading_row,
      history_rows,
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Enter] View logs  [Esc] Back", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render config view
fn view_config(model: SchedulerModel) -> shore.Node(SchedulerMsg) {
  case model.config_state {
    None -> ui.col([ui.text("No configuration loaded")])
    Some(config) -> {
      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("⚙ Job Configuration", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        ui.input("Schedule:", config.schedule, style.Pct(60), fn(s) {
          ConfigScheduleChanged(s)
        }),
        ui.br(),

        ui.input(
          "Timeout (s):",
          int.to_string(config.timeout),
          style.Pct(30),
          fn(s) {
            case int.parse(s) {
              Ok(t) -> ConfigTimeoutChanged(t)
              Error(_) -> NoOp
            }
          },
        ),
        ui.br(),

        ui.input(
          "Retries:",
          int.to_string(config.retries),
          style.Pct(30),
          fn(s) {
            case int.parse(s) {
              Ok(r) -> ConfigRetriesChanged(r)
              Error(_) -> NoOp
            }
          },
        ),
        ui.br(),

        ui.text(
          "Enabled: "
          <> case config.enabled {
            True -> "Yes"
            False -> "No"
          },
        ),
        ui.br(),

        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ])
    }
  }
}

/// Render logs view
fn view_logs(
  _model: SchedulerModel,
  execution_id: String,
) -> shore.Node(SchedulerMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📝 Execution Logs", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Execution ID: " <> execution_id),
    ui.br(),
    ui.text("(Logs view coming soon)"),
    ui.br(),

    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Render run confirmation
fn view_run_confirm(
  __model: SchedulerModel,
  job_id: String,
) -> shore.Node(SchedulerMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("▶ Run Job Now?", Some(style.Yellow), None),
    ),
    ui.hr_styled(style.Yellow),
    ui.br(),

    ui.text("This will immediately trigger the job:"),
    ui.text("Job ID: " <> job_id),
    ui.br(),

    ui.text_styled("[y] Yes, run now  [n] Cancel", Some(style.Cyan), None),
  ])
}

/// Render delete confirmation
fn view_delete_confirm(
  __model: SchedulerModel,
  job_id: String,
) -> shore.Node(SchedulerMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚠ Delete Job?", Some(style.Red), None),
    ),
    ui.hr_styled(style.Red),
    ui.br(),

    ui.text("This will permanently delete the job:"),
    ui.text("Job ID: " <> job_id),
    ui.br(),

    ui.text_styled("[y] Yes, delete  [n] Cancel", Some(style.Yellow), None),
  ])
}
