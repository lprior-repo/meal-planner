/// Tests for Supermarket decoder
///
/// Following TDD: These tests should FAIL first (RED), then pass after implementation (GREEN)
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/supermarket/supermarket_decoder
import meal_planner/tandoor/types/supermarket/supermarket.{
  Supermarket, SupermarketCategoryRelation,
}

/// Test decoding a minimal supermarket (required fields only, empty category list)
pub fn decode_minimal_supermarket_test() {
  let json_str =
    "{\"id\": 1, \"name\": \"Whole Foods\", \"category_to_supermarket\": []}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(Supermarket(
    id: 1,
    name: "Whole Foods",
    description: None,
    category_to_supermarket: [],
    open_data_slug: None,
  ))
}

/// Test decoding a complete supermarket with all fields
pub fn decode_complete_supermarket_test() {
  let json_str =
    "{\"id\": 2, \"name\": \"Trader Joe's\", \"description\": \"Neighborhood grocery store\", \"category_to_supermarket\": [{\"id\": 1, \"category\": 10, \"supermarket\": 2, \"order\": 0}, {\"id\": 2, \"category\": 20, \"supermarket\": 2, \"order\": 1}], \"open_data_slug\": \"trader-joes\"}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(Supermarket(
    id: 2,
    name: "Trader Joe's",
    description: Some("Neighborhood grocery store"),
    category_to_supermarket: [
      SupermarketCategoryRelation(
        id: 1,
        category_id: 10,
        supermarket_id: 2,
        order: 0,
      ),
      SupermarketCategoryRelation(
        id: 2,
        category_id: 20,
        supermarket_id: 2,
        order: 1,
      ),
    ],
    open_data_slug: Some("trader-joes"),
  ))
}

/// Test decoding with null optional fields
pub fn decode_supermarket_with_nulls_test() {
  let json_str =
    "{\"id\": 3, \"name\": \"Safeway\", \"description\": null, \"category_to_supermarket\": [], \"open_data_slug\": null}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(Supermarket(
    id: 3,
    name: "Safeway",
    description: None,
    category_to_supermarket: [],
    open_data_slug: None,
  ))
}

/// Test decoding fails on missing required field (id)
pub fn decode_supermarket_missing_id_test() {
  let json_str = "{\"name\": \"Kroger\", \"category_to_supermarket\": []}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_error
}

/// Test decoding fails on missing required field (name)
pub fn decode_supermarket_missing_name_test() {
  let json_str = "{\"id\": 5, \"category_to_supermarket\": []}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_error
}

/// Test decoding fails on missing required field (category_to_supermarket)
pub fn decode_supermarket_missing_categories_test() {
  let json_str = "{\"id\": 6, \"name\": \"Albertsons\"}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_error
}

/// Test decoding with single category relation
pub fn decode_supermarket_single_category_test() {
  let json_str =
    "{\"id\": 7, \"name\": \"Target\", \"category_to_supermarket\": [{\"id\": 100, \"category\": 5, \"supermarket\": 7, \"order\": 0}]}"

  let result = json.parse(json_str, using: supermarket_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(Supermarket(
    id: 7,
    name: "Target",
    description: None,
    category_to_supermarket: [
      SupermarketCategoryRelation(
        id: 100,
        category_id: 5,
        supermarket_id: 7,
        order: 0,
      ),
    ],
    open_data_slug: None,
  ))
}
