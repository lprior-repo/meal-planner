/// Macro scaling and calculations for meal logging
///
/// Separates macro calculation logic for reusability across different
/// meal logging scenarios (single meals, batch operations, retry logic).
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Macro Scaling
// ============================================================================

/// Scale recipe macros by servings count
///
/// Takes per-serving macros and multiplies by number of servings consumed.
/// Uses exact floating point arithmetic - no rounding.
///
/// ## Parameters
/// - per_serving: Recipe macros for one serving
/// - servings: Number of servings consumed (as Float for precision)
///
/// ## Returns
/// Scaled Macros with exact floating point values
///
/// ## Example
/// ```gleam
/// let per_serving = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
/// let total = scale_by_servings(per_serving, 2.5)
/// // Result: Macros(protein: 50.0, fat: 25.0, carbs: 75.0)
/// ```
pub fn scale_by_servings(per_serving: Macros, servings: Float) -> Macros {
  macros.scale(per_serving, servings)
}

/// Calculate exact total calories from macros
///
/// Uses standard calorie-per-gram ratios:
/// - Protein: 4 cal/g
/// - Fat: 9 cal/g
/// - Carbs: 4 cal/g
///
/// ## Parameters
/// - macros: The macros to calculate calories for
///
/// ## Returns
/// Total calories as Float (exact, no rounding)
pub fn calculate_calories(macros: Macros) -> Float {
  macros.calories(macros)
}

// ============================================================================
// Validation
// ============================================================================

/// Validate that servings count is positive
///
/// ## Parameters
/// - servings: Number of servings to validate
///
/// ## Returns
/// - Ok(servings) if valid (> 0)
/// - Error(message) if invalid (<= 0)
pub fn validate_servings(servings: Int) -> Result(Int, String) {
  case servings > 0 {
    True -> Ok(servings)
    False -> Error("Servings must be greater than 0")
  }
}

/// Validate that macros are non-negative
///
/// Ensures no macro value is negative (invalid nutritional data).
///
/// ## Parameters
/// - macros: The macros to validate
///
/// ## Returns
/// - Ok(macros) if valid (all >= 0)
/// - Error(message) if any value is negative
pub fn validate_macros(macros: Macros) -> Result(Macros, String) {
  case macros.has_negative_values(macros) {
    True -> Error("Macros cannot have negative values")
    False -> Ok(macros)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "erlang", "float")
pub fn int_to_float(n: Int) -> Float
