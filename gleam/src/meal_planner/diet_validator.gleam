/// Diet principle validation module
///
/// This module provides validation functions for different diet principles:
/// - Vertical Diet: Emphasizes digestibility, low-FODMAP foods, and nutrient density
/// - Tim Ferriss Slow-Carb Diet: High protein, no white carbs (except rice post-workout)
import gleam/float
import gleam/list
import gleam/string
import meal_planner/fodmap
import shared/types.{type Ingredient, type Recipe}

// ============================================================================
// Types
// ============================================================================

/// Supported diet principles
pub type DietPrinciple {
  VerticalDiet
  TimFerriss
}

/// Result of diet compliance validation
pub type ComplianceResult {
  ComplianceResult(
    compliant: Bool,
    score: Float,
    violations: List(String),
    warnings: List(String),
  )
}

// ============================================================================
// Main Validation Function
// ============================================================================

/// Validate a recipe against one or more diet principles
/// Returns combined compliance result
pub fn validate_recipe(
  recipe: Recipe,
  principles: List(DietPrinciple),
) -> ComplianceResult {
  case principles {
    [] ->
      // No principles to validate against - everything is compliant
      ComplianceResult(compliant: True, score: 1.0, violations: [], warnings: [])
    _ -> {
      // Validate against each principle and combine results
      let results =
        list.map(principles, fn(principle) {
          case principle {
            VerticalDiet -> check_vertical_diet(recipe)
            TimFerriss -> check_tim_ferriss(recipe)
          }
        })

      // Combine results - all must be compliant for overall compliance
      let all_compliant =
        list.all(results, fn(result) { result.compliant })

      // Average the scores
      let avg_score = case list.length(results) {
        0 -> 1.0
        count -> {
          let total_score =
            list.fold(results, 0.0, fn(acc, result) { acc +. result.score })
          total_score /. int_to_float(count)
        }
      }

      // Combine violations and warnings
      let all_violations =
        list.fold(results, [], fn(acc, result) {
          list.append(acc, result.violations)
        })

      let all_warnings =
        list.fold(results, [], fn(acc, result) {
          list.append(acc, result.warnings)
        })

      ComplianceResult(
        compliant: all_compliant,
        score: avg_score,
        violations: all_violations,
        warnings: all_warnings,
      )
    }
  }
}

// ============================================================================
// Vertical Diet Validation
// ============================================================================

/// Check if recipe complies with Vertical Diet principles
/// Rules:
/// - No seed oils (canola, soybean, corn, sunflower)
/// - Preferred proteins: red meat, eggs, chicken
/// - Preferred carbs: white rice, sweet potatoes
/// - No high-FODMAP ingredients
pub fn check_vertical_diet(recipe: Recipe) -> ComplianceResult {
  let violations = []
  let warnings = []
  // TODO: Fix scoring system - Gleam doesn't support mutable variables
  let score = 1.0

  // Check for seed oils (major violation)
  let violations = case has_seed_oils(recipe.ingredients) {
    True -> {
      let seed_oil_ingredients =
        list.filter(recipe.ingredients, fn(ing) {
          is_seed_oil(string.lowercase(ing.name))
        })
      let oil_violations =
        list.map(seed_oil_ingredients, fn(ing) {
          "Contains seed oil: " <> ing.name
        })
      list.append(violations, oil_violations)
    }
    False -> violations
  }

  // Check FODMAP compliance using existing module
  let fodmap_analysis = fodmap.analyze_recipe_fodmap(recipe)
  let warnings = case fodmap_analysis.is_low_fodmap {
    False -> {
      let fodmap_warnings =
        list.map(fodmap_analysis.high_fodmap_found, fn(ingredient) {
          "High FODMAP ingredient: " <> ingredient
        })
      list.append(warnings, fodmap_warnings)
    }
    True -> warnings
  }

  // Adjust score based on FODMAP compliance
  let score = case fodmap_analysis.is_low_fodmap {
    True -> score
    False -> score *. { fodmap_analysis.compliance_percentage /. 100.0 }
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

  let warnings = case has_preferred_protein {
    True -> warnings
    False -> [
      "Consider adding preferred proteins (beef, chicken, eggs)",
      ..warnings
    ]
  }

  // Check for preferred carbs (informational only)
  let has_preferred_carbs =
    list.any(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      string.contains(name_lower, "white rice")
      || string.contains(name_lower, "sweet potato")
    })

  let warnings = case has_preferred_carbs {
    True -> warnings
    False -> [
      "Consider adding preferred carbs (white rice, sweet potatoes)",
      ..warnings
    ]
  }

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
// Tim Ferriss Diet Validation
// ============================================================================

/// Check if recipe complies with Tim Ferriss Slow-Carb Diet principles
/// Rules:
/// - High protein (30g+ per serving)
/// - No white carbs (except white rice with post-workout flag)
/// - Contains legumes or quality protein
pub fn check_tim_ferriss(recipe: Recipe) -> ComplianceResult {
  let violations = []
  let warnings = []
  let mut score = 1.0

  // Check protein content
  let protein_per_serving = calculate_protein_per_serving(recipe)
  let warnings = case protein_per_serving <. 30.0 {
    True -> {
      let protein_str = float.to_string(protein_per_serving)
      ["Low protein per serving: " <> protein_str <> "g (target: 30g+)", ..warnings]
    }
    False -> warnings
  }

  // Adjust score based on protein
  let score = case protein_per_serving <. 30.0 {
    True -> score *. { protein_per_serving /. 30.0 }
    False -> score
  }

  // Check for white carbs (violations)
  let white_carb_ingredients =
    list.filter(recipe.ingredients, fn(ing) {
      let name_lower = string.lowercase(ing.name)
      is_white_carb(name_lower) && !string.contains(name_lower, "white rice")
    })

  let violations = case list.is_empty(white_carb_ingredients) {
    True -> violations
    False -> {
      let carb_violations =
        list.map(white_carb_ingredients, fn(ing) {
          "Contains white carbs: " <> ing.name
        })
      list.append(violations, carb_violations)
    }
  }

  // Check for white rice (warning only - allowed post-workout)
  let has_white_rice =
    list.any(recipe.ingredients, fn(ing) {
      string.contains(string.lowercase(ing.name), "white rice")
    })

  let warnings = case has_white_rice {
    True -> ["Contains white rice (allowed post-workout)", ..warnings]
    False -> warnings
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

  let warnings = case has_legumes || has_quality_protein {
    True -> warnings
    False -> [
      "Consider adding legumes or quality protein source",
      ..warnings
    ]
  }

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

/// Check if ingredient list contains seed oils
pub fn has_seed_oils(ingredients: List(Ingredient)) -> Bool {
  list.any(ingredients, fn(ing) {
    is_seed_oil(string.lowercase(ing.name))
  })
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

/// Calculate protein per serving
pub fn calculate_protein_per_serving(recipe: Recipe) -> Float {
  // According to shared/types.gleam, macros are already stored per serving
  // The macros_per_serving function just returns recipe.macros directly
  recipe.macros.protein
}

/// Check if ingredient list contains white carbs
pub fn has_white_carbs(ingredients: List(Ingredient)) -> Bool {
  list.any(ingredients, fn(ing) {
    is_white_carb(string.lowercase(ing.name))
  })
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

// Helper to convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
