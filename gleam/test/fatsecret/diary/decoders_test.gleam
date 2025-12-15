/// FatSecret Diary Decoders Tests
/// Tests the JSON decoders against real API response formats from FatSecret docs.
///
/// Reference: https://platform.fatsecret.com/docs/v2/food_entries.get
///
/// Run with: cd gleam && gleam test -- --module fatsecret/diary/decoders_test
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
