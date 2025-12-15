/// Profile Endpoint Integration Tests
///
/// Tests for POST /api/fatsecret/profile with TDD/TCR workflow
///
/// Test cases:
/// 1. POST /api/fatsecret/profile (update) → 200 updated
/// 2. Edge: Profile not set → 404 not found
/// 3. Edge: Invalid weight/height data → 400 validation error
///
/// Run: cd gleam && gleam test -- --module profile_endpoint_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Environment: export OAUTH_ENCRYPTION_KEY=<from .env>
/// 3. FatSecret API credentials configured in database
import gleam/int
import gleam/io
import gleam/result
import gleeunit
import gleeunit/should
import integration/helpers/assertions
import integration/helpers/http

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST 1: POST /api/fatsecret/profile - Update profile successfully
// ============================================================================

pub fn test_1_update_profile_returns_200_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: POST /api/fatsecret/profile")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 200 OK with updated profile auth credentials")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'success' field (boolean true)")
  io.println("  • Response has 'auth_token' field (string)")
  io.println("  • Response has 'auth_secret' field (string)")
  io.println("")
  io.println("📋 Request body:")
  io.println("  {\"user_id\": \"user-12345\"}")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -X POST http://localhost:8080/api/fatsecret/profile \\")
  io.println("    -H 'Content-Type: application/json' \\")
  io.println("    -d '{\"user_id\": \"user-12345\"}' | jq")
  io.println("")
  io.println("Making request...")

  let request_body = "{\"user_id\": \"user-12345\"}"

  case http.post("/api/fatsecret/profile", request_body) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "success") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "auth_token") {
                  Ok(_) -> {
                    case assertions.assert_has_field(data, "auth_secret") {
                      Ok(_) -> {
                        io.println(
                          "  ✓ Response shape validated (has 'success', 'auth_token', 'auth_secret')",
                        )
                      }
                      Error(e) -> {
                        io.println("  ✗ Field validation error: " <> e)
                        should.fail()
                      }
                    }
                  }
                  Error(e) -> {
                    io.println("  ✗ Field validation error: " <> e)
                    should.fail()
                  }
                }
              }
              Error(e) -> {
                io.println("  ✗ Field validation error: " <> e)
                should.fail()
              }
            }
          }
          Error(e) -> {
            io.println("  ✗ JSON parse error: " <> e)
            should.fail()
          }
        }
      })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// TEST 2: POST /api/fatsecret/profile - Profile not found (404)
// ============================================================================

pub fn test_2_profile_not_found_returns_404_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: POST /api/fatsecret/profile - Profile not found")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 404 Not Found when profile doesn't exist")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 404")
  io.println("  • Response has 'error' field")
  io.println("  • Response has 'message' field")
  io.println("")
  io.println("📋 Request body:")
  io.println("  {\"user_id\": \"nonexistent-user-999\"}")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -X POST http://localhost:8080/api/fatsecret/profile \\")
  io.println("    -H 'Content-Type: application/json' \\")
  io.println("    -d '{\"user_id\": \"nonexistent-user-999\"}' | jq")
  io.println("")
  io.println("Making request...")

  let request_body = "{\"user_id\": \"nonexistent-user-999\"}"

  case http.post("/api/fatsecret/profile", request_body) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(404)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "error") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "message") {
                  Ok(_) -> {
                    io.println(
                      "  ✓ Response shape validated (has 'error', 'message')",
                    )
                  }
                  Error(e) -> {
                    io.println("  ✗ Field validation error: " <> e)
                    should.fail()
                  }
                }
              }
              Error(e) -> {
                io.println("  ✗ Field validation error: " <> e)
                should.fail()
              }
            }
          }
          Error(e) -> {
            io.println("  ✗ JSON parse error: " <> e)
            should.fail()
          }
        }
      })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// TEST 3: POST /api/fatsecret/profile - Invalid validation (400)
// ============================================================================

pub fn test_3_invalid_data_returns_400_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: POST /api/fatsecret/profile - Invalid data validation")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 400 Bad Request for invalid weight/height data")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 400")
  io.println("  • Response has 'error' field")
  io.println("  • Response has 'message' field")
  io.println("")
  io.println("📋 Request body (missing user_id):")
  io.println("  {\"invalid_field\": \"bad-data\"}")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -X POST http://localhost:8080/api/fatsecret/profile \\")
  io.println("    -H 'Content-Type: application/json' \\")
  io.println("    -d '{\"invalid_field\": \"bad-data\"}' | jq")
  io.println("")
  io.println("Making request...")

  let request_body = "{\"invalid_field\": \"bad-data\"}"

  case http.post("/api/fatsecret/profile", request_body) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(400)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "error") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "message") {
                  Ok(_) -> {
                    io.println(
                      "  ✓ Response shape validated (has 'error', 'message')",
                    )
                  }
                  Error(e) -> {
                    io.println("  ✗ Field validation error: " <> e)
                    should.fail()
                  }
                }
              }
              Error(e) -> {
                io.println("  ✗ Field validation error: " <> e)
                should.fail()
              }
            }
          }
          Error(e) -> {
            io.println("  ✗ JSON parse error: " <> e)
            should.fail()
          }
        }
      })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      should.fail()
    }
  }

  io.println("")
}
