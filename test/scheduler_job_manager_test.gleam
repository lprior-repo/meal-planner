//// Tests for scheduler job manager

import gleam/json
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// create_job tests
// ============================================================================

pub fn create_job_weekly_generation_test() {
  let result =
    job_manager.create_job(
      job_type: types.WeeklyGeneration,
      frequency: types.Weekly(day: 5, hour: 6, minute: 0),
      trigger_source: types.Scheduled,
    )

  result
  |> should.be_ok
}

pub fn create_job_auto_sync_test() {
  let result =
    job_manager.create_job(
      job_type: types.AutoSync,
      frequency: types.EveryNHours(hours: 2),
      trigger_source: types.Scheduled,
    )

  result
  |> should.be_ok
}

// ============================================================================
// mark_job_running tests
// ============================================================================

pub fn mark_job_running_success_test() {
  let assert Ok(job) =
    job_manager.create_job(
      job_type: types.WeeklyGeneration,
      frequency: types.Weekly(day: 5, hour: 6, minute: 0),
      trigger_source: types.Scheduled,
    )

  let result = job_manager.mark_job_running(job.id)

  result
  |> should.be_ok
}

// ============================================================================
// mark_job_completed tests
// ============================================================================

pub fn mark_job_completed_success_test() {
  let assert Ok(job) =
    job_manager.create_job(
      job_type: types.AutoSync,
      frequency: types.EveryNHours(hours: 2),
      trigger_source: types.Scheduled,
    )
  let assert Ok(_execution) = job_manager.mark_job_running(job.id)

  let result = job_manager.mark_job_completed(job.id, output: option.None)

  result
  |> should.be_ok
}

pub fn mark_job_completed_with_output_test() {
  let assert Ok(job) =
    job_manager.create_job(
      job_type: types.WeeklyGeneration,
      frequency: types.Weekly(day: 5, hour: 6, minute: 0),
      trigger_source: types.Scheduled,
    )
  let assert Ok(_execution) = job_manager.mark_job_running(job.id)

  let output = json.object([#("recipes_generated", json.int(7))])
  let result =
    job_manager.mark_job_completed(job.id, output: option.Some(output))

  result
  |> should.be_ok
}

// ============================================================================
// mark_job_failed tests
// ============================================================================

pub fn mark_job_failed_success_test() {
  let assert Ok(job) =
    job_manager.create_job(
      job_type: types.AutoSync,
      frequency: types.EveryNHours(hours: 2),
      trigger_source: types.Scheduled,
    )
  let assert Ok(_execution) = job_manager.mark_job_running(job.id)

  let result =
    job_manager.mark_job_failed(job.id, error: "API connection timeout")

  result
  |> should.be_ok
}

// ============================================================================
// get_next_pending_jobs tests
// ============================================================================

pub fn get_next_pending_jobs_empty_test() {
  let result = job_manager.get_next_pending_jobs(limit: 10)

  result
  |> should.be_ok
}

pub fn get_next_pending_jobs_limit_test() {
  let result = job_manager.get_next_pending_jobs(limit: 5)

  result
  |> should.be_ok

  let assert Ok(jobs) = result
  jobs
  |> should.be_list
}
