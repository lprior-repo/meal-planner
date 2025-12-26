/// Nutrition input validation
///
/// This module contains validation functions for nutrition-related inputs
/// such as dates and goal values.
import gleam/int
import gleam/result
import gleam/string
import meal_planner/types/goal_type.{
  type GoalType, Calories, Carbs, Fat, Protein,
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate date format (YYYY-MM-DD or "today")
pub fn validate_date_format(date_str: String) -> Result(Nil, String) {
  case date_str {
    "today" -> Ok(Nil)
    _ -> {
      // Basic validation: check if it matches YYYY-MM-DD pattern
      let parts = string.split(date_str, "-")
      case parts {
        [year, month, day] -> {
          case
            string.length(year) == 4
            && string.length(month) == 2
            && string.length(day) == 2
          {
            True -> Ok(Nil)
            False -> Error("Invalid date format. Use YYYY-MM-DD or 'today'")
          }
        }
        _ -> Error("Invalid date format. Use YYYY-MM-DD or 'today'")
      }
    }
  }
}

/// Validate goal value based on type
pub fn validate_goal_value(
  goal_type: GoalType,
  value: Int,
) -> Result(Float, String) {
  let float_val = int.to_float(value)
  case goal_type {
    Calories -> {
      case value >= 500 && value <= 10_000 {
        True -> Ok(float_val)
        False -> Error("Calories must be between 500 and 10,000")
      }
    }
    Protein -> {
      case value > 0 && value < 500 {
        True -> Ok(float_val)
        False -> Error("Protein must be between 1 and 500 grams")
      }
    }
    Carbs -> {
      case value > 0 && value < 1000 {
        True -> Ok(float_val)
        False -> Error("Carbs must be between 1 and 1000 grams")
      }
    }
    Fat -> {
      case value > 0 && value < 500 {
        True -> Ok(float_val)
        False -> Error("Fat must be between 1 and 500 grams")
      }
    }
  }
}
