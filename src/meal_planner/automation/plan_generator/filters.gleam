//// Recipe Filtering Logic
////
//// Implements dietary preference filters:
//// - Vertical diet compliance
//// - FODMAP level restrictions
//// - Minimum protein requirements
//// - Maximum calorie limits

import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/automation/plan_generator/types.{type DietaryPreferences}
import meal_planner/types/macros
import meal_planner/types/recipe.{
  type FodmapLevel, type Recipe, High, Low, Medium, is_vertical_diet_compliant,
}

/// Filter recipes by dietary preferences
///
/// Applies all enabled filters:
/// - Vertical diet compliance
/// - FODMAP level restrictions
/// - Minimum protein requirements
/// - Maximum calorie limits
pub fn filter_by_preferences(
  recipes: List(Recipe),
  prefs: DietaryPreferences,
) -> List(Recipe) {
  recipes
  |> filter_by_vertical_diet(prefs.require_vertical_diet, _)
  |> filter_by_fodmap_level(prefs.max_fodmap_level, _)
  |> filter_by_protein(prefs.min_protein_per_serving, _)
  |> filter_by_calories(prefs.max_calories_per_serving, _)
}

/// Filter by Vertical Diet compliance
fn filter_by_vertical_diet(require: Bool, recipes: List(Recipe)) -> List(Recipe) {
  case require {
    True -> list.filter(recipes, is_vertical_diet_compliant)
    False -> recipes
  }
}

/// Filter by maximum FODMAP level
fn filter_by_fodmap_level(
  max_level: Option(FodmapLevel),
  recipes: List(Recipe),
) -> List(Recipe) {
  case max_level {
    None -> recipes
    Some(max) ->
      list.filter(recipes, fn(r) { is_fodmap_acceptable(r.fodmap_level, max) })
  }
}

/// Check if recipe FODMAP level is acceptable
fn is_fodmap_acceptable(recipe_level: FodmapLevel, max: FodmapLevel) -> Bool {
  case recipe_level, max {
    Low, _ -> True
    Medium, Medium | Medium, High -> True
    High, High -> True
    _, _ -> False
  }
}

/// Filter by minimum protein per serving
fn filter_by_protein(
  min_protein: Option(Float),
  recipes: List(Recipe),
) -> List(Recipe) {
  case min_protein {
    None -> recipes
    Some(min) -> list.filter(recipes, fn(r) { r.macros.protein >=. min })
  }
}

/// Filter by maximum calories per serving
fn filter_by_calories(
  max_calories: Option(Float),
  recipes: List(Recipe),
) -> List(Recipe) {
  case max_calories {
    None -> recipes
    Some(max) ->
      list.filter(recipes, fn(r) { macros.calories(r.macros) <=. max })
  }
}
