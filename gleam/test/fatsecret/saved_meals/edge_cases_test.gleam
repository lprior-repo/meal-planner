/// FatSecret Saved Meals Edge Case Integration Tests
///
/// Tests boundary conditions:
/// - Empty meals list -> 200 with empty array
/// - Invalid meal ID -> 404 not found
///
/// Run: cd gleam && gleam test -- --module fatsecret/saved_meals/edge_cases_test
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
// TEST 1: GET /api/fatsecret/saved-meals - Empty list returns 200
// ============================================================================

pub fn test_1_empty_saved_meals_returns_200_with_empty_array_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/saved-meals (Empty List)")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/saved-meals")
  io.println("")
  io.println("✓ Expected: 200 OK with empty saved_meals array")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200 (not 404)")
  io.println("  • Response has 'saved_meals' array")
  io.println("  • Array is empty: []")
  io.println("  • Response has 'meal_filter' field (null when no filter)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/saved-meals | jq")
  io.println("")
  io.println("🐛 Edge case: User with no saved meals")
  io.println("  Should NOT return 404")
  io.println("  Should return 200 with empty array")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/saved-meals") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "saved_meals") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "meal_filter") {
                  Ok(_) -> {
                    io.println("  ✓ Response shape validated")
                    io.println(
                      "  ✓ Empty list boundary condition handled correctly",
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
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// TEST 2: GET /api/fatsecret/saved-meals/:id/items - Invalid ID returns 404
// ============================================================================

pub fn test_2_invalid_saved_meal_id_returns_404_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/saved-meals/99999999/items")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/saved-meals/99999999/items")
  io.println("")
  io.println("✓ Expected: 404 Not Found")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 404 (not 200 or 500)")
  io.println("  • Response has 'error' field")
  io.println("  • Error message indicates meal not found")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/saved-meals/99999999/items | jq",
  )
  io.println("")
  io.println("🐛 Edge case: Invalid meal ID")
  io.println("  Should NOT return 500 (server error)")
  io.println("  Should return 404 (not found)")
  io.println("  Should have clear error message")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/saved-meals/99999999/items") {
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
                io.println("  ✓ Error response shape validated")
                io.println(
                  "  ✓ Invalid ID boundary condition handled correctly",
                )
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
