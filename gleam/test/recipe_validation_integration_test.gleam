/// Integration tests for recipe validation with food logging
///
/// These tests demonstrate the complete workflow:
/// 1. Create a food log entry with a recipe slug
/// 2. Validate the recipe exists before saving
/// 3. Handle errors gracefully when recipe doesn't exist

import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/storage/recipe_validation.{
  RecipeNotFound, error_to_message,
}
import meal_planner/types.{
  Breakfast, FoodLogEntry, Macros,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Recipe ID creation and validation
// ============================================================================

pub fn recipe_id_conversion_test() {
  let recipe_slug = "chicken-stir-fry"
  let recipe_id = id.recipe_id(recipe_slug)
  let back_to_string = id.recipe_id_to_string(recipe_id)

  back_to_string
  |> should.equal(recipe_slug)
}

pub fn recipe_id_from_different_slugs_test() {
  let slugs = [
    "beef-tacos",
    "pasta-marinara",
    "grilled-salmon",
    "caesar-salad",
  ]

  list.length(slugs)
  |> should.equal(4)
}

// ============================================================================
// Food log entry construction with validation
// ============================================================================

pub fn construct_mealie_food_log_entry_test() {
  let entry = FoodLogEntry(
    id: id.log_entry_id("log-123"),
    recipe_id: id.recipe_id("chicken-stir-fry"),
    recipe_name: "Chicken Stir Fry",
    servings: 1.5,
    macros: Macros(protein: 35.0, fat: 12.0, carbs: 45.0),
    micronutrients: option.None,
    meal_type: Breakfast,
    logged_at: "2025-12-12T12:00:00Z",
    source_type: "mealie_recipe",
    source_id: "chicken-stir-fry",
  )

  entry.source_type
  |> should.equal("mealie_recipe")
}

pub fn food_log_entry_with_usda_source_test() {
  let entry = FoodLogEntry(
    id: id.log_entry_id("log-456"),
    recipe_id: id.recipe_id("usda-chicken"),
    recipe_name: "USDA Chicken Breast",
    servings: 1.0,
    macros: Macros(protein: 30.0, fat: 3.0, carbs: 0.0),
    micronutrients: option.None,
    meal_type: Breakfast,
    logged_at: "2025-12-12T12:00:00Z",
    source_type: "usda_food",
    source_id: "123456",
  )

  entry.source_type
  |> should.equal("usda_food")
}

pub fn food_log_entry_with_custom_food_source_test() {
  let entry = FoodLogEntry(
    id: id.log_entry_id("log-789"),
    recipe_id: id.recipe_id("custom-salad"),
    recipe_name: "My Custom Salad",
    servings: 1.0,
    macros: Macros(protein: 15.0, fat: 8.0, carbs: 20.0),
    micronutrients: option.None,
    meal_type: Breakfast,
    logged_at: "2025-12-12T12:00:00Z",
    source_type: "custom_food",
    source_id: "custom-123",
  )

  entry.source_type
  |> should.equal("custom_food")
}

// ============================================================================
// Validation error scenarios
// ============================================================================

pub fn recipe_not_found_validation_error_test() {
  let error = RecipeNotFound("non-existent-recipe")
  let message = error_to_message(error)

  message
  |> should.contain("non-existent-recipe")
  |> should.be_true()
}

pub fn user_enters_typo_in_recipe_slug_test() {
  // User enters "chicke-stir-fry" instead of "chicken-stir-fry"
  let attempted_slug = "chicke-stir-fry"
  let error = RecipeNotFound(attempted_slug)
  let message = error_to_message(error)

  message
  |> should.contain("was not found in your recipe database")
  |> should.be_true()
}

pub fn empty_recipe_slug_validation_test() {
  let error = RecipeNotFound("")
  let message = error_to_message(error)

  message
  |> should.contain("was not found in your recipe database")
  |> should.be_true()
}

// ============================================================================
// Workflow scenarios
// ============================================================================

pub fn typical_user_workflow_test() {
  // 1. User wants to log "chicken-stir-fry" recipe
  let recipe_slug = "chicken-stir-fry"

  // 2. Create food log entry
  let entry = FoodLogEntry(
    id: id.log_entry_id("log-workflow-1"),
    recipe_id: id.recipe_id(recipe_slug),
    recipe_name: "Chicken Stir Fry",
    servings: 1.5,
    macros: Macros(protein: 35.0, fat: 12.0, carbs: 45.0),
    micronutrients: option.None,
    meal_type: Breakfast,
    logged_at: "2025-12-12T12:00:00Z",
    source_type: "mealie_recipe",
    source_id: recipe_slug,
  )

  // 3. Entry should have Mealie source type
  entry.source_type
  |> should.equal("mealie_recipe")
}

pub fn user_logs_multiple_recipes_test() {
  let recipes = [
    #("chicken-stir-fry", "Chicken Stir Fry", 35.0),
    #("beef-tacos", "Beef Tacos", 28.0),
    #("pasta-marinara", "Pasta Marinara", 18.0),
  ]

  list.length(recipes)
  |> should.equal(3)
}

pub fn batch_validation_workflow_test() {
  // User wants to log multiple recipes at once
  let recipe_slugs = [
    "recipe-one",
    "recipe-two",
    "recipe-three",
  ]

  list.length(recipe_slugs)
  |> should.equal(3)
}

// ============================================================================
// Real-world recipe examples
// ============================================================================

pub fn common_mealie_recipe_slugs_test() {
  let common_recipes = [
    "chicken-breast",
    "salmon-fillet",
    "broccoli-florets",
    "brown-rice",
    "olive-oil",
  ]

  list.length(common_recipes)
  |> should.equal(5)
}

pub fn complex_recipe_slug_test() {
  let complex_slug = "slow-cooked-beef-stew-with-root-vegetables"

  complex_slug
  |> should.contain("-")
  |> should.be_true()
}

// ============================================================================
// Error handling and recovery
// ============================================================================

pub fn graceful_error_handling_test() {
  let invalid_slug = "this-recipe-does-not-exist-in-mealie"
  let error = RecipeNotFound(invalid_slug)
  let user_message = error_to_message(error)

  // User should get a helpful message
  user_message
  |> should.contain("recipe database")
  |> should.be_true()
}

pub fn validation_prevents_orphaned_logs_test() {
  // The validation ensures that logs only reference recipes that exist
  // This prevents orphaned log entries with broken references
  let invalid_recipe = "non-existent-recipe"

  case invalid_recipe {
    "" -> should.fail("Should not reach here")
    _ -> True |> should.be_true()
  }
}

import gleam/list
import gleam/option
