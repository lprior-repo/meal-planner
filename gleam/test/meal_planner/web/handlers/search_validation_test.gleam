//// Tests for search handler validation functions

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/types.{SearchFilters}
import meal_planner/web/handlers/search

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Query Validation Tests
// ============================================================================

pub fn validate_query_min_length_test() {
  // Query too short
  search.validate_search_query("a")
  |> should.be_error
  |> should.equal("Query must be at least 2 characters")
}

pub fn validate_query_empty_test() {
  // Empty query after trimming
  search.validate_search_query("  ")
  |> should.be_error
  |> should.equal("Query must be at least 2 characters")
}

pub fn validate_query_max_length_test() {
  // Query too long (201 characters)
  let long_query = "a" <> string.repeat("b", 200)
  search.validate_search_query(long_query)
  |> should.be_error
  |> should.equal("Query exceeds maximum length of 200 characters")
}

pub fn validate_query_valid_test() {
  // Valid query
  search.validate_search_query("apple")
  |> should.be_ok
  |> should.equal("apple")
}

pub fn validate_query_trimming_test() {
  // Query with whitespace should be trimmed
  search.validate_search_query("  apple  ")
  |> should.be_ok
  |> should.equal("apple")
}

pub fn validate_query_exactly_200_chars_test() {
  // Query exactly 200 characters should be valid
  let exactly_200 = string.repeat("a", 200)
  search.validate_search_query(exactly_200)
  |> should.be_ok
  |> should.equal(exactly_200)
}

// ============================================================================
// Boolean Filter Validation Tests
// ============================================================================

pub fn validate_boolean_true_test() {
  search.validate_boolean_filter("true")
  |> should.be_ok
  |> should.equal(True)
}

pub fn validate_boolean_true_uppercase_test() {
  search.validate_boolean_filter("TRUE")
  |> should.be_ok
  |> should.equal(True)
}

pub fn validate_boolean_one_test() {
  search.validate_boolean_filter("1")
  |> should.be_ok
  |> should.equal(True)
}

pub fn validate_boolean_false_test() {
  search.validate_boolean_filter("false")
  |> should.be_ok
  |> should.equal(False)
}

pub fn validate_boolean_zero_test() {
  search.validate_boolean_filter("0")
  |> should.be_ok
  |> should.equal(False)
}

pub fn validate_boolean_invalid_test() {
  search.validate_boolean_filter("yes")
  |> should.be_error
  |> should.equal("Invalid filter value: must be true, false, 1, or 0")
}

pub fn validate_boolean_with_whitespace_test() {
  search.validate_boolean_filter("  true  ")
  |> should.be_ok
  |> should.equal(True)
}

// ============================================================================
// Filter Validation Tests
// ============================================================================

pub fn validate_filters_all_defaults_test() {
  search.validate_filters(None, None, None)
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: False,
    branded_only: False,
    category: None,
  ))
}

pub fn validate_filters_verified_true_test() {
  search.validate_filters(Some("true"), None, None)
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: True,
    branded_only: False,
    category: None,
  ))
}

pub fn validate_filters_branded_one_test() {
  search.validate_filters(None, Some("1"), None)
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: False,
    branded_only: True,
    category: None,
  ))
}

pub fn validate_filters_with_category_test() {
  search.validate_filters(None, None, Some("Vegetables"))
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: False,
    branded_only: False,
    category: Some("Vegetables"),
  ))
}

pub fn validate_filters_category_all_test() {
  // "all" should be treated as None
  search.validate_filters(None, None, Some("all"))
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: False,
    branded_only: False,
    category: None,
  ))
}

pub fn validate_filters_category_empty_test() {
  // Empty category should be treated as None
  search.validate_filters(None, None, Some(""))
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: False,
    branded_only: False,
    category: None,
  ))
}

pub fn validate_filters_invalid_verified_test() {
  search.validate_filters(Some("invalid"), None, None)
  |> should.be_error
  |> should.equal("Invalid filter value: must be true, false, 1, or 0")
}

pub fn validate_filters_invalid_branded_test() {
  search.validate_filters(None, Some("maybe"), None)
  |> should.be_error
  |> should.equal("Invalid filter value: must be true, false, 1, or 0")
}

pub fn validate_filters_all_params_valid_test() {
  search.validate_filters(Some("1"), Some("0"), Some("Dairy"))
  |> should.be_ok
  |> should.equal(SearchFilters(
    verified_only: True,
    branded_only: False,
    category: Some("Dairy"),
  ))
}
