/// Test Fixtures for Tandoor Types
///
/// This module provides pre-configured test fixtures as JSON strings
/// for use in unit and integration tests.
import gleam/int
import gleam/json
import gleam/string

// ============================================================================
// Recipe Fixtures
// ============================================================================

/// Default recipe fixture JSON
pub fn recipe_json() -> String {
  "{
    \"id\": 1,
    \"name\": \"Test Recipe\",
    \"description\": \"A test recipe for unit tests\",
    \"servings\": 4,
    \"working_time\": 30,
    \"waiting_time\": 0,
    \"created_at\": \"2025-01-01T00:00:00Z\",
    \"updated_at\": \"2025-01-01T00:00:00Z\"
  }"
}

/// Simple recipe fixture JSON
pub fn recipe_simple_json() -> String {
  "{
    \"id\": 1,
    \"name\": \"Simple Recipe\"
  }"
}

/// Recipe with custom ID
pub fn recipe_with_id_json(id: Int) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \"Test Recipe "
  <> int.to_string(id)
  <> "\",
    \"description\": \"Test recipe\",
    \"servings\": 4
  }"
}

/// Recipe with custom name
pub fn recipe_with_name_json(id: Int, name: String) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \""
  <> name
  <> "\",
    \"description\": \"Test recipe\",
    \"servings\": 4
  }"
}

// ============================================================================
// Food Fixtures
// ============================================================================

/// Default food fixture JSON
pub fn food_json() -> String {
  "{
    \"id\": 1,
    \"name\": \"Test Food\"
  }"
}

/// Food with custom ID
pub fn food_with_id_json(id: Int) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \"Test Food "
  <> int.to_string(id)
  <> "\"
  }"
}

/// Food with custom ID and name
pub fn food_with_name_json(id: Int, name: String) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \""
  <> name
  <> "\"
  }"
}

// ============================================================================
// Ingredient Fixtures
// ============================================================================

/// Default ingredient fixture JSON
pub fn ingredient_json() -> String {
  "{
    \"id\": 1,
    \"food\": {\"id\": 1, \"name\": \"Flour\"},
    \"unit\": {\"id\": 1, \"name\": \"cup\"},
    \"amount\": 1.5,
    \"note\": \"sifted\"
  }"
}

// ============================================================================
// Keyword Fixtures
// ============================================================================

/// Default keyword fixture JSON
pub fn keyword_json() -> String {
  "{
    \"id\": 1,
    \"name\": \"vegetarian\",
    \"description\": \"Vegetarian recipe\"
  }"
}

/// Keyword with custom ID
pub fn keyword_with_id_json(id: Int, name: String) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \""
  <> name
  <> "\"
  }"
}

// ============================================================================
// Unit Fixtures
// ============================================================================

/// Default unit fixture JSON
pub fn unit_json() -> String {
  "{
    \"id\": 1,
    \"name\": \"gram\",
    \"plural_name\": \"grams\"
  }"
}

/// Unit with custom ID
pub fn unit_with_id_json(id: Int, name: String) -> String {
  "{
    \"id\": "
  <> int.to_string(id)
  <> ",
    \"name\": \""
  <> name
  <> "\",
    \"plural_name\": \""
  <> name
  <> "s\"
  }"
}

// ============================================================================
// MealPlan Fixtures
// ============================================================================

/// Default mealplan fixture JSON
pub fn mealplan_json() -> String {
  "{
    \"id\": 1,
    \"recipe\": {\"id\": 1, \"name\": \"Test Recipe\"},
    \"servings\": 4,
    \"date\": \"2025-12-15\",
    \"meal_type\": {\"id\": 1, \"name\": \"dinner\"}
  }"
}

// ============================================================================
// User Fixtures
// ============================================================================

/// Default user fixture JSON
pub fn user_json() -> String {
  "{
    \"id\": 1,
    \"username\": \"testuser\",
    \"first_name\": \"Test\",
    \"last_name\": \"User\"
  }"
}

// ============================================================================
// Paginated Response Fixtures
// ============================================================================

/// Create paginated response JSON
pub fn paginated_json(
  count: Int,
  results_json: String,
  next: String,
  previous: String,
) -> String {
  let next_value = case next {
    "" -> "null"
    url -> "\"" <> url <> "\""
  }

  let previous_value = case previous {
    "" -> "null"
    url -> "\"" <> url <> "\""
  }

  "{
    \"count\": "
  <> int.to_string(count)
  <> ",
    \"next\": "
  <> next_value
  <> ",
    \"previous\": "
  <> previous_value
  <> ",
    \"results\": "
  <> results_json
  <> "
  }"
}

/// Empty paginated response
pub fn empty_paginated_json() -> String {
  paginated_json(count: 0, results_json: "[]", next: "", previous: "")
}

/// Paginated recipes
pub fn paginated_recipes_json(count: Int, page_size: Int) -> String {
  // Generate array of recipe JSONs
  let recipes =
    "[" <> string.join(list_of_recipe_ids(page_size), ", ") <> "]"

  paginated_json(count: count, results_json: recipes, next: "", previous: "")
}

// Helper to generate list of recipe IDs
fn list_of_recipe_ids(count: Int) -> List(String) {
  case count {
    0 -> []
    n -> [recipe_with_id_json(n), ..list_of_recipe_ids(n - 1)]
  }
}

// ============================================================================
// Error Response Fixtures
// ============================================================================

/// Error response fixture
pub fn error_json(status: Int, detail: String) -> String {
  "{
    \"status\": "
  <> int.to_string(status)
  <> ",
    \"detail\": \""
  <> detail
  <> "\"
  }"
}

/// 404 Not Found error
pub fn not_found_error_json(resource: String) -> String {
  error_json(404, resource <> " not found")
}

/// 400 Bad Request error
pub fn bad_request_error_json(message: String) -> String {
  error_json(400, message)
}

/// 401 Unauthorized error
pub fn unauthorized_error_json() -> String {
  error_json(401, "Invalid credentials")
}
