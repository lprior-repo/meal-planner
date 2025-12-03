//// Integration tests for auto planner API endpoints

import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/auto_planner/storage as auto_storage
import meal_planner/auto_planner/types
import meal_planner/storage
import shared/types.{Ingredient, Low, Macros, Recipe}
import pog

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Setup
// ============================================================================

fn setup_test_db() -> pog.Connection {
  let config = storage.default_config()
  let assert Ok(db) = storage.start_pool(config)

  // Clean up any existing test data
  let _ = pog.query("DELETE FROM auto_meal_plans WHERE id LIKE 'test-%'")
    |> pog.execute(db)
  let _ = pog.query("DELETE FROM recipe_sources WHERE id LIKE 'test-%'")
    |> pog.execute(db)

  db
}

fn seed_test_recipes(db: pog.Connection) {
  // Create test recipes with different diet profiles
  let recipes = [
    Recipe(
      id: "test-vertical-chicken",
      name: "Vertical Diet Chicken",
      ingredients: [
        Ingredient(name: "Chicken breast", quantity: "8 oz"),
        Ingredient(name: "White rice", quantity: "1 cup"),
      ],
      instructions: ["Cook chicken", "Cook rice", "Serve"],
      macros: Macros(protein: 50.0, fat: 8.0, carbs: 45.0),
      servings: 1,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "test-vertical-beef",
      name: "Vertical Diet Beef",
      ingredients: [
        Ingredient(name: "Ground beef", quantity: "6 oz"),
        Ingredient(name: "Potatoes", quantity: "200g"),
      ],
      instructions: ["Cook beef", "Boil potatoes", "Combine"],
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "test-high-protein-salmon",
      name: "High Protein Salmon",
      ingredients: [
        Ingredient(name: "Salmon fillet", quantity: "8 oz"),
        Ingredient(name: "Vegetables", quantity: "2 cups"),
      ],
      instructions: ["Bake salmon", "Steam vegetables", "Serve"],
      macros: Macros(protein: 45.0, fat: 15.0, carbs: 10.0),
      servings: 1,
      category: "seafood",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "test-keto-eggs",
      name: "Keto Eggs",
      ingredients: [
        Ingredient(name: "Eggs", quantity: "4 large"),
        Ingredient(name: "Butter", quantity: "2 tbsp"),
      ],
      instructions: ["Scramble eggs in butter", "Serve"],
      macros: Macros(protein: 25.0, fat: 30.0, carbs: 2.0),
      servings: 1,
      category: "eggs",
      fodmap_level: Low,
      vertical_compliant: False,
    ),
  ]

  list.each(recipes, fn(recipe) {
    let _ = storage.save_recipe(db, recipe)
    Nil
  })
}

// ============================================================================
// Auto Plan Generation Tests
// ============================================================================

pub fn generate_auto_plan_vertical_diet_test() {
  let db = setup_test_db()
  seed_test_recipes(db)

  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 3,
      variety_factor: 0.7,
    )

  let result = meal_planner/auto_planner/core.generate_auto_plan(db, config)

  result
  |> should.be_ok

  let assert Ok(plan) = result

  // Verify plan has correct number of recipes
  list.length(plan.recipes)
  |> should.equal(3)

  // Verify all recipes are vertical diet compliant
  list.all(plan.recipes, fn(r) { r.vertical_compliant })
  |> should.be_true

  // Verify plan has an ID
  string.starts_with(plan.id, "plan-")
  |> should.be_true
}

pub fn generate_auto_plan_high_protein_test() {
  let db = setup_test_db()
  seed_test_recipes(db)

  let config =
    types.AutoPlanConfig(
      diet_principles: [types.HighProtein],
      macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 150.0),
      recipe_count: 4,
      variety_factor: 0.5,
    )

  let result = meal_planner/auto_planner/core.generate_auto_plan(db, config)

  result
  |> should.be_ok

  let assert Ok(plan) = result

  // Verify plan has recipes
  list.length(plan.recipes)
  |> should.be_greater_than(0)

  // Verify high protein recipes (>30g per serving)
  list.all(plan.recipes, fn(r) { r.macros.protein >. 30.0 })
  |> should.be_true
}

pub fn generate_auto_plan_invalid_config_test() {
  let db = setup_test_db()

  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 0,
      variety_factor: 0.7,
    )

  let result = meal_planner/auto_planner/core.generate_auto_plan(db, config)

  result
  |> should.be_error
}

pub fn generate_auto_plan_no_matching_recipes_test() {
  let db = setup_test_db()
  // Don't seed recipes

  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 3,
      variety_factor: 0.7,
    )

  let result = meal_planner/auto_planner/core.generate_auto_plan(db, config)

  result
  |> should.be_error
}

// ============================================================================
// Storage Tests
// ============================================================================

pub fn save_and_retrieve_auto_plan_test() {
  let db = setup_test_db()
  seed_test_recipes(db)

  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 2,
      variety_factor: 0.7,
    )

  // Generate plan
  let assert Ok(plan) = meal_planner/auto_planner/core.generate_auto_plan(db, config)

  // Retrieve plan
  let result = auto_storage.get_auto_plan(db, plan.id)

  result
  |> should.be_ok

  let assert Ok(retrieved_plan) = result

  // Verify plan ID matches
  retrieved_plan.id
  |> should.equal(plan.id)

  // Verify recipes are included
  list.length(retrieved_plan.recipes)
  |> should.equal(list.length(plan.recipes))
}

pub fn get_nonexistent_plan_test() {
  let db = setup_test_db()

  let result = auto_storage.get_auto_plan(db, "nonexistent-plan")

  result
  |> should.be_error
}

// ============================================================================
// Recipe Source Tests
// ============================================================================

pub fn save_and_retrieve_recipe_sources_test() {
  let db = setup_test_db()

  let source =
    types.RecipeSource(
      id: "test-source-1",
      name: "Test Database Source",
      source_type: types.Database,
      config: Some("{\"table\": \"recipes\"}"),
    )

  // Save source
  let save_result = auto_storage.save_recipe_source(db, source)
  save_result
  |> should.be_ok

  // Retrieve sources
  let retrieve_result = auto_storage.get_recipe_sources(db)
  retrieve_result
  |> should.be_ok

  let assert Ok(sources) = retrieve_result

  // Verify our source is in the list
  list.any(sources, fn(s) { s.id == "test-source-1" })
  |> should.be_true
}

// ============================================================================
// Config Validation Tests
// ============================================================================

pub fn validate_valid_config_test() {
  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = types.validate_config(config)
  result
  |> should.be_ok
}

pub fn validate_invalid_recipe_count_test() {
  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 0,
      variety_factor: 0.7,
    )

  let result = types.validate_config(config)
  result
  |> should.be_error
}

pub fn validate_invalid_variety_factor_test() {
  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 1.5,
    )

  let result = types.validate_config(config)
  result
  |> should.be_error
}

pub fn validate_negative_macros_test() {
  let config =
    types.AutoPlanConfig(
      diet_principles: [types.VerticalDiet],
      macro_targets: Macros(protein: -10.0, fat: 50.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = types.validate_config(config)
  result
  |> should.be_error
}
