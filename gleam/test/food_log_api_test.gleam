/// Tests for food log API with recipe data
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/storage/logs

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tests
// ============================================================================

/// Test that FoodLogInput can be created with valid recipe slug
pub fn test_create_food_log_input_valid_slug() {
  let input =
    logs.FoodLogInput(
      date: "2025-12-12",
      recipe_slug: "chicken-stir-fry",
      recipe_name: "Chicken Stir Fry",
      servings: 1.5,
      protein: 35.5,
      fat: 12.3,
      carbs: 45.2,
      meal_type: "dinner",
      fiber: Some(3.2),
      sugar: None,
      sodium: None,
      cholesterol: None,
      vitamin_a: None,
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: None,
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  input.recipe_slug
  |> should.equal("chicken-stir-fry")

  input.meal_type
  |> should.equal("dinner")

  input.servings
  |> should.equal(1.5)
}

/// Test that FoodLogInput accepts various meal types
pub fn test_food_log_input_meal_types() {
  let meal_types = ["breakfast", "lunch", "dinner", "snack"]

  list.each(meal_types, fn(meal_type) {
    let input =
      logs.FoodLogInput(
        date: "2025-12-12",
        recipe_slug: "test-recipe",
        recipe_name: "Test Recipe",
        servings: 1.0,
        protein: 20.0,
        fat: 10.0,
        carbs: 30.0,
        meal_type: meal_type,
        fiber: None,
        sugar: None,
        sodium: None,
        cholesterol: None,
        vitamin_a: None,
        vitamin_c: None,
        vitamin_d: None,
        vitamin_e: None,
        vitamin_k: None,
        vitamin_b6: None,
        vitamin_b12: None,
        folate: None,
        thiamin: None,
        riboflavin: None,
        niacin: None,
        calcium: None,
        iron: None,
        magnesium: None,
        phosphorus: None,
        potassium: None,
        zinc: None,
      )

    input.meal_type
    |> should.equal(meal_type)
  })
}

/// Test with full micronutrient data
pub fn test_food_log_input_with_micronutrients() {
  let input =
    logs.FoodLogInput(
      date: "2025-12-12",
      recipe_slug: "salmon-bowl",
      recipe_name: "Salmon Bowl",
      servings: 2.0,
      protein: 45.0,
      fat: 18.0,
      carbs: 55.0,
      meal_type: "lunch",
      fiber: Some(8.5),
      sugar: Some(12.3),
      sodium: Some(480.0),
      cholesterol: Some(85.0),
      vitamin_a: Some(150.0),
      vitamin_c: Some(45.0),
      vitamin_d: Some(20.0),
      vitamin_e: Some(8.0),
      vitamin_k: Some(120.0),
      vitamin_b6: Some(1.5),
      vitamin_b12: Some(3.2),
      folate: Some(210.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.8),
      niacin: Some(8.5),
      calcium: Some(350.0),
      iron: Some(2.8),
      magnesium: Some(95.0),
      phosphorus: Some(480.0),
      potassium: Some(850.0),
      zinc: Some(3.2),
    )

  // Verify all micronutrients are present
  input.fiber
  |> should.equal(Some(8.5))

  input.calcium
  |> should.equal(Some(350.0))

  input.zinc
  |> should.equal(Some(3.2))
}

/// Test date format validation
pub fn test_food_log_input_iso_date_format() {
  let valid_dates = ["2025-12-12", "2025-01-01", "2024-12-31"]

  list.each(valid_dates, fn(date) {
    let input =
      logs.FoodLogInput(
        date: date,
        recipe_slug: "test",
        recipe_name: "Test",
        servings: 1.0,
        protein: 20.0,
        fat: 10.0,
        carbs: 30.0,
        meal_type: "breakfast",
        fiber: None,
        sugar: None,
        sodium: None,
        cholesterol: None,
        vitamin_a: None,
        vitamin_c: None,
        vitamin_d: None,
        vitamin_e: None,
        vitamin_k: None,
        vitamin_b6: None,
        vitamin_b12: None,
        folate: None,
        thiamin: None,
        riboflavin: None,
        niacin: None,
        calcium: None,
        iron: None,
        magnesium: None,
        phosphorus: None,
        potassium: None,
        zinc: None,
      )

    input.date
    |> should.equal(date)
  })
}

/// Test recipe slug with hyphens and lowercase
pub fn test_food_log_recipe_slug_formats() {
  let slugs = [
    "chicken-stir-fry",
    "grilled-salmon",
    "vegetable-curry",
    "pasta-carbonara",
    "thai-green-curry",
  ]

  list.each(slugs, fn(slug) {
    let input =
      logs.FoodLogInput(
        date: "2025-12-12",
        recipe_slug: slug,
        recipe_name: "Recipe Name",
        servings: 1.0,
        protein: 20.0,
        fat: 10.0,
        carbs: 30.0,
        meal_type: "dinner",
        fiber: None,
        sugar: None,
        sodium: None,
        cholesterol: None,
        vitamin_a: None,
        vitamin_c: None,
        vitamin_d: None,
        vitamin_e: None,
        vitamin_k: None,
        vitamin_b6: None,
        vitamin_b12: None,
        folate: None,
        thiamin: None,
        riboflavin: None,
        niacin: None,
        calcium: None,
        iron: None,
        magnesium: None,
        phosphorus: None,
        potassium: None,
        zinc: None,
      )

    input.recipe_slug
    |> should.equal(slug)
  })
}

/// Test edge case: empty micronutrient values (all None)
pub fn test_food_log_input_no_micronutrients() {
  let input =
    logs.FoodLogInput(
      date: "2025-12-12",
      recipe_slug: "simple-meal",
      recipe_name: "Simple Meal",
      servings: 1.0,
      protein: 20.0,
      fat: 10.0,
      carbs: 30.0,
      meal_type: "breakfast",
      fiber: None,
      sugar: None,
      sodium: None,
      cholesterol: None,
      vitamin_a: None,
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: None,
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  // All micronutrients should be None
  input.fiber
  |> should.equal(None)

  input.calcium
  |> should.equal(None)
}

/// Test macro values with edge cases
pub fn test_food_log_input_macro_values() {
  let input =
    logs.FoodLogInput(
      date: "2025-12-12",
      recipe_slug: "test",
      recipe_name: "Test",
      servings: 0.5,
      protein: 0.0,
      fat: 100.0,
      carbs: 200.5,
      meal_type: "snack",
      fiber: None,
      sugar: None,
      sodium: None,
      cholesterol: None,
      vitamin_a: None,
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: None,
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  input.servings
  |> should.equal(0.5)

  input.protein
  |> should.equal(0.0)

  input.fat
  |> should.equal(100.0)
}
