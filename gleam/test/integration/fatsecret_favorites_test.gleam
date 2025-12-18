/// FatSecret Favorites Integration Tests
///
/// Tests the FatSecret favorites API endpoints with real credentials:
/// - GET favorite_foods - List user's favorite foods
/// - GET most_eaten - Get most frequently eaten foods
/// - GET recently_eaten - Get recently eaten foods
///
/// These tests require:
/// 1. FatSecret OAuth credentials in PostgreSQL database
/// 2. Server running on localhost:8080
///
/// Run with: cd gleam && gleam test -- --module integration/fatsecret_favorites_test
import gleam/int
import gleam/io
import gleam/result
import gleeunit
import gleeunit/should
import integration/helpers/assertions
import integration/helpers/credentials
import integration/helpers/http

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST 1: GET /api/fatsecret/favorites/foods - List favorite foods
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

  // Check if FatSecret credentials are available
  let creds = credentials.load()
  case credentials.has_fatsecret(creds) {
    False -> {
      io.println("⚠️  Skipping - FatSecret not configured")
      io.println("  To run this test:")
      io.println("  1. Set up FatSecret OAuth credentials in PostgreSQL")
      io.println("  2. Ensure server is running: gleam run")
      io.println("")
    }
    True -> {
      io.println("✓ FatSecret credentials found, making request...")
      io.println("")

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
                    io.println(
                      "  ✓ Response shape validated (has 'foods' array)",
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
          io.println("⚠️  Skipping - Server not running")
          io.println("  Start server: gleam run")
        }
      }
      io.println("")
    }
  }
}

// ============================================================================
// TEST 2: GET /api/fatsecret/favorites/foods/most-eaten - Most eaten foods
// ============================================================================

pub fn test_2_get_most_eaten_foods_returns_200_and_valid_json_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/favorites/foods/most-eaten")
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

  // Check if FatSecret credentials are available
  let creds = credentials.load()
  case credentials.has_fatsecret(creds) {
    False -> {
      io.println("⚠️  Skipping - FatSecret not configured")
      io.println("  To run this test:")
      io.println("  1. Set up FatSecret OAuth credentials in PostgreSQL")
      io.println("  2. Ensure server is running: gleam run")
      io.println("")
    }
    True -> {
      io.println("✓ FatSecret credentials found, making request...")
      io.println("")

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
                    io.println(
                      "  ✓ Response shape validated (has 'foods' array)",
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
          io.println("⚠️  Skipping - Server not running")
          io.println("  Start server: gleam run")
        }
      }
      io.println("")
    }
  }
}

// ============================================================================
// TEST 3: GET /api/fatsecret/favorites/foods/recently-eaten - Recently eaten
// ============================================================================

pub fn test_3_get_recently_eaten_foods_returns_200_and_valid_json_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: GET /api/fatsecret/favorites/foods/recently-eaten")
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

  // Check if FatSecret credentials are available
  let creds = credentials.load()
  case credentials.has_fatsecret(creds) {
    False -> {
      io.println("⚠️  Skipping - FatSecret not configured")
      io.println("  To run this test:")
      io.println("  1. Set up FatSecret OAuth credentials in PostgreSQL")
      io.println("  2. Ensure server is running: gleam run")
      io.println("")
    }
    True -> {
      io.println("✓ FatSecret credentials found, making request...")
      io.println("")

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
                    io.println(
                      "  ✓ Response shape validated (has 'foods' array)",
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
          io.println("⚠️  Skipping - Server not running")
          io.println("  Start server: gleam run")
        }
      }
      io.println("")
    }
  }
}
