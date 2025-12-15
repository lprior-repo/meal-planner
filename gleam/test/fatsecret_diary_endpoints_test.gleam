/// FatSecret Diary API Endpoints Tests
///
/// Tests for the diary endpoints:
/// - POST /api/fatsecret/diary/entries - Create entry
/// - GET /api/fatsecret/diary/entries/:entry_id - Get entry
/// - PATCH /api/fatsecret/diary/entries/:entry_id - Update entry
/// - DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
/// - GET /api/fatsecret/diary/day/:date_int - Get day entries
/// - GET /api/fatsecret/diary/month/:date_int - Get month summary
///
/// Run with: cd gleam && gleam test
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tests for Date Conversion
// ============================================================================

pub fn date_to_int_test() {
  let result = types.date_to_int("2024-01-15")
  should.be_ok(result)
}

pub fn date_to_int_epoch_test() {
  let result = types.date_to_int("1970-01-01")
  result |> should.equal(Ok(0))
}

pub fn date_to_int_invalid_format_test() {
  let result = types.date_to_int("2024/01/15")
  should.be_error(result)
}

pub fn int_to_date_test() {
  let date = types.int_to_date(0)
  date |> should.equal("1970-01-01")
}

pub fn int_to_date_roundtrip_test() {
  let original = "2024-01-15"
  let result =
    original
    |> types.date_to_int
    |> result.map(types.int_to_date)

  case result {
    Ok(converted) -> converted |> should.equal(original)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Tests for Meal Type Parsing
// ============================================================================

pub fn meal_type_breakfast_test() {
  let result = types.meal_type_from_string("breakfast")
  result |> should.equal(Ok(types.Breakfast))
}

pub fn meal_type_lunch_test() {
  let result = types.meal_type_from_string("lunch")
  result |> should.equal(Ok(types.Lunch))
}

pub fn meal_type_dinner_test() {
  let result = types.meal_type_from_string("dinner")
  result |> should.equal(Ok(types.Dinner))
}

pub fn meal_type_snack_test() {
  let result = types.meal_type_from_string("snack")
  result |> should.equal(Ok(types.Snack))
}

pub fn meal_type_other_as_snack_test() {
  // FatSecret API uses "other" for snack
  let result = types.meal_type_from_string("other")
  result |> should.equal(Ok(types.Snack))
}

pub fn meal_type_invalid_test() {
  let result = types.meal_type_from_string("invalid")
  should.be_error(result)
}

pub fn meal_type_to_string_breakfast_test() {
  let result = types.meal_type_to_string(types.Breakfast)
  result |> should.equal("breakfast")
}

pub fn meal_type_to_string_snack_test() {
  // Snack converts to "other" for API
  let result = types.meal_type_to_string(types.Snack)
  result |> should.equal("other")
}

// ============================================================================
// Tests for Food Entry ID
// ============================================================================

pub fn food_entry_id_creation_test() {
  let id = types.food_entry_id("123456")
  let id_str = types.food_entry_id_to_string(id)
  id_str |> should.equal("123456")
}

pub fn food_entry_id_roundtrip_test() {
  let original = "987654321"
  let id = types.food_entry_id(original)
  let result = types.food_entry_id_to_string(id)
  result |> should.equal(original)
}

// ============================================================================
// Tests for Food Entry Type Construction
// ============================================================================

pub fn from_food_entry_construction_test() {
  let entry =
    types.FromFood(
      food_id: "4142",
      food_entry_name: "Chicken Breast",
      serving_id: "12345",
      number_of_units: 1.5,
      meal: types.Dinner,
      date_int: 19_723,
    )

  case entry {
    types.FromFood(
      food_id,
      food_entry_name,
      serving_id,
      number_of_units,
      meal,
      date_int,
    ) -> {
      food_id |> should.equal("4142")
      food_entry_name |> should.equal("Chicken Breast")
      serving_id |> should.equal("12345")
      number_of_units |> should.equal(1.5)
      meal |> should.equal(types.Dinner)
      date_int |> should.equal(19_723)
    }
    types.Custom(..) -> should.fail()
  }
}

pub fn custom_entry_construction_test() {
  let entry =
    types.Custom(
      food_entry_name: "Custom Salad",
      serving_description: "Large bowl",
      number_of_units: 1.0,
      meal: types.Lunch,
      date_int: 19_723,
      calories: 350.0,
      carbohydrate: 40.0,
      protein: 15.0,
      fat: 8.0,
    )

  case entry {
    types.FromFood(..) -> should.fail()
    types.Custom(
      food_entry_name,
      serving_description,
      number_of_units,
      meal,
      date_int,
      calories,
      carbohydrate,
      protein,
      fat,
    ) -> {
      food_entry_name |> should.equal("Custom Salad")
      serving_description |> should.equal("Large bowl")
      number_of_units |> should.equal(1.0)
      meal |> should.equal(types.Lunch)
      date_int |> should.equal(19_723)
      calories |> should.equal(350.0)
      carbohydrate |> should.equal(40.0)
      protein |> should.equal(15.0)
      fat |> should.equal(8.0)
    }
  }
}

// ============================================================================
// Tests for Food Entry Update Type
// ============================================================================

pub fn food_entry_update_both_fields_test() {
  let update =
    types.FoodEntryUpdate(
      number_of_units: option.Some(2.0),
      meal: option.Some(types.Dinner),
    )

  case update {
    types.FoodEntryUpdate(number_of_units, meal) -> {
      number_of_units |> should.equal(option.Some(2.0))
      meal |> should.equal(option.Some(types.Dinner))
    }
  }
}

pub fn food_entry_update_partial_test() {
  let update =
    types.FoodEntryUpdate(number_of_units: option.Some(1.5), meal: option.None)

  case update {
    types.FoodEntryUpdate(number_of_units, meal) -> {
      number_of_units |> should.equal(option.Some(1.5))
      meal |> should.equal(option.None)
    }
  }
}

pub fn food_entry_update_empty_test() {
  let update =
    types.FoodEntryUpdate(number_of_units: option.None, meal: option.None)

  case update {
    types.FoodEntryUpdate(number_of_units, meal) -> {
      number_of_units |> should.equal(option.None)
      meal |> should.equal(option.None)
    }
  }
}

// ============================================================================
// Tests for Summary Types
// ============================================================================

pub fn day_summary_construction_test() {
  let summary =
    types.DaySummary(
      date_int: 19_723,
      calories: 2100.0,
      carbohydrate: 200.0,
      protein: 150.0,
      fat: 70.0,
    )

  case summary {
    types.DaySummary(date_int, calories, carbohydrate, protein, fat) -> {
      date_int |> should.equal(19_723)
      calories |> should.equal(2100.0)
      carbohydrate |> should.equal(200.0)
      protein |> should.equal(150.0)
      fat |> should.equal(70.0)
    }
  }
}

pub fn month_summary_construction_test() {
  let day1 =
    types.DaySummary(
      date_int: 19_723,
      calories: 2100.0,
      carbohydrate: 200.0,
      protein: 150.0,
      fat: 70.0,
    )
  let day2 =
    types.DaySummary(
      date_int: 19_724,
      calories: 1950.0,
      carbohydrate: 180.0,
      protein: 140.0,
      fat: 65.0,
    )

  let summary = types.MonthSummary(days: [day1, day2], month: 1, year: 2024)

  case summary {
    types.MonthSummary(days, month, year) -> {
      list.length(days) |> should.equal(2)
      month |> should.equal(1)
      year |> should.equal(2024)
    }
  }
}

// Tests for GET /api/fatsecret/diary/entries/:id - Single Entry Read
// ============================================================================

pub fn get_single_diary_entry_returns_200_test() {
  // This test will verify GET /api/fatsecret/diary/entries/:id
  // Expected: 200 OK with complete FoodEntry JSON
  // Fields: food_entry_id, food_entry_name, calories, protein, fat, carbs, meal, date_int
  should.fail()
}

// ============================================================================
// Tests for GET /api/fatsecret/diary/entries?filter=date - Batch Read
// ============================================================================

pub fn get_diary_entries_by_date_filter_returns_200_test() {
  // This test will verify GET /api/fatsecret/diary/entries?filter=date
  // Expected: 200 OK with array of FoodEntry objects filtered by date
  // Response should be an array (not wrapped in object like /day endpoint)
  should.fail()
}

// ============================================================================
// Edge Case Tests - Data Integrity and Error Handling
// ============================================================================

pub fn zero_calorie_custom_entry_validation_test() {
  // Edge case: Custom entry with zero calories should be allowed
  // Validates system handles nutritional edge cases (water, diet soda, etc.)
  let result =
    types.validate_custom_entry(
      food_entry_name: "Zero Cal Beverage",
      serving_description: "1 cup",
      number_of_units: 1.0,
      calories: 0.0,
      carbohydrate: 0.0,
      protein: 0.0,
      fat: 0.0,
    )

  result |> should.be_ok()
}

pub fn invalid_date_int_string_parsing_test() {
  // Edge case: Non-numeric date_int in URL should return validation error
  // Tests handler-level validation for "/api/fatsecret/diary/day/abc"
  let result = types.validate_date_int_string("not-a-number")
  should.be_error(result)
}

pub fn expired_oauth_token_error_mapping_test() {
  // Edge case: Expired token (401) should map to AuthRevoked service error
  // Tests proper error mapping from API to service layer
  let api_error = types.map_auth_error(401)
  api_error |> should.equal(types.AuthRevoked)
}

pub fn malformed_entry_data_negative_units_test() {
  // Edge case: Negative number_of_units should be rejected
  // Validates data integrity - you can't eat -1 servings
  let result = types.validate_number_of_units(-1.5)

  should.be_error(result)
}
