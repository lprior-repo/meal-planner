//// Tests for Plan Generator - Weekly Meal Plan Generation
////
//// Tests the public API for weekly meal plan generation.
//// Part of meal-planner-cy7y (Automation: Plan Generator)

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/automation/plan_generator
import meal_planner/fatsecret/profile/types as fatsecret_profile
import meal_planner/generator/weekly
import meal_planner/id
import meal_planner/types/recipe.{type Recipe, Recipe, type FodmapLevel, High, Low}
import meal_planner/types/macros.{Macros}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_recipe(
  name: String,
  category: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  fodmap: types.FodmapLevel,
  vertical: Bool,
) -> Recipe {
  Recipe(
    id: id.recipe_id(name),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: category,
    fodmap_level: fodmap,
    vertical_compliant: vertical,
  )
}

fn test_profile() -> fatsecret_profile.Profile {
  fatsecret_profile.Profile(
    goal_weight_kg: None,
    last_weight_kg: None,
    last_weight_date_int: None,
    last_weight_comment: None,
    height_cm: None,
    calorie_goal: Some(2000),
    weight_measure: None,
    height_measure: None,
  )
}

fn default_prefs() -> plan_generator.DietaryPreferences {
  plan_generator.DietaryPreferences(
    require_vertical_diet: False,
    max_fodmap_level: None,
    min_protein_per_serving: None,
    max_calories_per_serving: None,
  )
}

fn default_constraints() -> weekly.Constraints {
  weekly.Constraints(locked_meals: [], travel_dates: [])
}

/// Create minimal viable recipe pool (7 breakfasts, 2 lunches, 2 dinners)
fn create_minimal_recipe_pool() -> List(Recipe) {
  [
    create_recipe("B1", "Breakfast", 30.0, 10.0, 40.0, Low, True),
    create_recipe("B2", "Breakfast", 32.0, 12.0, 38.0, Low, True),
    create_recipe("B3", "Breakfast", 28.0, 11.0, 42.0, Low, True),
    create_recipe("B4", "Breakfast", 31.0, 9.0, 41.0, Low, True),
    create_recipe("B5", "Breakfast", 29.0, 13.0, 39.0, Low, True),
    create_recipe("B6", "Breakfast", 33.0, 10.0, 40.0, Low, True),
    create_recipe("B7", "Breakfast", 30.0, 11.0, 41.0, Low, True),
    create_recipe("L1", "Lunch", 40.0, 15.0, 50.0, Low, True),
    create_recipe("L2", "Lunch", 42.0, 14.0, 52.0, Low, True),
    create_recipe("D1", "Dinner", 45.0, 20.0, 60.0, Low, True),
    create_recipe("D2", "Dinner", 48.0, 22.0, 58.0, Low, True),
  ]
}

// ============================================================================
// Generation Tests
// ============================================================================

pub fn generate_plan_success_with_sufficient_recipes_test() {
  let recipes = create_minimal_recipe_pool()
  let profile = test_profile()
  let prefs = default_prefs()
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  result
  |> should.be_ok
}

pub fn generate_plan_fails_with_insufficient_recipes_test() {
  // Only 1 breakfast, 1 lunch, 1 dinner (need 7, 2, 2)
  let recipes = [
    create_recipe("B1", "Breakfast", 30.0, 10.0, 40.0, Low, True),
    create_recipe("L1", "Lunch", 40.0, 15.0, 50.0, Low, True),
    create_recipe("D1", "Dinner", 45.0, 20.0, 60.0, Low, True),
  ]

  let profile = test_profile()
  let prefs = default_prefs()
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  result
  |> should.be_error
}

pub fn generate_plan_filters_by_vertical_diet_test() {
  let recipes = [
    // Vertical-compliant recipes (enough to generate plan)
    create_recipe("VB1", "Breakfast", 30.0, 10.0, 40.0, Low, True),
    create_recipe("VB2", "Breakfast", 32.0, 12.0, 38.0, Low, True),
    create_recipe("VB3", "Breakfast", 28.0, 11.0, 42.0, Low, True),
    create_recipe("VB4", "Breakfast", 31.0, 9.0, 41.0, Low, True),
    create_recipe("VB5", "Breakfast", 29.0, 13.0, 39.0, Low, True),
    create_recipe("VB6", "Breakfast", 33.0, 10.0, 40.0, Low, True),
    create_recipe("VB7", "Breakfast", 30.0, 11.0, 41.0, Low, True),
    create_recipe("VL1", "Lunch", 40.0, 15.0, 50.0, Low, True),
    create_recipe("VL2", "Lunch", 42.0, 14.0, 52.0, Low, True),
    create_recipe("VD1", "Dinner", 45.0, 20.0, 60.0, Low, True),
    create_recipe("VD2", "Dinner", 48.0, 22.0, 58.0, Low, True),
    // Non-compliant recipes (should be filtered out)
    create_recipe("NVB", "Breakfast", 15.0, 25.0, 80.0, High, False),
    create_recipe("NVL", "Lunch", 20.0, 30.0, 85.0, High, False),
    create_recipe("NVD", "Dinner", 25.0, 35.0, 90.0, High, False),
  ]

  let profile = test_profile()
  let prefs =
    plan_generator.DietaryPreferences(
      require_vertical_diet: True,
      max_fodmap_level: None,
      min_protein_per_serving: None,
      max_calories_per_serving: None,
    )
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  // Should succeed using only vertical-compliant recipes
  result
  |> should.be_ok
}

pub fn generate_plan_filters_by_fodmap_level_test() {
  let recipes = [
    // Low FODMAP recipes (enough to generate plan)
    create_recipe("LB1", "Breakfast", 30.0, 10.0, 40.0, Low, True),
    create_recipe("LB2", "Breakfast", 32.0, 12.0, 38.0, Low, True),
    create_recipe("LB3", "Breakfast", 28.0, 11.0, 42.0, Low, True),
    create_recipe("LB4", "Breakfast", 31.0, 9.0, 41.0, Low, True),
    create_recipe("LB5", "Breakfast", 29.0, 13.0, 39.0, Low, True),
    create_recipe("LB6", "Breakfast", 33.0, 10.0, 40.0, Low, True),
    create_recipe("LB7", "Breakfast", 30.0, 11.0, 41.0, Low, True),
    create_recipe("LL1", "Lunch", 40.0, 15.0, 50.0, Low, True),
    create_recipe("LL2", "Lunch", 42.0, 14.0, 52.0, Low, True),
    create_recipe("LD1", "Dinner", 45.0, 20.0, 60.0, Low, True),
    create_recipe("LD2", "Dinner", 48.0, 22.0, 58.0, Low, True),
    // High FODMAP recipes (should be filtered out)
    create_recipe("HB", "Breakfast", 35.0, 12.0, 45.0, High, True),
    create_recipe("HL", "Lunch", 45.0, 18.0, 55.0, High, True),
    create_recipe("HD", "Dinner", 50.0, 25.0, 65.0, High, True),
  ]

  let profile = test_profile()
  let prefs =
    plan_generator.DietaryPreferences(
      require_vertical_diet: False,
      max_fodmap_level: Some(Low),
      min_protein_per_serving: None,
      max_calories_per_serving: None,
    )
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  // Should succeed using only Low FODMAP recipes
  result
  |> should.be_ok
}

pub fn generate_plan_fails_when_no_recipes_match_preferences_test() {
  // All recipes are High FODMAP
  let recipes = [
    create_recipe("HB1", "Breakfast", 30.0, 10.0, 40.0, High, False),
    create_recipe("HB2", "Breakfast", 32.0, 12.0, 38.0, High, False),
    create_recipe("HL", "Lunch", 40.0, 15.0, 50.0, High, False),
    create_recipe("HD", "Dinner", 45.0, 20.0, 60.0, High, False),
  ]

  let profile = test_profile()
  // Require Low FODMAP (none available)
  let prefs =
    plan_generator.DietaryPreferences(
      require_vertical_diet: False,
      max_fodmap_level: Some(Low),
      min_protein_per_serving: None,
      max_calories_per_serving: None,
    )
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  // Should fail with NoRecipesMatchPreferences
  result
  |> should.be_error
}

pub fn generate_plan_fails_with_invalid_weights_test() {
  let recipes = create_minimal_recipe_pool()
  let profile = test_profile()
  let prefs = default_prefs()
  let constraints = default_constraints()

  // Invalid weights (sum > 1.0)
  let bad_weights =
    Some(plan_generator.NutritionWeights(
      protein_weight: 0.5,
      calorie_weight: 0.5,
      balance_weight: 0.5,
    ))

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: bad_weights,
    )

  // Should fail with InvalidWeights
  result
  |> should.be_error
}

pub fn generate_plan_succeeds_with_valid_custom_weights_test() {
  let recipes = create_minimal_recipe_pool()
  let profile = test_profile()
  let prefs = default_prefs()
  let constraints = default_constraints()

  // Valid custom weights (sum = 1.0)
  let custom_weights =
    Some(plan_generator.NutritionWeights(
      protein_weight: 0.5,
      calorie_weight: 0.3,
      balance_weight: 0.2,
    ))

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: custom_weights,
    )

  // Should succeed
  result
  |> should.be_ok
}

pub fn generate_plan_uses_default_weights_when_none_provided_test() {
  let recipes = create_minimal_recipe_pool()
  let profile = test_profile()
  let prefs = default_prefs()
  let constraints = default_constraints()

  let result =
    plan_generator.generate_weekly_meal_plan(
      week_of: "2025-12-22",
      all_recipes: recipes,
      preferences: prefs,
      macro_profile: profile,
      constraints: constraints,
      weights: None,
    )

  // Should succeed with default weights (40/40/20)
  result
  |> should.be_ok
}
