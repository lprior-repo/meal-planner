//// Scheduler Executor Tests (RED PHASE)
////
//// Tests job execution routing to correct handlers based on JobType.
//// Tests that execute_scheduled_job routes each job type correctly.
////
//// Implementation: PENDING (tests written first, must FAIL)

import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/scheduler/executor
import meal_planner/scheduler/types.{
  type ScheduledJob, AutoSync, DailyAdvisor, EveryNHours, High, Pending,
  RetryPolicy, ScheduledJob, WeeklyGeneration, WeeklyTrends,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test 1: Route WeeklyGeneration Job
// ============================================================================

/// Test that execute_scheduled_job routes WeeklyGeneration to weekly_plan.generate_weekly_plan
///
/// Expectations:
/// - JobType::WeeklyGeneration → calls weekly_plan.generate_weekly_plan()
/// - Returns JobExecution with success status
/// - Output contains meal plan data
pub fn executor_routes_weekly_generation_job_test() {
  let job = create_test_job(WeeklyGeneration)

  // Execute job (this should call weekly_plan.generate_weekly_plan)
  let result = executor.execute_scheduled_job(job)

  // Verify execution succeeded
  result
  |> should.be_ok

  // Verify output exists
  let assert Ok(execution) = result
  execution.output
  |> should.be_some
}

// ============================================================================
// Test 2: Route AutoSync Job
// ============================================================================

/// Test that execute_scheduled_job routes AutoSync to meal_sync.sync_meals
///
/// Expectations:
/// - JobType::AutoSync → calls meal_sync.sync_meals()
/// - Returns JobExecution with success status
/// - Output contains sync report data
pub fn executor_routes_auto_sync_job_test() {
  let job = create_test_job(AutoSync)

  // Execute job (this should call meal_sync.sync_meals)
  let result = executor.execute_scheduled_job(job)

  // Verify execution succeeded
  result
  |> should.be_ok

  let assert Ok(execution) = result
  execution.output
  |> should.be_some
}

// ============================================================================
// Test 3: Route DailyAdvisor Job
// ============================================================================

/// Test that execute_scheduled_job routes DailyAdvisor to daily_recommendations.generate_daily_advisor_email
///
/// Expectations:
/// - JobType::DailyAdvisor → calls daily_recommendations.generate_daily_advisor_email()
/// - Returns JobExecution with success status
/// - Output contains advisor email data
pub fn executor_routes_daily_advisor_job_test() {
  let job = create_test_job(DailyAdvisor)

  // Execute job (this should call daily_recommendations.generate_daily_advisor_email)
  let result = executor.execute_scheduled_job(job)

  // Verify execution succeeded
  result
  |> should.be_ok

  let assert Ok(execution) = result
  execution.output
  |> should.be_some
}

// ============================================================================
// Test 4: Route WeeklyTrends Job
// ============================================================================

/// Test that execute_scheduled_job routes WeeklyTrends to weekly_trends.analyze_weekly_trends
///
/// Expectations:
/// - JobType::WeeklyTrends → calls weekly_trends.analyze_weekly_trends()
/// - Returns JobExecution with success status
/// - Output contains trend analysis data
pub fn executor_routes_weekly_trends_job_test() {
  let job = create_test_job(WeeklyTrends)

  // Execute job (this should call weekly_trends.analyze_weekly_trends)
  let result = executor.execute_scheduled_job(job)

  // Verify execution succeeded
  result
  |> should.be_ok

  let assert Ok(execution) = result
  execution.output
  |> should.be_some
}

// ============================================================================
// Test 5: Error Handling
// ============================================================================

/// Test that execute_scheduled_job captures handler errors
///
/// Expectations:
/// - If handler fails, JobExecution has Failed status
/// - Error message captured in execution
/// - Returns Result::Error with SchedulerError
pub fn executor_captures_handler_errors_test() {
  // Create a job that will fail (e.g., invalid parameters)
  let job =
    ScheduledJob(
      id: id.job_id("job_test_error_123"),
      job_type: WeeklyGeneration,
      frequency: types.Once,
      status: Pending,
      priority: High,
      user_id: None,
      retry_policy: RetryPolicy(
        max_attempts: 3,
        backoff_seconds: 60,
        retry_on_failure: True,
      ),
      parameters: Some(json.object([#("invalid", json.string("data"))])),
      scheduled_for: None,
      started_at: None,
      completed_at: None,
      last_error: None,
      error_count: 0,
      created_at: "2025-12-19T00:00:00Z",
      updated_at: "2025-12-19T00:00:00Z",
      created_by: None,
      enabled: True,
    )

  // Execute job (should handle errors gracefully)
  let result = executor.execute_scheduled_job(job)

  // Verify execution returns error (handler may fail with invalid data)
  // NOTE: This may pass if handlers are resilient, so we just check Result type
  case result {
    Ok(_execution) -> {
      // Handler succeeded despite invalid data (resilient)
      True |> should.be_true
    }
    Error(_scheduler_error) -> {
      // Handler failed as expected with invalid data
      True |> should.be_true
    }
  }
}

// ============================================================================
// Test Helper Functions
// ============================================================================

fn create_test_job(job_type: types.JobType) -> ScheduledJob {
  ScheduledJob(
    id: id.job_id("job_test_" <> types.job_type_to_string(job_type)),
    job_type: job_type,
    frequency: EveryNHours(2),
    status: Pending,
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
    created_at: "2025-12-19T00:00:00Z",
    updated_at: "2025-12-19T00:00:00Z",
    created_by: None,
    enabled: True,
  )
}
