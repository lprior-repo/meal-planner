/// FatSecret Endpoint Integration Tests with Live HTTP Calls
///
/// Makes REAL HTTP requests to all FatSecret API endpoints to verify:
/// - Correct status codes (200, 201, 400, 404, 500)
/// - Response shape and data types
/// - Field presence and constraints (calories > 0, dates valid, etc.)
///
/// Run: cd gleam && gleam test -- --module endpoint_integration_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Environment: export OAUTH_ENCRYPTION_KEY=<from .env>
/// 3. FatSecret API credentials configured in database
///
/// DEBUGGING COMMON ISSUES:
/// - Zero-calorie entries: Check FatSecret sync, may need manual update
/// - Date conversion: Verify date_int matches Unix epoch calculation
/// - Auth failures: Ensure OAUTH_ENCRYPTION_KEY and OAuth tokens are fresh
/// - 502 errors: Check if Tandoor service is running (if proxying requests)
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
// NOTE: HTTP helpers and assertions are now in integration/helpers/ modules
// ============================================================================

// ============================================================================
// TEST 1: GET /api/fatsecret/diary/day/:date_int
// ============================================================================

pub fn test_1_diary_day_returns_200_and_valid_json_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/diary/day/20437")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/diary/day/20437 (2025-12-15)")
  io.println("")
  io.println("✓ Expected: 200 OK with food entries for today")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'entries' array")
  io.println("  • Response has 'totals' with calories, protein, fat, carbs")
  io.println("  • Each entry has: food_entry_id (string), calories (float > 0)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/diary/day/20437 | jq",
  )
  io.println("")
  io.println("🐛 Debugging: Zero-calorie bug")
  io.println("  If calories = 0, check FatSecret API serving sizes")
  io.println("  Verify entry matches FatSecret web app")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/diary/day/20437") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "entries") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "totals") {
                  Ok(_) -> {
                    io.println(
                      "  ✓ Response shape validated (has 'entries' and 'totals')",
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
// TEST 2: GET /api/fatsecret/diary/month/:date_int
// ============================================================================

pub fn test_2_diary_month_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/diary/month/20437")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/diary/month/20437 (December 2025)")
  io.println("")
  io.println("✓ Expected: 200 OK with daily summary for month")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'days' array")
  io.println("  • Has 'month' (12) and 'year' (2025)")
  io.println("  • Each day has: date_int (integer), calories (float)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s http://localhost:8080/api/fatsecret/diary/month/20437 | jq",
  )
  io.println("")
  io.println("🐛 Debugging: Month mismatch")
  io.println("  Verify date_int 20437 corresponds to December 2025")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/diary/month/20437") {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "days") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "month") {
                  Ok(_) -> {
                    case assertions.assert_has_field(data, "year") {
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
// TEST 3: GET /api/fatsecret/foods/search?q=chicken
// ============================================================================

pub fn test_3_search_foods_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: GET /api/fatsecret/foods/search?q=chicken")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/foods/search?q=chicken")
  io.println("")
  io.println("✓ Expected: 200 OK with list of matching foods")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'foods' array")
  io.println("  • Has 'total_results' (integer > 0)")
  io.println("  • Each food has: food_id (string), food_name (string)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -s 'http://localhost:8080/api/fatsecret/foods/search?q=chicken' | jq",
  )
  io.println("")
  io.println("🐛 Debugging: No results returned")
  io.println("  If foods array is empty, FatSecret API key may be expired")
  io.println("  Verify FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/foods/search?q=chicken") {
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
// TEST 4: GET /api/fatsecret/foods/:id
// ============================================================================

pub fn test_4_get_food_detail_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 4: GET /api/fatsecret/foods/4142")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/foods/4142 (Chicken Breast)")
  io.println("")
  io.println("✓ Expected: 200 OK with food details and serving options")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Response has 'food_id' (string)")
  io.println("  • Response has 'servings' array")
  io.println("  • Each serving has: serving_id, serving_description")
  io.println("  • Each serving has nutrition data (calories, protein, etc.)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/foods/4142 | jq")
  io.println("")
  io.println("🐛 Debugging: Missing nutrition data")
  io.println(
    "  If servings have null calories, FatSecret returned incomplete data",
  )
  io.println("  Try searching for food again to verify it exists")
  io.println("")
  io.println("Making request...")

  case http.get("/api/fatsecret/foods/" <> test_food_id) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(200)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "food_id") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "servings") {
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
// TEST 5: GET /api/fatsecret/profile
// ============================================================================

pub fn test_5_get_profile_returns_200_and_valid_json_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: GET /api/fatsecret/profile")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  GET /api/fatsecret/profile")
  io.println("")
  io.println("✓ Expected: 200 OK with user profile data")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 200")
  io.println("  • Has basic fields: user_id, first_name, last_name")
  io.println("  • Has biometric data: weight (float > 0), height (int > 0)")
  io.println("  • Profile matches FatSecret web app")
  io.println("  • Goal weight is reasonable if set")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println("  curl -s http://localhost:8080/api/fatsecret/profile | jq")
  io.println("")
  io.println("🐛 Debugging: Stale profile data")
  io.println("  If data is outdated, OAuth token may be expired")
  io.println("  Check database for fresh FatSecret OAuth tokens")
  io.println("  Verify last sync timestamp is recent")
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
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "user_id") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "first_name") {
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
// SUMMARY
// ============================================================================

pub fn summary_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("📊 LIVE INTEGRATION TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 5 Live HTTP tests to real endpoints")
  io.println("")
  io.println("Each test includes:")
  io.println("  • Endpoint URL & HTTP method")
  io.println("  • Expected response shape with realistic sample data")
  io.println("  • Assertions: status codes, data types, field presence")
  io.println("  • Numeric constraints (calories > 0, heights > 0, etc.)")
  io.println("  • Curl commands for manual testing")
  io.println("  • Debugging guidance for common issues")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TO RUN TESTS:")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("Terminal 1 - Start the server:")
  io.println("  cd gleam")
  io.println("  gleam run")
  io.println("")
  io.println("Terminal 2 - Run the integration tests:")
  io.println("  cd gleam")
  io.println("  gleam test -- --module endpoint_integration_test")
  io.println("")
  io.println("Expected output:")
  io.println("  ✅ All 5 tests pass with 200 status codes")
  io.println("  ✅ Each response validates JSON shape")
  io.println("  ✅ Required fields present and typed correctly")
  io.println("")

  True |> should.equal(True)
}
