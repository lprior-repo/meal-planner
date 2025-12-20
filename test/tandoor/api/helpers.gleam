/// Test Helpers and Factories for Tandoor API Tests
///
/// Consolidates common test patterns:
/// - Config factories (bearer token, server URLs)
/// - Response mocking and builders
/// - Test data factories for Food, Unit, Property, etc.
/// - Builder functions for customizing test data
///
/// Reduces 150-200 lines of duplication across test files.
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/client.{type ClientConfig, ApiResponse}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{type Food, Food, FoodSimple}
import meal_planner/tandoor/keyword.{type Keyword, Keyword}
import meal_planner/tandoor/property.{type Property, FoodProperty, Property}
import meal_planner/tandoor/supermarket.{
  type SupermarketCategory, SupermarketCategory,
}
import meal_planner/tandoor/unit.{type Unit, Unit}

// ============================================================================
// Config Factories
// ============================================================================

/// No-server URL for testing (will fail with connection error)
pub const no_server_url = "http://localhost:8000"

/// Bearer token for testing
pub const test_token = "test-token"

/// Create a test client config with bearer authentication
pub fn test_config() -> ClientConfig {
  client.bearer_config(no_server_url, test_token)
}

/// Create a test client config with custom URL
pub fn test_config_with_url(url: String) -> ClientConfig {
  client.bearer_config(url, test_token)
}

// ============================================================================
// Response Builders
// ============================================================================

/// Create a successful JSON response (status 200)
pub fn json_response_200(body: String) {
  ApiResponse(status: 200, body: body, headers: [])
}

/// Create a successful empty response (status 204)
pub fn empty_response_204() {
  ApiResponse(status: 204, body: "", headers: [])
}

/// Create a not-found response (status 404)
pub fn not_found_response() {
  ApiResponse(status: 404, body: "{\"error\": \"Not found\"}", headers: [])
}

/// Create a server error response (status 500)
pub fn server_error_response() {
  ApiResponse(
    status: 500,
    body: "{\"error\": \"Internal server error\"}",
    headers: [],
  )
}

// ============================================================================
// Test Data Factories
// ============================================================================

/// Create a test Unit with default values
///
/// Default Unit: id=1, name="gram", full metadata
/// Use builder functions to customize:
///
/// ```gleam
/// test_unit()  // gram unit
/// test_unit_with_id(5)  // custom ID
/// test_unit_minimal()  // minimal fields
/// ```
pub fn test_unit() -> Unit {
  Unit(
    id: 1,
    name: "gram",
    plural_name: Some("grams"),
    description: Some("Metric unit of mass"),
    base_unit: Some("kilogram"),
    open_data_slug: Some("g"),
  )
}

/// Create a minimal test Unit (only required fields)
pub fn test_unit_minimal() -> Unit {
  Unit(
    id: 1,
    name: "piece",
    plural_name: None,
    description: None,
    base_unit: None,
    open_data_slug: None,
  )
}

/// Create a test Unit with custom ID
pub fn test_unit_with_id(id: Int) -> Unit {
  let base = test_unit()
  Unit(..base, id: id)
}

/// Create a test Unit with custom name
pub fn test_unit_with_name(name: String) -> Unit {
  let base = test_unit()
  Unit(..base, name: name)
}

/// Create a test SupermarketCategory with default values
pub fn test_supermarket_category() -> SupermarketCategory {
  SupermarketCategory(
    id: 1,
    name: "Produce",
    description: Some("Fresh produce section"),
    open_data_slug: None,
  )
}

/// Create a minimal test SupermarketCategory
pub fn test_supermarket_category_minimal() -> SupermarketCategory {
  SupermarketCategory(
    id: 1,
    name: "Groceries",
    description: None,
    open_data_slug: None,
  )
}

/// Create a test SupermarketCategory with custom ID and name
pub fn test_supermarket_category_with_id_name(
  id: Int,
  name: String,
) -> SupermarketCategory {
  SupermarketCategory(
    id: id,
    name: name,
    description: None,
    open_data_slug: None,
  )
}

/// Create a test Property with default values
pub fn test_property() -> Property {
  Property(
    id: ids.property_id_from_int(1),
    name: "calories",
    description: "Caloric content",
    property_type: property.FoodProperty,
    unit: Some("kcal"),
    order: 1,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
}

/// Create a test Property with custom ID and name
pub fn test_property_with_id_name(id: Int, name: String) -> Property {
  Property(
    id: ids.property_id_from_int(id),
    name: name,
    description: "",
    property_type: property.FoodProperty,
    unit: None,
    order: 1,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )
}

/// Create a test Food with full default values
///
/// Default Food: id=1, name="Tomato", full metadata including category and properties
/// Use builder functions to customize specific fields.
pub fn test_food() -> Food {
  Food(
    id: ids.food_id_from_int(1),
    name: "Tomato",
    plural_name: Some("Tomatoes"),
    description: "Fresh red tomatoes",
    recipe: None,
    food_onhand: Some(True),
    supermarket_category: Some(test_supermarket_category()),
    ignore_shopping: False,
    shopping: "Fresh tomatoes",
    url: Some("https://example.com/tomato"),
    properties: Some([test_property()]),
    properties_food_amount: 100.0,
    properties_food_unit: Some(test_unit()),
    fdc_id: None,
    parent: None,
    numchild: 0,
    inherit_fields: None,
    full_name: "Vegetables > Tomato",
  )
}

/// Create a minimal test Food (only required fields, no optional metadata)
pub fn test_food_minimal() -> Food {
  Food(
    id: ids.food_id_from_int(1),
    name: "Carrot",
    plural_name: None,
    description: "",
    recipe: None,
    food_onhand: None,
    supermarket_category: None,
    ignore_shopping: False,
    shopping: "",
    url: None,
    properties: None,
    properties_food_amount: 0.0,
    properties_food_unit: None,
    fdc_id: None,
    parent: None,
    numchild: 0,
    inherit_fields: None,
    full_name: "Carrot",
  )
}

/// Create a test Food with custom ID
pub fn test_food_with_id(id: Int) -> Food {
  let base = test_food()
  Food(..base, id: ids.food_id_from_int(id))
}

/// Create a test Food with custom ID and name
pub fn test_food_with_id_name(id: Int, name: String) -> Food {
  let base = test_food()
  Food(..base, id: ids.food_id_from_int(id), name: name, full_name: name)
}

/// Create a test Food with custom description
pub fn test_food_with_description(
  id: Int,
  name: String,
  description: String,
) -> Food {
  let base = test_food()
  Food(
    ..base,
    id: ids.food_id_from_int(id),
    name: name,
    description: description,
    full_name: name,
  )
}

/// Create a test FoodSimple
pub fn test_food_simple() -> FoodSimple {
  FoodSimple(
    id: ids.food_id_from_int(1),
    name: "Tomato",
    plural_name: Some("Tomatoes"),
  )
}

/// Create a test FoodSimple with custom ID and name
pub fn test_food_simple_with_id_name(id: Int, name: String) -> FoodSimple {
  FoodSimple(
    id: ids.food_id_from_int(id),
    name: name,
    plural_name: Some(name <> "s"),
  )
}

/// Create a test Keyword with default values
pub fn test_keyword() -> Keyword {
  Keyword(
    id: 1,
    name: "vegetarian",
    label: "Vegetarian",
    description: "",
    icon: None,
    parent: None,
    numchild: 0,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
    full_name: "Vegetarian",
  )
}

/// Create a test Keyword with custom ID and name
pub fn test_keyword_with_id_name(id: Int, name: String) -> Keyword {
  let base = test_keyword()
  Keyword(
    ..base,
    id: id,
    name: name,
    label: string.capitalise(name),
    full_name: string.capitalise(name),
  )
}
