/// High Protein Diet Validator
///
/// Validates recipes against high protein diet principles:
/// - 40g+ protein per serving
/// - Supports muscle building and satiety
///
/// Common for bodybuilding, athletic performance, and weight loss.
import gleam/float
import gleam/int
import meal_planner/types.{type Recipe}
import meal_planner/validators/protocol.{type ComplianceResult, ComplianceResult}

// ============================================================================
// Public API
// ============================================================================

/// Check if recipe complies with high protein diet principles
/// Rules: 40g+ protein per serving
pub fn validate(recipe: Recipe) -> ComplianceResult {
  let protein_per_serving =
    recipe.macros.protein /. int.to_float(recipe.servings)

  let warnings = case protein_per_serving <. 40.0 {
    True -> [
      "Lower protein: "
      <> float.to_string(protein_per_serving)
      <> "g per serving (target: 40g+)",
    ]
    False -> []
  }

  let score = case protein_per_serving <. 40.0 {
    True -> protein_per_serving /. 40.0
    False -> 1.0
  }

  ComplianceResult(
    compliant: True,
    score: score,
    violations: [],
    warnings: warnings,
  )
}
