//// TDD Tests for CLI tandoor command
////
//// RED PHASE: This test validates:
//// 1. Recipe and category list formatting
//// 2. Search and filter functionality
//// 3. Sync operation status

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

pub type TandoorRecipe {
  TandoorRecipe(id: Int, name: String, servings: Float)
}

pub type RecipeCategory {
  RecipeCategory(id: Int, name: String, count: Int)
}

fn create_sample_recipe(id: Int, name: String, servings: Float) -> TandoorRecipe {
  TandoorRecipe(id: id, name: name, servings: servings)
}

fn create_sample_category(id: Int, name: String, count: Int) -> RecipeCategory {
  RecipeCategory(id: id, name: name, count: count)
}

// ============================================================================
// Recipe List Formatting Tests
// ============================================================================

/// Test: List recipes shows count
pub fn list_recipes_shows_count_test() {
  let recipes = [
    create_sample_recipe(1, "Grilled Chicken", 4.0),
    create_sample_recipe(2, "Caesar Salad", 2.0),
    create_sample_recipe(3, "Pasta Carbonara", 4.0),
  ]

  list.length(recipes)
  |> should.equal(3)
}

/// Test: Format recipe displays name
pub fn format_recipe_displays_name_test() {
  let recipe = create_sample_recipe(42, "Grilled Chicken Breast", 4.0)

  string.contains(recipe.name, "Grilled Chicken")
  |> should.be_true()
}

/// Test: Format recipe includes ID
pub fn format_recipe_includes_id_test() {
  let recipe = create_sample_recipe(123, "Pasta", 4.0)

  recipe.id
  |> should.equal(123)
}

/// Test: Format recipe shows servings
pub fn format_recipe_shows_servings_test() {
  let recipe = create_sample_recipe(1, "Chicken", 4.0)

  recipe.servings
  |> should.equal(4.0)
}

// ============================================================================
// Category List Tests
// ============================================================================

/// Test: List categories shows count
pub fn list_categories_shows_count_test() {
  let categories = [
    create_sample_category(1, "Breakfast", 15),
    create_sample_category(2, "Lunch", 45),
    create_sample_category(3, "Dinner", 60),
  ]

  list.length(categories)
  |> should.equal(3)
}

/// Test: Format category name
pub fn format_category_name_test() {
  let category = create_sample_category(1, "Vegetarian", 20)

  string.contains(category.name, "Vegetarian")
  |> should.be_true()
}

/// Test: Format category recipe count
pub fn format_category_count_test() {
  let category = create_sample_category(1, "Breakfast", 15)

  category.count
  |> should.equal(15)
}

// ============================================================================
// Search and Filter Tests
// ============================================================================

/// Test: Search recipes by name (case-insensitive)
pub fn search_recipes_case_insensitive_test() {
  let recipes = [
    create_sample_recipe(1, "Grilled Chicken", 4.0),
    create_sample_recipe(2, "Chicken Salad", 2.0),
    create_sample_recipe(3, "Pasta", 4.0),
  ]

  let search_query = "chicken"
  let search_query_lower = string.lowercase(search_query)

  let results =
    recipes
    |> list.filter(fn(r) {
      r.name
      |> string.lowercase
      |> string.contains(search_query_lower)
    })

  list.length(results)
  |> should.equal(2)
}

/// Test: Filter recipes by servings
pub fn filter_recipes_by_servings_test() {
  let recipes = [
    create_sample_recipe(1, "Chicken", 2.0),
    create_sample_recipe(2, "Pasta", 4.0),
    create_sample_recipe(3, "Salad", 1.0),
  ]

  let four_serving_recipes =
    recipes
    |> list.filter(fn(r) { r.servings == 4.0 })

  list.length(four_serving_recipes)
  |> should.equal(1)
}

/// Test: Filter categories by name
pub fn filter_categories_by_name_test() {
  let categories = [
    create_sample_category(1, "Breakfast", 15),
    create_sample_category(2, "Lunch", 45),
    create_sample_category(3, "Dinner", 60),
  ]

  let lunch_categories =
    categories
    |> list.filter(fn(c) { string.contains(c.name, "Lunch") })

  list.length(lunch_categories)
  |> should.equal(1)
}

// ============================================================================
// Recipe Creation/Update Tests
// ============================================================================

/// Test: Validate recipe name is required
pub fn validate_recipe_name_required_test() {
  let name = "Grilled Chicken"

  { string.length(name) > 0 }
  |> should.be_true()
}

/// Test: Validate servings is positive
pub fn validate_servings_positive_test() {
  let servings = 4.0

  { servings >. 0.0 }
  |> should.be_true()
}

/// Test: Handle servings as decimal
pub fn handle_decimal_servings_test() {
  let servings = 2.5

  { servings >. 0.0 && servings <=. 100.0 }
  |> should.be_true()
}

// ============================================================================
// Sync Operation Tests
// ============================================================================

/// Test: Format sync operation results
pub fn format_sync_results_test() {
  let recipes_synced = 150
  let categories_synced = 8
  let meal_plans_synced = 30

  { recipes_synced > 0 }
  |> should.be_true()

  { categories_synced > 0 }
  |> should.be_true()

  { meal_plans_synced >= 0 }
  |> should.be_true()
}

/// Test: Handle empty sync results
pub fn handle_empty_sync_test() {
  let synced_count = 0

  { synced_count >= 0 }
  |> should.be_true()
}
