/// Shore async commands for the CLI
///
/// Wraps long-running operations (API calls, DB queries) as Shore effect functions
import meal_planner/cli/types.{type Msg}
import meal_planner/ncp
import meal_planner/scheduler/job_manager
import meal_planner/scheduler/types as scheduler_types

/// Search foods via FatSecret API
/// Returns an effect function that Shore will execute
pub fn search_foods(
  query: String,
  on_result: fn(Result(List(Nil), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Call actual foods_service.search(query)
    // For now, return a placeholder
    case query {
      "" -> Error("Empty search query")
      _ -> Ok([])
    }
    |> on_result
  }
}

/// Get food details from FatSecret API
/// Returns an effect function that Shore will execute
pub fn get_food_details(
  food_id: String,
  on_result: fn(Result(String, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Call actual foods_service.get(food_id)
    case food_id {
      "" -> Error("Invalid food ID")
      _ -> Ok("Food details placeholder")
    }
    |> on_result
  }
}

// ============================================================================
// Nutrition Commands
// ============================================================================

/// Get nutrition goals
pub fn get_nutrition_goals(
  on_result: fn(Result(ncp.NutritionGoals, String)) -> Msg,
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
  on_result: fn(Result(#(ncp.NutritionData, ncp.DeviationResult), String)) ->
    Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Calculate from diary entries
    let _ = date
    let consumed =
      ncp.NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    let goals = ncp.get_default_goals()
    let deviation = ncp.calculate_deviation(goals, consumed)
    Ok(#(consumed, deviation))
    |> on_result
  }
}

/// Get nutrition trends over specified number of days
pub fn get_nutrition_trends(
  days: Int,
  on_result: fn(Result(ncp.TrendAnalysis, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Calculate trends from history
    let _ = days
    Error("Trend analysis not yet implemented")
    |> on_result
  }
}

/// Check nutrition compliance for a specific date
pub fn check_nutrition_compliance(
  date: String,
  tolerance: Float,
  on_result: fn(Result(#(ncp.DeviationResult, Bool), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Calculate from diary entries
    let _ = date
    let consumed =
      ncp.NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
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
    // TODO: Query from database
    case job_manager.get_next_pending_jobs(limit: 100) {
      Ok(jobs) -> Ok(jobs)
      Error(_) -> Ok([])
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
    // TODO: Query from database by job_id
    let _ = job_id
    Error("Job not found")
    |> on_result
  }
}

/// Manually trigger a job
pub fn trigger_job(
  job_id: String,
  on_result: fn(Result(scheduler_types.JobExecution, String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Trigger job execution
    let _ = job_id
    Error("Job triggering not yet implemented")
    |> on_result
  }
}

/// List execution history for a job
pub fn list_job_executions(
  job_id: String,
  on_result: fn(Result(List(scheduler_types.JobExecution), String)) -> Msg,
) -> fn() -> Msg {
  fn() {
    // TODO: Query execution history from database
    let _ = job_id
    Ok([])
    |> on_result
  }
}
