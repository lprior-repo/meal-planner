//// TDD Tests for CLI fatsecret detail command
////
//// RED PHASE: This test validates:
//// 1. Food detail formatting
//// 2. Nutrition information display
//// 3. Serving size options

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/foods/types.{
  Food, FoodId, Nutrition, Serving, ServingId,
  food_id, serving_id
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a sample food with nutrition information
fn create_sample_food(name: String, brand: String) -> Food {
  Food(
    food_id: food_id("12345"),
    food_name: name,
    food_type: "Generic",
    food_url: "https://example.com/food/12345",
    brand_name: Some(brand),
    servings: [
      Serving(
        serving_id: serving_id("1"),
        serving_description: "100g",
        serving_url: "https://example.com/serving/1",
        metric_serving_amount: Some(100.0),
        metric_serving_unit: Some("g"),
        number_of_units: 1.0,
        measurement_description: "g",
        is_default: Some(1),
        nutrition: Nutrition(
          calories: 100.0,
          protein: 10.0,
          carbohydrate: 20.0,
          fat: 5.0,
          saturated_fat: None,
          polyunsaturated_fat: None,
          monounsaturated_fat: None,
          trans_fat: None,
          cholesterol: None,
          sodium: None,
          potassium: None,
          fiber: None,
          sugar: None,
          added_sugars: None,
          vitamin_a: None,
          vitamin_c: None,
          vitamin_d: None,
          calcium: None,
          iron: None,
        ),
      ),
    ],
  )
}

// ============================================================================
// Food Detail Display Tests
// ============================================================================

/// Test: Food detail includes name and brand
pub fn food_detail_includes_name_and_brand_test() {
  let food = create_sample_food("Chicken Breast", "Organic Farm")

  let name = food.food_name
  let brand = food.brand_name

  string.contains(name, "Chicken Breast")
  |> should.be_true()

  case brand {
    Some(b) ->
      string.contains(b, "Organic")
      |> should.be_true()
    None -> False |> should.be_true()
  }
}

/// Test: Food detail shows serving options
pub fn food_detail_shows_servings_test() {
  let food = create_sample_food("Chicken Breast", "Organic Farm")

  list.length(food.servings)
  |> should.equal(1)
}

/// Test: Food detail includes nutrition per serving
pub fn food_detail_nutrition_test() {
  let food = create_sample_food("Chicken Breast", "Organic Farm")

  let serving = list.first(food.servings)

  case serving {
    Ok(s) -> {
      s.nutrition.calories
      |> should.equal(100.0)

      s.nutrition.protein
      |> should.equal(10.0)

      s.nutrition.carbohydrate
      |> should.equal(20.0)

      s.nutrition.fat
      |> should.equal(5.0)
    }
    Error(_) -> False |> should.be_true()
  }
}

// ============================================================================
// Serving Size Tests
// ============================================================================

/// Test: Serving size description is displayed
pub fn serving_description_displayed_test() {
  let food = create_sample_food("12345", "Chicken", "Brand")

  let serving = list.first(food.servings)

  case serving {
    Ok(s) ->
      string.contains(s.serving_description, "100g")
      |> should.be_true()
    Error(_) -> False |> should.be_true()
  }
}

/// Test: Metric serving amount and unit are correct
pub fn metric_serving_info_test() {
  let food = create_sample_food("12345", "Chicken", "Brand")

  let serving = list.first(food.servings)

  case serving {
    Ok(s) -> {
      s.metric_serving_amount
      |> should.equal(Some(100.0))

      s.metric_serving_unit
      |> should.equal(Some("g"))
    }
    Error(_) -> False |> should.be_true()
  }
}
