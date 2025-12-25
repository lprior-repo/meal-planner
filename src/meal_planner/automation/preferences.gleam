//// Recipe Filtering by User Preferences
////
//// Filter recipes by user dietary restrictions, cuisine preferences, and difficulty.
//// Part of the Autonomous Nutritional Control Plane (meal-planner-918)

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/types/recipe.{type FodmapLevel, type Recipe}

// ============================================================================
// Types
// ============================================================================

/// Difficulty level based on total preparation time
pub type Difficulty {
  Easy
  Medium
  Hard
}

/// User preference filters for recipe selection
pub type PreferenceFilters {
  PreferenceFilters(
    /// Maximum FODMAP level allowed (None = no restriction)
    max_fodmap_level: Option(FodmapLevel),
    /// Require recipes to be Vertical Diet compliant
    require_vertical_diet: Bool,
    /// Allowed cuisine types (None = all cuisines, Some([]) = no cuisines)
    allowed_cuisines: Option(List(String)),
    /// Maximum difficulty level allowed (None = no restriction)
    max_difficulty: Option(Difficulty),
    /// Minimum protein per serving in grams (None = no minimum)
    min_protein_per_serving: Option(Float),
    /// Maximum calories per serving (None = no maximum)
    max_calories_per_serving: Option(Float),
  )
}

// ============================================================================
// Public API
// ============================================================================

/// Create default preference filters (no restrictions)
pub fn default_filters() -> PreferenceFilters {
  PreferenceFilters(
    max_fodmap_level: None,
    require_vertical_diet: False,
    allowed_cuisines: None,
    max_difficulty: None,
    min_protein_per_serving: None,
    max_calories_per_serving: None,
  )
}

/// Filter recipes by user preferences
///
/// Applies all enabled filters:
/// - FODMAP level restrictions
/// - Vertical diet compliance
/// - Cuisine preferences
/// - Difficulty level
/// - Minimum protein requirements
/// - Maximum calorie limits
///
/// ## Example
///
/// ```gleam
/// let filters = PreferenceFilters(
///   max_fodmap_level: Some(Low),
///   require_vertical_diet: True,
///   allowed_cuisines: Some(["Italian", "Mexican"]),
///   max_difficulty: Some(Medium),
///   min_protein_per_serving: Some(30.0),
///   max_calories_per_serving: Some(600.0),
/// )
/// let filtered = filter_recipes(all_recipes, filters)
/// ```
pub fn filter_recipes(
  recipes: List(Recipe),
  filters: PreferenceFilters,
) -> List(Recipe) {
  recipes
  |> filter_by_fodmap_level(filters.max_fodmap_level, _)
  |> filter_by_vertical_diet(filters.require_vertical_diet, _)
  |> filter_by_cuisines(filters.allowed_cuisines, _)
  |> filter_by_difficulty(filters.max_difficulty, _)
  |> filter_by_protein(filters.min_protein_per_serving, _)
  |> filter_by_calories(filters.max_calories_per_serving, _)
}

/// Calculate recipe difficulty based on total time
///
/// Difficulty levels:
/// - Easy: < 30 minutes total time
/// - Medium: 30-60 minutes total time
/// - Hard: > 60 minutes total time
///
/// For recipes without timing information, defaults to Medium.
pub fn calculate_difficulty(recipe: Recipe) -> Difficulty {
  // Note: Recipe type from types.gleam doesn't have working_time/waiting_time
  // For now, we'll use a simple heuristic based on category
  // In a real implementation, this would use recipe timing metadata
  case recipe.category {
    "Breakfast" | "breakfast" -> Easy
    "Snack" | "snack" -> Easy
    _ -> Medium
  }
}

/// Check if recipe matches user preferences
///
/// Returns True if the recipe passes all enabled filters.
pub fn matches_preferences(recipe: Recipe, filters: PreferenceFilters) -> Bool {
  matches_fodmap(recipe, filters.max_fodmap_level)
  && matches_vertical_diet(recipe, filters.require_vertical_diet)
  && matches_cuisines(recipe, filters.allowed_cuisines)
  && matches_difficulty(recipe, filters.max_difficulty)
  && matches_protein(recipe, filters.min_protein_per_serving)
  && matches_calories(recipe, filters.max_calories_per_serving)
}

// ============================================================================
// Filtering Functions
// ============================================================================

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
    types.Low, _ -> True
    types.Medium, types.Medium | types.Medium, types.High -> True
    types.High, types.High -> True
    _, _ -> False
  }
}

/// Filter by Vertical Diet compliance
fn filter_by_vertical_diet(require: Bool, recipes: List(Recipe)) -> List(Recipe) {
  case require {
    True -> list.filter(recipes, types.is_vertical_diet_compliant)
    False -> recipes
  }
}

/// Filter by allowed cuisines
fn filter_by_cuisines(
  allowed: Option(List(String)),
  recipes: List(Recipe),
) -> List(Recipe) {
  case allowed {
    None -> recipes
    Some(cuisines) ->
      list.filter(recipes, fn(r) { is_cuisine_allowed(r.category, cuisines) })
  }
}

/// Check if recipe cuisine is in allowed list
fn is_cuisine_allowed(category: String, allowed_cuisines: List(String)) -> Bool {
  case allowed_cuisines {
    [] -> False
    _ ->
      list.any(allowed_cuisines, fn(cuisine) {
        string.lowercase(category) == string.lowercase(cuisine)
      })
  }
}

/// Filter by maximum difficulty level
fn filter_by_difficulty(
  max_level: Option(Difficulty),
  recipes: List(Recipe),
) -> List(Recipe) {
  case max_level {
    None -> recipes
    Some(max) ->
      list.filter(recipes, fn(r) {
        is_difficulty_acceptable(calculate_difficulty(r), max)
      })
  }
}

/// Check if recipe difficulty is acceptable
fn is_difficulty_acceptable(recipe_diff: Difficulty, max: Difficulty) -> Bool {
  case recipe_diff, max {
    Easy, _ -> True
    Medium, Medium | Medium, Hard -> True
    Hard, Hard -> True
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
      list.filter(recipes, fn(r) { types.macros_calories(r.macros) <=. max })
  }
}

// ============================================================================
// Matching Functions
// ============================================================================

/// Check if recipe matches FODMAP filter
fn matches_fodmap(recipe: Recipe, max_level: Option(FodmapLevel)) -> Bool {
  case max_level {
    None -> True
    Some(max) -> is_fodmap_acceptable(recipe.fodmap_level, max)
  }
}

/// Check if recipe matches vertical diet filter
fn matches_vertical_diet(recipe: Recipe, require: Bool) -> Bool {
  case require {
    True -> types.is_vertical_diet_compliant(recipe)
    False -> True
  }
}

/// Check if recipe matches cuisine filter
fn matches_cuisines(recipe: Recipe, allowed: Option(List(String))) -> Bool {
  case allowed {
    None -> True
    Some(cuisines) -> is_cuisine_allowed(recipe.category, cuisines)
  }
}

/// Check if recipe matches difficulty filter
fn matches_difficulty(recipe: Recipe, max_level: Option(Difficulty)) -> Bool {
  case max_level {
    None -> True
    Some(max) -> is_difficulty_acceptable(calculate_difficulty(recipe), max)
  }
}

/// Check if recipe matches protein filter
fn matches_protein(recipe: Recipe, min_protein: Option(Float)) -> Bool {
  case min_protein {
    None -> True
    Some(min) -> recipe.macros.protein >=. min
  }
}

/// Check if recipe matches calorie filter
fn matches_calories(recipe: Recipe, max_calories: Option(Float)) -> Bool {
  case max_calories {
    None -> True
    Some(max) -> types.macros_calories(recipe.macros) <=. max
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Count recipes that match preferences
pub fn count_matching(recipes: List(Recipe), filters: PreferenceFilters) -> Int {
  recipes
  |> filter_recipes(filters)
  |> list.length
}

/// Get percentage of recipes that match preferences
pub fn match_percentage(
  recipes: List(Recipe),
  filters: PreferenceFilters,
) -> Float {
  let total = list.length(recipes)
  case total {
    0 -> 0.0
    _ -> {
      let matching = count_matching(recipes, filters)
      int_to_float(matching) /. int_to_float(total)
    }
  }
}

/// Convert Int to Float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
