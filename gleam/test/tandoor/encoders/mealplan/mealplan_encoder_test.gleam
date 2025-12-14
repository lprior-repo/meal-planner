/// Tests for MealPlan encoder
///
/// These tests verify that MealPlan types are correctly encoded to JSON
/// for the Tandoor API.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/mealplan/mealplan_encoder
import meal_planner/tandoor/types/mealplan/mealplan.{
  Breakfast, Dinner, Lunch, MealPlanCreate, MealPlanUpdate,
}

pub fn encode_meal_plan_create_minimal_test() {
  let create =
    MealPlanCreate(
      recipe: None,
      recipe_name: "Oatmeal",
      servings: 1.0,
      note: "",
      from_date: "2025-12-14",
      to_date: "2025-12-14",
      meal_type: Breakfast,
    )

  let encoded = mealplan_encoder.encode_meal_plan_create(create)
  let json_string = json.to_string(encoded)

  // Verify it's valid JSON and contains expected fields
  json_string
  |> should.equal(
    "{\"recipe\":null,\"recipe_name\":\"Oatmeal\",\"servings\":1.0,\"note\":\"\",\"from_date\":\"2025-12-14\",\"to_date\":\"2025-12-14\",\"meal_type\":\"breakfast\"}",
  )
}

pub fn encode_meal_plan_create_with_recipe_test() {
  let create =
    MealPlanCreate(
      recipe: Some(ids.recipe_id_from_int(42)),
      recipe_name: "Chicken Curry",
      servings: 4.0,
      note: "Extra spicy",
      from_date: "2025-12-15",
      to_date: "2025-12-16",
      meal_type: Dinner,
    )

  let encoded = mealplan_encoder.encode_meal_plan_create(create)
  let json_string = json.to_string(encoded)

  // Should include recipe ID
  json_string
  |> should.equal(
    "{\"recipe\":42,\"recipe_name\":\"Chicken Curry\",\"servings\":4.0,\"note\":\"Extra spicy\",\"from_date\":\"2025-12-15\",\"to_date\":\"2025-12-16\",\"meal_type\":\"dinner\"}",
  )
}

pub fn encode_meal_plan_create_all_meal_types_test() {
  // Test all meal types encode correctly
  let test_meal_type = fn(meal_type, expected) {
    let create =
      MealPlanCreate(
        recipe: None,
        recipe_name: "Test",
        servings: 1.0,
        note: "",
        from_date: "2025-12-14",
        to_date: "2025-12-14",
        meal_type: meal_type,
      )

    let encoded = mealplan_encoder.encode_meal_plan_create(create)
    let json_string = json.to_string(encoded)

    json_string
    |> should.contain("\"meal_type\":\"" <> expected <> "\"")
  }

  test_meal_type(Breakfast, "breakfast")
  test_meal_type(Lunch, "lunch")
  test_meal_type(Dinner, "dinner")
  test_meal_type(mealplan.Snack, "snack")
  test_meal_type(mealplan.Other, "other")
}

pub fn encode_meal_plan_update_test() {
  let update =
    MealPlanUpdate(
      recipe: Some(ids.recipe_id_from_int(123)),
      recipe_name: "Updated Recipe",
      servings: 2.0,
      note: "Modified",
      from_date: "2025-12-20",
      to_date: "2025-12-21",
      meal_type: Lunch,
    )

  let encoded = mealplan_encoder.encode_meal_plan_update(update)
  let json_string = json.to_string(encoded)

  // Verify update encoding
  json_string
  |> should.equal(
    "{\"recipe\":123,\"recipe_name\":\"Updated Recipe\",\"servings\":2.0,\"note\":\"Modified\",\"from_date\":\"2025-12-20\",\"to_date\":\"2025-12-21\",\"meal_type\":\"lunch\"}",
  )
}
