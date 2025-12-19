/// Meal Logger specific error types
///
/// Domain-specific errors for meal logging operations.
/// Extends FatSecret core errors with meal-specific failures.
import gleam/int
import meal_planner/fatsecret/core/errors.{type FatSecretError}

// ============================================================================
// Error Types
// ============================================================================

/// Meal logging specific errors
pub type MealLogError {
  /// Invalid servings count (must be > 0)
  InvalidServings(value: Int)
  /// Recipe has no macros defined
  MissingRecipeMacros(recipe_id: String)
  /// Invalid macro values (negative or NaN)
  InvalidMacros(reason: String)
  /// Invalid date format (must be YYYY-MM-DD)
  InvalidDateFormat(date: String)
  /// Invalid meal type (must be breakfast/lunch/dinner/snack)
  InvalidMealType(meal_type: String)
  /// Recipe ID is empty or malformed
  InvalidRecipeId(recipe_id: String)
  /// Meal already logged (duplicate)
  DuplicateEntry(recipe_id: String, date: String)
  /// FatSecret API error (wrapped)
  FatSecretApiError(error: FatSecretError)
  /// Timeout waiting for FatSecret response
  Timeout(seconds: Int)
  /// Batch operation partial failure
  BatchPartialFailure(succeeded: Int, failed: Int, errors: List(String))
}

// ============================================================================
// Error Formatting
// ============================================================================

/// Convert MealLogError to human-readable string
pub fn to_string(error: MealLogError) -> String {
  case error {
    InvalidServings(value) ->
      "Invalid servings count: " <> int.to_string(value) <> " (must be > 0)"

    MissingRecipeMacros(recipe_id) ->
      "Recipe " <> recipe_id <> " has no macros defined"

    InvalidMacros(reason) -> "Invalid macros: " <> reason

    InvalidDateFormat(date) ->
      "Invalid date format: " <> date <> " (must be YYYY-MM-DD)"

    InvalidMealType(meal_type) ->
      "Invalid meal type: "
      <> meal_type
      <> " (must be breakfast/lunch/dinner/snack)"

    InvalidRecipeId(recipe_id) -> "Invalid recipe ID: " <> recipe_id

    DuplicateEntry(recipe_id, date) ->
      "Meal already logged: recipe " <> recipe_id <> " on " <> date

    FatSecretApiError(fs_error) ->
      "FatSecret API error: " <> errors.error_to_string(fs_error)

    Timeout(seconds) -> "Timeout after " <> int.to_string(seconds) <> " seconds"

    BatchPartialFailure(succeeded, failed, _errors) ->
      "Batch operation partially failed: "
      <> int.to_string(succeeded)
      <> " succeeded, "
      <> int.to_string(failed)
      <> " failed"
  }
}

/// Get detailed error message with context
pub fn to_detailed_string(error: MealLogError) -> String {
  case error {
    BatchPartialFailure(_succeeded, _failed, error_list) -> {
      let header = to_string(error)
      let details = error_list |> list_join("\n  - ")
      header <> "\nErrors:\n  - " <> details
    }

    _ -> to_string(error)
  }
}

// ============================================================================
// Error Classification
// ============================================================================

/// Check if error is retryable (transient failure)
pub fn is_retryable(error: MealLogError) -> Bool {
  case error {
    // Network/API errors may be transient
    FatSecretApiError(fs_error) -> errors.is_recoverable(fs_error)
    Timeout(_) -> True

    // Validation errors are not retryable
    InvalidServings(_) -> False
    MissingRecipeMacros(_) -> False
    InvalidMacros(_) -> False
    InvalidDateFormat(_) -> False
    InvalidMealType(_) -> False
    InvalidRecipeId(_) -> False

    // Duplicate entries should not retry
    DuplicateEntry(_, _) -> False

    // Batch failures need case-by-case analysis
    BatchPartialFailure(_, _, _) -> False
  }
}

/// Check if error is due to validation failure
pub fn is_validation_error(error: MealLogError) -> Bool {
  case error {
    InvalidServings(_) -> True
    MissingRecipeMacros(_) -> True
    InvalidMacros(_) -> True
    InvalidDateFormat(_) -> True
    InvalidMealType(_) -> True
    InvalidRecipeId(_) -> True
    _ -> False
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn list_join(list: List(String), separator: String) -> String {
  case list {
    [] -> ""
    [single] -> single
    [first, ..rest] -> first <> separator <> list_join(rest, separator)
  }
}
