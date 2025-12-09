//// Tests for recipe handlers

import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/types.{Ingredient, Low, Macros, Recipe}
import meal_planner/web/handlers/recipe

pub fn parse_valid_recipe_form_test() {
  let form_values = [
    #("name", "Test Recipe"),
    #("category", "chicken"),
    #("servings", "2"),
    #("protein", "30.5"),
    #("fat", "10.0"),
    #("carbs", "45.0"),
    #("fodmap_level", "low"),
    #("vertical_compliant", "true"),
    #("ingredient_name_0", "Chicken"),
    #("ingredient_quantity_0", "200g"),
    #("instruction_0", "Cook it"),
  ]

  case recipe.parse_recipe_from_form(form_values) {
    Ok(r) -> {
      r.name
      |> should.equal("Test Recipe")

      r.servings
      |> should.equal(2)

      r.vertical_compliant
      |> should.equal(True)

      list.length(r.ingredients)
      |> should.equal(1)

      list.length(r.instructions)
      |> should.equal(1)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_missing_required_fields_test() {
  let form_values = [
    #("name", "Test Recipe"),
    // Missing category, servings, macros, etc.
  ]

  case recipe.parse_recipe_from_form(form_values) {
    Error(errors) -> should.be_true(errors != [])
    Ok(_) -> should.fail()
  }
}

pub fn generate_recipe_id_test() {
  let id1 = recipe.generate_recipe_id("Chicken Rice")
  let id2 = recipe.generate_recipe_id("Chicken Rice")

  // Should start with normalized name
  string.contains(id1, "chicken-rice")
  |> should.be_true()

  // Should be unique (different timestamps)
  id1
  |> should.not_equal(id2)
}

pub fn generate_recipe_id_removes_special_chars_test() {
  let id = recipe.generate_recipe_id("Bob's \"Amazing\" Recipe")

  // Should remove apostrophes and quotes
  string.contains(id, "'")
  |> should.be_false()

  string.contains(id, "\"")
  |> should.be_false()

  string.contains(id, "bobs")
  |> should.be_true()

  string.contains(id, "amazing")
  |> should.be_true()
}
