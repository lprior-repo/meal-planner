/// Tests for Supermarkets Handler Module
///
/// Following TDD: Test FIRST (RED), then implement (GREEN), then refactor (BLUE)
///
/// Tests the extracted supermarkets handler that was split from tandoor.gleam.
/// Verifies JSON encoding functions work correctly.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/handlers/supermarkets

/// Test that supermarket JSON encoder produces correct format
pub fn encode_supermarket_json_test() {
  let supermarket_data = #(1, "Whole Foods", Some("Organic grocery store"))

  let expected_json =
    json.object([
      #("id", json.int(1)),
      #("name", json.string("Whole Foods")),
      #("description", json.string("Organic grocery store")),
    ])

  let actual_json = supermarkets.encode_supermarket(supermarket_data)

  should.equal(json.to_string(actual_json), json.to_string(expected_json))
}

/// Test supermarket encoding with no description (None)
pub fn encode_supermarket_no_description_test() {
  let supermarket_data = #(2, "Trader Joe's", None)

  let expected_json =
    json.object([
      #("id", json.int(2)),
      #("name", json.string("Trader Joe's")),
      #("description", json.null()),
    ])

  let actual_json = supermarkets.encode_supermarket(supermarket_data)

  should.equal(json.to_string(actual_json), json.to_string(expected_json))
}

/// Test supermarket category JSON encoder
pub fn encode_category_json_test() {
  let category_data = #(10, "Produce", Some("Fresh fruits and vegetables"))

  let expected_json =
    json.object([
      #("id", json.int(10)),
      #("name", json.string("Produce")),
      #("description", json.string("Fresh fruits and vegetables")),
    ])

  let actual_json = supermarkets.encode_category(category_data)

  should.equal(json.to_string(actual_json), json.to_string(expected_json))
}

/// Test category encoding with no description
pub fn encode_category_no_description_test() {
  let category_data = #(20, "Dairy", None)

  let expected_json =
    json.object([
      #("id", json.int(20)),
      #("name", json.string("Dairy")),
      #("description", json.null()),
    ])

  let actual_json = supermarkets.encode_category(category_data)

  should.equal(json.to_string(actual_json), json.to_string(expected_json))
}
