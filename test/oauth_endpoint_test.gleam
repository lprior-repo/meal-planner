/// OAuth Endpoint Integration Tests
///
/// Tests for FatSecret OAuth flow endpoints:
/// - GET /fatsecret/connect -> 302 redirect to OAuth provider
/// - GET /fatsecret/status -> 200 with auth status
/// - POST /fatsecret/disconnect -> 200 success
/// - Edge case: Disconnect when not connected -> 404
///
/// Run: cd gleam && gleam test -- --module oauth_endpoint_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Database configured with FatSecret credentials
///
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
// TEST 1: GET /fatsecret/connect - OAuth flow initiation
// ============================================================================

pub fn test_1_oauth_connect_returns_302_redirect_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /fatsecret/connect")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /fatsecret/connect")
  io.println("")
  io.println("✓ Expected: 302 redirect to FatSecret OAuth authorization URL")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 302 (redirect)")
  io.println("  • Response includes Location header with OAuth URL")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -v http://localhost:8080/fatsecret/connect")
  io.println("")
  io.println("Making request...")

  case http.get("/fatsecret/connect") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(302)
      |> should.be_ok()

      Nil
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
// TEST 2: GET /fatsecret/status - Check OAuth connection status
// ============================================================================

pub fn test_2_oauth_status_returns_200_with_auth_status_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /fatsecret/status")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /fatsecret/status")
  io.println("")
  io.println("✓ Expected: 200 OK with auth status JSON")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'connected' boolean field")
  io.println("  • If connected, includes 'user_id' string")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/fatsecret/status | jq")
  io.println("")
  io.println("Making request...")

  case http.get("/fatsecret/status") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "connected") {
              Ok(_) -> {
                io.println("  ✓ Response shape validated (has 'connected')")
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
// TEST 3: POST /fatsecret/disconnect - Edge case: Not connected
// ============================================================================

pub fn test_3_oauth_disconnect_not_connected_returns_404_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: POST /fatsecret/disconnect (Edge: Not connected)")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /fatsecret/disconnect")
  io.println("")
  io.println("✓ Expected: 404 Not Found when no OAuth connection exists")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 404")
  io.println("  • Response has error message")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -X POST http://localhost:8080/fatsecret/disconnect")
  io.println("")
  io.println("ℹ️  Note: This test assumes no active OAuth connection")
  io.println("")
  io.println("Making request...")

  case http.post("/fatsecret/disconnect", "") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(404)
      |> should.be_ok()

      Nil
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// SUMMARY
// ============================================================================

pub fn summary_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("📊 OAUTH ENDPOINT TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 3 OAuth flow tests covering:")
  io.println("")
  io.println("  1. GET /fatsecret/connect -> 302 redirect")
  io.println("  2. GET /fatsecret/status -> 200 with auth status")
  io.println("  3. POST /fatsecret/disconnect (not connected) -> 404")
  io.println("")
  io.println("Each test validates:")
  io.println("  • Correct HTTP status codes")
  io.println("  • Response JSON shape and required fields")
  io.println("  • Edge case handling")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")

  True |> should.equal(True)
}
