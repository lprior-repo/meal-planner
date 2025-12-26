/// Scheduler Model - State Types
///
/// This module contains all state types for the Scheduler screen.
/// Following Shore Framework (Elm Architecture) MVC pattern.
///
/// TYPES:
/// - SchedulerModel: Root state container
/// - SchedulerViewState: View state machine
/// - Display types: JobDisplayEntry, JobDetails, ExecutionDisplayEntry
/// - Filter types: JobFilter, JobType, JobSortOption
/// - Config types: JobConfigState
import birl
import gleam/option.{type Option}
import meal_planner/scheduler/types as scheduler_types

// ============================================================================
// Root Model
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

// ============================================================================
// View State
// ============================================================================

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

// ============================================================================
// Display Types
// ============================================================================

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

// ============================================================================
// Filter Types
// ============================================================================

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

// ============================================================================
// Configuration Types
// ============================================================================

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

// ============================================================================
// Initialization
// ============================================================================

/// Create initial SchedulerModel
pub fn init() -> SchedulerModel {
  SchedulerModel(
    view_state: ListView,
    jobs: [],
    selected_job: option.None,
    execution_history: [],
    filter: default_filter(),
    is_loading: False,
    error_message: option.None,
    config_state: option.None,
    current_time: get_current_time(),
    auto_refresh: False,
  )
}

/// Default filter
pub fn default_filter() -> JobFilter {
  JobFilter(
    enabled_only: False,
    failed_only: False,
    job_type: option.None,
    search_query: "",
    sort_by: SortByName,
  )
}

/// Get current time as Unix timestamp
pub fn get_current_time() -> Int {
  birl.now()
  |> birl.to_unix
}
