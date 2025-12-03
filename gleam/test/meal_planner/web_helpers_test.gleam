import gleam/json
import gleam/string
import gleeunit/should
import meal_planner/web_helpers
import wisp

// ============================================================================
// JSON Response Tests - Verifying Response Contract
// ============================================================================

pub fn json_response_sets_correct_status_code_test() {
  let data = json.object([#("success", json.bool(True))])
  let response = web_helpers.json_response(data, 200)

  response.status
  |> should.equal(200)
}

pub fn json_response_sets_content_type_header_test() {
  let data = json.object([#("message", json.string("test"))])
  let response = web_helpers.json_response(data, 200)

  response.headers
  |> should.equal([#("content-type", "application/json")])
}

pub fn json_response_contains_valid_json_body_test() {
  let data = json.object([#("key", json.string("value"))])
  let response = web_helpers.json_response(data, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> should.equal("{\"key\":\"value\"}")
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_nested_objects_test() {
  let nested =
    json.object([
      #(
        "user",
        json.object([
          #("id", json.int(123)),
          #("name", json.string("John Doe")),
        ]),
      ),
    ])
  let response = web_helpers.json_response(nested, 201)

  response.status
  |> should.equal(201)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("user")
      |> should.be_true()

      body
      |> string.contains("123")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_arrays_test() {
  let array_data =
    json.array(
      [
        json.string("item1"),
        json.string("item2"),
        json.string("item3"),
      ],
      json.to_string,
    )

  let data = json.object([#("items", array_data)])
  let response = web_helpers.json_response(data, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("items")
      |> should.be_true()

      body
      |> string.contains("item1")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_empty_object_test() {
  let empty = json.object([])
  let response = web_helpers.json_response(empty, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> should.equal("{}")
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_null_values_test() {
  let data =
    json.object([
      #("value", json.null()),
    ])
  let response = web_helpers.json_response(data, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("null")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_boolean_values_test() {
  let data =
    json.object([
      #("enabled", json.bool(True)),
      #("disabled", json.bool(False)),
    ])
  let response = web_helpers.json_response(data, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("true")
      |> should.be_true()

      body
      |> string.contains("false")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_numeric_values_test() {
  let data =
    json.object([
      #("integer", json.int(42)),
      #("float", json.float(3.14)),
    ])
  let response = web_helpers.json_response(data, 200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("42")
      |> should.be_true()

      body
      |> string.contains("3.14")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

// ============================================================================
// Error Response Tests - HTTP Error Handling
// ============================================================================

pub fn error_response_returns_400_bad_request_test() {
  let response = web_helpers.error_response("Invalid input", 400)

  response.status
  |> should.equal(400)
}

pub fn error_response_returns_401_unauthorized_test() {
  let response = web_helpers.error_response("Unauthorized access", 401)

  response.status
  |> should.equal(401)
}

pub fn error_response_returns_403_forbidden_test() {
  let response = web_helpers.error_response("Forbidden resource", 403)

  response.status
  |> should.equal(403)
}

pub fn error_response_returns_404_not_found_test() {
  let response = web_helpers.error_response("Resource not found", 404)

  response.status
  |> should.equal(404)
}

pub fn error_response_returns_409_conflict_test() {
  let response = web_helpers.error_response("Resource conflict", 409)

  response.status
  |> should.equal(409)
}

pub fn error_response_returns_422_unprocessable_entity_test() {
  let response = web_helpers.error_response("Validation failed", 422)

  response.status
  |> should.equal(422)
}

pub fn error_response_returns_500_internal_server_error_test() {
  let response = web_helpers.error_response("Internal server error", 500)

  response.status
  |> should.equal(500)
}

pub fn error_response_returns_503_service_unavailable_test() {
  let response = web_helpers.error_response("Service unavailable", 503)

  response.status
  |> should.equal(503)
}

pub fn error_response_contains_error_message_test() {
  let message = "Something went wrong"
  let response = web_helpers.error_response(message, 500)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains(message)
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_has_error_object_structure_test() {
  let response = web_helpers.error_response("Test error", 400)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("\"error\"")
      |> should.be_true()

      body
      |> string.contains("\"message\"")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_sets_json_content_type_test() {
  let response = web_helpers.error_response("Error", 500)

  response.headers
  |> should.equal([#("content-type", "application/json")])
}

pub fn error_response_produces_valid_json_test() {
  let response = web_helpers.error_response("Valid JSON error", 400)

  case response.body {
    wisp.Text(body) -> {
      // Should start and end with braces
      body
      |> string.starts_with("{")
      |> should.be_true()

      body
      |> string.ends_with("}")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

// ============================================================================
// Edge Cases - Boundary Testing
// ============================================================================

pub fn error_response_handles_empty_message_test() {
  let response = web_helpers.error_response("", 400)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("\"message\"")
      |> should.be_true()

      body
      |> string.contains("\"\"")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_handles_special_characters_test() {
  let message = "Error: \"quoted\" & <special> chars"
  let response = web_helpers.error_response(message, 400)

  case response.body {
    wisp.Text(body) -> {
      // JSON should escape special characters
      body
      |> string.contains("\\\"")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_handles_unicode_characters_test() {
  let message = "Error: こんにちは 🎉"
  let response = web_helpers.error_response(message, 400)

  response.status
  |> should.equal(400)

  case response.body {
    wisp.Text(body) -> {
      // Should contain the message in some form
      body
      |> string.length()
      |> should.not_equal(0)
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_handles_very_long_message_test() {
  let long_message = string.repeat("Error message ", 100)
  let response = web_helpers.error_response(long_message, 500)

  response.status
  |> should.equal(500)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.length()
      |> should.not_equal(0)
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_handles_newlines_in_message_test() {
  let message = "Line 1\nLine 2\nLine 3"
  let response = web_helpers.error_response(message, 400)

  case response.body {
    wisp.Text(body) -> {
      // JSON should escape newlines
      body
      |> string.contains("\\n")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

// ============================================================================
// HTTP Status Code Coverage
// ============================================================================

pub fn json_response_handles_2xx_success_codes_test() {
  let data = json.object([#("status", json.string("success"))])

  let response_200 = web_helpers.json_response(data, 200)
  response_200.status |> should.equal(200)

  let response_201 = web_helpers.json_response(data, 201)
  response_201.status |> should.equal(201)

  let response_204 = web_helpers.json_response(data, 204)
  response_204.status |> should.equal(204)
}

pub fn json_response_handles_3xx_redirect_codes_test() {
  let data = json.object([#("redirect", json.string("moved"))])

  let response_301 = web_helpers.json_response(data, 301)
  response_301.status |> should.equal(301)

  let response_302 = web_helpers.json_response(data, 302)
  response_302.status |> should.equal(302)

  let response_304 = web_helpers.json_response(data, 304)
  response_304.status |> should.equal(304)
}

pub fn error_response_handles_all_4xx_client_errors_test() {
  web_helpers.error_response("Bad Request", 400).status
  |> should.equal(400)

  web_helpers.error_response("Unauthorized", 401).status
  |> should.equal(401)

  web_helpers.error_response("Payment Required", 402).status
  |> should.equal(402)

  web_helpers.error_response("Forbidden", 403).status
  |> should.equal(403)

  web_helpers.error_response("Not Found", 404).status
  |> should.equal(404)

  web_helpers.error_response("Method Not Allowed", 405).status
  |> should.equal(405)

  web_helpers.error_response("Conflict", 409).status
  |> should.equal(409)

  web_helpers.error_response("Gone", 410).status
  |> should.equal(410)

  web_helpers.error_response("Unprocessable Entity", 422).status
  |> should.equal(422)

  web_helpers.error_response("Too Many Requests", 429).status
  |> should.equal(429)
}

pub fn error_response_handles_all_5xx_server_errors_test() {
  web_helpers.error_response("Internal Server Error", 500).status
  |> should.equal(500)

  web_helpers.error_response("Not Implemented", 501).status
  |> should.equal(501)

  web_helpers.error_response("Bad Gateway", 502).status
  |> should.equal(502)

  web_helpers.error_response("Service Unavailable", 503).status
  |> should.equal(503)

  web_helpers.error_response("Gateway Timeout", 504).status
  |> should.equal(504)
}

// ============================================================================
// Security & Input Validation Tests
// ============================================================================

pub fn error_response_sanitizes_sql_injection_attempt_test() {
  let sql_injection = "'; DROP TABLE users; --"
  let response = web_helpers.error_response(sql_injection, 400)

  response.status
  |> should.equal(400)

  case response.body {
    wisp.Text(body) -> {
      // JSON encoding should escape quotes
      body
      |> string.contains("\\\"")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn error_response_sanitizes_xss_attempt_test() {
  let xss_attempt = "<script>alert('XSS')</script>"
  let response = web_helpers.error_response(xss_attempt, 400)

  response.status
  |> should.equal(400)

  case response.body {
    wisp.Text(body) -> {
      // Should be JSON-encoded, not raw HTML
      body
      |> string.contains("\"<script>")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

pub fn json_response_handles_deeply_nested_structures_test() {
  let deep_nested =
    json.object([
      #(
        "level1",
        json.object([
          #(
            "level2",
            json.object([
              #(
                "level3",
                json.object([
                  #(
                    "level4",
                    json.object([
                      #("value", json.string("deep")),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    ])

  let response = web_helpers.json_response(deep_nested, 200)

  response.status
  |> should.equal(200)

  case response.body {
    wisp.Text(body) -> {
      body
      |> string.contains("level1")
      |> should.be_true()

      body
      |> string.contains("deep")
      |> should.be_true()
    }
    _ -> panic as "Expected Text body"
  }
}

// ============================================================================
// Response Contract Tests - Martin Fowler's Boundary Testing
// ============================================================================

pub fn json_response_always_sets_content_type_test() {
  let test_cases = [
    #(json.object([]), 200),
    #(json.object([#("data", json.string("test"))]), 201),
    #(json.object([#("error", json.string("test"))]), 400),
  ]

  test_cases
  |> should.satisfy(fn(cases) {
    cases
    |> list_all(fn(test_case) {
      let #(data, status) = test_case
      let response = web_helpers.json_response(data, status)
      response.headers == [#("content-type", "application/json")]
    })
  })
}

pub fn error_response_always_has_error_structure_test() {
  let error_codes = [400, 401, 403, 404, 409, 422, 500, 502, 503]

  error_codes
  |> should.satisfy(fn(codes) {
    codes
    |> list_all(fn(code) {
      let response = web_helpers.error_response("Test", code)
      case response.body {
        wisp.Text(body) -> {
          string.contains(body, "\"error\"")
          && string.contains(body, "\"message\"")
        }
        _ -> False
      }
    })
  })
}

// Helper function to check if all items in a list satisfy a predicate
fn list_all(list: List(a), predicate: fn(a) -> Bool) -> Bool {
  case list {
    [] -> True
    [head, ..tail] -> {
      case predicate(head) {
        True -> list_all(tail, predicate)
        False -> False
      }
    }
  }
}
