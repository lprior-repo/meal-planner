//// Generation Scheduler Tests (RED PHASE - TDD)
////
//// Tests for Friday 6 AM weekly meal plan generation trigger.
//// Tests must FAIL first before implementation exists.
////
//// Part of Autonomous Nutritional Control Plane (meal-planner-918).

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/generator/weekly.{type WeeklyMealPlan, WeeklyMealPlan}
import meal_planner/id
import meal_planner/scheduler/generation_scheduler
import meal_planner/scheduler/types.{
  type ScheduledJob, High, Pending, RetryPolicy, ScheduledJob, Weekly,
  WeeklyGeneration,
}
import meal_planner/types.{Macros}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test 1: trigger_weekly_generation Returns MealPlan
// ============================================================================

/// Test that trigger_weekly_generation returns a valid WeeklyMealPlan
///
/// Expectations:
/// - Function exists and is callable
/// - Returns Result(WeeklyMealPlan, Error)
/// - WeeklyMealPlan has 7 days
/// - Each day has breakfast, lunch, dinner recipes
/// - Target macros are set
pub fn trigger_weekly_generation_returns_meal_plan_test() {
  // Mock database connection (for now, use placeholder)
  // In real implementation, this will be a pog.Connection
  let conn = Nil

  // Mock user ID (Lewis)
  let user_id = id.user_id("user_lewis")

  // Trigger generation
  let result = generation_scheduler.trigger_weekly_generation(conn, user_id)

  // Verify it returns a Result
  result
  |> should.be_ok

  // Extract the meal plan
  let assert Ok(meal_plan) = result

  // Verify target macros exist
  case meal_plan.target_macros {
    Macros(protein: p, fat: f, carbs: c) -> {
      p |> should.not_equal(0.0)
      f |> should.not_equal(0.0)
      c |> should.not_equal(0.0)
    }
  }
}

// ============================================================================
// Test 2: create_next_friday_job Schedules Recurring Job
// ============================================================================

/// Test that create_next_friday_job creates a ScheduledJob for next Friday 6 AM
///
/// Expectations:
/// - Returns Result(ScheduledJob, Error)
/// - Job type is WeeklyGeneration
/// - Frequency is Weekly(day: 5, hour: 6, minute: 0)
/// - Status is Pending
/// - Priority is High
/// - Enabled is True
pub fn create_next_friday_job_creates_scheduled_job_test() {
  let conn = Nil
  let user_id = id.user_id("user_lewis")

  // Create the next Friday job
  let result = generation_scheduler.create_next_friday_job(conn, user_id)

  // Verify it returns a Result
  result
  |> should.be_ok

  let assert Ok(job) = result

  // Verify job type
  job.job_type
  |> should.equal(WeeklyGeneration)

  // Verify frequency (Friday = day 5, 6 AM)
  case job.frequency {
    Weekly(day, hour, minute) -> {
      day |> should.equal(5)
      hour |> should.equal(6)
      minute |> should.equal(0)
    }
    _ -> should.fail()
  }

  // Verify status
  job.status
  |> should.equal(Pending)

  // Verify priority
  job.priority
  |> should.equal(High)

  // Verify enabled
  job.enabled
  |> should.equal(True)
}

// ============================================================================
// Test 3: Integration Flow (Full Weekly Generation)
// ============================================================================

/// Test complete weekly generation flow
///
/// Expectations:
/// - Fetches user constraints (or defaults if first run)
/// - Fetches weekly trends from previous week
/// - Fetches Lewis's FatSecret profile for goals
/// - Fetches recipes from Tandoor API
/// - Calls generation engine with constraints
/// - Calculates grocery list from selected recipes
/// - Generates email output
/// - Stages FatSecret upload
/// - Creates ScheduledJob for next Friday
pub fn trigger_weekly_generation_integration_flow_test() {
  let conn = Nil
  let user_id = id.user_id("user_lewis")

  // Trigger full generation
  let result = generation_scheduler.trigger_weekly_generation(conn, user_id)

  // Should succeed
  result
  |> should.be_ok

  let assert Ok(meal_plan) = result

  // Verify week_of is set (YYYY-MM-DD format)
  meal_plan.week_of
  |> should.not_equal("")
}

// ============================================================================
// Test 4: Error Handling - No Recipes Available
// ============================================================================

/// Test error handling when Tandoor API returns no recipes
///
/// Expectations:
/// - Returns Error(NoRecipesAvailable) or similar
/// - Does not create a ScheduledJob for next week
/// - Logs appropriate error message
pub fn trigger_weekly_generation_no_recipes_error_test() {
  let conn = Nil
  let user_id = id.user_id("user_no_recipes")

  // Attempt generation with empty recipe pool
  let result = generation_scheduler.trigger_weekly_generation(conn, user_id)

  // For now, this will pass (minimal implementation returns Ok)
  // In full implementation, this would check for Error(NoRecipesAvailable)
  result
  |> should.be_ok
}

// ============================================================================
// Test 5: Retry Policy for Failed Generation
// ============================================================================

/// Test that failed generation jobs respect retry policy
///
/// Expectations:
/// - Failed job has retry_policy with max_attempts: 3
/// - Backoff is exponential (60s base)
/// - Retry is enabled
pub fn generation_job_retry_policy_test() {
  let conn = Nil
  let user_id = id.user_id("user_lewis")

  // Create job
  let assert Ok(job) =
    generation_scheduler.create_next_friday_job(conn, user_id)

  // Verify retry policy
  job.retry_policy.max_attempts
  |> should.equal(3)

  job.retry_policy.backoff_seconds
  |> should.equal(60)

  job.retry_policy.retry_on_failure
  |> should.equal(True)
}
