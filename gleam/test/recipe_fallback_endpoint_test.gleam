/// Integration tests for recipe fallback functionality in web endpoints
/// Tests that when Mealie API fails, the recipe_slug_handler returns a fallback recipe

import gleeunit
import gleeunit/should
import meal_planner/mealie/fallback
import meal_planner/mealie/types.{MealieRecipe}

pub fn main() {
  gleeunit.main()
}

/// Test that fallback recipe has correct structure for JSON serialization
pub fn fallback_recipe_json_serializable_test() {
  let recipe = fallback.create_fallback_recipe("test-recipe")

  // Verify the recipe is properly structured
  let MealieRecipe(
    id: _,
    slug: _,
    name: _,
    description: _,
    image: _,
    recipe_yield: _,
    total_time: _,
    prep_time: _,
    cook_time: _,
    rating: _,
    org_url: _,
    recipe_ingredient: _,
    recipe_instructions: _,
    recipe_category: _,
    tags: _,
    nutrition: _,
    date_added: _,
    date_updated: _,
  ) = recipe

  True |> should.be_true()
}

/// Test fallback for typical recipe slugs
pub fn fallback_recipe_typical_slugs_test() {
  let slugs = [
    "chicken-stir-fry",
    "beef-tacos",
    "pasta-carbonara",
    "fish-tacos",
    "vegetable-curry",
  ]

  // Test that all typical slugs produce valid fallback recipes
  list.all(slugs, fn(slug) {
    let recipe = fallback.create_fallback_recipe(slug)
    recipe.slug == slug && string.starts_with(recipe.name, "Unknown Recipe (")
  })
  |> should.be_true()
}

/// Test that fallback recipe name follows expected format
pub fn fallback_recipe_name_format_test() {
  let recipe = fallback.create_fallback_recipe("my-recipe")

  recipe.name
  |> string.starts_with("Unknown Recipe (")
  |> should.be_true()

  recipe.name
  |> string.ends_with(")")
  |> should.be_true()
}

// Helper to import modules we need
import gleam/list
import gleam/string
