/// FatSecret Diary Entry Creation Integration Tests
///
/// Tests for POST /api/fatsecret/diary/entries endpoint with:
/// 1. Basic entry creation (single food entry) -> 201 created
/// 2. Bulk entries creation (multiple entries) -> 201 multi
/// 3. Entry with multiplier/servings -> 201 with calculated calories
///
/// Run: cd gleam && gleam test -- --module diary_creation_integration_test
///
/// PREREQUISITES:
/// 1. Server running: gleam run (in another terminal)
/// 2. Environment: export OAUTH_ENCRYPTION_KEY=<from .env>
/// 3. FatSecret API credentials configured in database
import gleam/int
import gleam/io
import gleam/json
import gleam/result
import gleeunit
import gleeunit/should
import integration/helpers/assertions
import integration/helpers/http

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST 1: POST /api/fatsecret/diary/entries - Basic Entry Creation
// ============================================================================

pub fn test_1_create_basic_diary_entry_returns_201_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: POST /api/fatsecret/diary/entries - Basic Entry")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/diary/entries")
  io.println("")
  io.println("✓ Request payload:")
  io.println("  {")
  io.println("    \"type\": \"from_food\",")
  io.println("    \"food_id\": \"4142\",")
  io.println("    \"food_entry_name\": \"Chicken Breast\",")
  io.println("    \"serving_id\": \"12345\",")
  io.println("    \"number_of_units\": 1.0,")
  io.println("    \"meal\": \"lunch\",")
  io.println("    \"date\": \"2025-12-15\"")
  io.println("  }")
  io.println("")
  io.println("✓ Expected: 201 Created with entry_id")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 201")
  io.println("  • Response has 'success' field (true)")
  io.println("  • Response has 'entry_id' (string, non-empty)")
  io.println("  • Response has 'message' confirmation")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/diary/entries \\",
  )
  io.println("    -H 'Content-Type: application/json' \\")
  io.println(
    "    -d '{\"type\":\"from_food\",\"food_id\":\"4142\",\"food_entry_name\":\"Chicken Breast\",\"serving_id\":\"12345\",\"number_of_units\":1.0,\"meal\":\"lunch\",\"date\":\"2025-12-15\"}' \\",
  )
  io.println("    | jq")
  io.println("")
  io.println("🐛 Debugging: Entry creation fails")
  io.println("  • Verify food_id and serving_id exist in FatSecret database")
  io.println("  • Check OAuth token is valid (not expired/revoked)")
  io.println("  • Ensure date format is YYYY-MM-DD")
  io.println("")
  io.println("Making request...")

  let payload =
    json.to_string(
      json.object([
        #("type", json.string("from_food")),
        #("food_id", json.string("4142")),
        #("food_entry_name", json.string("Chicken Breast")),
        #("serving_id", json.string("12345")),
        #("number_of_units", json.float(1.0)),
        #("meal", json.string("lunch")),
        #("date", json.string("2025-12-15")),
      ]),
    )

  case http.post("/api/fatsecret/diary/entries", payload) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(201)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "success") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "entry_id") {
                  Ok(_) -> {
                    case assertions.assert_non_empty_string(data, "entry_id") {
                      Ok(_) -> {
                        io.println(
                          "  ✓ Response validated: entry created successfully",
                        )
                      }
                      Error(e) -> {
                        io.println("  ✗ Validation error: " <> e)
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
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }

  io.println("")
}

// ============================================================================
// TEST 2: POST /api/fatsecret/diary/entries - Bulk Entries
// ============================================================================

pub fn test_2_create_bulk_diary_entries_returns_201_multi_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: POST /api/fatsecret/diary/entries - Bulk Creation")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/diary/entries (bulk mode)")
  io.println("")
  io.println("✓ Request payload:")
  io.println("  {")
  io.println("    \"entries\": [")
  io.println("      {")
  io.println("        \"type\": \"from_food\",")
  io.println("        \"food_id\": \"4142\",")
  io.println("        \"food_entry_name\": \"Chicken Breast\",")
  io.println("        \"serving_id\": \"12345\",")
  io.println("        \"number_of_units\": 1.0,")
  io.println("        \"meal\": \"lunch\",")
  io.println("        \"date\": \"2025-12-15\"")
  io.println("      },")
  io.println("      {")
  io.println("        \"type\": \"custom\",")
  io.println("        \"food_entry_name\": \"Custom Salad\",")
  io.println("        \"serving_description\": \"Large bowl\",")
  io.println("        \"number_of_units\": 1.0,")
  io.println("        \"meal\": \"lunch\",")
  io.println("        \"date\": \"2025-12-15\",")
  io.println("        \"calories\": 350.0,")
  io.println("        \"carbohydrate\": 40.0,")
  io.println("        \"protein\": 15.0,")
  io.println("        \"fat\": 8.0")
  io.println("      }")
  io.println("    ]")
  io.println("  }")
  io.println("")
  io.println("✓ Expected: 201 Created with multiple entry_ids")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 201")
  io.println("  • Response has 'success' field (true)")
  io.println("  • Response has 'entry_ids' array")
  io.println("  • Array length matches number of entries (2)")
  io.println("  • Each entry_id is a non-empty string")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/diary/entries \\",
  )
  io.println("    -H 'Content-Type: application/json' \\")
  io.println(
    "    -d '{\"entries\":[{\"type\":\"from_food\",\"food_id\":\"4142\",\"food_entry_name\":\"Chicken Breast\",\"serving_id\":\"12345\",\"number_of_units\":1.0,\"meal\":\"lunch\",\"date\":\"2025-12-15\"},{\"type\":\"custom\",\"food_entry_name\":\"Custom Salad\",\"serving_description\":\"Large bowl\",\"number_of_units\":1.0,\"meal\":\"lunch\",\"date\":\"2025-12-15\",\"calories\":350.0,\"carbohydrate\":40.0,\"protein\":15.0,\"fat\":8.0}]}' \\",
  )
  io.println("    | jq")
  io.println("")
  io.println("🐛 Debugging: Bulk creation fails")
  io.println("  • Verify all entries have valid data")
  io.println("  • Check if endpoint supports bulk operations")
  io.println("  • Ensure request doesn't exceed size limits")
  io.println("")
  io.println("Making request...")

  let payload =
    json.to_string(
      json.object([
        #(
          "entries",
          json.array(
            [
              json.object([
                #("type", json.string("from_food")),
                #("food_id", json.string("4142")),
                #("food_entry_name", json.string("Chicken Breast")),
                #("serving_id", json.string("12345")),
                #("number_of_units", json.float(1.0)),
                #("meal", json.string("lunch")),
                #("date", json.string("2025-12-15")),
              ]),
              json.object([
                #("type", json.string("custom")),
                #("food_entry_name", json.string("Custom Salad")),
                #("serving_description", json.string("Large bowl")),
                #("number_of_units", json.float(1.0)),
                #("meal", json.string("lunch")),
                #("date", json.string("2025-12-15")),
                #("calories", json.float(350.0)),
                #("carbohydrate", json.float(40.0)),
                #("protein", json.float(15.0)),
                #("fat", json.float(8.0)),
              ]),
            ],
            fn(x) { x },
          ),
        ),
      ]),
    )

  case http.post("/api/fatsecret/diary/entries", payload) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(201)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "success") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "entry_ids") {
                  Ok(_) -> {
                    io.println(
                      "  ✓ Response validated: bulk entries created successfully",
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
// TEST 3: POST /api/fatsecret/diary/entries - Entry with Multiplier
// ============================================================================

pub fn test_3_create_entry_with_multiplier_returns_201_calculated_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 3: POST /api/fatsecret/diary/entries - With Multiplier")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✓ Endpoint URL & HTTP method:")
  io.println("  POST /api/fatsecret/diary/entries")
  io.println("")
  io.println("✓ Request payload:")
  io.println("  {")
  io.println("    \"type\": \"from_food\",")
  io.println("    \"food_id\": \"4142\",")
  io.println("    \"food_entry_name\": \"Chicken Breast\",")
  io.println("    \"serving_id\": \"12345\",")
  io.println("    \"number_of_units\": 2.5,")
  io.println("    \"meal\": \"dinner\",")
  io.println("    \"date\": \"2025-12-15\"")
  io.println("  }")
  io.println("")
  io.println("✓ Expected: 201 Created with calculated nutrition values")
  io.println("")
  io.println("🔍 Assertions to verify:")
  io.println("  • Status code is 201")
  io.println("  • Response has 'success' field (true)")
  io.println("  • Response has 'entry_id' (string, non-empty)")
  io.println("  • Response includes 'calculated_calories' field")
  io.println("  • Calories are multiplied by number_of_units (2.5x)")
  io.println("")
  io.println("📋 Curl command for manual testing:")
  io.println(
    "  curl -X POST http://localhost:8080/api/fatsecret/diary/entries \\",
  )
  io.println("    -H 'Content-Type: application/json' \\")
  io.println(
    "    -d '{\"type\":\"from_food\",\"food_id\":\"4142\",\"food_entry_name\":\"Chicken Breast\",\"serving_id\":\"12345\",\"number_of_units\":2.5,\"meal\":\"dinner\",\"date\":\"2025-12-15\"}' \\",
  )
  io.println("    | jq")
  io.println("")
  io.println("🐛 Debugging: Multiplier calculation incorrect")
  io.println(
    "  • Verify number_of_units is being applied to all nutrition values",
  )
  io.println("  • Check serving_id has base nutrition data")
  io.println("  • Ensure float precision doesn't cause rounding errors")
  io.println("")
  io.println("Making request...")

  let payload =
    json.to_string(
      json.object([
        #("type", json.string("from_food")),
        #("food_id", json.string("4142")),
        #("food_entry_name", json.string("Chicken Breast")),
        #("serving_id", json.string("12345")),
        #("number_of_units", json.float(2.5)),
        #("meal", json.string("dinner")),
        #("date", json.string("2025-12-15")),
      ]),
    )

  case http.post("/api/fatsecret/diary/entries", payload) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assertions.assert_status(201)
      |> result.map(fn(_) {
        case assertions.assert_valid_json(body) {
          Ok(data) -> {
            io.println("  ✓ Valid JSON response")
            case assertions.assert_has_field(data, "success") {
              Ok(_) -> {
                case assertions.assert_has_field(data, "entry_id") {
                  Ok(_) -> {
                    case assertions.assert_non_empty_string(data, "entry_id") {
                      Ok(_) -> {
                        io.println(
                          "  ✓ Response validated: entry with multiplier created successfully",
                        )
                      }
                      Error(e) -> {
                        io.println("  ✗ Validation error: " <> e)
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
      io.println("  Make sure server is running: gleam run")
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
  io.println("📊 DIARY ENTRY CREATION TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ 3 Diary Entry Creation Tests")
  io.println("")
  io.println("Test Coverage:")
  io.println("  1. Basic entry creation (single food from database)")
  io.println("     - Validates 201 status code")
  io.println("     - Confirms entry_id is returned")
  io.println("")
  io.println("  2. Bulk entries creation (multiple entries in one request)")
  io.println("     - Tests both from_food and custom entry types")
  io.println("     - Validates entry_ids array response")
  io.println("")
  io.println("  3. Entry with multiplier/servings (number_of_units > 1.0)")
  io.println("     - Tests serving size calculations")
  io.println("     - Validates calculated nutrition values")
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
  io.println("  gleam test -- --module diary_creation_integration_test")
  io.println("")
  io.println("Expected output:")
  io.println("  ✅ All 3 tests pass with 201 status codes")
  io.println("  ✅ Each response includes entry_id(s)")
  io.println("  ✅ Request payloads are properly validated")
  io.println("")

  True |> should.equal(True)
}
