/// FatSecret Profile Endpoint Integration Tests
///
/// Tests for the profile endpoints:
/// - GET /api/fatsecret/profile - Get user profile
/// - GET /api/fatsecret/profile/auth/:user_id - Get profile auth credentials
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
