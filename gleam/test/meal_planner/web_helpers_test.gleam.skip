/// Tests for web_helpers module
/// Test HTTP response helper functions
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/web_helpers

// ============================================================================
// JSON Response Tests
// ============================================================================

pub fn json_response_sets_correct_status_test() {
  // Test that json_response sets the correct status code
  let data = json.object([#("message", json.string("success"))])

  let response = web_helpers.json_response(data, 200)

  response.status
  |> should.equal(200)
}

pub fn json_response_sets_content_type_test() {
  // Test that json_response sets correct content-type header
  let data = json.object([#("data", json.string("test"))])

  let response = web_helpers.json_response(data, 200)

  // Check that content-type header is set
  let has_content_type =
    list.any(response.headers, fn(header) {
      let #(name, value) = header
      name == "content-type" && value == "application/json"
    })

  has_content_type
  |> should.be_true
}

pub fn json_response_with_different_status_codes_test() {
  // Test various status codes
  let data = json.object([])

  // 201 Created
  let response_201 = web_helpers.json_response(data, 201)
  response_201.status
  |> should.equal(201)

  // 400 Bad Request
  let response_400 = web_helpers.json_response(data, 400)
  response_400.status
  |> should.equal(400)

  // 404 Not Found
  let response_404 = web_helpers.json_response(data, 404)
  response_404.status
  |> should.equal(404)

  // 500 Internal Server Error
  let response_500 = web_helpers.json_response(data, 500)
  response_500.status
  |> should.equal(500)
}

pub fn json_response_with_complex_data_test() {
  // Test with nested JSON structure
  let data =
    json.object([
      #("user", json.object([#("name", json.string("Alice")), #(
        "age",
        json.int(30),
      )])),
      #("items", json.array([json.string("item1"), json.string("item2")], json.string)),
    ])

  let response = web_helpers.json_response(data, 200)

  response.status
  |> should.equal(200)
}

pub fn json_response_with_empty_object_test() {
  // Test with empty JSON object
  let data = json.object([])

  let response = web_helpers.json_response(data, 204)

  response.status
  |> should.equal(204)
}

// ============================================================================
// Error Response Tests
// ============================================================================

pub fn error_response_sets_correct_status_test() {
  // Test that error_response sets the correct status code
  let response = web_helpers.error_response("Not found", 404)

  response.status
  |> should.equal(404)
}

pub fn error_response_sets_content_type_test() {
  // Test that error_response sets correct content-type header
  let response = web_helpers.error_response("Bad request", 400)

  // Check that content-type header is set
  let has_content_type =
    list.any(response.headers, fn(header) {
      let #(name, value) = header
      name == "content-type" && value == "application/json"
    })

  has_content_type
  |> should.be_true
}

pub fn error_response_with_various_errors_test() {
  // Test common error scenarios
  
  // 400 Bad Request
  let response_400 = web_helpers.error_response("Invalid input", 400)
  response_400.status
  |> should.equal(400)

  // 401 Unauthorized
  let response_401 = web_helpers.error_response("Unauthorized", 401)
  response_401.status
  |> should.equal(401)

  // 403 Forbidden
  let response_403 = web_helpers.error_response("Forbidden", 403)
  response_403.status
  |> should.equal(403)

  // 404 Not Found
  let response_404 = web_helpers.error_response("Resource not found", 404)
  response_404.status
  |> should.equal(404)

  // 500 Internal Server Error
  let response_500 = web_helpers.error_response("Server error", 500)
  response_500.status
  |> should.equal(500)
}

pub fn error_response_with_empty_message_test() {
  // Test error response with empty message
  let response = web_helpers.error_response("", 400)

  response.status
  |> should.equal(400)
}

pub fn error_response_with_long_message_test() {
  // Test error response with long message
  let long_message =
    "This is a very long error message that contains detailed information about what went wrong during the processing of the request. It includes context, suggestions, and potential solutions for the user to try."

  let response = web_helpers.error_response(long_message, 422)

  response.status
  |> should.equal(422)
}

pub fn error_response_with_special_characters_test() {
  // Test error message with special characters that need JSON escaping
  let message = "Error: User's \"data\" couldn't be processed\nPlease try again"

  let response = web_helpers.error_response(message, 400)

  response.status
  |> should.equal(400)
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn json_and_error_responses_have_same_structure_test() {
  // Test that both helpers produce similar response structure
  let json_data = json.object([#("data", json.string("test"))])
  let json_resp = web_helpers.json_response(json_data, 200)

  let error_resp = web_helpers.error_response("error", 400)

  // Both should have headers
  list.is_empty(json_resp.headers)
  |> should.be_false

  list.is_empty(error_resp.headers)
  |> should.be_false

  // Both should have content-type
  let json_has_content_type =
    list.any(json_resp.headers, fn(h) {
      let #(name, _value) = h
      name == "content-type"
    })

  let error_has_content_type =
    list.any(error_resp.headers, fn(h) {
      let #(name, _value) = h
      name == "content-type"
    })

  json_has_content_type
  |> should.be_true

  error_has_content_type
  |> should.be_true
}
