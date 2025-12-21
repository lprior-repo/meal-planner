/// Batch meal logging operations
///
/// Handles logging multiple meals to FatSecret in a single operation.
/// Provides partial failure handling and result aggregation.
import gleam/int
import gleam/list
import meal_planner/fatsecret/meal_logger/errors.{type MealLogError}
import meal_planner/types/recipe.{type MealPlanRecipe}

// ============================================================================
// Types
// ============================================================================

/// Batch meal log entry (recipe + context)
pub type BatchMealEntry {
  BatchMealEntry(
    recipe: MealPlanRecipe,
    servings: Int,
    date: String,
    meal_type: String,
  )
}

/// Batch operation result
pub type BatchResult(a) {
  BatchResult(
    /// Successfully processed items
    succeeded: List(a),
    /// Failed items with their errors
    failed: List(#(BatchMealEntry, MealLogError)),
  )
}

/// Single meal log result (for tracking in batch operations)
pub type MealLogResult {
  MealLogResult(
    recipe_id: String,
    date: String,
    meal_type: String,
    calories: Float,
    status: ResultStatus,
  )
}

pub type ResultStatus {
  Success
  Failed(error: String)
}

// ============================================================================
// Batch Logging
// ============================================================================

/// Log multiple meals to FatSecret in batch
///
/// Processes all entries, tracking successes and failures separately.
/// Does NOT stop on first failure - continues processing all entries.
///
/// ## Parameters
/// - entries: List of meals to log
/// - log_fn: Function to log a single meal
///
/// ## Returns
/// - Ok(BatchResult) with succeeded/failed lists
/// - Error only if complete batch failure (no successes)
///
/// ## Example
/// ```gleam
/// let entries = [
///   BatchMealEntry(recipe1, 2, "2025-01-15", "lunch"),
///   BatchMealEntry(recipe2, 1, "2025-01-15", "dinner"),
/// ]
/// let result = log_meals_batch(entries, sync_meal_to_fatsecret)
/// ```
pub fn log_meals_batch(
  entries entries: List(BatchMealEntry),
  log_fn log_fn: fn(MealPlanRecipe, Int, String, String) ->
    Result(a, MealLogError),
) -> Result(BatchResult(a), MealLogError) {
  let results =
    entries
    |> list.map(fn(entry) {
      case log_fn(entry.recipe, entry.servings, entry.date, entry.meal_type) {
        Ok(result) -> Ok(result)
        Error(error) -> Error(#(entry, error))
      }
    })

  let succeeded =
    results
    |> list.filter_map(fn(r) {
      case r {
        Ok(val) -> Ok(val)
        Error(_) -> Error(Nil)
      }
    })

  let failed =
    results
    |> list.filter_map(fn(r) {
      case r {
        Ok(_) -> Error(Nil)
        Error(err_tuple) -> Ok(err_tuple)
      }
    })

  // If all failed, return error
  case succeeded == [], failed != [] {
    True, True -> {
      let error_messages = list.map(failed, fn(f) { errors.to_string(f.1) })
      Error(errors.BatchPartialFailure(
        succeeded: 0,
        failed: list.length(failed),
        errors: error_messages,
      ))
    }
    _, _ -> Ok(BatchResult(succeeded: succeeded, failed: failed))
  }
}

// ============================================================================
// Batch Creation Helpers
// ============================================================================

/// Create batch entry from recipe and context
pub fn create_entry(
  recipe recipe: MealPlanRecipe,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
) -> BatchMealEntry {
  BatchMealEntry(
    recipe: recipe,
    servings: servings,
    date: date,
    meal_type: meal_type,
  )
}

/// Create batch entries for a full day's meals
///
/// ## Parameters
/// - meals: List of (recipe, servings, meal_type) tuples
/// - date: Date string (YYYY-MM-DD)
///
/// ## Returns
/// List of BatchMealEntry for the day
pub fn create_daily_batch(
  meals meals: List(#(MealPlanRecipe, Int, String)),
  date date: String,
) -> List(BatchMealEntry) {
  list.map(meals, fn(meal) {
    let #(recipe, servings, meal_type) = meal
    create_entry(recipe, servings, date, meal_type)
  })
}

// ============================================================================
// Result Analysis
// ============================================================================

/// Check if batch operation was fully successful
pub fn is_full_success(result: BatchResult(a)) -> Bool {
  result.failed == []
}

/// Check if batch operation had partial failures
pub fn is_partial_success(result: BatchResult(a)) -> Bool {
  let has_successes = result.succeeded != []
  let has_failures = result.failed != []
  has_successes && has_failures
}

/// Get success rate as percentage (0.0 to 1.0)
pub fn success_rate(result: BatchResult(a)) -> Float {
  let total = list.length(result.succeeded) + list.length(result.failed)
  case total == 0 {
    True -> 0.0
    False -> {
      let succeeded_float = int_to_float(list.length(result.succeeded))
      let total_float = int_to_float(total)
      succeeded_float /. total_float
    }
  }
}

/// Format batch result summary
pub fn format_summary(result: BatchResult(a)) -> String {
  let succeeded_count = list.length(result.succeeded)
  let failed_count = list.length(result.failed)
  let total = succeeded_count + failed_count

  "Batch result: "
  <> int.to_string(succeeded_count)
  <> "/"
  <> int.to_string(total)
  <> " succeeded ("
  <> format_percentage(success_rate(result))
  <> "%)"
}

fn format_percentage(rate: Float) -> String {
  let percentage = rate *. 100.0
  float_to_string(percentage)
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

@external(erlang, "erlang", "float_to_list")
fn float_to_string(f: Float) -> String
