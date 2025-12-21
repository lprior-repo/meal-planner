/// Tests for Scheduler View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Job display entries
/// - Job details
/// - Execution history
/// - Job filter and sorting
/// - Job configuration state
/// - Message and effect variants
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/scheduler_view.{
  type ExecutionDisplayEntry, type JobConfigState, type JobDetails,
  type JobDisplayEntry, type JobFilter, type JobSortOption, type JobType,
  type SchedulerEffect, type SchedulerModel, type SchedulerMsg,
  type SchedulerViewState, AnalysisJob, CleanupJob, ConfigView,
  DeleteConfirmView, DetailsView, ExecutionDisplayEntry, HistoryView,
  JobConfigState, JobDetails, JobDisplayEntry, JobFilter, ListView, LogsView,
  NotificationJob, ReportJob, RunConfirmView, SchedulerModel, SortByLastRun,
  SortByName, SortByNextRun, SortByStatus, SyncJob,
}
import meal_planner/scheduler/types as scheduler_types

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // WHEN: Initializing SchedulerModel
  let model = scheduler_view.init()

  // THEN: Model should have correct initial state
  model.view_state
  |> should.equal(ListView)

  model.jobs
  |> should.equal([])

  model.selected_job
  |> should.equal(None)

  model.execution_history
  |> should.equal([])

  model.is_loading
  |> should.equal(False)

  model.error_message
  |> should.equal(None)

  model.config_state
  |> should.equal(None)

  model.auto_refresh
  |> should.equal(False)
}

pub fn init_filter_state_test() {
  // GIVEN: Initial model
  let model = scheduler_view.init()

  // THEN: Filter should have defaults
  model.filter.enabled_only
  |> should.equal(False)

  model.filter.failed_only
  |> should.equal(False)

  model.filter.job_type
  |> should.equal(None)

  model.filter.search_query
  |> should.equal("")

  model.filter.sort_by
  |> should.equal(SortByName)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_list_view_test() {
  let view_state: SchedulerViewState = ListView
  case view_state {
    ListView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_details_view_test() {
  let view_state: SchedulerViewState = DetailsView
  case view_state {
    DetailsView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_history_view_test() {
  let view_state: SchedulerViewState = HistoryView
  case view_state {
    HistoryView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_config_view_test() {
  let view_state: SchedulerViewState = ConfigView
  case view_state {
    ConfigView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_logs_view_test() {
  let view_state: SchedulerViewState = LogsView("exec_123")
  case view_state {
    LogsView(id) -> id == "exec_123"
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_run_confirm_view_test() {
  let view_state: SchedulerViewState = RunConfirmView("job_456")
  case view_state {
    RunConfirmView(id) -> id == "job_456"
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_delete_confirm_view_test() {
  let view_state: SchedulerViewState = DeleteConfirmView("job_789")
  case view_state {
    DeleteConfirmView(id) -> id == "job_789"
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// Job Display Entry Tests
// ============================================================================

pub fn job_display_entry_construction_test() {
  let job = scheduler_types.scheduled_job(
    job_id: "job_001",
    name: "Daily Sync",
    description: "Sync data with FatSecret",
    schedule: "0 6 * * *",
    enabled: True,
    timeout_seconds: 300,
    retry_count: 3,
    last_run: Some(1_700_000_000),
    next_run: Some(1_700_086_400),
  )

  let entry = JobDisplayEntry(
    job: job,
    name_display: "Daily Sync",
    status_display: "✓ Enabled",
    next_run_display: "Tomorrow 6:00 AM",
    last_run_display: "Today 6:00 AM",
    success_rate_display: "95%",
  )

  entry.name_display
  |> should.equal("Daily Sync")

  entry.status_display
  |> should.equal("✓ Enabled")

  entry.success_rate_display
  |> should.equal("95%")
}

// ============================================================================
// Job Details Tests
// ============================================================================

pub fn job_details_construction_test() {
  let job = scheduler_types.scheduled_job(
    job_id: "job_002",
    name: "Weekly Report",
    description: "Generate weekly nutrition report",
    schedule: "0 8 * * 1",
    enabled: True,
    timeout_seconds: 600,
    retry_count: 2,
    last_run: Some(1_699_900_000),
    next_run: Some(1_700_500_000),
  )

  let details = JobDetails(
    job: job,
    total_executions: 52,
    successful_executions: 50,
    failed_executions: 2,
    average_duration_ms: 45_000,
    last_error: Some("Timeout after 600s"),
    schedule_expression: "Every Monday at 8:00 AM",
    timeout_seconds: 600,
    retry_count: 2,
    created_at: 1_680_000_000,
    updated_at: 1_699_900_000,
  )

  details.total_executions
  |> should.equal(52)

  details.successful_executions
  |> should.equal(50)

  details.failed_executions
  |> should.equal(2)

  details.average_duration_ms
  |> should.equal(45_000)

  details.last_error
  |> should.equal(Some("Timeout after 600s"))
}

// ============================================================================
// Execution Display Entry Tests
// ============================================================================

pub fn execution_display_entry_construction_test() {
  let execution = scheduler_types.job_execution(
    execution_id: "exec_001",
    job_id: "job_001",
    started_at: 1_700_000_000,
    completed_at: Some(1_700_000_030),
    status: scheduler_types.Completed,
    result: Some("Synced 150 entries"),
    error: None,
  )

  let entry = ExecutionDisplayEntry(
    execution: execution,
    started_at_display: "2023-11-14 06:00:00",
    duration_display: "30s",
    status_display: "✓ Completed",
    result_summary: "Synced 150 entries",
  )

  entry.started_at_display
  |> should.equal("2023-11-14 06:00:00")

  entry.duration_display
  |> should.equal("30s")

  entry.status_display
  |> should.equal("✓ Completed")
}

// ============================================================================
// Job Filter Tests
// ============================================================================

pub fn job_filter_construction_test() {
  let filter = JobFilter(
    enabled_only: True,
    failed_only: False,
    job_type: Some(SyncJob),
    search_query: "daily",
    sort_by: SortByNextRun,
  )

  filter.enabled_only
  |> should.equal(True)

  filter.job_type
  |> should.equal(Some(SyncJob))

  filter.search_query
  |> should.equal("daily")

  filter.sort_by
  |> should.equal(SortByNextRun)
}

// ============================================================================
// Job Type Tests
// ============================================================================

pub fn job_type_all_variants_test() {
  let _types: List(JobType) = [
    SyncJob,
    AnalysisJob,
    NotificationJob,
    CleanupJob,
    ReportJob,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Job Sort Option Tests
// ============================================================================

pub fn job_sort_option_all_variants_test() {
  let _options: List(JobSortOption) = [
    SortByName,
    SortByNextRun,
    SortByLastRun,
    SortByStatus,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Job Config State Tests
// ============================================================================

pub fn job_config_state_construction_test() {
  let config = JobConfigState(
    job_id: "job_003",
    schedule: "0 */4 * * *",
    timeout: 300,
    retries: 3,
    enabled: True,
    original_schedule: "0 */6 * * *",
    original_timeout: 600,
    original_retries: 2,
  )

  config.job_id
  |> should.equal("job_003")

  config.schedule
  |> should.equal("0 */4 * * *")

  config.timeout
  |> should.equal(300)

  config.retries
  |> should.equal(3)

  // Check original values for comparison
  config.original_schedule
  |> should.equal("0 */6 * * *")

  config.original_timeout
  |> should.equal(600)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn scheduler_msg_all_variants_compile_test() {
  let _msgs: List(SchedulerMsg) = [
    // Navigation
    scheduler_view.ShowListView,
    scheduler_view.ShowDetailsView("job_1"),
    scheduler_view.ShowHistoryView("job_1"),
    scheduler_view.ShowConfigView("job_1"),
    scheduler_view.ShowLogsView("exec_1"),
    scheduler_view.ShowRunConfirm("job_1"),
    scheduler_view.ShowDeleteConfirm("job_1"),
    scheduler_view.GoBack,
    // Job actions
    scheduler_view.EnableJob("job_1"),
    scheduler_view.DisableJob("job_1"),
    scheduler_view.RunJobNow("job_1"),
    scheduler_view.ConfirmRunJob,
    scheduler_view.CancelRunJob,
    scheduler_view.DeleteJob("job_1"),
    scheduler_view.ConfirmDeleteJob,
    scheduler_view.CancelDeleteJob,
    // Configuration
    scheduler_view.ConfigScheduleChanged("0 * * * *"),
    scheduler_view.ConfigTimeoutChanged(300),
    scheduler_view.ConfigRetriesChanged(3),
    scheduler_view.ConfigEnabledChanged(True),
    scheduler_view.SaveConfig,
    scheduler_view.CancelConfig,
    // Filtering
    scheduler_view.SetEnabledOnly(True),
    scheduler_view.SetFailedOnly(False),
    scheduler_view.SetJobTypeFilter(Some(SyncJob)),
    scheduler_view.SetSearchQuery("backup"),
    scheduler_view.SetSortBy(SortByLastRun),
    scheduler_view.ClearFilters,
    // UI
    scheduler_view.ToggleAutoRefresh,
    scheduler_view.ClearError,
    scheduler_view.KeyPressed("r"),
    scheduler_view.Refresh,
    scheduler_view.NoOp,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn scheduler_effect_all_variants_compile_test() {
  let filter = JobFilter(
    enabled_only: False,
    failed_only: False,
    job_type: None,
    search_query: "",
    sort_by: SortByName,
  )

  let _effects: List(SchedulerEffect) = [
    scheduler_view.NoEffect,
    scheduler_view.FetchJobs(filter),
    scheduler_view.FetchJobDetails("job_1"),
    scheduler_view.FetchExecutionHistory("job_1", 50),
    scheduler_view.EnableJobEffect("job_1"),
    scheduler_view.DisableJobEffect("job_1"),
    scheduler_view.TriggerJobEffect("job_1"),
    scheduler_view.DeleteJobEffect("job_1"),
    scheduler_view.SaveConfigEffect("job_1", "0 * * * *", 300, 3),
    scheduler_view.BatchEffects([]),
  ]

  True
  |> should.be_true
}
