/// Keto Diet Validator
///
/// Validates recipes against Ketogenic diet principles:
/// - Very low carbs (<20g per serving)
/// - High fat intake
/// - Moderate protein
///
/// The ketogenic diet forces the body into ketosis, burning fat for fuel.
import gleam/float
import gleam/int
import gleam/list
import meal_planner/types.{type Recipe}
import meal_planner/validators/protocol.{type ComplianceResult, ComplianceResult}

// ============================================================================
// Public API
// ============================================================================

/// Check if recipe complies with Keto diet principles
/// Rules: very low carbs (<20g per serving), high fat
pub fn validate(recipe: Recipe) -> ComplianceResult {
  let carbs_per_serving = recipe.macros.carbs /. int.to_float(recipe.servings)

  let violations = case carbs_per_serving >. 20.0 {
    True -> [
      "Too many carbs for keto: "
      <> float.to_string(carbs_per_serving)
      <> "g per serving (limit: 20g)",
    ]
    False -> []
  }

  let score = case carbs_per_serving >. 20.0 {
    True -> 0.0
    False -> 1.0
  }

  ComplianceResult(
    compliant: list.is_empty(violations),
    score: score,
    violations: violations,
    warnings: [],
  )
}
