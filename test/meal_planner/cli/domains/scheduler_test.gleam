/// Tests for scheduler CLI domain
import birl
import gleam/option
import gleeunit/should
import meal_planner/cli/domains/scheduler
import meal_planner/id
import meal_planner/scheduler/types

pub fn format_job_type_test() {
  scheduler.format_job_type(types.WeeklyGeneration)
  |> should.equal("Weekly Generation")

  scheduler.format_job_type(types.AutoSync)
  |> should.equal("Auto Sync")

  scheduler.format_job_type(types.DailyAdvisor)
  |> should.equal("Daily Advisor")

  scheduler.format_job_type(types.WeeklyTrends)
  |> should.equal("Weekly Trends")
}

pub fn format_job_status_test() {
  scheduler.format_job_status(types.Pending)
  |> should.equal("Pending")

  scheduler.format_job_status(types.Running)
  |> should.equal("Running")

  scheduler.format_job_status(types.Completed)
  |> should.equal("Completed")

  scheduler.format_job_status(types.Failed)
  |> should.equal("Failed")
}

pub fn format_job_priority_test() {
  scheduler.format_job_priority(types.Low)
  |> should.equal("Low")

  scheduler.format_job_priority(types.Medium)
  |> should.equal("Medium")

  scheduler.format_job_priority(types.High)
  |> should.equal("High")

  scheduler.format_job_priority(types.Critical)
  |> should.equal("Critical")
}

pub fn format_job_frequency_test() {
  scheduler.format_job_frequency(types.Weekly(5, 6, 0))
  |> should.equal("Weekly (Fri 06:00)")

  scheduler.format_job_frequency(types.Daily(20, 0))
  |> should.equal("Daily (20:00)")

  scheduler.format_job_frequency(types.EveryNHours(2))
  |> should.equal("Every 2 hours")

  scheduler.format_job_frequency(types.Once)
  |> should.equal("Once")
}

pub fn build_jobs_table_test() {
  let jobs = []
  let table = scheduler.build_jobs_table(jobs)

  // Should contain headers even with empty jobs
  table
  |> should.not_equal("")
}

pub fn format_trigger_source_test() {
  scheduler.format_trigger_source(types.Scheduled)
  |> should.equal("Scheduled")

  scheduler.format_trigger_source(types.Manual)
  |> should.equal("Manual")

  scheduler.format_trigger_source(types.Retry)
  |> should.equal("Retry")
}

pub fn build_executions_table_test() {
  let now = birl.now() |> birl.to_iso8601
  let job_id = id.job_id("job_test_123")

  let executions = [
    types.JobExecution(
      id: 1,
      job_id: job_id,
      started_at: now,
      completed_at: option.Some(now),
      status: types.Completed,
      error_message: option.None,
      attempt_number: 1,
      duration_ms: option.Some(1500),
      output: option.None,
      triggered_by: types.Manual,
    ),
  ]

  let table = scheduler.build_executions_table(executions)

  // Should contain headers and at least one row
  table
  |> should.not_equal("")
}

pub fn build_executions_table_empty_test() {
  let executions = []
  let table = scheduler.build_executions_table(executions)

  // Should contain headers even with empty executions
  table
  |> should.not_equal("")
}

pub fn format_duration_test() {
  scheduler.format_duration(option.Some(1500))
  |> should.equal("1.50s")

  scheduler.format_duration(option.Some(500))
  |> should.equal("0.50s")

  scheduler.format_duration(option.Some(60_000))
  |> should.equal("60.00s")

  scheduler.format_duration(option.None)
  |> should.equal("-")
}
