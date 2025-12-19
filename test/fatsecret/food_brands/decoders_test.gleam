/// Tests for FatSecret Food Brands API decoders (meal-planner-sl7q)
///
/// RED PHASE: These tests verify the food_brands decoders handle:
/// - Multiple brands in array response
/// - Single brand as object (FatSecret quirk)
/// - Empty brands array
/// - All BrandType variants (Manufacturer, Restaurant, Supermarket)
/// - Invalid brand type with fallback to Manufacturer
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
