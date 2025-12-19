/// MealLogEntry validation functions
///
/// Validates meal log entries before sending to FatSecret API.
/// Ensures data integrity and prevents invalid API calls.
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import meal_planner/fatsecret/meal_logger/errors.{type MealLogError}
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Date Validation
// ============================================================================

/// Validate date format (YYYY-MM-DD)
///
/// Checks:
/// - Length is 10 characters
/// - Format matches YYYY-MM-DD pattern
/// - Month is 01-12
/// - Day is 01-31 (basic check, doesn't validate month-specific days)
///
/// ## Parameters
/// - date: Date string to validate
///
/// ## Returns
/// - Ok(date) if valid
/// - Error(InvalidDateFormat) if invalid
pub fn validate_date(date: String) -> Result(String, MealLogError) {
  case string.length(date) == 10 {
    False -> Error(errors.InvalidDateFormat(date))
    True -> {
      let parts = string.split(date, "-")
      case parts {
        [year, month, day] -> validate_date_parts(year, month, day, date)
        _ -> Error(errors.InvalidDateFormat(date))
      }
    }
  }
}

fn validate_date_parts(
  year: String,
  month: String,
  day: String,
  original: String,
) -> Result(String, MealLogError) {
  case
    string.length(year) == 4,
    string.length(month) == 2,
    string.length(day) == 2
  {
    True, True, True -> {
      // Validate month range (01-12)
      case int.parse(month) {
        Ok(m) if m >= 1 && m <= 12 -> {
          // Validate day range (01-31)
          case int.parse(day) {
            Ok(d) if d >= 1 && d <= 31 -> Ok(original)
            _ -> Error(errors.InvalidDateFormat(original))
          }
        }
        _ -> Error(errors.InvalidDateFormat(original))
      }
    }
    _, _, _ -> Error(errors.InvalidDateFormat(original))
  }
}

// ============================================================================
// Meal Type Validation
// ============================================================================

/// Valid meal types for FatSecret diary
const valid_meal_types = ["breakfast", "lunch", "dinner", "snack"]

/// Validate meal type
///
/// Checks if meal_type is one of: breakfast, lunch, dinner, snack
///
/// ## Parameters
/// - meal_type: Meal type string to validate
///
/// ## Returns
/// - Ok(meal_type) if valid
/// - Error(InvalidMealType) if invalid
pub fn validate_meal_type(meal_type: String) -> Result(String, MealLogError) {
  case list.contains(valid_meal_types, meal_type) {
    True -> Ok(meal_type)
    False -> Error(errors.InvalidMealType(meal_type))
  }
}

// ============================================================================
// Recipe ID Validation
// ============================================================================

/// Validate recipe ID
///
/// Checks:
/// - Not empty
/// - No whitespace
/// - Reasonable length (< 100 chars)
///
/// ## Parameters
/// - recipe_id: Recipe ID string to validate
///
/// ## Returns
/// - Ok(recipe_id) if valid
/// - Error(InvalidRecipeId) if invalid
pub fn validate_recipe_id(recipe_id: String) -> Result(String, MealLogError) {
  case string.is_empty(recipe_id) {
    True -> Error(errors.InvalidRecipeId(recipe_id))
    False ->
      case string.contains(recipe_id, " ") {
        True -> Error(errors.InvalidRecipeId(recipe_id))
        False ->
          case string.length(recipe_id) > 100 {
            True -> Error(errors.InvalidRecipeId(recipe_id))
            False -> Ok(recipe_id)
          }
      }
  }
}

// ============================================================================
// Servings Validation
// ============================================================================

/// Validate servings count
///
/// Checks:
/// - Greater than 0
/// - Reasonable upper limit (< 100 servings)
///
/// ## Parameters
/// - servings: Number of servings to validate
///
/// ## Returns
/// - Ok(servings) if valid
/// - Error(InvalidServings) if invalid
pub fn validate_servings(servings: Int) -> Result(Int, MealLogError) {
  case servings > 0, servings < 100 {
    True, True -> Ok(servings)
    _, _ -> Error(errors.InvalidServings(servings))
  }
}

// ============================================================================
// Macros Validation
// ============================================================================

/// Validate macros
///
/// Checks:
/// - No negative values
/// - Reasonable upper limits (prevent data errors)
///   - Protein: < 500g
///   - Fat: < 500g
///   - Carbs: < 1000g
///
/// ## Parameters
/// - macros: Macros to validate
///
/// ## Returns
/// - Ok(macros) if valid
/// - Error(InvalidMacros) if invalid
pub fn validate_macros(macros: Macros) -> Result(Macros, MealLogError) {
  // Check for negative values
  case macros.has_negative_values(macros) {
    True -> Error(errors.InvalidMacros("Macros cannot have negative values"))
    False -> validate_macro_ranges(macros)
  }
}

fn validate_macro_ranges(macros: Macros) -> Result(Macros, MealLogError) {
  case macros.protein >. 500.0 {
    True ->
      Error(errors.InvalidMacros("Protein value too high (max 500g per meal)"))
    False ->
      case macros.fat >. 500.0 {
        True ->
          Error(errors.InvalidMacros("Fat value too high (max 500g per meal)"))
        False ->
          case macros.carbs >. 1000.0 {
            True ->
              Error(errors.InvalidMacros(
                "Carbs value too high (max 1000g per meal)",
              ))
            False -> Ok(macros)
          }
      }
  }
}

// ============================================================================
// Composite Validation
// ============================================================================

/// Validate all meal log entry fields
///
/// Runs all validators in sequence. Fails on first error.
///
/// ## Parameters
/// - recipe_id: Recipe identifier
/// - servings: Number of servings
/// - date: Date string (YYYY-MM-DD)
/// - meal_type: Meal type (breakfast/lunch/dinner/snack)
/// - macros: Nutritional macros
///
/// ## Returns
/// - Ok(Nil) if all validations pass
/// - Error(MealLogError) on first validation failure
pub fn validate_entry(
  recipe_id recipe_id: String,
  servings servings: Int,
  date date: String,
  meal_type meal_type: String,
  macros macros: Macros,
) -> Result(Nil, MealLogError) {
  use _ <- result.try(validate_recipe_id(recipe_id))
  use _ <- result.try(validate_servings(servings))
  use _ <- result.try(validate_date(date))
  use _ <- result.try(validate_meal_type(meal_type))
  use _ <- result.try(validate_macros(macros))
  Ok(Nil)
}
