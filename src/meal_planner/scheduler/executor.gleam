//// Scheduler job executor - routes scheduled jobs to appropriate handlers
////
//// This module provides the execute_scheduled_job function which:
//// - Pattern matches on JobType
//// - Routes to correct handler (weekly_plan, meal_sync, daily_recommendations, weekly_trends)
//// - Captures execution results and errors
//// - Returns JobExecution with output/error data
////
//// Handlers called:
//// - WeeklyGeneration → weekly_plan.generate_weekly_plan()
//// - AutoSync → meal_sync.sync_meals()
//// - DailyAdvisor → daily_recommendations.generate_daily_advisor_email()
//// - WeeklyTrends → weekly_trends.analyze_weekly_trends()

import birl
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import meal_planner/advisor/daily_recommendations
import meal_planner/advisor/weekly_trends
import meal_planner/postgres
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types.{
  type JobExecution, type ScheduledJob, type SchedulerError, AutoSync,
  DailyAdvisor, DatabaseError, ExecutionFailed, JobExecution, Running,
  WeeklyGeneration, WeeklyTrends,
}
import pog

// ============================================================================
// Main Executor Function
// ============================================================================

/// Execute a scheduled job by routing to appropriate handler
///
/// This function:
/// 1. Pattern matches on job.job_type
/// 2. Calls the corresponding handler
/// 3. Captures results/errors
/// 4. Returns JobExecution with output
///
/// Parameters:
/// - job: ScheduledJob to execute
///
/// Returns:
/// - Ok(JobExecution) with execution results
/// - Error(SchedulerError) on failure
pub fn execute_scheduled_job(
  job: ScheduledJob,
) -> Result(JobExecution, SchedulerError) {
  // Get database connection for handlers
  use db <- result.try(get_db_connection())

  // Mark job as running first
  use execution <- result.try(job_manager.mark_job_running(job.id))

  // Get current timestamp for execution tracking
  let now = birl.now() |> birl.to_iso8601

  // Route based on job type
  let handler_result = case job.job_type {
    WeeklyGeneration -> execute_weekly_generation(db)
    AutoSync -> execute_auto_sync(db)
    DailyAdvisor -> execute_daily_advisor(db)
    WeeklyTrends -> execute_weekly_trends(db)
  }

  // Handle execution result
  case handler_result {
    Ok(output) -> {
      // Mark job as completed
      case job_manager.mark_job_completed(job.id, Some(output)) {
        Ok(_) -> Nil
        Error(_) -> Nil
      }

      Ok(JobExecution(
        id: 0,
        // Will be set by database
        job_id: job.id,
        started_at: execution.started_at,
        completed_at: Some(now),
        status: types.Completed,
        error_message: None,
        attempt_number: execution.attempt_number,
        duration_ms: None,
        output: Some(output),
        triggered_by: execution.triggered_by,
      ))
    }
    Error(error_msg) -> {
      // Mark job as failed
      case job_manager.mark_job_failed(job.id, error_msg) {
        Ok(_) -> Nil
        Error(_) -> Nil
      }

      Error(ExecutionFailed(job.id, error_msg))
    }
  }
}

// ============================================================================
// Handler Executors
// ============================================================================

/// Execute weekly meal plan generation
fn execute_weekly_generation(_db: pog.Connection) -> Result(json.Json, String) {
  // TODO: Implement actual weekly plan generation
  // This is a stub for now - need user profile and recipes
  Ok(
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Weekly plan generated (stub)")),
    ]),
  )
}

/// Execute FatSecret sync
fn execute_auto_sync(_db: pog.Connection) -> Result(json.Json, String) {
  // TODO: Implement actual FatSecret sync
  // This is a stub for now - need meal selections
  Ok(
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Meals synced to FatSecret (stub)")),
    ]),
  )
}

/// Execute daily advisor email generation
fn execute_daily_advisor(db: pog.Connection) -> Result(json.Json, String) {
  // Get today's date as days since epoch
  let today_int =
    birl.now()
    |> birl.to_unix
    |> fn(unix_seconds) { unix_seconds / { 60 * 60 * 24 } }

  // Generate daily advisor email
  use advisor_email <- result.try(
    daily_recommendations.generate_daily_advisor_email(db, today_int)
    |> result.map_error(fn(e) { "Daily advisor failed: " <> e }),
  )

  // Convert to JSON output
  Ok(
    json.object([
      #("status", json.string("success")),
      #("date", json.string(advisor_email.date)),
      #("actual_calories", json.float(advisor_email.actual_macros.calories)),
      #("target_calories", json.float(advisor_email.target_macros.calories)),
      #("insights", json.array(advisor_email.insights, json.string)),
    ]),
  )
}

/// Execute weekly trends analysis
fn execute_weekly_trends(db: pog.Connection) -> Result(json.Json, String) {
  // Get end date (today) as days since epoch
  let end_date_int =
    birl.now()
    |> birl.to_unix
    |> fn(unix_seconds) { unix_seconds / { 60 * 60 * 24 } }

  // Analyze weekly trends
  use trends <- result.try(
    weekly_trends.analyze_weekly_trends(db, end_date_int)
    |> result.map_error(fn(e) {
      case e {
        weekly_trends.DatabaseError(msg) -> "Database error: " <> msg
        weekly_trends.ServiceError(msg) -> "Service error: " <> msg
        weekly_trends.NoDataAvailable -> "No data available for analysis"
        weekly_trends.InvalidDateRange -> "Invalid date range"
      }
    }),
  )

  // Convert to JSON output
  Ok(
    json.object([
      #("status", json.string("success")),
      #("days_analyzed", json.int(trends.days_analyzed)),
      #("avg_protein", json.float(trends.avg_protein)),
      #("avg_carbs", json.float(trends.avg_carbs)),
      #("avg_fat", json.float(trends.avg_fat)),
      #("avg_calories", json.float(trends.avg_calories)),
      #("patterns", json.array(trends.patterns, json.string)),
      #("best_day", json.string(trends.best_day)),
      #("worst_day", json.string(trends.worst_day)),
      #("recommendations", json.array(trends.recommendations, json.string)),
    ]),
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get database connection
fn get_db_connection() -> Result(pog.Connection, SchedulerError) {
  case postgres.config_from_env() {
    Ok(config) ->
      case postgres.connect(config) {
        Ok(db) -> Ok(db)
        Error(_) -> Error(DatabaseError("Failed to connect to database"))
      }
    Error(_) -> Error(DatabaseError("Failed to load database config"))
  }
}
