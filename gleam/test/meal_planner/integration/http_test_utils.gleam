/// HTTP Integration Test Utilities
///
/// Provides utilities for testing HTTP endpoints in integration tests:
/// - Mock request building
/// - Response assertions
/// - JSON parsing helpers
/// - HTTP method utilities
///
/// This module simplifies writing integration tests for Wisp handlers
/// without needing a running web server.
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import wisp.{type Request as WispRequest, type Response as WispResponse}

// ============================================================================
// Mock Request Building
// ============================================================================

/// Build a mock HTTP GET request
pub fn mock_get(path: String) -> WispRequest {
  let assert Ok(req) = wisp.from_bit_string(http.Get, path, [], <<>>)
  req
}

/// Build a mock HTTP POST request with JSON body
pub fn mock_post(path: String, json_body: json.Json) -> WispRequest {
  let body_string = json.to_string(json_body)
  let body_bits = <<body_string:utf8>>

  let assert Ok(req) = wisp.from_bit_string(http.Post, path, [], body_bits)

  req
  |> wisp.set_header("content-type", "application/json")
}

/// Build a mock HTTP POST request with form data
pub fn mock_post_form(
  path: String,
  form_data: List(#(String, String)),
) -> WispRequest {
  let body =
    form_data
    |> list.map(fn(pair) {
      let #(key, value) = pair
      uri.percent_encode(key) <> "=" <> uri.percent_encode(value)
    })
    |> string.join("&")

  let body_bits = <<body:utf8>>

  let assert Ok(req) = wisp.from_bit_string(http.Post, path, [], body_bits)

  req
  |> wisp.set_header("content-type", "application/x-www-form-urlencoded")
}

/// Build a mock HTTP PUT request with JSON body
pub fn mock_put(path: String, json_body: json.Json) -> WispRequest {
  let body_string = json.to_string(json_body)
  let body_bits = <<body_string:utf8>>

  let assert Ok(req) = wisp.from_bit_string(http.Put, path, [], body_bits)

  req
  |> wisp.set_header("content-type", "application/json")
}

/// Build a mock HTTP DELETE request
pub fn mock_delete(path: String) -> WispRequest {
  let assert Ok(req) = wisp.from_bit_string(http.Delete, path, [], <<>>)
  req
}

/// Add a header to a request
pub fn with_header(
  req: WispRequest,
  name: String,
  value: String,
) -> WispRequest {
  req
  |> wisp.set_header(name, value)
}

/// Add query parameters to a request
pub fn with_query(req: WispRequest, params: List(#(String, String))) -> WispRequest {
  let query_string =
    params
    |> list.map(fn(pair) {
      let #(key, value) = pair
      uri.percent_encode(key) <> "=" <> uri.percent_encode(value)
    })
    |> string.join("&")

  // Update the request with the query string
  let path = case string.contains(req.path, "?") {
    True -> req.path <> "&" <> query_string
    False -> req.path <> "?" <> query_string
  }

  request.set_path(req, path)
}

/// Simulate an HTMX request by adding the hx-request header
pub fn as_htmx(req: WispRequest) -> WispRequest {
  req
  |> wisp.set_header("hx-request", "true")
}

// ============================================================================
// Response Assertions
// ============================================================================

/// Assert that a response has the expected status code
pub fn assert_status(response: WispResponse, expected_status: Int) -> Nil {
  case response.status == expected_status {
    True -> Nil
    False -> {
      panic as {
        "Expected status "
        <> string.inspect(expected_status)
        <> " but got "
        <> string.inspect(response.status)
      }
    }
  }
}

/// Assert that a response is a 200 OK
pub fn assert_ok(response: WispResponse) -> Nil {
  assert_status(response, 200)
}

/// Assert that a response is a 201 Created
pub fn assert_created(response: WispResponse) -> Nil {
  assert_status(response, 201)
}

/// Assert that a response is a 204 No Content
pub fn assert_no_content(response: WispResponse) -> Nil {
  assert_status(response, 204)
}

/// Assert that a response is a 400 Bad Request
pub fn assert_bad_request(response: WispResponse) -> Nil {
  assert_status(response, 400)
}

/// Assert that a response is a 404 Not Found
pub fn assert_not_found(response: WispResponse) -> Nil {
  assert_status(response, 404)
}

/// Assert that a response is a 500 Internal Server Error
pub fn assert_server_error(response: WispResponse) -> Nil {
  assert_status(response, 500)
}

/// Assert that a response has a specific header
pub fn assert_header(
  response: WispResponse,
  header_name: String,
  expected_value: String,
) -> Nil {
  case response.get_header(response, header_name) {
    Ok(value) if value == expected_value -> Nil
    Ok(value) -> {
      panic as {
        "Expected header '"
        <> header_name
        <> "' to be '"
        <> expected_value
        <> "' but got '"
        <> value
        <> "'"
      }
    }
    Error(_) -> {
      panic as { "Expected header '" <> header_name <> "' not found" }
    }
  }
}

/// Assert that a response has Content-Type: application/json
pub fn assert_json_response(response: WispResponse) -> Nil {
  case response.get_header(response, "content-type") {
    Ok(content_type) if string.starts_with(content_type, "application/json") ->
      Nil
    Ok(content_type) -> {
      panic as {
        "Expected JSON response but got Content-Type: " <> content_type
      }
    }
    Error(_) -> panic as "Response missing Content-Type header"
  }
}

/// Assert that a response has Content-Type: text/html
pub fn assert_html_response(response: WispResponse) -> Nil {
  case response.get_header(response, "content-type") {
    Ok(content_type) if string.starts_with(content_type, "text/html") -> Nil
    Ok(content_type) -> {
      panic as { "Expected HTML response but got Content-Type: " <> content_type }
    }
    Error(_) -> panic as "Response missing Content-Type header"
  }
}

// ============================================================================
// Response Body Utilities
// ============================================================================

/// Extract response body as a string
pub fn get_body_string(response: WispResponse) -> String {
  case response.body {
    wisp.Text(text) -> text
    wisp.Bytes(bytes) -> {
      case bit_array.to_string(bytes) {
        Ok(text) -> text
        Error(_) -> ""
      }
    }
    wisp.File(_) -> ""
  }
}

/// Assert that response body contains a specific substring
pub fn assert_body_contains(response: WispResponse, substring: String) -> Nil {
  let body = get_body_string(response)
  case string.contains(body, substring) {
    True -> Nil
    False -> {
      panic as {
        "Expected response body to contain '"
        <> substring
        <> "' but it didn't. Body: "
        <> body
      }
    }
  }
}

/// Assert that response body does not contain a specific substring
pub fn assert_body_not_contains(
  response: WispResponse,
  substring: String,
) -> Nil {
  let body = get_body_string(response)
  case string.contains(body, substring) {
    False -> Nil
    True -> {
      panic as {
        "Expected response body to NOT contain '"
        <> substring
        <> "' but it did. Body: "
        <> body
      }
    }
  }
}

// ============================================================================
// Test Data Builders
// ============================================================================

/// Create test recipe JSON
pub fn test_recipe_json(
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> json.Json {
  json.object([
    #("name", json.string(name)),
    #("category", json.string("test")),
    #("servings", json.int(1)),
    #("protein", json.float(protein)),
    #("fat", json.float(fat)),
    #("carbs", json.float(carbs)),
    #("fodmap_level", json.string("low")),
    #("vertical_compliant", json.bool(True)),
    #("ingredients", json.array([], fn(x) { x })),
    #("instructions", json.array([], fn(x) { x })),
  ])
}

/// Create test user profile JSON
pub fn test_profile_json(
  bodyweight: Float,
  activity_level: String,
  goal: String,
) -> json.Json {
  json.object([
    #("bodyweight", json.float(bodyweight)),
    #("activity_level", json.string(activity_level)),
    #("goal", json.string(goal)),
    #("meals_per_day", json.int(3)),
  ])
}

/// Create test food log JSON
pub fn test_food_log_json(
  recipe_id: String,
  servings: Float,
  meal_type: String,
) -> json.Json {
  json.object([
    #("recipe_id", json.string(recipe_id)),
    #("servings", json.float(servings)),
    #("meal_type", json.string(meal_type)),
  ])
}
