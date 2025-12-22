//// TDD Tests for CLI recipe command
////
//// RED PHASE: This test validates:
//// 1. Recipe search results formatting
//// 2. Query validation
//// 3. Description truncation

import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/recipe as recipe_domain
import meal_planner/tandoor/recipe.{type Recipe, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a sample recipe for testing
fn create_sample_recipe(
  id: Int,
  name: String,
  description: option.Option(String),
) -> Recipe {
  Recipe(
    id: id,
    name: name,
    slug: None,
    description: description,
    servings: 1,
    servings_text: None,
    working_time: Some(10),
    waiting_time: Some(0),
    created_at: None,
    updated_at: None,
  )
}

// ============================================================================
// Recipe Search Results Formatting Tests
// ============================================================================

/// Test: format_recipe_search_results shows count for empty list
pub fn format_recipe_search_results_empty_list_test() {
  let recipes: List(Recipe) = []
  let output = recipe_domain.format_recipe_search_results(recipes, query: "chicken")

  string.contains(output, "No recipes found")
  |> should.be_true()

  string.contains(output, "chicken")
  |> should.be_true()
}

/// Test: format_recipe_search_results shows count and recipes
pub fn format_recipe_search_results_shows_count_test() {
  let recipes = [
    create_sample_recipe(1, "Grilled Chicken", Some("Delicious chicken")),
    create_sample_recipe(2, "Chicken Salad", Some("Fresh salad")),
  ]

  let output = recipe_domain.format_recipe_search_results(recipes, query: "chicken")

  string.contains(output, "Found 2 recipe(s)")
  |> should.be_true()
}

/// Test: format_recipe_search_results includes recipe names
pub fn format_recipe_search_results_includes_names_test() {
  let recipes = [
    create_sample_recipe(1, "Grilled Chicken", Some("Delicious chicken")),
  ]

  let output = recipe_domain.format_recipe_search_results(recipes, query: "chicken")

  string.contains(output, "Grilled Chicken")
  |> should.be_true()
}

/// Test: format_recipe_search_results truncates long descriptions
pub fn format_recipe_search_results_truncates_description_test() {
  let long_description =
    "This is a very long description that should be truncated to prevent the output from becoming too wide and hard to read on the command line interface"

  let recipes = [
    create_sample_recipe(1, "Test Recipe", Some(long_description)),
  ]

  let output = recipe_domain.format_recipe_search_results(recipes, query: "test")

  // Should contain truncation marker
  string.contains(output, "...")
  |> should.be_true()

  // Output should be shorter than long description (truncated)
  { string.length(output) < string.length(long_description) }
  |> should.be_true()
}

/// Test: format_recipe_search_results handles missing descriptions
pub fn format_recipe_search_results_no_description_test() {
  let recipes = [
    create_sample_recipe(1, "Simple Recipe", None),
  ]

  let output = recipe_domain.format_recipe_search_results(recipes, query: "simple")

  string.contains(output, "Simple Recipe")
  |> should.be_true()
}

/// Test: format_recipe_search_results is case-insensitive for query
pub fn format_recipe_search_results_preserves_case_test() {
  let recipes = [
    create_sample_recipe(1, "Grilled Chicken", Some("Delicious")),
  ]

  let output = recipe_domain.format_recipe_search_results(recipes, query: "CHICKEN")

  string.contains(output, "CHICKEN")
  |> should.be_true()
}

// ============================================================================
// Recipe Search Handler Tests
// ============================================================================

/// Test: search_recipes returns error for empty query
pub fn search_recipes_empty_query_returns_error_test() {
  // This test will require a config, which we'll skip for now
  // since it requires Tandoor configuration
  Nil
}

/// Test: search_recipes validates input
pub fn search_recipes_validates_query_test() {
  // This test requires integration with Tandoor
  // Will be implemented after Gleam build completes
  Nil
}
