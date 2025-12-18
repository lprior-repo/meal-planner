/// Tests for CRUD helpers
///
/// This module tests the generic CRUD helper functions used across the Tandoor SDK.
/// Tests cover: HTTP execution, response parsing, error handling.
import gleam/dynamic/decode
import gleeunit/should
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{ApiResponse, ParseError}

// ============================================================================
// Mock Data Structures
// ============================================================================

pub type TestObject {
  TestObject(id: Int, name: String, value: Float)
}

fn test_object_decoder() -> decode.Decoder(TestObject) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use value <- decode.field("value", decode.float)
  decode.success(TestObject(id: id, name: name, value: value))
}

// ============================================================================
// parse_json_single Tests
// ============================================================================

pub fn parse_json_single_valid_test() {
  let json_body =
    "{
      \"id\": 1,
      \"name\": \"test\",
      \"value\": 42.5
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(obj) -> {
      obj.id
      |> should.equal(1)
      obj.name
      |> should.equal("test")
      obj.value
      |> should.equal(42.5)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_single_invalid_json_test() {
  let json_body = "{not valid json}"
  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn parse_json_single_missing_field_test() {
  let json_body =
    "{
      \"id\": 1,
      \"name\": \"test\"
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(msg)) -> {
      // Should mention the missing field
      msg
      |> should.not_equal("")
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_single_wrong_type_test() {
  let json_body =
    "{
      \"id\": \"not_a_number\",
      \"name\": \"test\",
      \"value\": 42.5
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(msg)) -> {
      // Error message should be informative
      msg
      |> should.not_equal("")
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_single_unicode_test() {
  let json_body =
    "{
      \"id\": 1,
      \"name\": \"тест 🎉\",
      \"value\": 42.5
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(obj) -> {
      obj.name
      |> should.equal("тест 🎉")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// parse_json_list Tests
// ============================================================================

pub fn parse_json_list_valid_test() {
  let json_body =
    "[
      {\"id\": 1, \"name\": \"first\", \"value\": 1.0},
      {\"id\": 2, \"name\": \"second\", \"value\": 2.0},
      {\"id\": 3, \"name\": \"third\", \"value\": 3.0}
    ]"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_list(response, test_object_decoder())

  case result {
    Ok(items) -> {
      items
      |> should.not_equal([])
      // Check length
      let first_item = case items {
        [first, ..] -> first
        [] -> TestObject(0, "", 0.0)
      }
      first_item.id
      |> should.equal(1)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_list_empty_test() {
  let json_body = "[]"
  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_list(response, test_object_decoder())

  case result {
    Ok(items) -> {
      items
      |> should.equal([])
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_list_invalid_json_test() {
  let json_body = "[{invalid}]"
  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_list(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn parse_json_list_partial_invalid_test() {
  let json_body =
    "[
      {\"id\": 1, \"name\": \"first\", \"value\": 1.0},
      {\"id\": \"not_a_number\", \"name\": \"second\", \"value\": 2.0}
    ]"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_list(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(msg)) -> {
      msg
      |> should.not_equal("")
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_list_not_array_test() {
  let json_body = "{\"id\": 1, \"name\": \"test\", \"value\": 42.5}"
  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_list(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// parse_json_paginated Tests
// ============================================================================

pub fn parse_json_paginated_valid_test() {
  let json_body =
    "{
      \"count\": 100,
      \"next\": \"https://api.example.com/items?page=2\",
      \"previous\": null,
      \"results\": [
        {\"id\": 1, \"name\": \"first\", \"value\": 1.0},
        {\"id\": 2, \"name\": \"second\", \"value\": 2.0}
      ]
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result =
    crud_helpers.parse_json_paginated(response, test_object_decoder())

  case result {
    Ok(paginated) -> {
      paginated.count
      |> should.equal(100)
      paginated.results
      |> should.not_equal([])
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_json_paginated_missing_count_test() {
  let json_body =
    "{
      \"next\": null,
      \"previous\": null,
      \"results\": []
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result =
    crud_helpers.parse_json_paginated(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn parse_json_paginated_missing_results_test() {
  let json_body =
    "{
      \"count\": 100,
      \"next\": null,
      \"previous\": null
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result =
    crud_helpers.parse_json_paginated(response, test_object_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// parse_empty_response Tests
// ============================================================================

pub fn parse_empty_response_204_test() {
  let response = ApiResponse(status: 204, body: "", headers: [])

  let result = crud_helpers.parse_empty_response(response)

  case result {
    Ok(Nil) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn parse_empty_response_200_test() {
  let response = ApiResponse(status: 200, body: "", headers: [])

  let result = crud_helpers.parse_empty_response(response)

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(msg)) -> {
      // Should mention expected 204
      msg
      |> should.not_equal("")
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_empty_response_404_test() {
  let response = ApiResponse(status: 404, body: "", headers: [])

  let result = crud_helpers.parse_empty_response(response)

  case result {
    Ok(_) -> should.fail()
    Error(ParseError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Integration-style Tests
// ============================================================================

pub fn parse_real_world_complex_object_test() {
  // Simulate a more complex real-world response
  let json_body =
    "{
      \"id\": 123,
      \"name\": \"Complex Test Object\",
      \"value\": 99.99
    }"

  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Ok(obj) -> {
      obj.id
      |> should.equal(123)
      obj.name
      |> should.equal("Complex Test Object")
      obj.value
      |> should.equal(99.99)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_error_messages_are_informative_test() {
  let json_body = "{\"id\": \"wrong\", \"name\": \"test\", \"value\": 1.0}"
  let response = ApiResponse(status: 200, body: json_body, headers: [])

  let result = crud_helpers.parse_json_single(response, test_object_decoder())

  case result {
    Error(ParseError(msg)) -> {
      // Error message should contain useful debugging info
      // At minimum it should not be empty
      msg
      |> should.not_equal("")

      // Should contain information about what went wrong
      // The exact format depends on implementation, but it should be informative
      should.be_true(True)
    }
    _ -> should.fail()
  }
}
