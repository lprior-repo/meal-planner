/// Tests for handler consolidation patterns
///
/// Verifies that handler wrapper functions properly flatten nested case
/// expressions into pipelines, following GLEAM RULE 3 (PIPE_EVERYTHING).
import gleam/json
import gleam/option
import gleam/string

import meal_planner/tandoor/core/ids
import meal_planner/tandoor/handlers/handler_wrapper
import meal_planner/tandoor/types/cuisine/cuisine

import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Test fixtures
fn mock_cuisine() -> cuisine.Cuisine {
  cuisine.Cuisine(
    id: ids.cuisine_id_from_int(1),
    name: "Italian",
    description: option.Some("Italian cuisine"),
    icon: option.None,
    parent: option.None,
    num_recipes: 42,
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
  )
}

fn cuisine_to_json(cuisine: cuisine.Cuisine) -> json.Json {
  json.object([
    #("id", json.int(ids.cuisine_id_to_int(cuisine.id))),
    #("name", json.string(cuisine.name)),
  ])
}

// =============================================================================
// Test: Handle authenticated API call success with JSON encoding
// =============================================================================

pub fn test_handle_authenticated_success() {
  let cuisine = mock_cuisine()

  let result =
    handler_wrapper.handle_authenticated_call(
      fn() { Ok("mock_config") },
      fn(_config) { Ok(cuisine) },
      cuisine_to_json,
      200,
    )

  // Should return Ok with status 200
  case result {
    Ok(#(status, _body)) -> {
      status |> should.equal(200)
    }
    Error(_) -> {
      should.fail()
    }
  }
}

// =============================================================================
// Test: Handle authentication failure
// =============================================================================

pub fn test_handle_auth_failure() {
  let result =
    handler_wrapper.handle_authenticated_call(
      fn() { Error(Nil) },
      fn(_config) { Ok(mock_cuisine()) },
      cuisine_to_json,
      200,
    )

  // Should return Error when authentication fails
  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

// =============================================================================
// Test: Handle API call failure after authentication
// =============================================================================

pub fn test_handle_api_call_failure() {
  let result =
    handler_wrapper.handle_authenticated_call(
      fn() { Ok("mock_config") },
      fn(_config) { Error("API error") },
      cuisine_to_json,
      200,
    )

  // Should return Error when API call fails
  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

// =============================================================================
// Test: Verify JSON encoding is applied
// =============================================================================

pub fn test_json_encoding_applied() {
  let cuisine = mock_cuisine()

  let result =
    handler_wrapper.handle_authenticated_call(
      fn() { Ok("mock_config") },
      fn(_config) { Ok(cuisine) },
      cuisine_to_json,
      200,
    )

  case result {
    Ok(#(_status, body)) -> {
      // Body should contain encoded JSON with cuisine name
      body
      |> string.contains("Italian")
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// Test: Custom status code is honored
// =============================================================================

pub fn test_custom_status_code() {
  let result =
    handler_wrapper.handle_authenticated_call(
      fn() { Ok("mock_config") },
      fn(_config) { Ok(mock_cuisine()) },
      cuisine_to_json,
      201,
    )

  case result {
    Ok(#(status, _body)) -> {
      status |> should.equal(201)
    }
    Error(_) -> should.fail()
  }
}
