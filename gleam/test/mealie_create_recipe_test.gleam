import gleam/json
import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/mealie/types.{MealieCategory, MealieRecipe, MealieTag}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tests for category_to_json
// ============================================================================

pub fn category_to_json_with_all_fields_test() {
  let category =
    MealieCategory(id: "cat-123", name: "Dinner", slug: "dinner")

  let result = types.category_to_json(category)
  let json_string = json.to_string(result)

  json_string
  |> should.equal("{\"id\":\"cat-123\",\"name\":\"Dinner\",\"slug\":\"dinner\"}")
}

// ============================================================================
// Tests for tag_to_json
// ============================================================================

pub fn tag_to_json_with_all_fields_test() {
  let tag = MealieTag(id: "tag-123", name: "Vegetarian", slug: "vegetarian")

  let result = types.tag_to_json(tag)
  let json_string = json.to_string(result)

  json_string
  |> should.equal(
    "{\"id\":\"tag-123\",\"name\":\"Vegetarian\",\"slug\":\"vegetarian\"}",
  )
}

// ============================================================================
// Tests for recipe_to_json
// ============================================================================

pub fn recipe_to_json_minimal_recipe_test() {
  let recipe =
    MealieRecipe(
      id: "",
      slug: "",
      name: "Simple Recipe",
      description: None,
      image: None,
      recipe_yield: None,
      total_time: None,
      prep_time: None,
      cook_time: None,
      rating: None,
      org_url: None,
      recipe_ingredient: [],
      recipe_instructions: [],
      recipe_category: [],
      tags: [],
      nutrition: None,
      date_added: None,
      date_updated: None,
    )

  let result = types.recipe_to_json(recipe)
  let json_string = json.to_string(result)

  // Verify key fields are present
  string.contains(json_string, "\"name\":\"Simple Recipe\"")
  |> should.be_true

  string.contains(json_string, "\"recipeIngredient\":[]")
  |> should.be_true

  string.contains(json_string, "\"recipeInstructions\":[]")
  |> should.be_true
}
