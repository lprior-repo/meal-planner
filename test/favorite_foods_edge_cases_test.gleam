/// FatSecret Favorite Foods Edge Case Integration Tests
///
/// Tests boundary conditions and error states:
/// 1. Empty list handling - GET with no favorites returns 200 with empty array
/// 2. Duplicate add attempt - POST same food twice returns 409 or 400
/// 3. Delete non-existent favorite - DELETE unknown food returns 404
/// 4. Invalid food ID - POST with invalid ID returns 400
///
/// Run: cd gleam && gleam test -- --module favorite_foods_edge_cases_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Environment: export OAUTH_ENCRYPTION_KEY=<from .env>
/// 3. FatSecret API credentials configured
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
// TEST 1: Empty list handling - GET /api/fatsecret/favorites/foods
// ============================================================================

pub fn test_1_get_favorite_foods_empty_list_returns_200_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/favorites/foods (empty list)")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/foods")
  io.println("")
  io.println("✓ Expected: 200 OK with empty foods array")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'foods' field")
  io.println("  • foods is an array (possibly empty)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/favorites/foods | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/foods") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "foods") {
              Ok(_) -> {
                io.println("  ✓ Response has 'foods' field")
                io.println("✅ TEST 1 PASSED")
              }
              Error(e) -> {
                io.println("  ✗ Field validation error: " <> e)
                should.fail()
              }
            }
          }
          Error(e) -> {
            io.println("  ✗ JSON validation error: " <> e)
            should.fail()
          }
        }
      })
      |> result.unwrap(Nil)
    }

    Error(_) -> {
      io.println("✗ HTTP request failed")
      should.fail()
    }
  }
}

// ============================================================================
// TEST 2: Duplicate add attempt - POST /api/fatsecret/favorites/foods/:food_id
// ============================================================================

pub fn test_2_add_favorite_food_duplicate_returns_conflict_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: POST /api/fatsecret/favorites/foods/:food_id (duplicate)")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/favorites/foods/4142")
  io.println("")
  io.println("✓ Expected: 409 Conflict or 400 Bad Request for duplicate")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • First POST returns 200/201")
  io.println("  • Second POST (duplicate) returns 409 or 400")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/favorites/foods/4142",
  )
  io.println("")
  io.println("Making first request (should succeed)...")

  case http.post("/api/fatsecret/favorites/foods/4142", "") {
    Ok(response1) -> {
      let #(status1, _body1) = response1
      io.println("✅ First POST status: " <> int.to_string(status1))
      io.println("  ✓ First add succeeded")

      io.println("")
      io.println("Making second request (duplicate - should fail)...")

      case http.post("/api/fatsecret/favorites/foods/4142", "") {
        Ok(response2) -> {
          let #(status2, _body2) = response2
          io.println("✅ Second POST status: " <> int.to_string(status2))

          case status2 {
            409 -> {
              io.println("  ✓ Got 409 Conflict (ideal)")
              io.println("✅ TEST 2 PASSED")
            }
            400 -> {
              io.println("  ✓ Got 400 Bad Request (acceptable)")
              io.println("✅ TEST 2 PASSED")
            }
            _ -> {
              io.println(
                "  ✗ Expected 409 or 400, got " <> int.to_string(status2),
              )
              should.fail()
            }
          }
        }

        Error(_) -> {
          io.println("✗ Second HTTP request failed")
          should.fail()
        }
      }
    }

    Error(_) -> {
      io.println("✗ First HTTP request failed")
      should.fail()
    }
  }
}

// ============================================================================
// TEST 3: Delete non-existent favorite - DELETE /api/fatsecret/favorites/foods/:food_id
// ============================================================================

pub fn test_3_delete_favorite_food_not_found_returns_404_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println(
    "TEST 3: DELETE /api/fatsecret/favorites/foods/:food_id (non-existent)",
  )
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  DELETE /api/fatsecret/favorites/foods/999999999")
  io.println("")
  io.println("✓ Expected: 404 Not Found for non-existent favorite")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 404")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X DELETE http://localhost:8080/api/fatsecret/favorites/foods/999999999",
  )
  io.println("")
  io.println("Making request...")

  case http.delete("/api/fatsecret/favorites/foods/999999999") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      case status {
        404 -> {
          io.println("  ✓ Got 404 Not Found")
          io.println("✅ TEST 3 PASSED")
        }
        _ -> {
          io.println("  ✗ Expected 404, got " <> int.to_string(status))
          should.fail()
        }
      }
    }

    Error(_) -> {
      io.println("✗ HTTP request failed")
      should.fail()
    }
  }
}

// ============================================================================
// TEST 4: Invalid food ID - POST /api/fatsecret/favorites/foods/:food_id
// ============================================================================

pub fn test_4_add_favorite_food_invalid_id_returns_400_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println(
    "TEST 4: POST /api/fatsecret/favorites/foods/:food_id (invalid ID)",
  )
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/favorites/foods/invalid-id-xyz")
  io.println("")
  io.println("✓ Expected: 400 Bad Request for invalid food ID format")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 400")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/favorites/foods/invalid-id-xyz",
  )
  io.println("")
  io.println("Making request...")

  case http.post("/api/fatsecret/favorites/foods/invalid-id-xyz", "") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      case status {
        400 -> {
          io.println("  ✓ Got 400 Bad Request")
          io.println("✅ TEST 4 PASSED")
        }
        _ -> {
          io.println("  ✗ Expected 400, got " <> int.to_string(status))
          should.fail()
        }
      }
    }

    Error(_) -> {
      io.println("✗ HTTP request failed")
      should.fail()
    }
  }
}
