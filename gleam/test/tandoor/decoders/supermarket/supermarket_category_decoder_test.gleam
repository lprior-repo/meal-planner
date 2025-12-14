/// Tests for SupermarketCategory decoder
///
/// Following TDD: These tests should FAIL first (RED), then pass after implementation (GREEN)
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/supermarket/supermarket_category_decoder
import meal_planner/tandoor/types/supermarket/supermarket_category.{
  SupermarketCategory,
}

/// Test decoding a minimal supermarket category (required fields only)
pub fn decode_minimal_supermarket_category_test() {
  let json_str = "{\"id\": 1, \"name\": \"Produce\"}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(SupermarketCategory(
    id: 1,
    name: "Produce",
    description: None,
    open_data_slug: None,
  ))
}

/// Test decoding a complete supermarket category (all fields)
pub fn decode_complete_supermarket_category_test() {
  let json_str =
    "{\"id\": 2, \"name\": \"Dairy\", \"description\": \"Milk, cheese, yogurt\", \"open_data_slug\": \"dairy-products\"}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(SupermarketCategory(
    id: 2,
    name: "Dairy",
    description: Some("Milk, cheese, yogurt"),
    open_data_slug: Some("dairy-products"),
  ))
}

/// Test decoding with null optional fields
pub fn decode_category_with_nulls_test() {
  let json_str =
    "{\"id\": 3, \"name\": \"Frozen Foods\", \"description\": null, \"open_data_slug\": null}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(SupermarketCategory(
    id: 3,
    name: "Frozen Foods",
    description: None,
    open_data_slug: None,
  ))
}

/// Test decoding fails on missing required field (id)
pub fn decode_category_missing_id_test() {
  let json_str = "{\"name\": \"Bakery\"}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_error
}

/// Test decoding fails on missing required field (name)
pub fn decode_category_missing_name_test() {
  let json_str = "{\"id\": 5}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_error
}

/// Test decoding with special characters in name
pub fn decode_category_special_chars_test() {
  let json_str =
    "{\"id\": 6, \"name\": \"Fruits & Vegetables\", \"description\": \"Fresh produce section\"}"

  let result =
    json.decode(from: json_str, using: supermarket_category_decoder.decoder())

  result
  |> should.be_ok
  |> should.equal(SupermarketCategory(
    id: 6,
    name: "Fruits & Vegetables",
    description: Some("Fresh produce section"),
    open_data_slug: None,
  ))
}
