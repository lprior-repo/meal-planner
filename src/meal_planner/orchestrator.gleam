/// Main orchestration module that ties all meal planning components together
///
/// This module provides the primary integration point for the V1 MVP:
/// 1. Select recipes from Tandoor
/// 2. Generate grocery list
/// 3. Generate meal prep plan (with AI)
/// 4. Sync to FatSecret (nutrition tracking)
import gleam/int
import gleam/list
import gleam/result
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/grocery_list.{type GroceryList}
import meal_planner/meal_prep_ai.{type MealPrepPlan}
import meal_planner/meal_sync.{
  type MealNutrition, type MealSelection, type MealSyncResult, sync_meals,
}
import meal_planner/tandoor/client.{type ClientConfig}

// ============================================================================
// Types
// ============================================================================

/// Complete meal planning workflow result
pub type MealPlanningResult {
  MealPlanningResult(
    recipes_selected: Int,
    grocery_list: GroceryList,
    meal_prep_plan: MealPrepPlan,
    nutrition_data: List(MealNutrition),
  )
}

/// Complete meal planning with FatSecret sync result
pub type MealPlanningWithSyncResult {
  MealPlanningWithSyncResult(
    plan: MealPlanningResult,
    sync_results: List(MealSyncResult),
  )
}

// ============================================================================
// Main Workflow
// ============================================================================

/// Execute the complete meal planning workflow
pub fn plan_meals(
  tandoor_config: ClientConfig,
  meal_selections: List(MealSelection),
) -> Result(MealPlanningResult, String) {
  let recipe_count = list.length(meal_selections)

  // Step 1: Validate we have recipes
  case recipe_count > 0 {
    False -> Error("Must select at least one recipe")
    True -> {
      // Step 2: Generate grocery list
      use grocery_list <- result.try(meal_sync.get_grocery_list_for_meals(
        tandoor_config,
        meal_selections,
      ))

      // Step 3: Get nutrition data for each meal
      let nutrition_results =
        meal_selections
        |> list.map(fn(meal) {
          meal_sync.get_meal_nutrition(tandoor_config, meal)
        })

      use nutrition_data <- result.try(
        nutrition_results
        |> result.all,
      )

      // Step 4: Generate meal prep plan (placeholder for now)
      // In future, will use Claude API to generate optimized plan
      let meal_prep_plan =
        meal_prep_ai.MealPrepPlan(
          meal_count: recipe_count,
          total_prep_time_min: 90,
          cookware_needed: ["Pan", "Pot", "Cutting board"],
          instructions: [],
          notes: "AI-generated meal prep plan coming soon",
        )

      // Combine results
      Ok(MealPlanningResult(
        recipes_selected: recipe_count,
        grocery_list: grocery_list,
        meal_prep_plan: meal_prep_plan,
        nutrition_data: nutrition_data,
      ))
    }
  }
}

/// Execute the complete meal planning workflow with FatSecret sync
///
/// This orchestrates the full workflow:
/// 1. Plan meals (recipes, grocery list, nutrition)
/// 2. Sync meals to FatSecret diary
/// 3. Return both planning and sync results
pub fn plan_and_sync_meals(
  tandoor_config: ClientConfig,
  fatsecret_config: FatSecretConfig,
  fatsecret_token: AccessToken,
  meal_selections: List(MealSelection),
) -> Result(MealPlanningWithSyncResult, String) {
  use plan <- result.try(plan_meals(tandoor_config, meal_selections))

  let sync_results =
    sync_meals(
      tandoor_config,
      fatsecret_config,
      fatsecret_token,
      meal_selections,
    )

  Ok(MealPlanningWithSyncResult(plan:, sync_results:))
}

// ============================================================================
// Formatting & Display
// ============================================================================

/// Format the complete meal plan for display
pub fn format_meal_plan(plan: MealPlanningResult) -> String {
  let header =
    "🍽️ MEAL PLANNING SUMMARY\n"
    <> "=======================\n"
    <> "Recipes selected: "
    <> int_to_string(plan.recipes_selected)
    <> "\n\n"

  let grocery_section =
    "🛒 SHOPPING LIST\n"
    <> "================\n"
    <> grocery_list.format_as_text(plan.grocery_list)
    <> "\n\n"

  let meal_prep_section =
    "🍳 MEAL PREP PLAN\n"
    <> "=================\n"
    <> meal_prep_ai.format_meal_prep_plan(plan.meal_prep_plan)
    <> "\n\n"

  let nutrition_section =
    "📊 NUTRITION SUMMARY\n"
    <> "====================\n"
    <> format_nutrition_summary(plan.nutrition_data)

  header <> grocery_section <> meal_prep_section <> nutrition_section
}

fn format_nutrition_summary(nutrition_data: List(MealNutrition)) -> String {
  case list.is_empty(nutrition_data) {
    True -> "No nutrition data available"
    False -> {
      let calorie_list = nutrition_data |> list.map(fn(m) { m.calories })
      let protein_list = nutrition_data |> list.map(fn(m) { m.protein_g })
      let total_calories = sum_floats(calorie_list)
      let total_protein = sum_floats(protein_list)
      let avg_protein =
        total_protein /. int_to_float(list.length(nutrition_data))

      "Total meals: "
      <> int_to_string(list.length(nutrition_data))
      <> "\n"
      <> "Total calories: "
      <> float_to_string(total_calories)
      <> "\n"
      <> "Avg protein per meal: "
      <> float_to_string(avg_protein)
      <> "g"
    }
  }
}

fn sum_floats(floats: List(Float)) -> Float {
  floats |> list.fold(0.0, fn(acc, val) { acc +. val })
}

// ============================================================================
// Helpers
// ============================================================================

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}

fn float_to_string(f: Float) -> String {
  // Round to 1 decimal place
  let multiplied = f *. 10.0
  let rounded = float_to_int(multiplied)
  let integer_part = float_to_int(f)
  let decimal_part = rounded - integer_part * 10

  int_to_string(integer_part) <> "." <> int_to_string(abs_int(decimal_part))
}

fn abs_int(i: Int) -> Int {
  case i < 0 {
    True -> -i
    False -> i
  }
}

fn int_to_float(i: Int) -> Float {
  int.to_float(i)
}

@external(erlang, "erlang", "trunc")
fn float_to_int(f: Float) -> Int
