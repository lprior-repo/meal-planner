/// Tests for FatSecret fixture loading helpers
///
/// This module tests the test helper functions that load JSON fixtures
/// for FatSecret API responses. TDD approach: tests first, implementation follows.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/foods/types.{type FoodId}
import test/helpers/fatsecret_fixtures

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Food Search Fixtures Tests
// ============================================================================

pub fn load_food_search_single_test() {
  let response = fatsecret_fixtures.load_food_search_single()

  response.foods
  |> should.have_length(1)

  response.total_results
  |> should.equal(1)

  response.max_results
  |> should.equal(50)

  response.page_number
  |> should.equal(0)

  // Verify first food
  let assert [food] = response.foods
  food.food_name
  |> should.equal("Banana")

  types.food_id_to_string(food.food_id)
  |> should.equal("33691")

  food.food_type
  |> should.equal("Generic")

  food.brand_name
  |> should.equal(None)
}

pub fn load_food_search_multiple_test() {
  let response = fatsecret_fixtures.load_food_search_multiple()

  response.foods
  |> should.have_length(4)

  response.total_results
  |> should.equal(4)

  // Verify branded food (third item)
  let assert [_, _, branded, _] = response.foods
  branded.food_name
  |> should.equal("Banana Chips")

  branded.brand_name
  |> should.equal(Some("Great Value"))

  branded.food_type
  |> should.equal("Brand")
}

pub fn load_food_search_empty_test() {
  let response = fatsecret_fixtures.load_food_search_empty()

  response.foods
  |> should.have_length(0)

  response.total_results
  |> should.equal(0)
}

// ============================================================================
// Food Get (Detailed) Fixtures Tests
// ============================================================================

pub fn load_food_get_generic_test() {
  let food = fatsecret_fixtures.load_food_get_generic()

  food.food_name
  |> should.equal("Banana")

  types.food_id_to_string(food.food_id)
  |> should.equal("33691")

  food.food_type
  |> should.equal("Generic")

  food.brand_name
  |> should.equal(None)

  // Should have multiple servings
  food.servings
  |> should.have_length(4)

  // Verify default serving (medium banana)
  let default_serving =
    food.servings
    |> gleam_stdlib.list.find(fn(s) { s.is_default == Some(1) })

  case default_serving {
    Ok(serving) -> {
      serving.serving_description
      |> should.equal("1 medium (7\" to 7-7/8\" long)")

      serving.nutrition.calories
      |> should.equal(105.0)

      serving.nutrition.carbohydrate
      |> should.equal(27.0)

      serving.nutrition.protein
      |> should.equal(1.29)

      serving.nutrition.fat
      |> should.equal(0.39)
    }
    Error(_) -> should.fail()
  }
}

pub fn load_food_get_branded_test() {
  let food = fatsecret_fixtures.load_food_get_branded()

  food.food_name
  |> should.equal("Banana Chips")

  food.brand_name
  |> should.equal(Some("Great Value"))

  food.food_type
  |> should.equal("Brand")

  // Should have single serving
  food.servings
  |> should.have_length(1)

  let assert [serving] = food.servings
  serving.serving_description
  |> should.equal("1 oz")

  serving.nutrition.calories
  |> should.equal(150.0)

  serving.nutrition.saturated_fat
  |> should.equal(Some(8.0))

  // Added sugars present in branded foods
  serving.nutrition.added_sugars
  |> should.equal(Some(9.0))
}

// ============================================================================
// Barcode Lookup Fixtures Tests
// ============================================================================

pub fn load_barcode_lookup_success_test() {
  let food_id = fatsecret_fixtures.load_barcode_lookup_success()

  types.food_id_to_string(food_id)
  |> should.equal("4427908")
}

// ============================================================================
// Autocomplete Fixtures Tests (already exist, just verify)
// ============================================================================

pub fn load_autocomplete_multiple_test() {
  let response = fatsecret_fixtures.load_autocomplete_multiple()

  response.suggestions
  |> should.have_length(4)

  let assert [first, ..] = response.suggestions
  first.food_name
  |> should.equal("Banana")

  types.food_id_to_string(first.food_id)
  |> should.equal("35755")
}

pub fn load_autocomplete_single_test() {
  let response = fatsecret_fixtures.load_autocomplete_single()

  response.suggestions
  |> should.have_length(1)
}

pub fn load_autocomplete_empty_test() {
  let response = fatsecret_fixtures.load_autocomplete_empty()

  response.suggestions
  |> should.have_length(0)
}
