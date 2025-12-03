/// Strict Vertical Diet validation rules
///
/// Validates recipes against Vertical Diet guidelines including:
/// - Forbidden seed oils
/// - Forbidden grains (except white rice)
/// - High FODMAP ingredients
import gleam/list
import gleam/string
import meal_planner/fodmap
import shared/types.{type Recipe}

/// Result of validating a recipe or meal plan
pub type ValidationResult {
  ValidationResult(
    is_valid: Bool,
    violations: List(String),
    warnings: List(String),
    recipe_name: String,
  )
}

/// Forbidden seed oils not allowed on Vertical Diet
const forbidden_seed_oils = [
  "canola oil", "soybean oil", "corn oil", "vegetable oil", "sunflower oil",
  "safflower oil", "cottonseed oil", "grapeseed oil", "rice bran oil",
  "peanut oil",
]

/// Forbidden grains (white rice is the exception)
const forbidden_grains = [
  "wheat", "whole wheat", "bread", "pasta", "flour tortilla", "rye", "barley",
  "oats", "oatmeal", "quinoa", "couscous", "bulgur", "brown rice",
]

/// Allowed grain exceptions
const allowed_grains = [
  "white rice",
  "rice cereal",
  "cream of rice",
  "rice flour",
]

/// High FODMAP ingredients to check
const high_fodmap_ingredients = [
  "garlic", "onion", "beans", "chickpea", "lentil", "cauliflower", "broccoli",
  "asparagus", "mushroom", "apples", "pear", "mango", "watermelon", "wheat",
  "rye", "barley", "honey",
]

/// Perform strict Vertical Diet validation on a recipe
pub fn validate_recipe_strict(recipe: Recipe) -> ValidationResult {
  let violations =
    list.flat_map(recipe.ingredients, fn(ingredient) {
      let ing_lower = string.lowercase(ingredient.name)
      let seed_oil_violations = check_seed_oils(ing_lower, ingredient.name)
      let grain_violations = check_grains(ing_lower, ingredient.name)
      let fodmap_violations = check_fodmap(ing_lower, ingredient.name)

      list.flatten([seed_oil_violations, grain_violations, fodmap_violations])
    })

  ValidationResult(
    is_valid: list.is_empty(violations),
    violations: violations,
    warnings: [],
    recipe_name: recipe.name,
  )
}

/// Check for forbidden seed oils
fn check_seed_oils(ing_lower: String, ing_name: String) -> List(String) {
  case contains_any(ing_lower, forbidden_seed_oils) {
    True -> ["Contains forbidden seed oil: " <> ing_name]
    False -> []
  }
}

/// Check for forbidden grains (allowing white rice variants)
fn check_grains(ing_lower: String, ing_name: String) -> List(String) {
  // First check if it's an allowed grain
  case contains_any(ing_lower, allowed_grains) {
    True -> []
    False ->
      case contains_any(ing_lower, forbidden_grains) {
        True -> ["Contains forbidden grain: " <> ing_name]
        False -> []
      }
  }
}

/// Check for high FODMAP ingredients
fn check_fodmap(ing_lower: String, ing_name: String) -> List(String) {
  // Skip if it's a low FODMAP exception
  case fodmap.is_low_fodmap_exception(ing_lower) {
    True -> []
    False ->
      case contains_any(ing_lower, high_fodmap_ingredients) {
        True -> ["Contains high-FODMAP ingredient: " <> ing_name]
        False -> []
      }
  }
}

/// Check if a string contains any of the keywords
fn contains_any(text: String, keywords: List(String)) -> Bool {
  list.any(keywords, fn(keyword) { string.contains(text, keyword) })
}
