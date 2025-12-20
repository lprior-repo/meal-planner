//// TDD Test for CLI scheduler status command
////
//// RED PHASE: This test validates the status command shows:
//// 1. Job details from database
//// 2. Execution history
//// 3. Formatted output

import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/scheduler
import meal_planner/id
import meal_planner/scheduler/types.{
  Completed, High, JobExecution, Once, RetryPolicy, Running, Scheduled,
  ScheduledJob,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Formatting Tests (Pure Functions)
// ============================================================================

/// Test: build_job_status_view formats job details correctly
pub fn build_job_status_view_formats_correctly_test() {
  let job =
    ScheduledJob(
      id: id.job_id("test-job-id"),
      job_type: types.AutoSync,
      frequency: Once,
      status: Running,
      priority: High,
      user_id: None,
      retry_policy: RetryPolicy(
        max_attempts: 3,
        backoff_seconds: 60,
        retry_on_failure: True,
      ),
      parameters: None,
      scheduled_for: None,
      started_at: None,
      completed_at: None,
      last_error: None,
      error_count: 0,
      created_at: "2025-12-20T10:00:00Z",
      updated_at: "2025-12-20T10:00:00Z",
      created_by: None,
      enabled: True,
    )

  let output = scheduler.build_job_status_view(job)

  string.contains(output, "test-job-id")
  |> should.be_true()

  string.contains(output, "Auto Sync")
  |> should.be_true()

  string.contains(output, "Running")
  |> should.be_true()
}

/// Test: build_executions_table formats execution list
pub fn build_executions_table_formats_list_test() {
  let executions = [
    JobExecution(
      id: 1,
      job_id: id.job_id("test-job-id"),
      started_at: "2025-12-20T10:30:45Z",
      completed_at: Some("2025-12-20T10:30:50Z"),
      status: Completed,
      error_message: None,
      attempt_number: 1,
      duration_ms: Some(5000),
      output: None,
      triggered_by: Scheduled,
    ),
  ]

  let output = scheduler.build_executions_table(executions)

  // Should contain table headers
  string.contains(output, "ID")
  |> should.be_true()

  string.contains(output, "Status")
  |> should.be_true()

  string.contains(output, "Duration")
  |> should.be_true()
}

/// Test: build_executions_table handles empty list
pub fn build_executions_table_empty_test() {
  let output = scheduler.build_executions_table([])

  string.contains(output, "No executions found")
  |> should.be_true()
}

/// Test: format_duration shows seconds with 2 decimal places
pub fn format_duration_test() {
  scheduler.format_duration(Some(5000))
  |> should.equal("5.00s")

  scheduler.format_duration(Some(1234))
  |> should.equal("1.23s")

  scheduler.format_duration(None)
  |> should.equal("-")
}
