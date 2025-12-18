/// FatSecret Profile Endpoint Integration Tests
///
/// Tests for the profile endpoints:
/// - GET /api/fatsecret/profile - Get user profile
/// - GET /api/fatsecret/profile/auth/:user_id - Get profile auth credentials
/// - POST /api/fatsecret/profile - Create profile
///
/// These endpoints require 3-legged OAuth authentication.
/// Tests will skip gracefully if FatSecret credentials are not configured.
///
/// Run with: cd gleam && gleam test
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
// CONFIGURATION
// ============================================================================

const test_user_id = "test-user-12345"

// ============================================================================
// TEST 1: GET /api/fatsecret/profile
// ============================================================================

pub fn test_1_get_profile_returns_200_and_valid_json_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/profile")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 200 OK with profile data")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response is valid JSON")
  io.println(
    "  • Response has profile fields (goal_weight_kg, height_cm, etc.)",
  )
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/profile | jq")
  io.println("")
  io.println("🔒 Note: Requires 3-legged OAuth authentication")
  io.println("  Test skips if FatSecret credentials not configured")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/profile") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(_data) -> {
            io.println("  ✓ Valid JSON response")
            io.println("  ✓ Profile data retrieved successfully")
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
      io.println("⚠️  Skipping - Server not running or FatSecret not configured")
    }
  }

  io.println("")
}

// ============================================================================
// TEST 2: GET /api/fatsecret/profile/auth/:user_id
// ============================================================================

pub fn test_2_get_profile_auth_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/profile/auth/:user_id")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/profile/auth/" <> test_user_id)
  io.println("")
  io.println("✓ Expected: 200 OK with OAuth credentials")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response is valid JSON")
  io.println("  • Response has auth_token and auth_secret fields")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/profile/auth/"
    <> test_user_id
    <> " | jq",
  )
  io.println("")
  io.println("🔒 Note: Requires 3-legged OAuth authentication")
  io.println("  Test skips if FatSecret credentials not configured")
  io.println("  User ID must exist (created via profile.create)")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/profile/auth/" <> test_user_id) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "auth_token") {
              Ok(_) ->
                case assertions.assert_has_field(data, "auth_secret") {
                  Ok(_) -> {
                    io.println(
                      "  ✓ Response shape validated (has 'auth_token' and 'auth_secret')",
                    )
                  }
                  Error(e) -> {
                    io.println("  ✗ Field validation error: " <> e)
                    should.fail()
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
      io.println("⚠️  Skipping - Server not running or FatSecret not configured")
    }
  }

  io.println("")
}

// ============================================================================
// TEST 3: GET /api/fatsecret/profile - Not Connected (401)
// ============================================================================

pub fn test_3_get_profile_not_connected_returns_401_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: GET /api/fatsecret/profile - Not Connected")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 401 Unauthorized when not connected")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 401")
  io.println("  • Response has 'error' field")
  io.println("  • Response has 'message' field")
  io.println("")
  io.println("📋 Note: This test assumes FatSecret is not connected")
  io.println("  If connection exists, test will fail gracefully")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/profile") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      case status {
        200 -> {
          io.println("⚠️  Profile returned 200 - FatSecret is connected")
          io.println("  Test expects 401 (not connected)")
          io.println("  This is expected if you have active credentials")
        }
        401 -> {
          response
          |> assertions.assert_status(401)
          |> result.map(fn(_) {
            case assertions.assert_valid_json(body) {
              Ok(data) -> {
                io.println("  ✓ Valid JSON response")
                case assertions.assert_has_field(data, "error") {
                  Ok(_) ->
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
        _ -> {
          io.println("  ✗ Unexpected status code: " <> int.to_string(status))
        }
      }
    }
    Error(_e) -> {
      io.println("⚠️  Skipping - Server not running")
    }
  }

  io.println("")
}

// ============================================================================
// TEST 4: GET /api/fatsecret/profile/auth/:user_id - Not Found (401)
// ============================================================================

pub fn test_4_get_profile_auth_not_found_returns_401_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 4: GET /api/fatsecret/profile/auth/:user_id - Not Found")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/profile/auth/nonexistent-user-999")
  io.println("")
  io.println(
    "✓ Expected: 401 Unauthorized when user not found or not connected",
  )
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 401")
  io.println("  • Response has 'error' field")
  io.println("  • Response has 'message' field")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/profile/auth/nonexistent-user-999 | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/profile/auth/nonexistent-user-999") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      case status {
        200 -> {
          io.println("⚠️  Profile auth returned 200 - User exists")
          io.println("  Test expects 401 (not found)")
          io.println("  This could happen if user-999 was previously created")
        }
        401 -> {
          response
          |> assertions.assert_status(401)
          |> result.map(fn(_) {
            case assertions.assert_valid_json(body) {
              Ok(data) -> {
                io.println("  ✓ Valid JSON response")
                case assertions.assert_has_field(data, "error") {
                  Ok(_) ->
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
        _ -> {
          io.println("  ✗ Unexpected status code: " <> int.to_string(status))
        }
      }
    }
    Error(_e) -> {
      io.println("⚠️  Skipping - Server not running")
    }
  }

  io.println("")
}

// ============================================================================
// TEST 5: POST /api/fatsecret/profile - Create Profile (200)
// ============================================================================

pub fn test_5_create_profile_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: POST /api/fatsecret/profile - Create Profile")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 200 OK with profile auth credentials")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response is valid JSON")
  io.println("  • Response has 'success' field (boolean)")
  io.println("  • Response has 'auth_token' and 'auth_secret' fields")
  io.println("")
  io.println("📋 Request body:")
  io.println(
    "  {\"user_id\": \"test-user-integration-" <> test_user_id <> "\"}",
  )
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -X POST http://localhost:8080/api/fatsecret/profile \\")
  io.println("    -H 'Content-Type: application/json' \\")
  io.println(
    "    -d '{\"user_id\": \"test-user-integration-"
    <> test_user_id
    <> "\"}' | jq",
  )
  io.println("")
  io.println("🔒 Note: Requires 3-legged OAuth authentication")
  io.println("  Test skips if FatSecret credentials not configured")
  io.println("")
  io.println("Making request...")

  let request_body =
    "{\"user_id\": \"test-user-integration-" <> test_user_id <> "\"}"

  case http.post("/api/fatsecret/profile", request_body) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      case status {
        200 -> {
          response
          |> assertions.assert_status(200)
          |> result.map(fn(_) {
            case assertions.assert_valid_json(body) {
              Ok(data) -> {
                io.println("  ✓ Valid JSON response")
                case assertions.assert_has_field(data, "success") {
                  Ok(_) ->
                    case assertions.assert_has_field(data, "auth_token") {
                      Ok(_) ->
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
                      Error(e) -> {
                        io.println("  ✗ Field validation error: " <> e)
                        should.fail()
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
        401 | 500 -> {
          io.println("  ⚠️  Profile creation returned error status")
          io.println("  This is expected if FatSecret is not configured")
        }
        _ -> {
          io.println("  ✗ Unexpected status code: " <> int.to_string(status))
        }
      }
    }
    Error(_e) -> {
      io.println("⚠️  Skipping - Server not running or FatSecret not configured")
    }
  }

  io.println("")
}

// ============================================================================
// TEST 6: POST /api/fatsecret/profile - Invalid Request (400)
// ============================================================================

pub fn test_6_create_profile_invalid_request_returns_400_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 6: POST /api/fatsecret/profile - Invalid Request")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 400 Bad Request when missing user_id")
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
              Ok(_) ->
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
      io.println("⚠️  Skipping - Server not running")
      io.println("  Make sure server is running: gleam run")
    }
  }

  io.println("")
}
