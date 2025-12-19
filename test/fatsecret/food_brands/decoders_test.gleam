/// Tests for FatSecret Food Brands API decoders (meal-planner-sl7q)
///
/// RED PHASE: These tests verify the food_brands decoders handle:
/// - Multiple brands in array response
/// - Single brand as object (FatSecret quirk)
/// - Empty brands array
/// - All BrandType variants (Manufacturer, Restaurant, Supermarket)
/// - Invalid brand type with fallback to Manufacturer
///
/// EXTENDED: Fixture-based tests (meal-planner-vxh4)
/// - Multiple brands from scraped JSON fixture
/// - Single brand from scraped JSON fixture
import fatsecret/support/fixtures
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/fatsecret/food_brands/decoders
import meal_planner/fatsecret/food_brands/types

/// Test: Decoding multiple brands in array response
///
/// FatSecret returns array when multiple results exist.
pub fn brands_response_multiple_test() {
  let response =
    "{
    \"brands\": [
      {
        \"brand_id\": \"1\",
        \"brand_name\": \"Kraft\",
        \"brand_type\": \"manufacturer\"
      },
      {
        \"brand_id\": \"2\",
        \"brand_name\": \"KFC\",
        \"brand_type\": \"restaurant\"
      },
      {
        \"brand_id\": \"3\",
        \"brand_name\": \"Whole Foods\",
        \"brand_type\": \"supermarket\"
      }
    ]
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.brands), 3)
}

/// Test: Decoding SINGLE brand object (not array) - FatSecret quirk
///
/// When a single brand is returned, FatSecret returns object NOT array.
/// The decoder must handle this with decode.one_of().
pub fn brands_response_single_test() {
  let response =
    "{
    \"brands\": {
      \"brand_id\": \"1\",
      \"brand_name\": \"Kraft\",
      \"brand_type\": \"manufacturer\"
    }
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.brands), 1)
}

/// Test: Decoding empty brands array
pub fn brands_response_empty_test() {
  let response = "{\"brands\": []}"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.brands), 0)
}

/// Test: Brand with Manufacturer type
pub fn brand_type_manufacturer_test() {
  let response =
    "{
    \"brands\": [
      {
        \"brand_id\": \"1\",
        \"brand_name\": \"Kraft\",
        \"brand_type\": \"manufacturer\"
      }
    ]
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  let assert Ok(brand) = list.first(parsed.brands)
  let types.Brand(brand_id: _, brand_name: _, brand_type: t) = brand
  should.equal(t, types.Manufacturer)
}

/// Test: Brand with Restaurant type
pub fn brand_type_restaurant_test() {
  let response =
    "{
    \"brands\": [
      {
        \"brand_id\": \"2\",
        \"brand_name\": \"KFC\",
        \"brand_type\": \"restaurant\"
      }
    ]
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  let assert Ok(brand) = list.first(parsed.brands)
  let types.Brand(brand_id: _, brand_name: _, brand_type: t) = brand
  should.equal(t, types.Restaurant)
}

/// Test: Brand with Supermarket type
pub fn brand_type_supermarket_test() {
  let response =
    "{
    \"brands\": [
      {
        \"brand_id\": \"3\",
        \"brand_name\": \"Whole Foods\",
        \"brand_type\": \"supermarket\"
      }
    ]
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  let assert Ok(brand) = list.first(parsed.brands)
  let types.Brand(brand_id: _, brand_name: _, brand_type: t) = brand
  should.equal(t, types.Supermarket)
}

/// Test: Invalid brand type defaults to Manufacturer
///
/// When FatSecret returns an unknown brand_type, decoder defaults to Manufacturer
pub fn brand_type_invalid_test() {
  let response =
    "{
    \"brands\": [
      {
        \"brand_id\": \"99\",
        \"brand_name\": \"Unknown Brand\",
        \"brand_type\": \"unknown_type\"
      }
    ]
  }"

  let result = json.parse(response, decoders.brands_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  let assert Ok(brand) = list.first(parsed.brands)
  let types.Brand(brand_id: _, brand_name: _, brand_type: t) = brand
  should.equal(t, types.Manufacturer)
}

// ============================================================================
// Fixture-Based Tests (meal-planner-vxh4)
// ============================================================================

/// Test: Decode multiple brands from scraped JSON fixture
///
/// Uses realistic scraped API response with multiple brands.
/// Verifies decoder handles array response and all brand types.
pub fn brands_decoder_multiple_from_fixture_test() {
  // Arrange - Load scraped fixture with multiple brands
  let assert Ok(fixture_json) = fixtures.load_scraped_fixture("brands_multiple")

  // Act - Decode using the brands response decoder
  let result = json.parse(fixture_json, decoders.brands_response_decoder())

  // Assert - Should decode successfully with 3 brands
  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.brands), 3)

  // Verify first brand (Manufacturer)
  let assert Ok(brand1) = list.first(parsed.brands)
  should.equal(brand1.brand_name, "Kraft Foods")
  should.equal(brand1.brand_type, types.Manufacturer)

  // Verify second brand (Restaurant)
  let assert Ok(brand2) = parsed.brands |> list.drop(1) |> list.first()
  should.equal(brand2.brand_name, "McDonald's")
  should.equal(brand2.brand_type, types.Restaurant)

  // Verify third brand (Supermarket)
  let assert Ok(brand3) = parsed.brands |> list.drop(2) |> list.first()
  should.equal(brand3.brand_name, "Whole Foods Market")
  should.equal(brand3.brand_type, types.Supermarket)
}

/// Test: Decode SINGLE brand from scraped JSON fixture
///
/// FatSecret quirk: When only one brand exists, API returns object NOT array.
/// Uses realistic scraped fixture to verify decoder handles this edge case.
pub fn brands_decoder_single_from_fixture_test() {
  // Arrange - Load scraped fixture with single brand (object, not array)
  let assert Ok(fixture_json) = fixtures.load_scraped_fixture("brands_single")

  // Act - Decode using the brands response decoder
  let result = json.parse(fixture_json, decoders.brands_response_decoder())

  // Assert - Should decode successfully with 1 brand
  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.brands), 1)

  // Verify brand details
  let assert Ok(brand) = list.first(parsed.brands)
  should.equal(brand.brand_name, "Starbucks")
  should.equal(brand.brand_type, types.Restaurant)
  should.equal(types.brand_id_to_string(brand.brand_id), "42")
}
