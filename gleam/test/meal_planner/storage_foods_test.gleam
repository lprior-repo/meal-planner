/// Tests for food storage module - specifically testing for duplicate results
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/postgres
import meal_planner/storage/foods
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

/// Test that exposes duplicate food results when query matches both
/// full-text search and ILIKE pattern
///
/// This test will FAIL until DISTINCT is added to the SQL query
pub fn search_foods_no_duplicates_test() {
  // Setup: Connect to test database
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  // Search for a common food that matches both FTS and ILIKE
  // Using "chicken breast" as it's likely in the database
  let query = "chicken breast"
  let limit = 50

  // Execute search
  let assert Ok(results) = foods.search_foods(conn, query, limit)

  // Collect all FDC IDs
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })

  // Check for duplicates by comparing length of list vs length of unique set
  let unique_ids = fdc_ids |> list.unique()
  let total_count = list.length(fdc_ids)
  let unique_count = list.length(unique_ids)

  // This assertion will FAIL if there are duplicates
  // Once DISTINCT is added to SQL, it will PASS
  unique_count
  |> should.equal(total_count)
}

/// Test search with filters also has no duplicates
pub fn search_foods_filtered_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let query = "chicken"
  let limit = 20
  let filters =
    types.SearchFilters(
      branded_only: False,
      category: None,
      verified_only: False,
    )

  let assert Ok(results) =
    foods.search_foods_filtered(conn, query, filters, limit)

  // Check for duplicates
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })
  let unique_ids = fdc_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(fdc_ids))
}
