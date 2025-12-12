/// Tests for food storage module - specifically testing for duplicate results
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage/foods
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

/// Test that search_foods returns no duplicate FDC IDs
///
/// This test verifies that the DISTINCT ON (fdc_id) clause in the SQL
/// query successfully prevents duplicate food entries in search results.
pub fn search_foods_no_duplicates_test() {
  // Setup: Connect to test database
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  // Search for a common food that matches both full-text search and ILIKE
  // Using "chicken" as it's likely to have many matches in the database
  let query = "chicken"
  let limit = 50

  // Execute search
  let assert Ok(results) = foods.search_foods(conn, query, limit)

  // Collect all FDC IDs
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })

  // Check for duplicates by comparing length of list vs length of unique set
  let unique_ids = fdc_ids |> list.unique()
  let total_count = list.length(fdc_ids)
  let unique_count = list.length(unique_ids)

  // Assert no duplicates: unique count should equal total count
  unique_count
  |> should.equal(total_count)
}

/// Test that search_foods_filtered also has no duplicates
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

/// Test that search_foods_filtered_with_offset has no duplicates
pub fn search_foods_filtered_with_offset_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let query = "beef"
  let limit = 15
  let offset = 0
  let filters =
    types.SearchFilters(
      branded_only: False,
      category: None,
      verified_only: False,
    )

  let assert Ok(results) =
    foods.search_foods_filtered_with_offset(conn, query, filters, limit, offset)

  // Check for duplicates
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })
  let unique_ids = fdc_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(fdc_ids))
}

/// Test that search_custom_foods has no duplicates
pub fn search_custom_foods_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  // Create a test user ID
  let user_id = id.user_id("test-user-1")

  let query = "test"
  let limit = 20

  // Note: This test assumes custom foods exist for the test user
  // In a real test environment, you'd set up test data first
  let assert Ok(results) =
    foods.search_custom_foods(conn, user_id, query, limit)

  // Check for duplicates
  let food_ids = results |> list.map(fn(food) { food.id })
  let unique_ids = food_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(food_ids))
}
