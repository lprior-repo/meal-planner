/// Shore async commands for the CLI
///
/// Wraps long-running operations (API calls, DB queries) as Shore effect functions
import gleam/int
import gleam/string
import meal_planner/cli/types.{type Msg}
import meal_planner/fatsecret/foods/service as foods_service
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/id
import meal_planner/ncp
import meal_planner/ncp/types as ncp_types
import meal_planner/scheduler/errors as scheduler_errors
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types as scheduler_types

/// Search foods via FatSecret API
/// Returns an effect function that Shore will execute
pub fn search_foods(
  query: String,
  on_result: fn(Result(List(food_types.FoodSearchResult), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case string.trim(query) {
      "" -> Error("Empty search query")
      trimmed_query -> {
        case foods_service.search_foods_simple(trimmed_query) {
          Ok(response) -> Ok(response.foods)
          Error(err) -> Error(foods_service.error_to_string(err))
        }
      }
    }
    |> on_result
  }
}

/// Get food details from FatSecret API
/// Returns an effect function that Shore will execute
pub fn get_food_details(
  food_id: String,
  on_result: fn(Result(food_types.Food, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case string.trim(food_id) {
      "" -> Error("Invalid food ID")
      id -> {
        case foods_service.get_food(food_types.food_id(id)) {
          Ok(food) -> Ok(food)
          Error(err) -> Error(foods_service.error_to_string(err))
        }
      }
    }
    |> on_result
  }
}

// ============================================================================
// Nutrition Commands
// ============================================================================

/// Get nutrition goals
pub fn get_nutrition_goals(
  on_result: fn(Result(ncp_types.NutritionGoals, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Load from database, for now use defaults
    Ok(ncp.get_default_goals())
    |> on_result
  }
}

/// Get nutrition analysis for a specific date
pub fn get_nutrition_analysis(
  date: String,
  on_result: fn(
    Result(#(ncp_types.NutritionData, ncp_types.DeviationResult), String),
  ) ->
    Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Calculate from diary entries
    let _ = date
    let consumed =
      ncp_types.NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    let goals = ncp.get_default_goals()
    let deviation = ncp.calculate_deviation(goals, consumed)
    Ok(#(consumed, deviation))
    |> on_result
  }
}

/// Get nutrition trends over specified number of days
pub fn get_nutrition_trends(
  days: Int,
  on_result: fn(Result(ncp_types.TrendAnalysis, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case ncp.get_nutrition_history(days) {
      Ok(history) -> {
        let trends = ncp.analyze_nutrition_trends(history)
        Ok(trends)
      }
      Error(err) -> Error(err)
    }
    |> on_result
  }
}

/// Check nutrition compliance for a specific date
pub fn check_nutrition_compliance(
  date: String,
  tolerance: Float,
  on_result: fn(Result(#(ncp_types.DeviationResult, Bool), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Calculate from diary entries
    let _ = date
    let consumed =
      ncp_types.NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    let goals = ncp.get_default_goals()
    let deviation = ncp.calculate_deviation(goals, consumed)
    let compliant = ncp.deviation_is_within_tolerance(deviation, tolerance)
    Ok(#(deviation, compliant))
    |> on_result
  }
}

// ============================================================================
// Scheduler Commands
// ============================================================================

/// List all scheduled jobs
pub fn list_jobs(
  on_result: fn(Result(List(scheduler_types.ScheduledJob), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case job_manager.get_next_pending_jobs(limit: 100) {
      Ok(jobs) -> Ok(jobs)
      Error(err) -> Error(format_scheduler_error(err))
    }
    |> on_result
  }
}

/// Get status of a specific job
pub fn get_job_status(
  job_id: String,
  on_result: fn(Result(scheduler_types.ScheduledJob, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case string.trim(job_id) {
      "" -> Error("Invalid job ID")
      _ -> Error("Job lookup requires database connection")
    }
    |> on_result
  }
}

/// Manually trigger a job
pub fn trigger_job(
  job_id: String,
  on_result: fn(Result(scheduler_types.JobExecution, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case string.trim(job_id) {
      "" -> Error("Invalid job ID")
      trimmed_id -> {
        let job = id.job_id(trimmed_id)
        case job_manager.mark_job_running(job) {
          Ok(execution) -> Ok(execution)
          Error(err) -> Error(format_scheduler_error(err))
        }
      }
    }
    |> on_result
  }
}

/// List execution history for a job
pub fn list_job_executions(
  job_id: String,
  on_result: fn(Result(List(scheduler_types.JobExecution), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    let _ = job_id
    // Execution history requires database query
    Ok([])
    |> on_result
  }
}

/// Create a new scheduled job
pub fn create_job(
  job_type: scheduler_types.JobType,
  frequency: scheduler_types.JobFrequency,
  on_result: fn(Result(scheduler_types.ScheduledJob, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    case
      job_manager.create_job(
        job_type: job_type,
        frequency: frequency,
        trigger_source: scheduler_types.Manual,
      )
    {
      Ok(job) -> Ok(job)
      Error(err) -> Error(format_scheduler_error(err))
    }
    |> on_result
  }
}

/// Format scheduler error for display
fn format_scheduler_error(err: scheduler_errors.AppError) -> String {
  case err {
    scheduler_errors.ApiError(code, message) ->
      "API error (" <> int.to_string(code) <> "): " <> message
    scheduler_errors.TimeoutError(timeout_ms) ->
      "Timeout after " <> int.to_string(timeout_ms) <> "ms"
    scheduler_errors.DatabaseError(msg) -> "Database error: " <> msg
    scheduler_errors.TransactionError(msg) -> "Transaction error: " <> msg
    scheduler_errors.JobNotFound(job_id) ->
      "Job not found: " <> id.job_id_to_string(job_id)
    scheduler_errors.JobAlreadyRunning(job_id) ->
      "Job already running: " <> id.job_id_to_string(job_id)
    scheduler_errors.ExecutionFailed(job_id, reason) ->
      "Job " <> id.job_id_to_string(job_id) <> " failed: " <> reason
    scheduler_errors.MaxRetriesExceeded(job_id) ->
      "Max retries exceeded for job: " <> id.job_id_to_string(job_id)
    scheduler_errors.InvalidConfiguration(reason) ->
      "Invalid configuration: " <> reason
    scheduler_errors.InvalidJobType(job_type) ->
      "Invalid job type: " <> job_type
    scheduler_errors.SchedulerDisabled -> "Scheduler is disabled"
    scheduler_errors.DependencyNotMet(job_id, dependency) ->
      "Job "
      <> id.job_id_to_string(job_id)
      <> " dependency not met: "
      <> id.job_id_to_string(dependency)
  }
}
