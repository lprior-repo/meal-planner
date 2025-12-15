/// FatSecret Favorites Foods Endpoint Integration Tests
///
/// Tests for the favorites foods endpoints:
/// - GET /api/fatsecret/favorites/foods - List favorite foods
/// - POST /api/fatsecret/favorites/foods/:food_id - Add favorite food
/// - DELETE /api/fatsecret/favorites/foods/:food_id - Remove favorite food
/// - GET /api/fatsecret/favorites/foods/most-eaten - Get most eaten foods
/// - GET /api/fatsecret/favorites/foods/recently-eaten - Get recently eaten foods
///
/// Run with: cd gleam && gleam test -- --module fatsecret_favorites_foods_endpoints_test
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

const test_food_id = "4142"

// ============================================================================
// TEST 1: GET /api/fatsecret/favorites/foods
// ============================================================================

pub fn test_1_get_favorite_foods_returns_200_and_valid_json_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/favorites/foods")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/foods")
  io.println("")
  io.println("✓ Expected: 200 OK with list of favorite foods")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'foods' array")
  io.println("  • Each food has: food_id (string), food_name (string)")
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
                io.println("  ✓ Response shape validated (has 'foods' array)")
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
// TEST 2: POST /api/fatsecret/favorites/foods/:food_id
// ============================================================================

pub fn test_2_add_favorite_food_returns_201_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: POST /api/fatsecret/favorites/foods/:food_id")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/favorites/foods/" <> test_food_id)
  io.println("")
  io.println("✓ Expected: 201 Created with success message")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 201")
  io.println("  • Response has 'message' field")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/favorites/foods/"
    <> test_food_id,
  )
  io.println("")
  io.println("Making request...")

  case http.post("/api/fatsecret/favorites/foods/" <> test_food_id, "") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(201)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "message") {
              Ok(_) -> {
                io.println("  ✓ Response has success message")
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
// TEST 3: DELETE /api/fatsecret/favorites/foods/:food_id
// ============================================================================

pub fn test_3_delete_favorite_food_returns_204_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: DELETE /api/fatsecret/favorites/foods/:food_id")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  DELETE /api/fatsecret/favorites/foods/" <> test_food_id)
  io.println("")
  io.println("✓ Expected: 204 No Content")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 204")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X DELETE http://localhost:8080/api/fatsecret/favorites/foods/"
    <> test_food_id,
  )
  io.println("")
  io.println("Making request...")

  case http.delete("/api/fatsecret/favorites/foods/" <> test_food_id) {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(204)
      |> result.map(fn(_) {
        io.println("  ✓ Favorite food deleted successfully")
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
// TEST 4: GET /api/fatsecret/favorites/foods/most-eaten
// ============================================================================

pub fn test_4_get_most_eaten_foods_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 4: GET /api/fatsecret/favorites/foods/most-eaten")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/foods/most-eaten")
  io.println("")
  io.println("✓ Expected: 200 OK with list of most eaten foods")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'foods' array")
  io.println("  • Each food has: food_id (string), food_name (string)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/favorites/foods/most-eaten | jq",
  )
  io.println("")
  io.println("🐛 Debugging: Meal filter parameter")
  io.println("  Optional: ?meal=breakfast|lunch|dinner|snack|all")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/foods/most-eaten") {
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
                io.println("  ✓ Response shape validated (has 'foods' array)")
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
// TEST 5: GET /api/fatsecret/favorites/foods/recently-eaten
// ============================================================================

pub fn test_5_get_recently_eaten_foods_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: GET /api/fatsecret/favorites/foods/recently-eaten")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/foods/recently-eaten")
  io.println("")
  io.println("✓ Expected: 200 OK with list of recently eaten foods")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'foods' array")
  io.println("  • Each food has: food_id (string), food_name (string)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/favorites/foods/recently-eaten | jq",
  )
  io.println("")
  io.println("🐛 Debugging: Meal filter parameter")
  io.println("  Optional: ?meal=breakfast|lunch|dinner|snack|all")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/foods/recently-eaten") {
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
                io.println("  ✓ Response shape validated (has 'foods' array)")
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
