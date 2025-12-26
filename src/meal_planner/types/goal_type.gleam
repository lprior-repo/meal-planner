//// Type-safe goal type enumeration
////
//// This module provides a type-safe alternative to string-based goal type codes.
//// Replaces error-prone strings like "calories", "protein", "carbs", "fat"
//// with compile-time checked enum values.

import gleam/result

// ============================================================================
// Types
// ============================================================================

/// Type-safe goal type enumeration
///
/// Replaces string-based type codes which are prone to:
/// - Typos causing silent failures
/// - No compile-time safety
/// - Difficult refactoring
/// - No IDE autocomplete support
pub type GoalType {
  /// Daily calorie target
  Calories
  /// Daily protein target (grams)
  Protein
  /// Daily carbohydrate target (grams)
  Carbs
  /// Daily fat target (grams)
  Fat
}

// ============================================================================
// Conversion Functions
// ============================================================================

/// Convert GoalType to string representation
///
/// Used for I/O operations like:
/// - JSON encoding
/// - Database storage
/// - CLI output
pub fn to_string(goal_type: GoalType) -> String {
  case goal_type {
    Calories -> "calories"
    Protein -> "protein"
    Carbs -> "carbs"
    Fat -> "fat"
  }
}

/// Parse string to GoalType
///
/// Returns Error for unknown strings instead of silently defaulting.
/// This prevents typos from causing silent failures.
///
/// # Examples
///
/// ```gleam
/// goal_type_from_string("calories")
/// // -> Ok(Calories)
///
/// goal_type_from_string("caloriess")
/// // -> Error("Unknown goal type: caloriess")
/// ```
pub fn from_string(str: String) -> Result(GoalType, String) {
  case str {
    "calories" -> Ok(Calories)
    "protein" -> Ok(Protein)
    "carbs" -> Ok(Carbs)
    "fat" -> Ok(Fat)
    _ -> Error("Unknown goal type: " <> str)
  }
}

/// Get display name for a goal type
///
/// Returns a human-readable, capitalized name for UI display.
pub fn display_name(goal_type: GoalType) -> String {
  case goal_type {
    Calories -> "Calories"
    Protein -> "Protein"
    Carbs -> "Carbs"
    Fat -> "Fat"
  }
}

/// Get unit symbol for a goal type
///
/// Returns "kcal" for calories, "g" for all other types.
pub fn unit(goal_type: GoalType) -> String {
  case goal_type {
    Calories -> "kcal"
    Protein -> "g"
    Carbs -> "g"
    Fat -> "g"
  }
}
