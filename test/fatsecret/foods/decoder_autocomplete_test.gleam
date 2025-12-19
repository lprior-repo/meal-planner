/// Tests for FatSecret Foods Autocomplete decoders with scraped JSON fixtures
///
/// RED PHASE: These tests verify autocomplete decoders handle:
/// - Multiple suggestions in array response (typical case)
/// - Single suggestion as object (FatSecret single-vs-array quirk)
/// - Empty suggestions array
///
/// All tests use scraped JSON fixtures from test/fixtures/fatsecret/scraped/
import fatsecret/support/fixtures
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/fatsecret/foods/decoders
import meal_planner/fatsecret/foods/types

/// Test: Decode multiple autocomplete suggestions from scraped fixture
///
/// FatSecret returns array when multiple suggestions exist.
/// This is the typical autocomplete response pattern.
pub fn autocomplete_decoder_multiple_suggestions_from_fixture_test() {
  // Arrange - Load scraped fixture with multiple suggestions
  let assert Ok(fixture_json) =
    fixtures.load_scraped_fixture("autocomplete_multiple")

  // Act - Decode using the autocomplete response decoder
  let result =
    json.parse(fixture_json, decoders.food_autocomplete_response_decoder())

  // Assert - Should decode successfully with 4 suggestions
  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.suggestions), 4)

  // Verify first suggestion details
  let assert Ok(first) = list.first(parsed.suggestions)
  should.equal(first.food_name, "Banana")
  should.equal(types.food_id_to_string(first.food_id), "35755")
}

/// Test: Decode SINGLE autocomplete suggestion from scraped fixture
///
/// FatSecret quirk: When only one suggestion exists, API returns object NOT array.
/// The decoder must handle this with decode.one_of().
pub fn autocomplete_decoder_single_suggestion_from_fixture_test() {
  // Arrange - Load scraped fixture with single suggestion (object, not array)
  let assert Ok(fixture_json) =
    fixtures.load_scraped_fixture("autocomplete_single")

  // Act - Decode using the autocomplete response decoder
  let result =
    json.parse(fixture_json, decoders.food_autocomplete_response_decoder())

  // Assert - Should decode successfully with 1 suggestion
  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.suggestions), 1)

  // Verify suggestion details
  let assert Ok(suggestion) = list.first(parsed.suggestions)
  should.equal(suggestion.food_name, "Apple")
  should.equal(types.food_id_to_string(suggestion.food_id), "33691")
}

/// Test: Decode empty autocomplete suggestions from scraped fixture
///
/// When no suggestions match, FatSecret returns empty array.
pub fn autocomplete_decoder_empty_suggestions_from_fixture_test() {
  // Arrange - Load scraped fixture with empty suggestions
  let assert Ok(fixture_json) =
    fixtures.load_scraped_fixture("autocomplete_empty")

  // Act - Decode using the autocomplete response decoder
  let result =
    json.parse(fixture_json, decoders.food_autocomplete_response_decoder())

  // Assert - Should decode successfully with 0 suggestions
  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.suggestions), 0)
}
