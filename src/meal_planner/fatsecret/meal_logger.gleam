/// FatSecret Meal Logger
///
/// Syncs meal plans to FatSecret diary with exact macro tracking.
/// Part of NORTH STAR epic (meal-planner-gsa).
import gleam/result
import meal_planner/fatsecret/meal_logger/batch
import meal_planner/fatsecret/meal_logger/errors
import meal_planner/fatsecret/meal_logger/macro_calculator
import meal_planner/fatsecret/meal_logger/retry
import meal_planner/fatsecret/meal_logger/validators
import meal_planner/id
import meal_planner/types/recipe.{type MealPlanRecipe}

// ============================================================================
// Re-export types from submodules
// ============================================================================

/// Re-export error type for convenience
pub type MealLogError =
  errors.MealLogError

/// Re-export batch types for convenience
pub type BatchMealEntry =
  batch.BatchMealEntry

pub type BatchResult(a) =
  batch.BatchResult(a)

/// Re-export retry config for convenience
pub type RetryConfig =
  retry.RetryConfig

// ============================================================================
// Core Types
// ============================================================================

/// FatSecret diary meal log entry with exact macros
pub type MealLogEntry {
  MealLogEntry(
    recipe_id: String,
    meal_type: String,
    date: String,
    calories: Float,
    protein_g: Float,
    fat_g: Float,
    carbs_g: Float,
  )
}

// ============================================================================
// Sync Functions
// ============================================================================

/// Sync a meal to FatSecret diary with exact macro calculations
///
/// Calculates total macros by multiplying recipe per-serving macros by servings count.
/// No rounding - exact floating point values preserved for precision.
///
/// Now uses modular validators and macro calculator for improved reusability.
///
/// ## Parameters
/// - recipe: The meal plan recipe with per-serving macros
/// - servings: Number of servings consumed
/// - date: Date string (YYYY-MM-DD format)
/// - meal_type: Meal type ("breakfast", "lunch", "dinner", "snack")
///
/// ## Returns
/// - Ok(MealLogEntry) with exact calculated macros
/// - Error(String) if validation fails (maintains backward compatibility)
pub fn sync_meal_to_fatsecret(
  recipe recipe: MealPlanRecipe,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
) -> Result(MealLogEntry, String) {
  // Use new modular validation and calculation
  case sync_meal_to_fatsecret_typed(recipe, servings, date, meal_type) {
    Ok(entry) -> Ok(entry)
    Error(error) -> Error(errors.to_string(error))
  }
}

/// Sync a meal to FatSecret with typed errors (new version)
///
/// Same as sync_meal_to_fatsecret but returns typed MealLogError
/// instead of String for better error handling.
///
/// ## Parameters
/// - recipe: The meal plan recipe with per-serving macros
/// - servings: Number of servings consumed
/// - date: Date string (YYYY-MM-DD format)
/// - meal_type: Meal type ("breakfast", "lunch", "dinner", "snack")
///
/// ## Returns
/// - Ok(MealLogEntry) with exact calculated macros
/// - Error(MealLogError) if validation fails
pub fn sync_meal_to_fatsecret_typed(
  recipe recipe: MealPlanRecipe,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
) -> Result(MealLogEntry, MealLogError) {
  // Validate servings
  use validated_servings <- result.try(validators.validate_servings(servings))

  // Validate date
  use validated_date <- result.try(validators.validate_date(date))

  // Validate meal type
  use validated_meal_type <- result.try(validators.validate_meal_type(meal_type))

  // Get per-serving macros from recipe
  let per_serving_macros = recipe.recipe_macros_per_serving(recipe)

  // Calculate total macros using macro_calculator module
  let servings_float = macro_calculator.int_to_float(validated_servings)
  let total_macros =
    macro_calculator.scale_by_servings(per_serving_macros, servings_float)

  // Validate macros
  use validated_macros <- result.try(validators.validate_macros(total_macros))

  // Calculate exact calories using macro_calculator module
  let total_calories = macro_calculator.calculate_calories(validated_macros)

  // Get recipe ID as string
  let recipe_id_value = recipe.recipe_id(recipe)
  let recipe_id_string = id.recipe_id_to_string(recipe_id_value)

  // Validate recipe ID
  use validated_recipe_id <- result.try(validators.validate_recipe_id(
    recipe_id_string,
  ))

  // Create meal log entry with exact values
  Ok(MealLogEntry(
    recipe_id: validated_recipe_id,
    meal_type: validated_meal_type,
    date: validated_date,
    calories: total_calories,
    protein_g: validated_macros.protein,
    fat_g: validated_macros.fat,
    carbs_g: validated_macros.carbs,
  ))
}

// ============================================================================
// Batch Operations
// ============================================================================

/// Batch log multiple meals to FatSecret efficiently
///
/// Now uses the modular batch logging system with improved error handling.
/// Maintains backward compatibility with old BatchResult type.
///
/// ## Parameters
/// - meals: List of BatchMealEntry
///
/// ## Returns
/// - Ok with successes and failures separated
/// - Error if complete batch failure
pub fn batch_log_meals(
  meals: List(BatchMealEntry),
) -> Result(batch.BatchResult(MealLogEntry), String) {
  case
    batch.log_meals_batch(meals, fn(recipe, servings, date, meal_type) {
      sync_meal_to_fatsecret_typed(recipe, servings, date, meal_type)
    })
  {
    Ok(result) -> Ok(result)
    Error(error) -> Error(errors.to_string(error))
  }
}

/// Create a batch entry for convenience
pub fn create_batch_entry(
  recipe recipe: MealPlanRecipe,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
) -> BatchMealEntry {
  batch.create_entry(recipe, servings, date, meal_type)
}

/// Create batch entries for a full day
pub fn create_daily_batch(
  meals meals: List(#(MealPlanRecipe, Int, String)),
  date date: String,
) -> List(BatchMealEntry) {
  batch.create_daily_batch(meals, date)
}

// ============================================================================
// Retry Operations
// ============================================================================

/// Sync meal with retry on transient failures
///
/// Uses default retry config (3 attempts, exponential backoff).
/// Maintained for backward compatibility with old retry_with_backoff.
///
/// ## Parameters
/// - recipe: The meal plan recipe
/// - servings: Number of servings
/// - date: Date string (YYYY-MM-DD)
/// - meal_type: Meal type
///
/// ## Returns
/// - Ok(MealLogEntry) if successful (possibly after retries)
/// - Error(String) if all retries exhausted
pub fn sync_meal_with_retry(
  recipe recipe: MealPlanRecipe,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
) -> Result(MealLogEntry, String) {
  let config = retry.default_config()
  case
    retry.with_retry(config, fn() {
      sync_meal_to_fatsecret_typed(recipe, servings, date, meal_type)
    })
  {
    Ok(entry) -> Ok(entry)
    Error(error) -> Error(errors.to_string(error))
  }
}

/// Sync meals batch with retry
///
/// Uses default retry config for entire batch operation.
///
/// ## Parameters
/// - entries: List of meals to log
///
/// ## Returns
/// - Ok(BatchResult) if successful
/// - Error(String) if all retries exhausted
pub fn sync_meals_batch_with_retry(
  entries entries: List(BatchMealEntry),
) -> Result(batch.BatchResult(MealLogEntry), String) {
  let config = retry.default_config()
  case
    retry.with_retry(config, fn() {
      batch.log_meals_batch(entries, fn(recipe, servings, date, meal_type) {
        sync_meal_to_fatsecret_typed(recipe, servings, date, meal_type)
      })
    })
  {
    Ok(result) -> Ok(result)
    Error(error) -> Error(errors.to_string(error))
  }
}

/// Retry an operation with exponential backoff (legacy)
///
/// DEPRECATED: Use sync_meal_with_retry instead for type-safe retries.
/// Maintained for backward compatibility.
///
/// ## Parameters
/// - operation: Function to retry
/// - max_retries: Maximum number of retry attempts
/// - initial_delay_ms: Initial delay in milliseconds
///
/// ## Returns
/// - Ok(T) if operation succeeds within retry limit
/// - Error("Max retries exceeded: <error>") if all retries fail
pub fn retry_with_backoff(
  operation operation: fn() -> Result(a, String),
  max_retries max_retries: Int,
  initial_delay_ms initial_delay_ms: Int,
) -> Result(a, String) {
  retry_with_backoff_helper(operation, max_retries, initial_delay_ms, 0, "")
}

fn retry_with_backoff_helper(
  operation: fn() -> Result(a, String),
  max_retries: Int,
  delay_ms: Int,
  attempt: Int,
  last_error: String,
) -> Result(a, String) {
  case attempt >= max_retries {
    True -> Error("Max retries exceeded: " <> last_error)
    False -> {
      case operation() {
        Ok(value) -> Ok(value)
        Error(error) -> {
          sleep_ms(delay_ms)
          retry_with_backoff_helper(
            operation,
            max_retries,
            delay_ms * 2,
            attempt + 1,
            error,
          )
        }
      }
    }
  }
}

// ============================================================================
// Validation Helpers (re-exported for convenience)
// ============================================================================

/// Validate date format (YYYY-MM-DD)
pub fn validate_date(date: String) -> Result(String, String) {
  case validators.validate_date(date) {
    Ok(d) -> Ok(d)
    Error(e) -> Error(errors.to_string(e))
  }
}

/// Validate meal type (breakfast/lunch/dinner/snack)
pub fn validate_meal_type(meal_type: String) -> Result(String, String) {
  case validators.validate_meal_type(meal_type) {
    Ok(mt) -> Ok(mt)
    Error(e) -> Error(errors.to_string(e))
  }
}

/// Validate servings count (> 0, < 100)
pub fn validate_servings(servings: Int) -> Result(Int, String) {
  case validators.validate_servings(servings) {
    Ok(s) -> Ok(s)
    Error(e) -> Error(errors.to_string(e))
  }
}

// ============================================================================
// Retry Config Helpers (re-exported for convenience)
// ============================================================================

/// Default retry configuration
pub fn default_retry_config() -> RetryConfig {
  retry.default_config()
}

/// Aggressive retry configuration
pub fn aggressive_retry_config() -> RetryConfig {
  retry.aggressive_config()
}

/// Conservative retry configuration
pub fn conservative_retry_config() -> RetryConfig {
  retry.conservative_config()
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "timer", "sleep")
fn sleep_ms(milliseconds: Int) -> Nil
