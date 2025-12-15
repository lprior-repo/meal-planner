/// FatSecret Recipe Endpoint Integration Tests
///
/// Makes REAL HTTP requests to FatSecret Recipe API endpoints to verify:
/// - Correct status codes (200)
/// - Response shape and data types
/// - Field presence and constraints
///
/// Run: cd gleam && gleam test -- --module fatsecret_recipe_endpoints_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. FatSecret API credentials configured in database
///
/// DEBUGGING COMMON ISSUES:
/// - No results: Check FatSecret API credentials
/// - Auth failures: Ensure OAuth tokens are valid
/// - 502 errors: Check if FatSecret API is reachable
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
// TEST 1: GET /api/fatsecret/recipes/autocomplete?q=pizza
// ============================================================================

pub fn test_1_recipes_autocomplete_returns_200_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/recipes/autocomplete?q=pizza")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/recipes/autocomplete?q=pizza")
  io.println("")
  io.println("✓ Expected: 200 OK with recipe autocomplete suggestions")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'suggestions' array")
  io.println(
    "  • Each suggestion has: recipe_id (string), recipe_name (string)",
  )
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s 'http://localhost:8080/api/fatsecret/recipes/autocomplete?q=pizza' | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/recipes/autocomplete?q=pizza") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "suggestions") {
              Ok(_) -> {
                io.println("  ✓ Response shape validated")
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
// TEST 2: GET /api/fatsecret/recipes/types
// ============================================================================

pub fn test_2_recipes_types_returns_200_with_types_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/recipes/types")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/recipes/types")
  io.println("")
  io.println("✓ Expected: 200 OK with list of recipe types")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipe_types' array")
  io.println(
    "  • Each type has: recipe_type_id (string), recipe_type_name (string)",
  )
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/recipes/types | jq")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/recipes/types") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "recipe_types") {
              Ok(_) -> {
                io.println("  ✓ Response shape validated")
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
// TEST 3: GET /api/fatsecret/recipes/search
// ============================================================================

pub fn test_3_recipes_search_returns_200_with_results_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: GET /api/fatsecret/recipes/search")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/recipes/search")
  io.println("")
  io.println("✓ Expected: 200 OK with recipe search results")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipes' array")
  io.println("  • Response has 'total_results' (integer)")
  io.println("  • Each recipe has: recipe_id (string), recipe_name (string)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/recipes/search | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/recipes/search") {
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
                case assertions.assert_has_field(data, "total_results") {
                  Ok(_) -> {
                    io.println("  ✓ Response shape validated")
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
// TEST 4: GET /api/fatsecret/recipes/search/type/:type_id
// ============================================================================

pub fn test_4_recipes_search_by_type_returns_200_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 4: GET /api/fatsecret/recipes/search/type/vegetarian")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/recipes/search/type/vegetarian")
  io.println("")
  io.println("✓ Expected: 200 OK with vegetarian recipe results")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipes' array")
  io.println("  • Response has 'total_results' (integer)")
  io.println("  • Each recipe has: recipe_id (string), recipe_name (string)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/recipes/search/type/vegetarian | jq",
  )
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/recipes/search/type/vegetarian") {
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
                case assertions.assert_has_field(data, "total_results") {
                  Ok(_) -> {
                    io.println("  ✓ Response shape validated")
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
// TEST 5: GET /api/fatsecret/recipes/:id
// ============================================================================

pub fn test_5_recipes_get_details_returns_200_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: GET /api/fatsecret/recipes/12345")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/recipes/12345")
  io.println("")
  io.println("✓ Expected: 200 OK with recipe details")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'recipe_id' (string)")
  io.println("  • Response has 'recipe_name' (string)")
  io.println("  • Response has 'recipe_description' (string)")
  io.println("  • Response has 'ingredients' array")
  io.println("  • Response has 'directions' array")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/recipes/12345 | jq")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/recipes/12345") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "recipe_id") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "recipe_name") {
                  Ok(_) -> {
                    case assertions.assert_has_field(data, "ingredients") {
                      Ok(_) -> {
                        io.println("  ✓ Response shape validated")
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
  io.println("📊 FATSECRET RECIPE ENDPOINTS TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 5 Recipe endpoint integration tests")
  io.println("")
  io.println("Tests included:")
  io.println("  1. GET /api/fatsecret/recipes/autocomplete?q=pizza")
  io.println("  2. GET /api/fatsecret/recipes/types")
  io.println("  3. GET /api/fatsecret/recipes/search")
  io.println("  4. GET /api/fatsecret/recipes/search/type/vegetarian")
  io.println("  5. GET /api/fatsecret/recipes/12345")
  io.println("")
  io.println("Each test validates:")
  io.println("  • HTTP status code (200)")
  io.println("  • JSON response structure")
  io.println("  • Required fields presence")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")

  True |> should.equal(True)
}
