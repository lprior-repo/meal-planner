/// Scheduler Messages - Events and Effects
///
/// This module contains all message types and effects for the Scheduler screen.
/// Following Shore Framework (Elm Architecture) MVC pattern.
///
/// TYPES:
/// - SchedulerMsg: All possible user and system events
/// - SchedulerEffect: Side effects to execute
import gleam/option.{type Option}
import meal_planner/cli/screens/scheduler/model.{
  type JobFilter, type JobSortOption, type JobType,
}
import meal_planner/scheduler/types as scheduler_types

// ============================================================================
// Messages
// ============================================================================

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
  GotJobDetails(Result(model.JobDetails, String))
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

// ============================================================================
// Effects
// ============================================================================

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
