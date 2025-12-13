/// Example integration patterns for performance monitoring
/// This module demonstrates how to wire monitoring into critical paths
///
/// This is NOT meant to be used directly, but rather as a reference for
/// implementing monitoring in actual business logic modules.
///
/// Patterns shown:
/// 1. Measuring individual function execution
/// 2. Recording operation success/failure
/// 3. Tracking batch operations
/// 4. Recording error types
/// 5. Monitoring resource usage

import gleam/result
import meal_planner/metrics/collector
import meal_planner/metrics/tandoor_monitoring as tm
import meal_planner/metrics/ncp_monitoring as nm
import meal_planner/metrics/storage_monitoring as sm
import meal_planner/tandoor/client

// ============================================================================
// Example 1: Monitoring Tandoor API Calls
// ============================================================================

/// Example: Monitor a Tandoor API call with retry logic
/// This would be used in tandoor/client.gleam or similar
pub fn example_monitored_api_call(
  metrics: collector.MetricCollector,
  api_token: String,
  recipe_id: Int,
  max_retries: Int,
) -> Result(String, String) {
  let context = tm.start_api_call("/api/recipes/" <> int.to_string(recipe_id) <> "/", "GET")
  
  // Make API call (pseudocode)
  let result = call_tandoor_api(api_token, recipe_id)
  
  case result {
    Ok(response) -> {
      // Record success
      let _metrics = tm.record_api_success(metrics, context)
      Ok(response)
    }
    Error(error) -> {
      // Record failure with error classification
      let _metrics = tm.record_api_failure(metrics, context, error)
      
      // Determine if we should retry
      case should_retry(error, max_retries) {
        True -> {
          let _metrics = tm.record_retry_attempt(
            metrics,
            "/api/recipes/" <> int.to_string(recipe_id) <> "/",
            1,
            classify_error(error)
          )
          // Recursive retry (simplified)
          example_monitored_api_call(metrics, api_token, recipe_id, max_retries - 1)
        }
        False -> Error(client.error_to_string(error))
      }
    }
  }
}

/// Example: Monitor batch recipe sync
pub fn example_monitored_recipe_sync(
  metrics: collector.MetricCollector,
  recipes: List(String),
) -> collector.MetricCollector {
  let start_time = get_timestamp_ms()
  
  let #(synced, failed) = sync_recipes_batch(recipes)
  
  let end_time = get_timestamp_ms()
  let duration_ms = int.to_float(end_time - start_time)
  
  tm.record_recipe_sync_batch(
    metrics,
    list.length(recipes),
    synced,
    failed,
    duration_ms,
  )
}

// ============================================================================
// Example 2: Monitoring NCP Calculations
// ============================================================================

/// Example: Monitor deviation calculation
pub fn example_monitored_deviation_calc(
  metrics: collector.MetricCollector,
  goals: NutritionGoals,
  actual: NutritionData,
) -> #(collector.MetricCollector, DeviationResult) {
  let context = nm.start_deviation_calculation()
  
  // Calculate deviation (pseudocode)
  let deviation = calculate_deviation(goals, actual)
  
  let max_dev = max_absolute_deviation(deviation)
  let metrics = nm.record_deviation_calculation_success(metrics, context, max_dev)
  
  #(metrics, deviation)
}

/// Example: Monitor full NCP reconciliation
pub fn example_monitored_reconciliation(
  metrics: collector.MetricCollector,
  history: List(NutritionState),
  goals: NutritionGoals,
) -> #(collector.MetricCollector, ReconciliationResult) {
  let rec_context = nm.start_reconciliation(list.length(history))
  
  // Run reconciliation (pseudocode)
  let result = run_reconciliation(history, goals)
  
  let consistency = calculate_consistency_rate(history, goals, 5.0)
  
  let metrics = nm.record_reconciliation_success(
    metrics,
    rec_context,
    list.length(history),
    consistency,
    result.within_tolerance,
  )
  
  #(metrics, result)
}

/// Example: Monitor recipe scoring operation
pub fn example_monitored_recipe_scoring(
  metrics: collector.MetricCollector,
  deviation: DeviationResult,
  recipes: List(ScoredRecipe),
) -> #(collector.MetricCollector, List(RecipeSuggestion)) {
  let context = nm.start_recipe_scoring(list.length(recipes))
  
  // Score recipes
  let scored_recipes = score_recipes(deviation, recipes)
  let avg_score = calculate_avg_score(scored_recipes)
  
  let metrics = nm.record_recipe_scoring_success(
    metrics,
    context,
    list.length(scored_recipes),
    avg_score,
  )
  
  #(metrics, scored_recipes)
}

// ============================================================================
// Example 3: Monitoring Storage Queries
// ============================================================================

/// Example: Monitor simple SELECT query
pub fn example_monitored_query_select(
  metrics: collector.MetricCollector,
  conn: Connection,
  table: String,
  date: String,
) -> Result(#(collector.MetricCollector, List(Food)), String) {
  let context = sm.start_query("select", table)
  
  // Execute query
  let result = query_foods_by_date(conn, date)
  
  case result {
    Ok(foods) -> {
      let metrics = sm.record_query_success(metrics, context, list.length(foods))
      Ok(#(metrics, foods))
    }
    Error(err) -> {
      let metrics = sm.record_query_failure(metrics, context, err)
      Error(err)
    }
  }
}

/// Example: Monitor complex query with aggregation
pub fn example_monitored_daily_log_query(
  metrics: collector.MetricCollector,
  conn: Connection,
  date: String,
) -> Result(#(collector.MetricCollector, DailyLog), String) {
  let start_time = get_timestamp_ms()
  
  // Execute complex query
  let result = get_daily_log(conn, date)
  
  let end_time = get_timestamp_ms()
  let duration_ms = int.to_float(end_time - start_time)
  
  case result {
    Ok(daily_log) -> {
      let row_count = list.length(daily_log.entries)
      let metrics = sm.record_complex_query(
        metrics,
        "get_daily_log",
        duration_ms,
        row_count,
        True,
      )
      Ok(#(metrics, daily_log))
    }
    Error(err) -> {
      let metrics = sm.record_complex_query(
        metrics,
        "get_daily_log",
        duration_ms,
        0,
        False,
      )
      Error(err)
    }
  }
}

/// Example: Monitor INSERT operation
pub fn example_monitored_insert(
  metrics: collector.MetricCollector,
  conn: Connection,
  table: String,
  records: List(FoodLog),
) -> Result(#(collector.MetricCollector, Int), String) {
  let start_time = get_timestamp_ms()
  
  let result = insert_records(conn, table, records)
  
  let end_time = get_timestamp_ms()
  let duration_ms = int.to_float(end_time - start_time)
  
  case result {
    Ok(count) -> {
      let metrics = sm.record_insert(metrics, table, count, duration_ms)
      Ok(#(metrics, count))
    }
    Error(err) -> Error(err)
  }
}

/// Example: Monitor cache behavior
pub fn example_monitored_cache_lookup(
  metrics: collector.MetricCollector,
  cache: Cache,
  key: String,
) -> #(collector.MetricCollector, Option(Value)) {
  let result = cache.get(cache, key)
  
  let metrics = case result {
    Some(_val) -> sm.record_cache_hit(metrics, key)
    None -> sm.record_cache_miss(metrics, key)
  }
  
  #(metrics, result)
}

// ============================================================================
// Example 4: Monitoring Multiple Operations
// ============================================================================

/// Example: Monitor complete workflow combining multiple operations
pub fn example_complete_workflow(
  metrics: collector.MetricCollector,
  conn: Connection,
  user_id: Int,
  date: String,
) -> Result(#(collector.MetricCollector, ReconciliationResult), String) {
  // Step 1: Get food logs for the day
  use #(metrics, logs) <- result.try(example_monitored_daily_log_query(metrics, conn, date))
  
  // Step 2: Convert to nutrition data
  let nutrition_history = logs_to_nutrition_history(logs)
  
  // Step 3: Get nutrition goals for user (would be another monitored query)
  use #(metrics, goals) <- result.try(example_monitored_query_select(metrics, conn, "user_goals", user_id))
  
  // Step 4: Run reconciliation with monitoring
  let #(metrics, result) = example_monitored_reconciliation(
    metrics,
    nutrition_history,
    goals,
  )
  
  // Step 5: If outside tolerance, score recipes
  case result.within_tolerance {
    True -> Ok(#(metrics, result))
    False -> {
      // Get available recipes
      let recipes = get_available_recipes()
      
      // Score them
      let #(metrics, _suggestions) = example_monitored_recipe_scoring(
        metrics,
        result.deviation,
        recipes,
      )
      
      Ok(#(metrics, result))
    }
  }
}

// ============================================================================
// Helper Functions (Pseudocode)
// ============================================================================

fn call_tandoor_api(
  _token: String,
  _recipe_id: Int,
) -> Result(String, client.TandoorError) {
  // Would make actual HTTP call
  Ok("recipe_data")
}

fn should_retry(_error: client.TandoorError, _retries: Int) -> Bool {
  False
}

fn classify_error(_error: client.TandoorError) -> String {
  "unknown_error"
}

fn sync_recipes_batch(_recipes: List(String)) -> #(Int, Int) {
  #(0, 0)
}

fn calculate_deviation(
  _goals: NutritionGoals,
  _actual: NutritionData,
) -> DeviationResult {
  unimplemented()
}

fn max_absolute_deviation(_deviation: DeviationResult) -> Float {
  0.0
}

fn run_reconciliation(
  _history: List(NutritionState),
  _goals: NutritionGoals,
) -> ReconciliationResult {
  unimplemented()
}

fn calculate_consistency_rate(
  _history: List(NutritionState),
  _goals: NutritionGoals,
  _tolerance: Float,
) -> Float {
  0.0
}

fn score_recipes(
  _deviation: DeviationResult,
  _recipes: List(ScoredRecipe),
) -> List(RecipeSuggestion) {
  []
}

fn calculate_avg_score(_suggestions: List(RecipeSuggestion)) -> Float {
  0.0
}

fn query_foods_by_date(_conn: Connection, _date: String) -> Result(List(Food), String) {
  Ok([])
}

fn get_daily_log(_conn: Connection, _date: String) -> Result(DailyLog, String) {
  unimplemented()
}

fn insert_records(
  _conn: Connection,
  _table: String,
  _records: List(FoodLog),
) -> Result(Int, String) {
  Ok(0)
}

fn logs_to_nutrition_history(_logs: DailyLog) -> List(NutritionState) {
  []
}

fn get_available_recipes() -> List(ScoredRecipe) {
  []
}

fn get_timestamp_ms() -> Int {
  0
}

// ============================================================================
// Placeholder Types (would be imported in real implementation)
// ============================================================================

pub type Connection
pub type Cache
pub type Value
pub type Food
pub type FoodLog
pub type DailyLog
pub type NutritionGoals
pub type NutritionData
pub type NutritionState
pub type DeviationResult
pub type ScoredRecipe
pub type RecipeSuggestion
pub type ReconciliationResult
pub type Option(a) {
  Some(a)
  None
}
pub type Result(a, b) {
  Ok(a)
  Error(b)
}
pub type List(a)
