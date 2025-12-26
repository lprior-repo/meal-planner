//// Meal Plan Generator - Automation Logic
////
//// This module has been decomposed into focused submodules:
//// - plan_generator/types.gleam: Type definitions
//// - plan_generator/filters.gleam: Recipe filtering logic
//// - plan_generator/scoring.gleam: Nutritional scoring
//// - plan_generator/selection.gleam: Recipe categorization and selection
//// - plan_generator/generator.gleam: Core generation logic
////
//// This file serves as a facade maintaining backward compatibility.
////
//// Implements the core meal plan generation algorithm:
//// 1. Filter recipes by dietary preferences
//// 2. Score recipes by nutritional alignment
//// 3. Build optimal 7-day meal plan
////
//// Part of the Autonomous Nutritional Control Plane (meal-planner-918)

import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/automation/plan_generator/filters
import meal_planner/automation/plan_generator/generator
import meal_planner/automation/plan_generator/scoring
import meal_planner/automation/plan_generator/selection
import meal_planner/automation/plan_generator/types
import meal_planner/fatsecret/profile/types as fatsecret_profile
import meal_planner/generator/types as gen_types
import meal_planner/generator/weekly
import meal_planner/types/recipe.{type Recipe}

// ============================================================================
// Re-export Types
// ============================================================================

pub type DietaryPreferences =
  types.DietaryPreferences

pub type ScoredRecipe =
  types.ScoredRecipe

pub type RecipePool =
  types.RecipePool

pub type NutritionWeights =
  types.NutritionWeights

pub type GenerationError =
  types.GenerationError

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
  let weights = option.unwrap(weights, scoring.default_weights)
  use _ <- result.try(scoring.validate_weights(weights))

  // Calculate target macros from profile
  let target_macros = generator.calculate_target_macros(macro_profile)

  // Filter recipes by dietary preferences
  let filtered_recipes = filters.filter_by_preferences(all_recipes, preferences)

  // Check if we have any recipes after filtering
  use _ <- result.try(case list.is_empty(filtered_recipes) {
    True -> Error(types.NoRecipesMatchPreferences)
    False -> Ok(Nil)
  })

  // Score all recipes by nutritional alignment
  let scored_recipes =
    scoring.score_recipes(filtered_recipes, target_macros, weights)

  // Categorize recipes by meal type
  let pool = selection.categorize_recipes(scored_recipes)

  // Validate recipe pool counts
  use _ <- result.try(selection.validate_pool(pool))

  // Select best recipes for meal plan
  let selected_breakfasts =
    selection.select_top_recipes(pool.breakfasts, selection.min_breakfasts)
  let selected_lunches =
    selection.select_top_recipes(pool.lunches, selection.min_lunches)
  let selected_dinners =
    selection.select_top_recipes(pool.dinners, selection.min_dinners)

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
      types.InsufficientRecipes(category: "general", required: 11, available: 0)
    }),
  )

  // TODO: Generate grocery list from meal plan
  // TODO: Generate prep instructions
  // TODO: Calculate macro summary

  // For now, return placeholder result
  let result =
    gen_types.GenerationResult(
      meal_plan: meal_plan,
      grocery_list: generator.create_placeholder_grocery_list(),
      prep_instructions: [],
      macro_summary: generator.create_placeholder_macro_summary(meal_plan),
    )

  Ok(result)
}
