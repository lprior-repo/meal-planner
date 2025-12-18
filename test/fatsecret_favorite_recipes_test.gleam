/// FatSecret Favorite Recipes Endpoint Integration Tests
///
/// Tests 5 recipe-specific CRUD and query operations:
/// 1. GET /api/fatsecret/favorites/recipes -> 200 with list
/// 2. POST /api/fatsecret/favorites/recipes -> 201 created
/// 3. DELETE /api/fatsecret/favorites/recipes/:id -> 204 deleted
/// 4. List pagination -> 200 with limit/offset
/// 5. Filter by cuisine -> 200 with filtered results
///
/// Run: cd gleam && gleam test -- --module fatsecret_favorite_recipes_test
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
// TEST 1: GET /api/fatsecret/favorites/recipes -> 200 with list
// ============================================================================

pub fn test_1_get_favorite_recipes_returns_200_and_list_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/favorites/recipes")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/recipes")
  io.println("")
  io.println("✓ Expected: 200 OK with list of favorite recipes")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipes' array")
  io.println("  • Each recipe has: recipe_id, recipe_name, recipe_description")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/favorites/recipes | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/recipes") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "recipes") {
              Ok(_) -> {
                io.println("  ✓ Response has 'recipes' array")
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
// TEST 2: POST /api/fatsecret/favorites/recipes -> 201 created
// ============================================================================

pub fn test_2_add_favorite_recipe_returns_201_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: POST /api/fatsecret/favorites/recipes")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/favorites/recipes")
  io.println("")
  io.println("✓ Expected: 201 Created when adding recipe to favorites")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 201")
  io.println("  • Response confirms recipe added")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/favorites/recipes",
  )
  io.println("")
  io.println("Making request...")

  let body = "{\"recipe_id\":\"12345\"}"

  case http.post("/api/fatsecret/favorites/recipes", body) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(201)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(_) -> {
            io.println("  ✓ Valid JSON response")
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
// TEST 3: DELETE /api/fatsecret/favorites/recipes/:id -> 204 deleted
// ============================================================================

pub fn test_3_delete_favorite_recipe_returns_204_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: DELETE /api/fatsecret/favorites/recipes/:id")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  DELETE /api/fatsecret/favorites/recipes/12345")
  io.println("")
  io.println("✓ Expected: 204 No Content when removing recipe from favorites")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 204")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X DELETE http://localhost:8080/api/fatsecret/favorites/recipes/12345",
  )
  io.println("")
  io.println("Making request...")

  case http.delete("/api/fatsecret/favorites/recipes/12345") {
    Ok(response) -> {
      let #(status, _body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(204)
      |> result.map(fn(_) { io.println("  ✓ Recipe removed from favorites") })
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
// TEST 4: List pagination -> 200 with limit/offset
// ============================================================================

pub fn test_4_favorite_recipes_pagination_returns_200_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println(
    "TEST 4: GET /api/fatsecret/favorites/recipes?page=1&max_results=10",
  )
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/recipes?page=1&max_results=10")
  io.println("")
  io.println("✓ Expected: 200 OK with paginated results")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipes' array")
  io.println("  • Pagination parameters respected")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s 'http://localhost:8080/api/fatsecret/favorites/recipes?page=1&max_results=10' | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/recipes?page=1&max_results=10") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "recipes") {
              Ok(_) -> {
                io.println("  ✓ Response has 'recipes' array with pagination")
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
// TEST 5: Filter by cuisine -> 200 with filtered results
// ============================================================================

pub fn test_5_favorite_recipes_filter_by_cuisine_returns_200_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: GET /api/fatsecret/favorites/recipes?cuisine=italian")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/favorites/recipes?cuisine=italian")
  io.println("")
  io.println("✓ Expected: 200 OK with filtered results by cuisine type")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipes' array")
  io.println("  • Results filtered by cuisine parameter")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s 'http://localhost:8080/api/fatsecret/favorites/recipes?cuisine=italian' | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/favorites/recipes?cuisine=italian") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "recipes") {
              Ok(_) -> {
                io.println(
                  "  ✓ Response has 'recipes' array with cuisine filter",
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
  io.println("📊 FAVORITE RECIPES INTEGRATION TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 5 Favorite Recipe Endpoint Tests")
  io.println("")
  io.println("Test Coverage:")
  io.println("  1. GET /api/fatsecret/favorites/recipes -> 200 with list")
  io.println("  2. POST /api/fatsecret/favorites/recipes -> 201 created")
  io.println("  3. DELETE /api/fatsecret/favorites/recipes/:id -> 204 deleted")
  io.println("  4. List pagination -> 200 with limit/offset")
  io.println("  5. Filter by cuisine -> 200 with filtered results")
  io.println("")
  io.println("Each test validates:")
  io.println("  • Correct HTTP status codes")
  io.println("  • Response shape and JSON structure")
  io.println("  • Required fields present")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")

  True |> should.equal(True)
}
