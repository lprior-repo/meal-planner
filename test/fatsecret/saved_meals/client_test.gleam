/// Tests for FatSecret Saved Meals API client and decoders
///
/// Verifies correct parsing of saved meals API responses including:
/// - Saved meals list
/// - Saved meal items
/// - Meal types
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleeunit/should
import meal_planner/fatsecret/saved_meals/decoders
import meal_planner/fatsecret/saved_meals/types

// ============================================================================
// Saved Meals Response Decoder Tests
// ============================================================================

pub fn decode_saved_meals_multiple_test() {
  let json_str = saved_meals_fixture()

  let result =
    json.parse(json_str, decoders.saved_meals_response_decoder())
    |> should.be_ok

  result.saved_meals |> list.length |> should.equal(2)

  let assert [first, ..] = result.saved_meals
  types.saved_meal_id_to_string(first.saved_meal_id) |> should.equal("12345")
  first.saved_meal_name |> should.equal("Breakfast Bowl")
  first.calories |> should.equal(350.0)
}

pub fn decode_saved_meals_single_test() {
  let json_str = saved_meals_single_fixture()

  let result =
    json.parse(json_str, decoders.saved_meals_response_decoder())
    |> should.be_ok

  // Single meal should be wrapped in list
  result.saved_meals |> list.length |> should.equal(1)
}

// ============================================================================
// Saved Meal Items Response Decoder Tests
// ============================================================================

pub fn decode_saved_meal_items_multiple_test() {
  let json_str = saved_meal_items_fixture()

  let result =
    json.parse(json_str, decoders.saved_meal_items_response_decoder())
    |> should.be_ok

  types.saved_meal_id_to_string(result.saved_meal_id) |> should.equal("12345")
  result.items |> list.length |> should.equal(2)

  let assert [first, ..] = result.items
  types.saved_meal_item_id_to_string(first.saved_meal_item_id)
  |> should.equal("67890")
  first.food_entry_name |> should.equal("Oatmeal")
  first.calories |> should.equal(150.0)
}

pub fn decode_saved_meal_items_single_test() {
  let json_str = saved_meal_items_single_fixture()

  let result =
    json.parse(json_str, decoders.saved_meal_items_response_decoder())
    |> should.be_ok

  // Single item should be wrapped in list
  result.items |> list.length |> should.equal(1)
}

// ============================================================================
// MealType Tests
// ============================================================================

pub fn meal_type_to_string_test() {
  types.meal_type_to_string(types.Breakfast) |> should.equal("breakfast")
  types.meal_type_to_string(types.Lunch) |> should.equal("lunch")
  types.meal_type_to_string(types.Dinner) |> should.equal("dinner")
  types.meal_type_to_string(types.Other) |> should.equal("other")
}

pub fn meal_type_from_string_test() {
  types.meal_type_from_string("breakfast")
  |> should.be_ok
  |> should.equal(types.Breakfast)
  types.meal_type_from_string("lunch")
  |> should.be_ok
  |> should.equal(types.Lunch)
  types.meal_type_from_string("dinner")
  |> should.be_ok
  |> should.equal(types.Dinner)
  types.meal_type_from_string("other")
  |> should.be_ok
  |> should.equal(types.Other)
  types.meal_type_from_string("invalid") |> should.be_error
}

// ============================================================================
// ID Type Tests
// ============================================================================

pub fn saved_meal_id_round_trip_test() {
  let id = types.saved_meal_id_from_string("12345")
  types.saved_meal_id_to_string(id) |> should.equal("12345")
}

pub fn saved_meal_item_id_round_trip_test() {
  let id = types.saved_meal_item_id_from_string("67890")
  types.saved_meal_item_id_to_string(id) |> should.equal("67890")
}

// ============================================================================
// SavedMealItemInput Tests
// ============================================================================

pub fn saved_meal_item_input_by_food_id_test() {
  let input = types.ByFoodId("33691", "12345", 1.5)
  case input {
    types.ByFoodId(food_id, serving_id, units) -> {
      food_id |> should.equal("33691")
      serving_id |> should.equal("12345")
      units |> should.equal(1.5)
    }
  }
}

pub fn saved_meal_item_input_by_nutrition_test() {
  let input =
    types.ByNutrition(
      food_entry_name: "Custom Food",
      serving_description: "1 serving",
      number_of_units: 1.0,
      calories: 200.0,
      carbohydrate: 20.0,
      protein: 10.0,
      fat: 8.0,
    )
  case input {
    types.ByNutrition(name, desc, units, cals, carbs, prot, fat) -> {
      name |> should.equal("Custom Food")
      desc |> should.equal("1 serving")
      units |> should.equal(1.0)
      cals |> should.equal(200.0)
      carbs |> should.equal(20.0)
      prot |> should.equal(10.0)
      fat |> should.equal(8.0)
    }
  }
}

// ============================================================================
// SavedMeal Type Tests
// ============================================================================

pub fn saved_meal_description_test() {
  let meal =
    types.SavedMeal(
      saved_meal_id: types.saved_meal_id_from_string("12345"),
      saved_meal_name: "Test Meal",
      saved_meal_description: Some("A test meal"),
      meals: [types.Breakfast, types.Lunch],
      calories: 500.0,
      carbohydrate: 50.0,
      protein: 30.0,
      fat: 20.0,
    )

  meal.saved_meal_name |> should.equal("Test Meal")
  meal.saved_meal_description |> should.equal(Some("A test meal"))
  meal.meals |> list.length |> should.equal(2)
  meal.calories |> should.equal(500.0)
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn saved_meals_fixture() -> String {
  "{
    \"saved_meals\": {
      \"saved_meal\": [
        {
          \"saved_meal_id\": \"12345\",
          \"saved_meal_name\": \"Breakfast Bowl\",
          \"saved_meal_description\": \"Healthy breakfast\",
          \"meals\": \"breakfast\",
          \"calories\": \"350\",
          \"carbohydrate\": \"45\",
          \"protein\": \"15\",
          \"fat\": \"12\"
        },
        {
          \"saved_meal_id\": \"12346\",
          \"saved_meal_name\": \"Lunch Combo\",
          \"saved_meal_description\": \"Quick lunch\",
          \"meals\": \"lunch\",
          \"calories\": \"550\",
          \"carbohydrate\": \"60\",
          \"protein\": \"30\",
          \"fat\": \"20\"
        }
      ]
    }
  }"
}

fn saved_meals_single_fixture() -> String {
  "{
    \"saved_meals\": {
      \"saved_meal\": {
        \"saved_meal_id\": \"12345\",
        \"saved_meal_name\": \"Breakfast Bowl\",
        \"saved_meal_description\": \"Healthy breakfast\",
        \"meals\": \"breakfast\",
        \"calories\": \"350\",
        \"carbohydrate\": \"45\",
        \"protein\": \"15\",
        \"fat\": \"12\"
      }
    }
  }"
}

fn saved_meal_items_fixture() -> String {
  "{
    \"saved_meal_id\": \"12345\",
    \"saved_meal_items\": {
      \"saved_meal_item\": [
        {
          \"saved_meal_item_id\": \"67890\",
          \"food_id\": \"33691\",
          \"food_entry_name\": \"Oatmeal\",
          \"serving_id\": \"12345\",
          \"number_of_units\": \"1.0\",
          \"calories\": \"150\",
          \"carbohydrate\": \"27\",
          \"protein\": \"5\",
          \"fat\": \"3\"
        },
        {
          \"saved_meal_item_id\": \"67891\",
          \"food_id\": \"33692\",
          \"food_entry_name\": \"Banana\",
          \"serving_id\": \"12346\",
          \"number_of_units\": \"1.0\",
          \"calories\": \"105\",
          \"carbohydrate\": \"27\",
          \"protein\": \"1\",
          \"fat\": \"0\"
        }
      ]
    }
  }"
}

fn saved_meal_items_single_fixture() -> String {
  "{
    \"saved_meal_id\": \"12345\",
    \"saved_meal_items\": {
      \"saved_meal_item\": {
        \"saved_meal_item_id\": \"67890\",
        \"food_id\": \"33691\",
        \"food_entry_name\": \"Oatmeal\",
        \"serving_id\": \"12345\",
        \"number_of_units\": \"1.0\",
        \"calories\": \"150\",
        \"carbohydrate\": \"27\",
        \"protein\": \"5\",
        \"fat\": \"3\"
      }
    }
  }"
}
