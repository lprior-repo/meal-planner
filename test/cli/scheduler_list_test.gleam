/// TDD tests for scheduler list command (RED phase)
///
/// Tests the `mp scheduler list` command which should:
/// - List all scheduled jobs from the database
/// - Display job name, schedule, next_run, and status
/// - Format cron expressions as human-readable text
///
/// These tests MUST fail initially (RED), then implementation makes them pass (GREEN)
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/scheduler
import meal_planner/id
import meal_planner/scheduler/types.{
  type JobFrequency, type JobPriority, type JobStatus, type JobType,
  type ScheduledJob, AutoSync, Completed, Critical, Daily, DailyAdvisor, Failed,
  High, Low, Medium, Pending, Running, ScheduledJob, Weekly, WeeklyGeneration,
  WeeklyTrends,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a mock weekly generation job
fn mock_weekly_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_weekly_gen_1234567890"),
    job_type: WeeklyGeneration,
    frequency: Weekly(day: 5, hour: 6, minute: 0),
    // Friday 06:00
    status: Pending,
    priority: High,
    user_id: None,
    retry_policy: types.default_retry_policy(),
    parameters: None,
    scheduled_for: Some("2025-12-20T06:00:00Z"),
    started_at: None,
    completed_at: None,
    last_error: None,
    error_count: 0,
    created_at: "2025-12-19T10:00:00Z",
    updated_at: "2025-12-19T10:00:00Z",
    created_by: None,
    enabled: True,
  )
}

/// Create a mock daily advisor job
fn mock_daily_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_daily_adv_1234567891"),
    job_type: DailyAdvisor,
    frequency: Daily(hour: 20, minute: 0),
    // 20:00
    status: Running,
    priority: Medium,
    user_id: None,
    retry_policy: types.default_retry_policy(),
    parameters: None,
    scheduled_for: Some("2025-12-19T20:00:00Z"),
    started_at: Some("2025-12-19T20:00:05Z"),
    completed_at: None,
    last_error: None,
    error_count: 0,
    created_at: "2025-12-01T10:00:00Z",
    updated_at: "2025-12-19T20:00:05Z",
    created_by: None,
    enabled: True,
  )
}

/// Create a mock auto sync job
fn mock_autosync_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_auto_sync_1234567892"),
    job_type: AutoSync,
    frequency: types.EveryNHours(hours: 4),
    status: Completed,
    priority: Low,
    user_id: None,
    retry_policy: types.default_retry_policy(),
    parameters: None,
    scheduled_for: Some("2025-12-19T16:00:00Z"),
    started_at: Some("2025-12-19T16:00:05Z"),
    completed_at: Some("2025-12-19T16:02:30Z"),
    last_error: None,
    error_count: 0,
    created_at: "2025-12-01T10:00:00Z",
    updated_at: "2025-12-19T16:02:30Z",
    created_by: None,
    enabled: True,
  )
}

/// Create a mock failed job
fn mock_failed_job() -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_weekly_trends_1234567893"),
    job_type: WeeklyTrends,
    frequency: Weekly(day: 4, hour: 20, minute: 0),
    // Thursday 20:00
    status: Failed,
    priority: Critical,
    user_id: None,
    retry_policy: types.default_retry_policy(),
    parameters: None,
    scheduled_for: Some("2025-12-19T20:00:00Z"),
    started_at: Some("2025-12-19T20:00:05Z"),
    completed_at: Some("2025-12-19T20:00:10Z"),
    last_error: Some("Database connection timeout"),
    error_count: 2,
    created_at: "2025-12-01T10:00:00Z",
    updated_at: "2025-12-19T20:00:10Z",
    created_by: None,
    enabled: True,
  )
}

// ============================================================================
// Test: Format job type as human-readable string
// ============================================================================

pub fn test_format_job_type_weekly_generation() {
  scheduler.format_job_type(WeeklyGeneration)
  |> should.equal("Weekly Generation")
}

pub fn test_format_job_type_auto_sync() {
  scheduler.format_job_type(AutoSync)
  |> should.equal("Auto Sync")
}

pub fn test_format_job_type_daily_advisor() {
  scheduler.format_job_type(DailyAdvisor)
  |> should.equal("Daily Advisor")
}

pub fn test_format_job_type_weekly_trends() {
  scheduler.format_job_type(WeeklyTrends)
  |> should.equal("Weekly Trends")
}

// ============================================================================
// Test: Format job status with correct labels
// ============================================================================

pub fn test_format_job_status_pending() {
  scheduler.format_job_status(Pending)
  |> should.equal("Pending")
}

pub fn test_format_job_status_running() {
  scheduler.format_job_status(Running)
  |> should.equal("Running")
}

pub fn test_format_job_status_completed() {
  scheduler.format_job_status(Completed)
  |> should.equal("Completed")
}

pub fn test_format_job_status_failed() {
  scheduler.format_job_status(Failed)
  |> should.equal("Failed")
}

// ============================================================================
// Test: Format job priority
// ============================================================================

pub fn test_format_job_priority_low() {
  scheduler.format_job_priority(Low)
  |> should.equal("Low")
}

pub fn test_format_job_priority_medium() {
  scheduler.format_job_priority(Medium)
  |> should.equal("Medium")
}

pub fn test_format_job_priority_high() {
  scheduler.format_job_priority(High)
  |> should.equal("High")
}

pub fn test_format_job_priority_critical() {
  scheduler.format_job_priority(Critical)
  |> should.equal("Critical")
}

// ============================================================================
// Test: Format job frequency as human-readable schedule
// ============================================================================

pub fn test_format_frequency_weekly() {
  scheduler.format_job_frequency(Weekly(day: 1, hour: 9, minute: 30))
  |> should.equal("Weekly (Mon 09:30)")
}

pub fn test_format_frequency_weekly_friday() {
  scheduler.format_job_frequency(Weekly(day: 5, hour: 6, minute: 0))
  |> should.equal("Weekly (Fri 06:00)")
}

pub fn test_format_frequency_daily() {
  scheduler.format_job_frequency(Daily(hour: 20, minute: 0))
  |> should.equal("Daily (20:00)")
}

pub fn test_format_frequency_every_n_hours() {
  scheduler.format_job_frequency(types.EveryNHours(hours: 4))
  |> should.equal("Every 4 hours")
}

pub fn test_format_frequency_once() {
  scheduler.format_job_frequency(types.Once)
  |> should.equal("Once")
}

// ============================================================================
// Test: Build jobs table with multiple jobs
// ============================================================================

pub fn test_build_jobs_table_with_jobs() {
  let jobs = [mock_weekly_job(), mock_daily_job(), mock_autosync_job()]

  let table = scheduler.build_jobs_table(jobs)

  // Table should contain job type names
  table
  |> should_contain("Weekly Generation")

  table
  |> should_contain("Daily Advisor")

  table
  |> should_contain("Auto Sync")

  // Table should contain frequency info
  table
  |> should_contain("Weekly (Fri 06:00)")

  table
  |> should_contain("Daily (20:00)")

  table
  |> should_contain("Every 4 hours")

  // Table should contain status info
  table
  |> should_contain("Pending")

  table
  |> should_contain("Running")

  table
  |> should_contain("Completed")

  // Table should contain priority info
  table
  |> should_contain("High")

  table
  |> should_contain("Medium")

  table
  |> should_contain("Low")
}

pub fn test_build_jobs_table_empty() {
  let table = scheduler.build_jobs_table([])

  // Empty table should show "No scheduled jobs" message
  table
  |> should_contain("No scheduled jobs")
}

// ============================================================================
// Test: Build detailed job status view
// ============================================================================

pub fn test_build_job_status_view_pending_job() {
  let job = mock_weekly_job()
  let view = scheduler.build_job_status_view(job)

  // Should contain job details
  view
  |> should_contain("Job Details:")

  view
  |> should_contain("Type:      Weekly Generation")

  view
  |> should_contain("Status:    Pending")

  view
  |> should_contain("Priority:  High")

  view
  |> should_contain("Frequency: Weekly (Fri 06:00)")

  view
  |> should_contain("Enabled:   Yes")

  view
  |> should_contain("Errors:    0")
}

pub fn test_build_job_status_view_failed_job() {
  let job = mock_failed_job()
  let view = scheduler.build_job_status_view(job)

  // Should show failed status
  view
  |> should_contain("Status:    Failed")

  // Should show error count
  view
  |> should_contain("Errors:    2")

  // Should show last error message
  view
  |> should_contain("Last Error:")

  view
  |> should_contain("Database connection timeout")
}

// ============================================================================
// Test: Format execution duration
// ============================================================================

pub fn test_format_duration_with_milliseconds() {
  scheduler.format_duration(Some(2500))
  |> should.equal("2.50s")
}

pub fn test_format_duration_whole_seconds() {
  scheduler.format_duration(Some(5000))
  |> should.equal("5.00s")
}

pub fn test_format_duration_none() {
  scheduler.format_duration(None)
  |> should.equal("-")
}

// ============================================================================
// Test: Build executions table (timing info)
// ============================================================================

pub fn test_build_executions_table_with_executions() {
  let execution1 =
    types.JobExecution(
      id: 1,
      job_id: id.job_id("job_test_123"),
      started_at: "2025-12-19T10:30:45Z",
      completed_at: Some("2025-12-19T10:30:50Z"),
      status: Completed,
      error_message: None,
      attempt_number: 1,
      duration_ms: Some(5000),
      output: None,
      triggered_by: types.Scheduled,
    )

  let execution2 =
    types.JobExecution(
      id: 2,
      job_id: id.job_id("job_test_123"),
      started_at: "2025-12-19T11:30:45Z",
      completed_at: Some("2025-12-19T11:30:47Z"),
      status: Completed,
      error_message: None,
      attempt_number: 1,
      duration_ms: Some(2000),
      output: None,
      triggered_by: types.Scheduled,
    )

  let table = scheduler.build_executions_table([execution1, execution2])

  // Should contain execution IDs
  table
  |> should_contain("1")

  table
  |> should_contain("2")

  // Should contain timestamps (time portion)
  table
  |> should_contain("10:30:45")

  table
  |> should_contain("11:30:45")

  // Should contain duration
  table
  |> should_contain("5.00s")

  table
  |> should_contain("2.00s")

  // Should contain status
  table
  |> should_contain("Completed")
}

pub fn test_build_executions_table_empty() {
  let table = scheduler.build_executions_table([])

  // Should show "No executions found" message
  table
  |> should_contain("No executions found")
}

// ============================================================================
// Helper function for substring matching
// ============================================================================

fn should_contain(haystack: String, needle: String) {
  let contains = contains_substring(haystack, needle)
  case contains {
    True -> should.be_true(True)
    False -> should.fail()
  }
}

fn contains_substring(haystack: String, needle: String) -> Bool {
  // Simple substring check using Erlang's string:find
  gleam_string_contains(haystack, needle)
}

@external(erlang, "string", "find")
fn gleam_string_contains(haystack: String, needle: String) -> Bool
