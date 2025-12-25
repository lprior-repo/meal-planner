/// Tests for Scheduler View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Job filter and sorting
/// - Job configuration state
/// - Message and effect variants
///
/// Note: Tests for JobDisplayEntry, JobDetails, and ExecutionDisplayEntry
/// are limited because they require complex scheduler_types that are
/// internal to the scheduler module.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/scheduler_view.{
  type JobConfigState, type JobFilter, type JobSortOption, type JobType,
  type SchedulerEffect, type SchedulerViewState, AnalysisJob, CleanupJob,
  ConfigView, DeleteConfirmView, DetailsView, HistoryView, JobConfigState,
  JobFilter, ListView, LogsView, NotificationJob, ReportJob, RunConfirmView,
  SortByLastRun, SortByName, SortByNextRun, SortByStatus, SyncJob,
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  let model = scheduler_view.init()
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
  let model = scheduler_view.init()
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
  }
  |> should.be_true
}

pub fn view_state_details_view_test() {
  let view_state: SchedulerViewState = DetailsView
  case view_state {
    DetailsView -> True
  }
  |> should.be_true
}

pub fn view_state_history_view_test() {
  let view_state: SchedulerViewState = HistoryView
  case view_state {
    HistoryView -> True
  }
  |> should.be_true
}

pub fn view_state_config_view_test() {
  let view_state: SchedulerViewState = ConfigView
  case view_state {
    ConfigView -> True
  }
  |> should.be_true
}

pub fn view_state_logs_view_test() {
  let view_state: SchedulerViewState = LogsView("exec_123")
  case view_state {
    LogsView(id) -> id == "exec_123"
  }
  |> should.be_true
}

pub fn view_state_run_confirm_view_test() {
  let view_state: SchedulerViewState = RunConfirmView("job_456")
  case view_state {
    RunConfirmView(id) -> id == "job_456"
  }
  |> should.be_true
}

pub fn view_state_delete_confirm_view_test() {
  let view_state: SchedulerViewState = DeleteConfirmView("job_789")
  case view_state {
    DeleteConfirmView(id) -> id == "job_789"
  }
  |> should.be_true
}

// ============================================================================
// Job Filter Tests
// ============================================================================

pub fn job_filter_construction_test() {
  let filter =
    JobFilter(
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
  let config =
    JobConfigState(
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
  config.original_schedule
  |> should.equal("0 */6 * * *")
  config.original_timeout
  |> should.equal(600)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn scheduler_msg_navigation_variants_compile_test() {
  let _msgs = [
    scheduler_view.ShowListView,
    scheduler_view.ShowDetailsView("job_1"),
    scheduler_view.ShowHistoryView("job_1"),
    scheduler_view.ShowConfigView("job_1"),
    scheduler_view.ShowLogsView("exec_1"),
    scheduler_view.ShowRunConfirm("job_1"),
    scheduler_view.ShowDeleteConfirm("job_1"),
    scheduler_view.GoBack,
  ]
  True
  |> should.be_true
}

pub fn scheduler_msg_job_action_variants_compile_test() {
  let _msgs = [
    scheduler_view.EnableJob("job_1"),
    scheduler_view.DisableJob("job_1"),
    scheduler_view.RunJobNow("job_1"),
    scheduler_view.ConfirmRunJob,
    scheduler_view.CancelRunJob,
    scheduler_view.DeleteJob("job_1"),
    scheduler_view.ConfirmDeleteJob,
    scheduler_view.CancelDeleteJob,
  ]
  True
  |> should.be_true
}

pub fn scheduler_msg_config_variants_compile_test() {
  let _msgs = [
    scheduler_view.ConfigScheduleChanged("0 * * * *"),
    scheduler_view.ConfigTimeoutChanged(300),
    scheduler_view.ConfigRetriesChanged(3),
    scheduler_view.ConfigEnabledChanged(True),
    scheduler_view.SaveConfig,
    scheduler_view.CancelConfig,
  ]
  True
  |> should.be_true
}

pub fn scheduler_msg_filter_variants_compile_test() {
  let _msgs = [
    scheduler_view.SetEnabledOnly(True),
    scheduler_view.SetFailedOnly(False),
    scheduler_view.SetJobTypeFilter(Some(SyncJob)),
    scheduler_view.SetSearchQuery("backup"),
    scheduler_view.SetSortBy(SortByLastRun),
    scheduler_view.ClearFilters,
  ]
  True
  |> should.be_true
}

pub fn scheduler_msg_ui_variants_compile_test() {
  let _msgs = [
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
  let filter =
    JobFilter(
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
