/// FatSecret Diary Decoders Tests
/// Tests the JSON decoders against real API response formats from FatSecret docs.
///
/// Reference: https://platform.fatsecret.com/docs/v2/food_entries.get
///
/// Run with: cd gleam && gleam test
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures: Real API Response Formats from Documentation
// ============================================================================

/// Single food entry response (from food_entry.get endpoint)
/// https://platform.fatsecret.com/docs/v2/food_entry.get
fn single_entry_json() -> String {
  "{"
  <> "  \"food_entry_id\": \"123456\","
  <> "  \"food_entry_name\": \"Chicken Breast\","
  <> "  \"food_entry_description\": \"Per 100g - Calories: 165kcal | Fat: 3.6g | Carbs: 0g | Protein: 31g\","
  <> "  \"food_id\": \"4142\","
  <> "  \"serving_id\": \"12345\","
  <> "  \"number_of_units\": \"1.5\","
  <> "  \"meal\": \"dinner\","
  <> "  \"date_int\": \"19723\","
  <> "  \"calories\": \"248\","
  <> "  \"carbohydrate\": \"0\","
  <> "  \"protein\": \"46.5\","
  <> "  \"fat\": \"5.4\","
  <> "  \"saturated_fat\": \"1.2\","
  <> "  \"polyunsaturated_fat\": \"0.8\","
  <> "  \"monounsaturated_fat\": \"1.5\","
  <> "  \"cholesterol\": \"110\","
  <> "  \"sodium\": \"95\","
  <> "  \"potassium\": \"420\","
  <> "  \"fiber\": \"0\","
  <> "  \"sugar\": \"0\""
  <> "}"
}

/// Multiple entries response (from food_entries.get endpoint)
/// https://platform.fatsecret.com/docs/v2/food_entries.get
fn multiple_entries_response_json() -> String {
  "{"
  <> "  \"food_entries\": {"
  <> "    \"food_entry\": ["
  <> "      {"
  <> "        \"food_entry_id\": \"123456\","
  <> "        \"food_entry_name\": \"Chicken Breast\","
  <> "        \"food_entry_description\": \"Per 100g\","
  <> "        \"food_id\": \"4142\","
  <> "        \"serving_id\": \"12345\","
  <> "        \"number_of_units\": \"1.5\","
  <> "        \"meal\": \"breakfast\","
  <> "        \"date_int\": \"19723\","
  <> "        \"calories\": \"248\","
  <> "        \"carbohydrate\": \"0\","
  <> "        \"protein\": \"46.5\","
  <> "        \"fat\": \"5.4\","
  <> "        \"saturated_fat\": \"1.2\","
  <> "        \"polyunsaturated_fat\": \"0.8\","
  <> "        \"monounsaturated_fat\": \"1.5\","
  <> "        \"cholesterol\": \"110\","
  <> "        \"sodium\": \"95\","
  <> "        \"potassium\": \"420\","
  <> "        \"fiber\": \"0\","
  <> "        \"sugar\": \"0\""
  <> "      },"
  <> "      {"
  <> "        \"food_entry_id\": \"123457\","
  <> "        \"food_entry_name\": \"Rice\","
  <> "        \"food_entry_description\": \"Cooked white rice\","
  <> "        \"food_id\": \"5000\","
  <> "        \"serving_id\": \"54321\","
  <> "        \"number_of_units\": \"1.0\","
  <> "        \"meal\": \"lunch\","
  <> "        \"date_int\": \"19723\","
  <> "        \"calories\": \"180\","
  <> "        \"carbohydrate\": \"40\","
  <> "        \"protein\": \"3.5\","
  <> "        \"fat\": \"0.3\","
  <> "        \"saturated_fat\": \"0.1\","
  <> "        \"polyunsaturated_fat\": \"0.1\","
  <> "        \"monounsaturated_fat\": \"0.1\","
  <> "        \"cholesterol\": \"0\","
  <> "        \"sodium\": \"1\","
  <> "        \"potassium\": \"30\","
  <> "        \"fiber\": \"0.4\","
  <> "        \"sugar\": \"0.1\""
  <> "      }"
  <> "    ]"
  <> "  }"
  <> "}"
}

/// Empty entries response
fn empty_entries_response_json() -> String {
  "{" <> "  \"food_entries\": {" <> "    \"food_entry\": []" <> "  }" <> "}"
}

// ============================================================================
// Tests: Decode Single Food Entry
// ============================================================================

pub fn decode_single_entry_test() {
  let json_str = single_entry_json()
  let assert Ok(decoded) = json.parse(json_str, decoders.food_entry_decoder())

  // Verify all fields parsed correctly
  let expected_name = "Chicken Breast"
  decoded.food_entry_name |> should.equal(expected_name)

  let expected_calories = 248.0
  decoded.calories |> should.equal(expected_calories)

  let expected_protein = 46.5
  decoded.protein |> should.equal(expected_protein)

  let expected_date = 19_723
  decoded.date_int |> should.equal(expected_date)
}

pub fn decode_single_entry_with_optional_fields_test() {
  let json_str = single_entry_json()
  let assert Ok(decoded) = json.parse(json_str, decoders.food_entry_decoder())

  // Verify optional fields are parsed
  case decoded.saturated_fat {
    Some(f) -> f |> should.equal(1.2)
    None -> should.fail()
  }

  case decoded.fiber {
    Some(f) -> f |> should.equal(0.0)
    None -> should.fail()
  }
}

// ============================================================================
// Tests: Decode Multiple Food Entries
// ============================================================================

pub fn decode_multiple_entries_test() {
  let json_str = multiple_entries_response_json()

  // Parse the response using the same path structure as the client
  let decoder =
    decode.at(
      ["food_entries", "food_entry"],
      decode.list(decoders.food_entry_decoder()),
    )

  let assert Ok(decoded) = json.parse(json_str, decoder)

  // Should have 2 entries
  let length = list.length(decoded)
  length |> should.equal(2)

  // First entry should be chicken
  let first = case decoded {
    [entry, ..] -> entry
    [] -> panic as "Expected at least one entry"
  }
  first.food_entry_name |> should.equal("Chicken Breast")
  first.meal |> should.equal(types.Breakfast)

  // Second entry should be rice
  let second = case decoded {
    [_, entry, ..] -> entry
    _ -> panic as "Expected at least two entries"
  }
  second.food_entry_name |> should.equal("Rice")
  second.meal |> should.equal(types.Lunch)
}

// ============================================================================
// Tests: Decode Empty Response
// ============================================================================

pub fn decode_empty_entries_test() {
  let json_str = empty_entries_response_json()

  let decoder =
    decode.at(
      ["food_entries", "food_entry"],
      decode.list(decoders.food_entry_decoder()),
    )

  let assert Ok(decoded) = json.parse(json_str, decoder)

  // Should have 0 entries
  let length = list.length(decoded)
  length |> should.equal(0)
}

// ============================================================================
// Tests: Day Summary Decoder
// ============================================================================

pub fn decode_day_summary_test() {
  let json_str =
    "{"
    <> "  \"date_int\": \"19723\","
    <> "  \"calories\": \"2100\","
    <> "  \"carbohydrate\": \"200\","
    <> "  \"protein\": \"150\","
    <> "  \"fat\": \"70\""
    <> "}"

  let assert Ok(decoded) = json.parse(json_str, decoders.day_summary_decoder())

  decoded.calories |> should.equal(2100.0)
  decoded.protein |> should.equal(150.0)
  decoded.date_int |> should.equal(19_723)
}

// ============================================================================
// Tests: Month Summary Decoder
// ============================================================================

pub fn decode_month_summary_test() {
  let json_str =
    "{"
    <> "  \"month\": \"1\","
    <> "  \"year\": \"2024\","
    <> "  \"days\": {"
    <> "    \"day\": ["
    <> "      {"
    <> "        \"date_int\": \"19723\","
    <> "        \"calories\": \"2100\","
    <> "        \"carbohydrate\": \"200\","
    <> "        \"protein\": \"150\","
    <> "        \"fat\": \"70\""
    <> "      },"
    <> "      {"
    <> "        \"date_int\": \"19724\","
    <> "        \"calories\": \"1950\","
    <> "        \"carbohydrate\": \"180\","
    <> "        \"protein\": \"140\","
    <> "        \"fat\": \"65\""
    <> "      }"
    <> "    ]"
    <> "  }"
    <> "}"

  let assert Ok(decoded) =
    json.parse(json_str, decoders.month_summary_decoder())

  decoded.month |> should.equal(1)
  decoded.year |> should.equal(2024)
  list.length(decoded.days) |> should.equal(2)
}

/// Test MonthSummary with single day (not in array)
pub fn decode_month_summary_single_day_test() {
  let json_str =
    "{"
    <> "  \"month\": \"2\","
    <> "  \"year\": \"2024\","
    <> "  \"days\": {"
    <> "    \"day\": {"
    <> "      \"date_int\": \"19724\","
    <> "      \"calories\": \"1950\","
    <> "      \"carbohydrate\": \"180\","
    <> "      \"protein\": \"140\","
    <> "      \"fat\": \"65\""
    <> "    }"
    <> "  }"
    <> "}"

  let assert Ok(decoded) =
    json.parse(json_str, decoders.month_summary_decoder())

  decoded.month |> should.equal(2)
  decoded.year |> should.equal(2024)
  list.length(decoded.days) |> should.equal(1)

  // Verify the single day was parsed correctly
  let first = case decoded.days {
    [day] -> day
    _ -> panic as "Expected exactly one day"
  }

  first.date_int |> should.equal(19_724)
  first.calories |> should.equal(1950.0)
}

// ============================================================================
// Edge Case Tests: Optional Fields
// ============================================================================

/// Test entry with missing optional micronutrient fields
pub fn decode_entry_without_optional_fields_test() {
  let json_str =
    "{"
    <> "  \"food_entry_id\": \"123456\","
    <> "  \"food_entry_name\": \"Apple\","
    <> "  \"food_entry_description\": \"Raw apple\","
    <> "  \"food_id\": \"1000\","
    <> "  \"serving_id\": \"5000\","
    <> "  \"number_of_units\": \"1.0\","
    <> "  \"meal\": \"snack\","
    <> "  \"date_int\": \"19723\","
    <> "  \"calories\": \"95\","
    <> "  \"carbohydrate\": \"25\","
    <> "  \"protein\": \"0.5\","
    <> "  \"fat\": \"0.3\""
    <> "}"

  let assert Ok(decoded) = json.parse(json_str, decoders.food_entry_decoder())

  decoded.food_entry_name |> should.equal("Apple")
  decoded.calories |> should.equal(95.0)

  // Optional fields should be None when missing
  decoded.saturated_fat |> should.equal(None)
  decoded.cholesterol |> should.equal(None)
  decoded.sodium |> should.equal(None)
}

/// Test entry with single entry not in array format
pub fn decode_single_entry_as_object_test() {
  let json_str =
    "{"
    <> "  \"food_entries\": {"
    <> "    \"food_entry\": {"
    <> "      \"food_entry_id\": \"123456\","
    <> "      \"food_entry_name\": \"Banana\","
    <> "      \"food_entry_description\": \"Yellow banana\","
    <> "      \"food_id\": \"3000\","
    <> "      \"serving_id\": \"30000\","
    <> "      \"number_of_units\": \"1.0\","
    <> "      \"meal\": \"breakfast\","
    <> "      \"date_int\": \"19723\","
    <> "      \"calories\": \"89\","
    <> "      \"carbohydrate\": \"23\","
    <> "      \"protein\": \"1.1\","
    <> "      \"fat\": \"0.3\""
    <> "    }"
    <> "  }"
    <> "}"

  // Test parsing with fallback strategy
  let decoder =
    decode.one_of(
      decode.at(
        ["food_entries", "food_entry"],
        decode.list(decoders.food_entry_decoder()),
      ),
      [
        decode.at(
          ["food_entries", "food_entry"],
          single_entry_to_list_decoder(),
        ),
        decode.success([]),
      ],
    )

  let assert Ok(decoded) = json.parse(json_str, decoder)
  list.length(decoded) |> should.equal(1)

  let first = case decoded {
    [entry] -> entry
    _ -> panic as "Expected exactly one entry"
  }

  first.food_entry_name |> should.equal("Banana")
  first.calories |> should.equal(89.0)
}

/// Test parsing of large calorie values
pub fn decode_entry_with_large_calories_test() {
  let json_str =
    "{"
    <> "  \"food_entry_id\": \"999999\","
    <> "  \"food_entry_name\": \"Feast\","
    <> "  \"food_entry_description\": \"Large meal\","
    <> "  \"food_id\": \"50000\","
    <> "  \"serving_id\": \"500000\","
    <> "  \"number_of_units\": \"10.0\","
    <> "  \"meal\": \"dinner\","
    <> "  \"date_int\": \"19723\","
    <> "  \"calories\": \"5000\","
    <> "  \"carbohydrate\": \"500\","
    <> "  \"protein\": \"200\","
    <> "  \"fat\": \"250\""
    <> "}"

  let assert Ok(decoded) = json.parse(json_str, decoders.food_entry_decoder())

  decoded.calories |> should.equal(5000.0)
  decoded.carbohydrate |> should.equal(500.0)
  decoded.protein |> should.equal(200.0)
  decoded.fat |> should.equal(250.0)
}

/// Test parsing of very small decimal values
pub fn decode_entry_with_small_decimals_test() {
  let json_str =
    "{"
    <> "  \"food_entry_id\": \"123456\","
    <> "  \"food_entry_name\": \"Spice\","
    <> "  \"food_entry_description\": \"Pinch of salt\","
    <> "  \"food_id\": \"20000\","
    <> "  \"serving_id\": \"200000\","
    <> "  \"number_of_units\": \"0.001\","
    <> "  \"meal\": \"snack\","
    <> "  \"date_int\": \"19723\","
    <> "  \"calories\": \"0.1\","
    <> "  \"carbohydrate\": \"0.01\","
    <> "  \"protein\": \"0.001\","
    <> "  \"fat\": \"0.0\""
    <> "}"

  let assert Ok(decoded) = json.parse(json_str, decoders.food_entry_decoder())

  decoded.number_of_units |> should.equal(0.001)
  decoded.calories |> should.equal(0.1)
  decoded.carbohydrate |> should.equal(0.01)
  decoded.protein |> should.equal(0.001)
}

// ============================================================================
// Helper Functions
// ============================================================================

fn single_entry_to_list_decoder() -> decode.Decoder(List(types.FoodEntry)) {
  use entry <- decode.then(decoders.food_entry_decoder())
  decode.success([entry])
}
