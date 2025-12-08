/// Tim Ferriss Slow-Carb Diet Validator
///
/// Validates recipes against Tim Ferriss Slow-Carb Diet principles:
/// - High protein (30g+ per serving)
/// - No white carbs (except white rice post-workout)
/// - Contains legumes or quality protein
///
/// From "The 4-Hour Body" by Tim Ferriss
import gleam/float
import gleam/list
import gleam/string
import meal_planner/types.{type Recipe}
import meal_planner/validators/protocol.{type ComplianceResult, ComplianceResult}

// ============================================================================
// Public API
// ============================================================================

/// Validate a recipe against Tim Ferriss Slow-Carb Diet principles
pub fn validate(recipe: Recipe) -> ComplianceResult {
  // Check protein content
  let protein_per_serving = calculate_protein_per_serving(recipe)
  let protein_warnings = case protein_per_serving <. 30.0 {
    True -> {
      let protein_str = float.to_string(protein_per_serving)
      ["Low protein per serving: " <> protein_str <> "g (target: 30g+)"]
    }
    False -> []
  }

  // Calculate score based on protein
  let score = case protein_per_serving <. 30.0 {
    True -> protein_per_serving /. 30.0
    False -> 1.0
  }

  // Check for white carbs (violations)
  let white_carb_ingredients =
    list.filter(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      is_white_carb(name_lower) && !string.contains(name_lower, "white rice")
    })

  let violations = case list.is_empty(white_carb_ingredients) {
    True -> []
    False ->
      list.map(white_carb_ingredients, fn(ing) {
        "Contains white carbs: " <> ing.name
      })
  }

  // Check for white rice (warning only - allowed post-workout)
  let has_white_rice =
    list.any(recipe.ingredients, fn(ing) {
      string.contains(string.lowercase(ing.name), "white rice")
    })

  let rice_warnings = case has_white_rice {
    True -> ["Contains white rice (allowed post-workout)"]
    False -> []
  }

  // Check for legumes or quality protein
  let has_legumes =
    list.any(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      string.contains(name_lower, "beans")
      || string.contains(name_lower, "lentil")
      || string.contains(name_lower, "chickpea")
    })

  let has_quality_protein =
    list.any(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      string.contains(name_lower, "beef")
      || string.contains(name_lower, "steak")
      || string.contains(name_lower, "chicken")
      || string.contains(name_lower, "egg")
      || string.contains(name_lower, "fish")
    })

  let protein_source_warnings = case has_legumes || has_quality_protein {
    True -> []
    False -> ["Consider adding legumes or quality protein source"]
  }

  // Combine all warnings
  let warnings =
    list.flatten([protein_warnings, rice_warnings, protein_source_warnings])

  // Overall compliance
  let is_compliant = list.is_empty(violations) && protein_per_serving >=. 30.0

  ComplianceResult(
    compliant: is_compliant,
    score: score,
    violations: violations,
    warnings: warnings,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate protein per serving
fn calculate_protein_per_serving(recipe: Recipe) -> Float {
  // According to shared/types.gleam, macros are already stored per serving
  // The macros_per_serving function just returns recipe.macros directly
  recipe.macros.protein
}

/// Check if an ingredient name is a white carb
fn is_white_carb(name_lower: String) -> Bool {
  string.contains(name_lower, "pasta")
  || string.contains(name_lower, "bread")
  || string.contains(name_lower, "bagel")
  || string.contains(name_lower, "cereal")
  || string.contains(name_lower, "tortilla")
  || string.contains(name_lower, "pizza")
  || string.contains(name_lower, "pancake")
  || string.contains(name_lower, "waffle")
  || string.contains(name_lower, "muffin")
  || string.contains(name_lower, "croissant")
}
