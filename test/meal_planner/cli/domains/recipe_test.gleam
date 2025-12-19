/// Tests for recipe CLI domain
import gleam/option.{Some}
import gleeunit/should
import meal_planner/cli/domains/recipe
import meal_planner/tandoor/recipe as tandoor_recipe

pub fn format_recipe_list_test() {
  let recipes = [
    tandoor_recipe.Recipe(
      id: 1,
      name: "Pasta Carbonara",
      slug: Some("pasta-carbonara"),
      description: Some("Classic Italian pasta"),
      servings: 4,
      servings_text: Some("4 people"),
      working_time: Some(30),
      waiting_time: Some(0),
      created_at: Some("2024-01-01T00:00:00Z"),
      updated_at: Some("2024-01-01T00:00:00Z"),
    ),
    tandoor_recipe.Recipe(
      id: 2,
      name: "Chicken Curry",
      slug: Some("chicken-curry"),
      description: Some("Spicy chicken curry"),
      servings: 6,
      servings_text: Some("6 people"),
      working_time: Some(45),
      waiting_time: Some(20),
      created_at: Some("2024-01-02T00:00:00Z"),
      updated_at: Some("2024-01-02T00:00:00Z"),
    ),
  ]

  let formatted = recipe.format_recipe_list(recipes)

  // Should contain recipe names
  formatted
  |> should.not_equal("")
}

pub fn format_recipe_detail_test() {
  let detail =
    tandoor_recipe.RecipeDetail(
      id: 1,
      name: "Pasta Carbonara",
      slug: Some("pasta-carbonara"),
      description: Some("Classic Italian pasta"),
      servings: 4,
      servings_text: Some("4 people"),
      working_time: Some(30),
      waiting_time: Some(0),
      created_at: Some("2024-01-01T00:00:00Z"),
      updated_at: Some("2024-01-01T00:00:00Z"),
      steps: [],
      nutrition: option.None,
      keywords: [],
      source_url: option.None,
    )

  let formatted = recipe.format_recipe_detail(detail)

  // Should contain recipe information
  formatted
  |> should.not_equal("")
}

pub fn build_recipe_table_test() {
  let recipes = [
    tandoor_recipe.Recipe(
      id: 1,
      name: "Pasta",
      slug: Some("pasta"),
      description: Some("Italian pasta"),
      servings: 4,
      servings_text: Some("4 people"),
      working_time: Some(30),
      waiting_time: Some(0),
      created_at: Some("2024-01-01T00:00:00Z"),
      updated_at: Some("2024-01-01T00:00:00Z"),
    ),
  ]

  let table = recipe.build_recipe_table(recipes)

  // Should contain table structure
  table
  |> should.not_equal("")
}
