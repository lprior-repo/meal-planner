/// Tests for FatSecret Diary JSON decoders
///
/// Verifies correct parsing of food diary API responses including:
/// - Food entry decoding with numeric strings
/// - MealType parsing
/// - Day and month summary handling
/// - Single vs array edge cases
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types

// ============================================================================
// MealType Tests
// ============================================================================

pub fn meal_type_from_string_breakfast_test() {
  types.meal_type_from_string("breakfast")
  |> should.be_ok
  |> should.equal(types.Breakfast)
}

pub fn meal_type_from_string_lunch_test() {
  types.meal_type_from_string("lunch")
  |> should.be_ok
  |> should.equal(types.Lunch)
}

pub fn meal_type_from_string_dinner_test() {
  types.meal_type_from_string("dinner")
  |> should.be_ok
  |> should.equal(types.Dinner)
}

pub fn meal_type_from_string_other_test() {
  types.meal_type_from_string("other")
  |> should.be_ok
  |> should.equal(types.Snack)
}

pub fn meal_type_from_string_snack_test() {
  types.meal_type_from_string("snack")
  |> should.be_ok
  |> should.equal(types.Snack)
}

pub fn meal_type_from_string_invalid_test() {
  types.meal_type_from_string("invalid")
  |> should.be_error
}

pub fn meal_type_to_string_test() {
  types.meal_type_to_string(types.Breakfast) |> should.equal("breakfast")
  types.meal_type_to_string(types.Lunch) |> should.equal("lunch")
  types.meal_type_to_string(types.Dinner) |> should.equal("dinner")
  types.meal_type_to_string(types.Snack) |> should.equal("other")
}

// ============================================================================
// FoodEntry Decoder Tests
// ============================================================================

pub fn decode_food_entry_with_all_fields_test() {
  let json_str = food_entry_fixture()

  let result =
    json.parse(json_str, decoders.food_entry_decoder())
    |> should.be_ok

  // Verify required fields
  types.food_entry_id_to_string(result.food_entry_id)
  |> should.equal("123456")
  result.food_entry_name |> should.equal("Chicken Breast")
  result.food_id |> should.equal("4142")
  result.serving_id |> should.equal("12345")
  result.number_of_units |> should.equal(1.5)
  result.meal |> should.equal(types.Dinner)
  result.date_int |> should.equal(19_723)

  // Verify macro nutrients
  result.calories |> should.equal(248.0)
  result.carbohydrate |> should.equal(0.0)
  result.protein |> should.equal(46.5)
  result.fat |> should.equal(5.4)

  // Verify optional micronutrients
  result.saturated_fat |> should.equal(Some(1.2))
  result.sodium |> should.equal(Some(95.0))
}

pub fn decode_food_entry_minimal_test() {
  let json_str = food_entry_minimal_fixture()

  let result =
    json.parse(json_str, decoders.food_entry_decoder())
    |> should.be_ok

  // Optional fields should be None
  result.saturated_fat |> should.equal(None)
  result.polyunsaturated_fat |> should.equal(None)
  result.fiber |> should.equal(None)
}

// ============================================================================
// DaySummary Decoder Tests
// ============================================================================

pub fn decode_day_summary_test() {
  let json_str = day_summary_fixture()

  let result =
    json.parse(json_str, decoders.day_summary_decoder())
    |> should.be_ok

  result.date_int |> should.equal(19_723)
  result.calories |> should.equal(2100.0)
  result.carbohydrate |> should.equal(200.0)
  result.protein |> should.equal(150.0)
  result.fat |> should.equal(70.0)
}

// ============================================================================
// MonthSummary Decoder Tests
// ============================================================================

pub fn decode_month_summary_multiple_days_test() {
  let json_str = month_summary_fixture()

  let result =
    json.parse(json_str, decoders.month_summary_decoder())
    |> should.be_ok

  result.month |> should.equal(1)
  result.year |> should.equal(2024)
  result.days |> list.length |> should.equal(2)

  // Verify first day
  let assert [first, ..] = result.days
  first.date_int |> should.equal(19_723)
  first.calories |> should.equal(2100.0)
}

pub fn decode_month_summary_single_day_test() {
  let json_str = month_summary_single_day_fixture()

  let result =
    json.parse(json_str, decoders.month_summary_decoder())
    |> should.be_ok

  // Single day should be wrapped in list
  result.days |> list.length |> should.equal(1)
}

// ============================================================================
// Date Conversion Tests
// ============================================================================

pub fn date_to_int_epoch_test() {
  types.date_to_int("1970-01-01")
  |> should.be_ok
  |> should.equal(0)
}

pub fn date_to_int_next_day_test() {
  types.date_to_int("1970-01-02")
  |> should.be_ok
  |> should.equal(1)
}

pub fn date_to_int_2024_test() {
  types.date_to_int("2024-01-01")
  |> should.be_ok
  |> should.equal(19_723)
}

pub fn int_to_date_epoch_test() {
  types.int_to_date(0)
  |> should.equal("1970-01-01")
}

pub fn int_to_date_2024_test() {
  types.int_to_date(19_723)
  |> should.equal("2024-01-01")
}

pub fn date_round_trip_test() {
  let date = "2024-12-15"
  let assert Ok(date_int) = types.date_to_int(date)
  types.int_to_date(date_int) |> should.equal(date)
}

// ============================================================================
// Validation Tests
// ============================================================================

pub fn validate_custom_entry_success_test() {
  types.validate_custom_entry(
    food_entry_name: "Test Food",
    serving_description: "1 serving",
    number_of_units: 1.0,
    calories: 100.0,
    carbohydrate: 20.0,
    protein: 10.0,
    fat: 5.0,
  )
  |> should.be_ok
}

pub fn validate_custom_entry_empty_name_test() {
  types.validate_custom_entry(
    food_entry_name: "",
    serving_description: "1 serving",
    number_of_units: 1.0,
    calories: 100.0,
    carbohydrate: 20.0,
    protein: 10.0,
    fat: 5.0,
  )
  |> should.be_error
  |> should.equal("food_entry_name cannot be empty")
}

pub fn validate_custom_entry_zero_units_test() {
  types.validate_custom_entry(
    food_entry_name: "Test Food",
    serving_description: "1 serving",
    number_of_units: 0.0,
    calories: 100.0,
    carbohydrate: 20.0,
    protein: 10.0,
    fat: 5.0,
  )
  |> should.be_error
  |> should.equal("number_of_units must be greater than 0")
}

pub fn validate_custom_entry_negative_calories_test() {
  types.validate_custom_entry(
    food_entry_name: "Test Food",
    serving_description: "1 serving",
    number_of_units: 1.0,
    calories: -100.0,
    carbohydrate: 20.0,
    protein: 10.0,
    fat: 5.0,
  )
  |> should.be_error
  |> should.equal("Nutrition values cannot be negative")
}

pub fn validate_custom_entry_zero_calories_allowed_test() {
  // Zero is allowed (e.g., for water)
  types.validate_custom_entry(
    food_entry_name: "Water",
    serving_description: "1 cup",
    number_of_units: 1.0,
    calories: 0.0,
    carbohydrate: 0.0,
    protein: 0.0,
    fat: 0.0,
  )
  |> should.be_ok
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn food_entry_fixture() -> String {
  "{
    \"food_entry_id\": \"123456\",
    \"food_entry_name\": \"Chicken Breast\",
    \"food_entry_description\": \"Per 150g - Calories: 248kcal | Fat: 5.4g | Carbs: 0g | Protein: 46.5g\",
    \"food_id\": \"4142\",
    \"serving_id\": \"12345\",
    \"number_of_units\": \"1.5\",
    \"meal\": \"dinner\",
    \"date_int\": \"19723\",
    \"calories\": \"248\",
    \"carbohydrate\": \"0\",
    \"protein\": \"46.5\",
    \"fat\": \"5.4\",
    \"saturated_fat\": \"1.2\",
    \"polyunsaturated_fat\": \"0.8\",
    \"monounsaturated_fat\": \"1.5\",
    \"cholesterol\": \"110\",
    \"sodium\": \"95\",
    \"potassium\": \"420\",
    \"fiber\": \"0\",
    \"sugar\": \"0\"
  }"
}

fn food_entry_minimal_fixture() -> String {
  "{
    \"food_entry_id\": \"123456\",
    \"food_entry_name\": \"Custom Food\",
    \"food_entry_description\": \"Per 1 serving - Calories: 100kcal\",
    \"food_id\": \"\",
    \"serving_id\": \"\",
    \"number_of_units\": \"1\",
    \"meal\": \"breakfast\",
    \"date_int\": \"19723\",
    \"calories\": \"100\",
    \"carbohydrate\": \"10\",
    \"protein\": \"5\",
    \"fat\": \"2\"
  }"
}

fn day_summary_fixture() -> String {
  "{
    \"date_int\": \"19723\",
    \"calories\": \"2100\",
    \"carbohydrate\": \"200\",
    \"protein\": \"150\",
    \"fat\": \"70\"
  }"
}

fn month_summary_fixture() -> String {
  "{
    \"month\": \"1\",
    \"year\": \"2024\",
    \"days\": {
      \"day\": [
        {\"date_int\": \"19723\", \"calories\": \"2100\", \"carbohydrate\": \"200\", \"protein\": \"150\", \"fat\": \"70\"},
        {\"date_int\": \"19724\", \"calories\": \"1950\", \"carbohydrate\": \"180\", \"protein\": \"140\", \"fat\": \"65\"}
      ]
    }
  }"
}

fn month_summary_single_day_fixture() -> String {
  "{
    \"month\": \"1\",
    \"year\": \"2024\",
    \"days\": {
      \"day\": {\"date_int\": \"19723\", \"calories\": \"2100\", \"carbohydrate\": \"200\", \"protein\": \"150\", \"fat\": \"70\"}
    }
  }"
}
