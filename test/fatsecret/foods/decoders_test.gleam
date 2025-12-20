/// Tests for FatSecret Foods JSON decoders
///
/// Verifies correct parsing of FatSecret API responses including:
/// - Single vs array edge cases
/// - Numeric strings vs numbers
/// - Optional fields
/// - Branded vs generic foods
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/foods/decoders
import meal_planner/fatsecret/foods/types
import fatsecret/support/fixtures

// ============================================================================
// Food Decoder Tests (food.get.v5)
// ============================================================================

pub fn decode_generic_food_with_multiple_servings_test() {
  let json_str = fixtures.load_scraped_fixture("food_get_generic")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_decoder())
    |> should.be_ok

  // Verify food details
  types.food_id_to_string(result.food_id) |> should.equal("33691")
  result.food_name |> should.equal("Banana")
  result.food_type |> should.equal("Generic")
  result.brand_name |> should.equal(None)

  // Verify multiple servings parsed
  result.servings |> list.length |> should.equal(4)

  // Verify first serving details
  let assert [first, ..] = result.servings
  types.serving_id_to_string(first.serving_id) |> should.equal("29698")
  first.serving_description
  |> should.equal("1 extra small (less than 6\" long)")
  first.nutrition.calories |> should.equal(72.0)
  first.nutrition.carbohydrate |> should.equal(18.5)
  first.nutrition.protein |> should.equal(0.88)
  first.nutrition.fat |> should.equal(0.27)
}

pub fn decode_branded_food_test() {
  let json_str = fixtures.load_scraped_fixture("food_get_branded")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_decoder())
    |> should.be_ok

  // Verify brand name is present
  result.food_type |> should.equal("Brand")
  result.brand_name |> should.be_some
}

pub fn decode_food_response_wrapper_test() {
  // Using the inline fixture for the wrapper test
  let json_str = fixtures.food_response()

  let result =
    json.parse(json_str, decoders.food_decoder())
    |> should.be_ok

  result.food_name |> should.equal("Apple")
  result.nutrition.calories |> should.equal(95.0)
}

// ============================================================================
// Food Search Response Tests (foods.search)
// ============================================================================

pub fn decode_food_search_multiple_results_test() {
  let json_str = fixtures.load_scraped_fixture("food_search_multiple")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_search_response_decoder())
    |> should.be_ok

  // Verify pagination metadata
  result.total_results |> should.equal(4)
  result.max_results |> should.equal(50)
  result.page_number |> should.equal(0)

  // Verify foods list
  result.foods |> list.length |> should.equal(4)

  // Verify first food
  let assert [first, ..] = result.foods
  types.food_id_to_string(first.food_id) |> should.equal("33691")
  first.food_name |> should.equal("Banana")
  first.food_type |> should.equal("Generic")
  first.brand_name |> should.equal(None)

  // Verify branded food in list
  let assert Ok(branded) =
    result.foods
    |> list.find(fn(f) { f.food_type == "Brand" })
  branded.brand_name |> should.equal(Some("Great Value"))
}

pub fn decode_food_search_single_result_test() {
  let json_str = fixtures.load_scraped_fixture("food_search_single")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_search_response_decoder())
    |> should.be_ok

  // Single result should still be wrapped in list
  result.foods |> list.length |> should.equal(1)
  result.total_results |> should.equal(1)
}

pub fn decode_food_search_empty_results_test() {
  let json_str = fixtures.load_scraped_fixture("food_search_empty")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_search_response_decoder())
    |> should.be_ok

  result.foods |> list.length |> should.equal(0)
  result.total_results |> should.equal(0)
}

pub fn decode_search_inline_fixture_test() {
  // Using the inline multi-result fixture
  let result =
    json.parse(
      fixtures.food_search_response(),
      decoders.food_search_response_decoder(),
    )
    |> should.be_ok

  result.total_results |> should.equal(3)
  result.foods |> list.length |> should.equal(3)
}

// ============================================================================
// Autocomplete Response Tests (foods.autocomplete.v2)
// ============================================================================

pub fn decode_autocomplete_multiple_suggestions_test() {
  let json_str = fixtures.load_scraped_fixture("autocomplete_multiple")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_autocomplete_response_decoder())
    |> should.be_ok

  // Verify multiple suggestions
  result.suggestions |> list.length |> should.equal(4)

  // Verify first suggestion
  let assert [first, ..] = result.suggestions
  types.food_id_to_string(first.food_id) |> should.equal("35755")
  first.food_name |> should.equal("Banana")
}

pub fn decode_autocomplete_single_suggestion_test() {
  let json_str = fixtures.load_scraped_fixture("autocomplete_single")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_autocomplete_response_decoder())
    |> should.be_ok

  // Single suggestion should be wrapped in list
  result.suggestions |> list.length |> should.equal(1)
}

pub fn decode_autocomplete_empty_test() {
  let json_str = fixtures.load_scraped_fixture("autocomplete_empty")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.food_autocomplete_response_decoder())
    |> should.be_ok

  result.suggestions |> list.length |> should.equal(0)
}

// ============================================================================
// Barcode Lookup Response Tests (food.find_id_for_barcode.v2)
// ============================================================================

pub fn decode_barcode_lookup_success_test() {
  let json_str = fixtures.load_scraped_fixture("barcode_lookup_success")
  let assert Ok(json_content) = json_str

  let result =
    json.parse(json_content, decoders.barcode_lookup_decoder())
    |> should.be_ok

  types.food_id_to_string(result) |> should.equal("4427908")
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn decode_numeric_string_values_test() {
  // FatSecret sometimes returns numbers as strings
  let json_str =
    "{
    \"calories\": \"100\",
    \"carbohydrate\": \"25.5\",
    \"protein\": \"5\",
    \"fat\": \"2.5\"
  }"

  let result =
    json.parse(json_str, decoders.nutrition_decoder())
    |> should.be_ok

  result.calories |> should.equal(100.0)
  result.carbohydrate |> should.equal(25.5)
  result.protein |> should.equal(5.0)
  result.fat |> should.equal(2.5)
}

pub fn decode_optional_nutrition_fields_test() {
  // Only required macros present
  let json_str =
    "{
    \"calories\": \"100\",
    \"carbohydrate\": \"25.5\",
    \"protein\": \"5\",
    \"fat\": \"2.5\"
  }"

  let result =
    json.parse(json_str, decoders.nutrition_decoder())
    |> should.be_ok

  // Optional fields should be None
  result.saturated_fat |> should.equal(None)
  result.fiber |> should.equal(None)
  result.vitamin_a |> should.equal(None)
}
