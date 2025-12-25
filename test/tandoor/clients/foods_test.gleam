/// Tests for Tandoor Foods API Client
///
/// Tests food operations including searching, retrieving, creating, and updating
/// food items in the Tandoor API.
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth}
import meal_planner/tandoor/client/foods
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{
  type Food, type FoodCreateRequest, type FoodSimple, type FoodUpdateRequest,
  Food, FoodCreateRequest, FoodSimple, FoodUpdateRequest, encode_food,
  encode_food_create_request, encode_food_simple, encode_food_update_request,
  food_decoder,
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Sample bearer config for testing
fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: "http://localhost:8000",
    auth: BearerAuth(token: "test-token"),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Sample food for testing
fn sample_food() -> Food {
  Food(
    id: ids.food_id_from_int(1),
    name: "Tomato",
    plural_name: Some("Tomatoes"),
    description: "Fresh red tomato",
    recipe: None,
    food_onhand: Some(True),
    supermarket_category: None,
    ignore_shopping: False,
    shopping: "produce",
    url: Some("https://example.com/tomato"),
    properties: None,
    properties_food_amount: 100.0,
    properties_food_unit: None,
    fdc_id: Some(123_456),
    parent: None,
    numchild: 0,
    inherit_fields: None,
    full_name: "Tomato",
  )
}

/// Sample food create request
fn sample_create_request() -> FoodCreateRequest {
  FoodCreateRequest(name: "Tomato")
}

/// Sample food update request
fn sample_update_request() -> FoodUpdateRequest {
  FoodUpdateRequest(
    name: Some("Cherry Tomato"),
    description: Some("Small sweet cherry tomatoes"),
    plural_name: Some(Some("Cherry Tomatoes")),
    recipe: None,
    food_onhand: Some(Some(True)),
    supermarket_category: None,
    ignore_shopping: Some(False),
    shopping: None,
    url: None,
    properties_food_amount: None,
    properties_food_unit: None,
    fdc_id: None,
    parent: None,
  )
}

// ============================================================================
// Request Encoding Tests
// ============================================================================

pub fn test_food_create_request_encodes_correctly() {
  let request = sample_create_request()
  let encoded = encode_food_create_request(request)

  case encoded {
    json.Object(fields) -> {
      fields
      |> should.have_length(1)
    }
    _ -> should.fail()
  }
}

pub fn test_food_update_request_with_name_encodes() {
  let request =
    FoodUpdateRequest(
      name: Some("Updated Name"),
      description: None,
      plural_name: None,
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: None,
      shopping: None,
      url: None,
      properties_food_amount: None,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
    )
  let encoded = encode_food_update_request(request)

  case encoded {
    json.Object(fields) -> {
      fields
      |> should.have_length(1)
    }
    _ -> should.fail()
  }
}

pub fn test_food_update_request_with_multiple_fields_encodes() {
  let request = sample_update_request()
  let encoded = encode_food_update_request(request)

  case encoded {
    json.Object(fields) -> {
      // Should have multiple fields
      fields
      |> should.have_length(4)
    }
    _ -> should.fail()
  }
}

pub fn test_food_update_request_empty_encodes_to_empty_object() {
  let request =
    FoodUpdateRequest(
      name: None,
      description: None,
      plural_name: None,
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: None,
      shopping: None,
      url: None,
      properties_food_amount: None,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
    )
  let encoded = encode_food_update_request(request)

  case encoded {
    json.Object(fields) -> {
      fields
      |> should.have_length(0)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Food Type Tests
// ============================================================================

pub fn test_food_simple_has_id_name_and_plural() {
  let food =
    FoodSimple(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
    )

  food.name
  |> should.equal("Tomato")
}

pub fn test_food_has_required_fields() {
  let food = sample_food()

  food.name
  |> should.equal("Tomato")

  food.description
  |> should.equal("Fresh red tomato")

  food.ignore_shopping
  |> should.equal(False)
}

pub fn test_food_optional_fields_can_be_none() {
  let food =
    Food(
      id: ids.food_id_from_int(1),
      name: "Test Food",
      plural_name: None,
      description: "A test food",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
      shopping: "default",
      url: None,
      properties: None,
      properties_food_amount: 0.0,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
      numchild: 0,
      inherit_fields: None,
      full_name: "Test Food",
    )

  food.plural_name
  |> should.equal(None)

  food.url
  |> should.equal(None)
}

pub fn test_food_optional_fields_can_be_some() {
  let food = sample_food()

  food.plural_name
  |> should.equal(Some("Tomatoes"))

  food.url
  |> should.equal(Some("https://example.com/tomato"))

  food.fdc_id
  |> should.equal(Some(123_456))
}

// ============================================================================
// Module Function Availability Tests
// ============================================================================

pub fn test_search_foods_function_exists() {
  // This test verifies the function exists and has the right signature
  // We can't test the actual HTTP behavior without mocking
  let _fn = foods.search_foods
  True
  |> should.be_true
}

pub fn test_get_food_function_exists() {
  let _fn = foods.get_food
  True
  |> should.be_true
}

pub fn test_create_food_function_exists() {
  let _fn = foods.create_food
  True
  |> should.be_true
}

pub fn test_update_food_function_exists() {
  let _fn = foods.update_food
  True
  |> should.be_true
}

// ============================================================================
// Request Payload Tests
// ============================================================================

pub fn test_create_request_type_structure() {
  let req = FoodCreateRequest(name: "Test")

  req.name
  |> should.equal("Test")
}

pub fn test_update_request_allows_partial_updates() {
  let req =
    FoodUpdateRequest(
      name: Some("New Name"),
      description: None,
      plural_name: None,
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: None,
      shopping: None,
      url: None,
      properties_food_amount: None,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
    )

  case req.name {
    Some(name) -> name |> should.equal("New Name")
    None -> should.fail()
  }

  req.description
  |> should.equal(None)
}

pub fn test_update_request_can_null_optional_fields() {
  let req =
    FoodUpdateRequest(
      name: None,
      description: None,
      plural_name: Some(None),
      recipe: Some(None),
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: None,
      shopping: None,
      url: None,
      properties_food_amount: None,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
    )

  // Can explicitly null out optional fields
  case req.plural_name {
    Some(None) -> True |> should.be_true
    _ -> should.fail()
  }
}

// ============================================================================
// Food Decoder Tests
// ============================================================================

pub fn test_food_decoder_handles_complete_food() {
  let json_str =
    "{\"id\": 1, \"name\": \"Tomato\", \"plural_name\": \"Tomatoes\", \"description\": \"Fresh\", \"recipe\": null, \"food_onhand\": true, \"supermarket_category\": null, \"ignore_shopping\": false, \"shopping\": \"produce\", \"url\": null, \"properties\": null, \"properties_food_amount\": 100.0, \"properties_food_unit\": null, \"fdc_id\": 123, \"parent\": null, \"numchild\": 0, \"inherit_fields\": null, \"full_name\": \"Tomato\"}"

  case json.parse(json_str, using: decode.dynamic) {
    Ok(json_val) -> {
      case decode.run(json_val, food_decoder()) {
        Ok(food) -> {
          food.name
          |> should.equal("Tomato")
        }
        Error(_) -> {
          // Decoder test - we expect it to succeed with valid JSON
          should.fail()
        }
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Food Encoder Tests
// ============================================================================

pub fn test_food_encode_includes_all_fields() {
  let food = sample_food()
  let encoded = encode_food(food)

  case encoded {
    json.Object(fields) -> {
      // Should have most major fields (some might be null in JSON)
      fields
      |> should.have_length(18)
    }
    _ -> should.fail()
  }
}

pub fn test_food_simple_encode_includes_required_fields() {
  let food_simple =
    FoodSimple(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
    )
  let encoded = encode_food_simple(food_simple)

  case encoded {
    json.Object(fields) -> {
      fields
      |> should.have_length(3)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Integration Tests - Config Tests
// ============================================================================

pub fn test_config_has_correct_base_url() {
  let config = test_config()

  config.base_url
  |> should.equal("http://localhost:8000")
}

pub fn test_config_has_bearer_auth() {
  let config = test_config()

  case config.auth {
    BearerAuth(token) -> {
      token |> should.equal("test-token")
    }
    _ -> should.fail()
  }
}

pub fn test_config_has_correct_timeout() {
  let config = test_config()

  config.timeout_ms
  |> should.equal(10_000)
}
