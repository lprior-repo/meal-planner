//// Meal Plan Generator - Automation Logic
////
//// Implements the core meal plan generation algorithm:
//// 1. Filter recipes by dietary preferences
//// 2. Score recipes by nutritional alignment
//// 3. Build optimal 7-day meal plan
////
//// Part of the Autonomous Nutritional Control Plane (meal-planner-918)

import gleam/dict

import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/fatsecret/profile/types as fatsecret_profile
import meal_planner/generator/types as gen_types
import meal_planner/generator/weekly
import meal_planner/grocery_list
import meal_planner/types.{
  type FodmapLevel, type Macros, type Recipe, High, Low, Medium, macros_calories,
  macros_subtract,
}

// ============================================================================
// Types
// ============================================================================

/// Dietary preference filters for recipe selection
pub type DietaryPreferences {
  DietaryPreferences(
    /// Require recipes to be Vertical Diet compliant
    require_vertical_diet: Bool,
    /// Maximum FODMAP level allowed (None = no restriction)
    max_fodmap_level: Option(FodmapLevel),
    /// Minimum protein per serving in grams (None = no minimum)
    min_protein_per_serving: Option(Float),
    /// Maximum calories per serving (None = no maximum)
    max_calories_per_serving: Option(Float),
  )
}

/// Scored recipe with nutritional alignment metrics
pub type ScoredRecipe {
  ScoredRecipe(
    recipe: Recipe,
    /// Overall nutritional score (0.0 to 1.0, higher is better)
    score: Float,
    /// Individual component scores for debugging
    protein_score: Float,
    calorie_score: Float,
    balance_score: Float,
  )
}

/// Recipe pool categorized by meal type
pub type RecipePool {
  RecipePool(
    breakfasts: List(ScoredRecipe),
    lunches: List(ScoredRecipe),
    dinners: List(ScoredRecipe),
  )
}

/// Nutrition scoring weights (must sum to 1.0)
pub type NutritionWeights {
  NutritionWeights(
    /// Weight for protein target alignment (0.0-1.0)
    protein_weight: Float,
    /// Weight for calorie target alignment (0.0-1.0)
    calorie_weight: Float,
    /// Weight for macro balance (0.0-1.0)
    balance_weight: Float,
  )
}

/// Error types for plan generation
pub type GenerationError {
  /// Not enough recipes in one or more categories
  InsufficientRecipes(category: String, required: Int, available: Int)
  /// No recipes pass the dietary preference filters
  NoRecipesMatchPreferences
  /// Invalid nutrition weights (don't sum to 1.0)
  InvalidWeights
}

// ============================================================================
// Constants
// ============================================================================

/// Default nutrition scoring weights
const default_weights: NutritionWeights = NutritionWeights(
  protein_weight: 0.4,
  calorie_weight: 0.4,
  balance_weight: 0.2,
)

/// Minimum recipes required for each meal type
const min_breakfasts: Int = 7

const min_lunches: Int = 2

const min_dinners: Int = 2

// ============================================================================
// Public API
// ============================================================================

/// Generate a complete weekly meal plan with automatic recipe selection
///
/// ## Algorithm
/// 1. Apply dietary preference filters
/// 2. Calculate daily macro targets from FatSecret profile
/// 3. Score all recipes by nutritional alignment
/// 4. Select best-scoring recipes for each meal type
/// 5. Build 7-day plan with ABABA rotation for lunch/dinner
///
/// ## Parameters
/// - `week_of`: ISO 8601 week start date (e.g., "2025-12-22")
/// - `all_recipes`: Complete recipe database
/// - `preferences`: Dietary filters (FODMAP, vertical diet, etc.)
/// - `macro_profile`: User's FatSecret profile with calorie/macro goals
/// - `constraints`: Locked meals and travel dates
/// - `weights`: Optional custom scoring weights (defaults to 40/40/20)
///
/// ## Returns
/// - `Ok(GenerationResult)`: Complete meal plan with groceries and prep
/// - `Error(GenerationError)`: Insufficient recipes or invalid configuration
pub fn generate_weekly_meal_plan(
  week_of week_of: String,
  all_recipes all_recipes: List(Recipe),
  preferences preferences: DietaryPreferences,
  macro_profile macro_profile: fatsecret_profile.Profile,
  constraints constraints: weekly.Constraints,
  weights weights: Option(NutritionWeights),
) -> Result(gen_types.GenerationResult, GenerationError) {
  // Validate weights
  let weights = option.unwrap(weights, default_weights)
  use _ <- result.try(validate_weights(weights))

  // Calculate target macros from profile
  let target_macros = calculate_target_macros(macro_profile)

  // Filter recipes by dietary preferences
  let filtered_recipes = filter_by_preferences(all_recipes, preferences)

  // Check if we have any recipes after filtering
  use _ <- result.try(case list.is_empty(filtered_recipes) {
    True -> Error(NoRecipesMatchPreferences)
    False -> Ok(Nil)
  })

  // Score all recipes by nutritional alignment
  let scored_recipes = score_recipes(filtered_recipes, target_macros, weights)

  // Categorize recipes by meal type
  let pool = categorize_recipes(scored_recipes)

  // Validate recipe pool counts
  use _ <- result.try(validate_pool(pool))

  // Select best recipes for meal plan
  let selected_breakfasts = select_top_recipes(pool.breakfasts, min_breakfasts)
  let selected_lunches = select_top_recipes(pool.lunches, min_lunches)
  let selected_dinners = select_top_recipes(pool.dinners, min_dinners)

  // Extract raw recipes from scored recipes
  let breakfast_recipes = list.map(selected_breakfasts, fn(sr) { sr.recipe })
  let lunch_recipes = list.map(selected_lunches, fn(sr) { sr.recipe })
  let dinner_recipes = list.map(selected_dinners, fn(sr) { sr.recipe })

  // Generate weekly meal plan
  use meal_plan <- result.try(
    weekly.generate_meal_plan(
      available_breakfasts: breakfast_recipes,
      available_lunches: lunch_recipes,
      available_dinners: dinner_recipes,
      target_macros: target_macros,
      constraints: constraints,
      week_of: week_of,
    )
    |> result.map_error(fn(_) {
      InsufficientRecipes(category: "general", required: 11, available: 0)
    }),
  )

  // TODO: Generate grocery list from meal plan
  // TODO: Generate prep instructions
  // TODO: Calculate macro summary

  // For now, return placeholder result
  let result =
    gen_types.GenerationResult(
      meal_plan: meal_plan,
      grocery_list: create_placeholder_grocery_list(),
      prep_instructions: [],
      macro_summary: create_placeholder_macro_summary(meal_plan),
    )

  Ok(result)
}

// ============================================================================
// Filtering Functions
// ============================================================================

/// Filter recipes by dietary preferences
///
/// Applies all enabled filters:
/// - Vertical diet compliance
/// - FODMAP level restrictions
/// - Minimum protein requirements
/// - Maximum calorie limits
fn filter_by_preferences(
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
    True -> list.filter(recipes, types.is_vertical_diet_compliant)
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
      list.filter(recipes, fn(r) { macros_calories(r.macros) <=. max })
  }
}

// ============================================================================
// Scoring Functions
// ============================================================================

/// Score all recipes by nutritional alignment to target macros
fn score_recipes(
  recipes: List(Recipe),
  target: Macros,
  weights: NutritionWeights,
) -> List(ScoredRecipe) {
  list.map(recipes, fn(recipe) { score_recipe(recipe, target, weights) })
}

/// Score a single recipe by nutritional alignment
///
/// ## Scoring Components
/// 1. Protein score: How close to daily protein target (per meal)
/// 2. Calorie score: How close to daily calorie target (per meal)
/// 3. Balance score: How balanced are the macro ratios
///
/// Each component is scored 0.0-1.0 and weighted
fn score_recipe(
  recipe: Recipe,
  target: Macros,
  weights: NutritionWeights,
) -> ScoredRecipe {
  let macros = recipe.macros

  // Calculate individual scores
  let protein_score = score_protein_alignment(macros.protein, target.protein)
  let calorie_score =
    score_calorie_alignment(macros_calories(macros), macros_calories(target))
  let balance_score = score_macro_balance(macros)

  // Calculate weighted total score
  let total_score =
    { protein_score *. weights.protein_weight }
    +. { calorie_score *. weights.calorie_weight }
    +. { balance_score *. weights.balance_weight }

  ScoredRecipe(
    recipe: recipe,
    score: total_score,
    protein_score: protein_score,
    calorie_score: calorie_score,
    balance_score: balance_score,
  )
}

/// Score protein alignment (0.0 = far from target, 1.0 = perfect match)
///
/// Uses Gaussian scoring: score = exp(-(diff/target)^2 / (2 * sigma^2))
/// Peaks at 1.0 when protein matches target, decays for deviation
fn score_protein_alignment(actual: Float, target: Float) -> Float {
  case target <=. 0.0 {
    True -> 0.5
    // No target, neutral score
    False -> {
      let per_meal_target = target /. 3.0
      // Assume 3 meals per day
      let deviation = actual -. per_meal_target
      let normalized_dev = deviation /. per_meal_target
      let sigma = 0.5
      // Controls spread (50% deviation = ~0.6 score)
      let exponent =
        0.0 -. { normalized_dev *. normalized_dev } /. { 2.0 *. sigma *. sigma }
      float_exp(exponent)
    }
  }
}

/// Score calorie alignment (0.0 = far from target, 1.0 = perfect match)
fn score_calorie_alignment(actual: Float, target: Float) -> Float {
  case target <=. 0.0 {
    True -> 0.5
    False -> {
      let per_meal_target = target /. 3.0
      let deviation = actual -. per_meal_target
      let normalized_dev = deviation /. per_meal_target
      let sigma = 0.4
      // Slightly stricter than protein
      let exponent =
        0.0 -. { normalized_dev *. normalized_dev } /. { 2.0 *. sigma *. sigma }
      float_exp(exponent)
    }
  }
}

/// Score macro balance (0.0 = unbalanced, 1.0 = perfect ratios)
///
/// Checks if macros follow healthy ratios:
/// - Protein: 25-35% of calories
/// - Fat: 25-35% of calories
/// - Carbs: 35-45% of calories
fn score_macro_balance(macros: Macros) -> Float {
  let total_cals = macros_calories(macros)
  case total_cals <=. 0.0 {
    True -> 0.0
    False -> {
      let protein_ratio = { macros.protein *. 4.0 } /. total_cals
      let fat_ratio = { macros.fat *. 9.0 } /. total_cals
      let carb_ratio = { macros.carbs *. 4.0 } /. total_cals

      let protein_ok = protein_ratio >=. 0.25 && protein_ratio <=. 0.35
      let fat_ok = fat_ratio >=. 0.25 && fat_ratio <=. 0.35
      let carb_ok = carb_ratio >=. 0.35 && carb_ratio <=. 0.45

      case protein_ok, fat_ok, carb_ok {
        True, True, True -> 1.0
        True, True, False | True, False, True | False, True, True -> 0.7
        True, False, False | False, True, False | False, False, True -> 0.4
        False, False, False -> 0.0
      }
    }
  }
}

// ============================================================================
// Recipe Selection & Categorization
// ============================================================================

/// Categorize scored recipes by meal type
///
/// Uses simple category-based heuristic:
/// - "Breakfast" category → breakfasts
/// - All other categories split between lunch and dinner
fn categorize_recipes(scored: List(ScoredRecipe)) -> RecipePool {
  let breakfasts =
    scored
    |> list.filter(fn(sr) {
      sr.recipe.category == "Breakfast" || sr.recipe.category == "breakfast"
    })

  let non_breakfasts =
    scored
    |> list.filter(fn(sr) {
      sr.recipe.category != "Breakfast" && sr.recipe.category != "breakfast"
    })

  // Split non-breakfasts into lunch and dinner (50/50 for now)
  let half = list.length(non_breakfasts) / 2
  let lunches = list.take(non_breakfasts, half)
  let dinners = list.drop(non_breakfasts, half)

  RecipePool(breakfasts: breakfasts, lunches: lunches, dinners: dinners)
}

/// Select top N recipes by score
fn select_top_recipes(
  recipes: List(ScoredRecipe),
  count: Int,
) -> List(ScoredRecipe) {
  recipes
  |> list.sort(fn(a, b) { float.compare(b.score, a.score) })
  |> list.take(count)
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate nutrition weights sum to 1.0 (with small tolerance)
fn validate_weights(weights: NutritionWeights) -> Result(Nil, GenerationError) {
  let sum =
    weights.protein_weight +. weights.calorie_weight +. weights.balance_weight
  let tolerance = 0.01

  case float_abs(sum -. 1.0) <. tolerance {
    True -> Ok(Nil)
    False -> Error(InvalidWeights)
  }
}

/// Validate recipe pool has sufficient recipes
fn validate_pool(pool: RecipePool) -> Result(Nil, GenerationError) {
  let breakfast_count = list.length(pool.breakfasts)
  let lunch_count = list.length(pool.lunches)
  let dinner_count = list.length(pool.dinners)

  case breakfast_count < min_breakfasts {
    True ->
      Error(InsufficientRecipes(
        category: "breakfasts",
        required: min_breakfasts,
        available: breakfast_count,
      ))
    False ->
      case lunch_count < min_lunches {
        True ->
          Error(InsufficientRecipes(
            category: "lunches",
            required: min_lunches,
            available: lunch_count,
          ))
        False ->
          case dinner_count < min_dinners {
            True ->
              Error(InsufficientRecipes(
                category: "dinners",
                required: min_dinners,
                available: dinner_count,
              ))
            False -> Ok(Nil)
          }
      }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate target macros from FatSecret profile
///
/// Uses calorie goal if available, otherwise uses defaults
fn calculate_target_macros(profile: fatsecret_profile.Profile) -> Macros {
  let daily_calories = case profile.calorie_goal {
    Some(cals) -> int_to_float(cals)
    None -> 2000.0
    // Default to 2000 cal/day
  }

  // Standard macro split: 30% protein, 30% fat, 40% carbs
  let protein_cals = daily_calories *. 0.3
  let fat_cals = daily_calories *. 0.3
  let carb_cals = daily_calories *. 0.4

  types.Macros(
    protein: protein_cals /. 4.0,
    // 4 cal/g
    fat: fat_cals /. 9.0,
    // 9 cal/g
    carbs: carb_cals /. 4.0,
  )
}

/// Absolute value for floats
fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

/// Exponential function approximation
/// For scoring purposes, we use a simple polynomial approximation
/// e^x ≈ 1 + x + x²/2 + x³/6 for small x
fn float_exp(x: Float) -> Float {
  case x <. -3.0 {
    True -> 0.0
    // Very small, approximate as 0
    False ->
      case x >. 3.0 {
        True -> 1.0
        // Cap at 1.0 for scoring
        False -> {
          // Taylor series approximation
          let x2 = x *. x
          let x3 = x2 *. x
          let result = 1.0 +. x +. { x2 /. 2.0 } +. { x3 /. 6.0 }
          case result <. 0.0 {
            True -> 0.0
            False ->
              case result >. 1.0 {
                True -> 1.0
                False -> result
              }
          }
        }
      }
  }
}

/// Convert Int to Float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// Placeholder Functions (TODO: Implement)
// ============================================================================

/// Create placeholder grocery list
/// TODO: Implement actual grocery list aggregation from meal plan
fn create_placeholder_grocery_list() -> grocery_list.GroceryList {
  grocery_list.GroceryList(by_category: dict.new(), all_items: [])
}

/// Create placeholder macro summary
/// TODO: Implement actual macro summary calculation from meal plan
fn create_placeholder_macro_summary(
  plan: weekly.WeeklyMealPlan,
) -> gen_types.WeeklyMacros {
  gen_types.WeeklyMacros(
    weekly_total: types.macros_zero(),
    daily_average: types.macros_zero(),
    daily_breakdowns: [],
  )
}
