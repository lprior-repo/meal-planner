/// Example: Using Pagination Helpers
///
/// This example demonstrates how to use the pagination helper utilities
/// from meal_planner/tandoor/core/pagination.gleam

import gleam/io
import gleam/option.{None, Some}
import meal_planner/tandoor/core/pagination

pub fn main() {
  // Example 1: Check if there's a next page
  example_check_next_page()

  // Example 2: Extract pagination params from URL
  example_extract_params()

  // Example 3: Build query strings
  example_build_query()

  // Example 4: Use PaginationParams type
  example_pagination_params()
}

fn example_check_next_page() {
  io.println("\n=== Example 1: Check for Next Page ===")

  // Simulate a paginated response with more pages
  let response_with_next =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=10"),
      previous: None,
      results: [],
    )

  case pagination.has_next_page(response_with_next) {
    True -> io.println("✓ Has next page - continue fetching")
    False -> io.println("✗ No next page")
  }

  // Simulate a final page
  let final_page =
    pagination.PaginatedResponse(
      count: 15,
      next: None,
      previous: Some("http://api.example.com/foods?limit=10&offset=0"),
      results: [],
    )

  case pagination.has_next_page(final_page) {
    True -> io.println("✓ Has next page")
    False -> io.println("✗ No next page - pagination complete")
  }
}

fn example_extract_params() {
  io.println("\n=== Example 2: Extract Pagination Parameters ===")

  let response =
    pagination.PaginatedResponse(
      count: 200,
      next: Some("http://api.example.com/foods?limit=50&offset=100"),
      previous: Some("http://api.example.com/foods?limit=50&offset=0"),
      results: [],
    )

  // Extract next page params
  case pagination.next_page_params(response) {
    Some(#(limit, offset)) -> {
      io.println(
        "Next page: limit="
        <> int_to_string(limit)
        <> ", offset="
        <> int_to_string(offset),
      )
    }
    None -> io.println("No next page parameters")
  }

  // Extract previous page params
  case pagination.previous_page_params(response) {
    Some(#(limit, offset)) -> {
      io.println(
        "Previous page: limit="
        <> int_to_string(limit)
        <> ", offset="
        <> int_to_string(offset),
      )
    }
    None -> io.println("No previous page parameters")
  }
}

fn example_build_query() {
  io.println("\n=== Example 3: Build Query Strings ===")

  // Build query with all parameters
  let query1 =
    pagination.build_query_string([
      #("limit", Some("20")),
      #("offset", Some("40")),
      #("search", Some("chicken")),
    ])
  io.println("Full query: " <> query1)
  // Output: limit=20&offset=40&search=chicken

  // Build query with some None values (they'll be filtered out)
  let query2 =
    pagination.build_query_string([
      #("limit", Some("10")),
      #("offset", None),
      #("filter", Some("vegetable")),
    ])
  io.println("Partial query: " <> query2)
  // Output: limit=10&filter=vegetable
}

fn example_pagination_params() {
  io.println("\n=== Example 4: PaginationParams Type ===")

  // Create pagination params
  let params =
    pagination.PaginationParams(limit: Some(25), offset: Some(75))

  // Convert to query string
  let query = pagination.pagination_params_to_query(params)
  io.println("Params as query: " <> query)
  // Output: limit=25&offset=75

  // With only limit
  let limit_only = pagination.PaginationParams(limit: Some(10), offset: None)
  io.println(
    "Limit only: " <> pagination.pagination_params_to_query(limit_only),
  )
  // Output: limit=10
}

// Helper function (normally would import from gleam/int)
fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    10 -> "10"
    20 -> "20"
    40 -> "40"
    50 -> "50"
    75 -> "75"
    100 -> "100"
    _ -> "N"
  }
}
