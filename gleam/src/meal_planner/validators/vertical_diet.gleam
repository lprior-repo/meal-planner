/// Vertical Diet Validator
///
/// Validates recipes against Vertical Diet principles:
/// - No seed oils (canola, soybean, corn, sunflower)
/// - Preferred proteins: red meat, eggs, chicken
/// - Preferred carbs: white rice, sweet potatoes
/// - No high-FODMAP ingredients
///
/// Created by Stan Efferding, emphasizes digestibility and nutrient density.
import gleam/list
import gleam/string
import meal_planner/fodmap
import meal_planner/types.{type Ingredient, type Recipe}
import meal_planner/validators/protocol.{type ComplianceResult, ComplianceResult}

// ============================================================================
// Public API
// ============================================================================

/// Validate a recipe against Vertical Diet principles
pub fn validate(recipe: Recipe) -> ComplianceResult {
  // Check for seed oils (major violation)
  let violations = case has_seed_oils(recipe.ingredients) {
    True -> {
      let seed_oil_ingredients =
        list.filter(recipe.ingredients, fn(ing) {
          is_seed_oil(string.lowercase(ing.name))
        })
      list.map(seed_oil_ingredients, fn(ing) {
        "Contains seed oil: " <> ing.name
      })
    }
    False -> []
  }

  // Check FODMAP compliance using existing module
  let fodmap_analysis = fodmap.analyze_recipe_fodmap(recipe)
  let fodmap_warnings = case fodmap_analysis.is_low_fodmap {
    False ->
      list.map(fodmap_analysis.high_fodmap_found, fn(ingredient) {
        "High FODMAP ingredient: " <> ingredient
      })
    True -> []
  }

  // Calculate score based on FODMAP compliance
  let score = case fodmap_analysis.is_low_fodmap {
    True -> 1.0
    False -> fodmap_analysis.compliance_percentage /. 100.0
  }

  // Check for preferred proteins (informational only)
  let has_preferred_protein =
    list.any(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      string.contains(name_lower, "beef")
      || string.contains(name_lower, "steak")
      || string.contains(name_lower, "chicken")
      || string.contains(name_lower, "egg")
    })

  let protein_warnings = case has_preferred_protein {
    True -> []
    False -> ["Consider adding preferred proteins (beef, chicken, eggs)"]
  }

  // Check for preferred carbs (informational only)
  let has_preferred_carbs =
    list.any(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      string.contains(name_lower, "white rice")
      || string.contains(name_lower, "sweet potato")
    })

  let carb_warnings = case has_preferred_carbs {
    True -> []
    False -> ["Consider adding preferred carbs (white rice, sweet potatoes)"]
  }

  // Combine all warnings
  let warnings =
    list.flatten([fodmap_warnings, protein_warnings, carb_warnings])

  // Overall compliance - fails only if there are violations
  let is_compliant = list.is_empty(violations)

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

/// Check if ingredient list contains seed oils
fn has_seed_oils(ingredients: List(Ingredient)) -> Bool {
  list.any(ingredients, fn(ing) { is_seed_oil(string.lowercase(ing.name)) })
}

/// Check if an ingredient name is a seed oil
fn is_seed_oil(name_lower: String) -> Bool {
  // Skip low-FODMAP exceptions like garlic-infused oil
  let is_exception =
    string.contains(name_lower, "garlic-infused")
    || string.contains(name_lower, "infused oil")

  case is_exception {
    True -> False
    False ->
      string.contains(name_lower, "canola")
      || string.contains(name_lower, "soybean")
      || string.contains(name_lower, "corn oil")
      || string.contains(name_lower, "sunflower")
      || string.contains(name_lower, "vegetable oil")
      || string.contains(name_lower, "rapeseed")
  }
}
