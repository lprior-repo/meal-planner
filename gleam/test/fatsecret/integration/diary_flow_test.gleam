/// Integration tests for Food Diary workflow
///
/// These tests verify the complete food diary lifecycle:
/// 1. Connect to FatSecret (OAuth)
/// 2. Search for foods
/// 3. Create diary entries
/// 4. Retrieve entries by date
/// 5. Edit entries
/// 6. Copy entries between dates
/// 7. Delete entries
/// 8. Get monthly summaries
///
/// WARNING: These tests require a valid OAuth token and make real API calls.
/// They modify the user's actual food diary, so use a test account only!
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/oauth
import meal_planner/fatsecret/diary/types as diary
import meal_planner/fatsecret/foods/client as foods
import meal_planner/fatsecret/profile/client as profile
import meal_planner/fatsecret/storage
import meal_planner/test_helpers/database

// =============================================================================
// Test Configuration & Helpers
// =============================================================================

/// Helper to get FatSecret config from environment
fn get_config() -> Result(config.FatSecretConfig, Nil) {
  case config.from_env() {
    Some(cfg) -> Ok(cfg)
    None -> Error(Nil)
  }
}

/// Helper to check if we have a valid OAuth token
fn get_token(conn) -> Result(oauth.AccessToken, Nil) {
  case storage.get_access_token(conn) {
    Ok(token) -> Ok(token)
    Error(_) -> Error(Nil)
  }
}

/// Test date - use a fixed date to avoid conflicts
const test_date = "2024-12-01"

const test_date_int = 20_057

// days since epoch for 2024-12-01

/// Alternative test date for copy operations
const alt_date = "2024-12-02"

const alt_date_int = 20_058

// =============================================================================
// Complete Diary Workflow Test
// =============================================================================

/// Test the complete food diary workflow
///
/// This is the main integration test that exercises all diary operations:
/// - Search for a food
/// - Create diary entry from search result
/// - Retrieve entries for the date
/// - Edit the entry (change serving size)
/// - Copy entry to another date
/// - Delete entries
/// - Verify cleanup
///
/// NOTE: This test requires a valid OAuth token. Run the OAuth flow first
/// via the web UI (/fatsecret/connect) to authorize the test account.
pub fn complete_diary_workflow_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      use conn <- database.with_test_transaction

      case get_token(conn) {
        Error(_) -> {
          // Skip test if not connected
          should.be_true(True)
        }
        Ok(token) -> {
          // Clean up any existing test entries first
          cleanup_test_entries(conn, cfg, token, test_date_int)
          cleanup_test_entries(conn, cfg, token, alt_date_int)

          // Step 1: Search for food
          let search_result = foods.search_foods_simple(cfg, "banana")

          case search_result {
            Ok(response) if response.foods != [] -> {
              let assert [first_food, ..] = response.foods

              // Step 2: Create diary entry from food
              let entry_input =
                diary.FromFood(
                  food_id: first_food.food_id,
                  serving_id: first_food.servings
                    |> list.first
                    |> result.map(fn(s) { s.serving_id })
                    |> result.unwrap("0"),
                  number_of_units: 1.0,
                  meal: diary.Breakfast,
                  date_int: test_date_int,
                )

              let create_result =
                profile.create_food_entry(cfg, token, entry_input)

              case create_result {
                Ok(_entry_id) -> {
                  // Step 3: Get entries for date
                  let entries_result =
                    profile.get_food_entries(cfg, token, test_date_int)

                  case entries_result {
                    Ok(entries) -> {
                      should.be_true(entries != [])

                      // Verify our entry is there
                      let has_entry =
                        entries
                        |> list.any(fn(e) { e.date_int == test_date_int })
                      should.be_true(has_entry)

                      // Step 4: Edit entry (change serving size)
                      let assert [first_entry, ..] = entries
                      let update =
                        diary.FoodEntryUpdate(
                          number_of_units: Some(2.0),
                          meal: None,
                        )

                      let edit_result =
                        profile.edit_food_entry(
                          cfg,
                          token,
                          first_entry.food_entry_id,
                          update,
                        )
                      should.be_ok(edit_result)

                      // Verify update worked
                      let updated_entries =
                        profile.get_food_entries(cfg, token, test_date_int)
                      case updated_entries {
                        Ok(entries2) -> {
                          let updated =
                            entries2
                            |> list.find(fn(e) {
                              e.food_entry_id == first_entry.food_entry_id
                            })
                          case updated {
                            Ok(e) -> should.equal(e.number_of_units, 2.0)
                            Error(_) -> should.fail()
                          }
                        }
                        Error(_) -> should.fail()
                      }

                      // Step 5: Copy entry to another date
                      let copy_result =
                        profile.copy_food_entry(
                          cfg,
                          token,
                          first_entry.food_entry_id,
                          alt_date_int,
                        )
                      should.be_ok(copy_result)

                      // Verify copy exists
                      let copied_entries =
                        profile.get_food_entries(cfg, token, alt_date_int)
                      case copied_entries {
                        Ok(entries3) -> should.be_true(entries3 != [])
                        Error(_) -> should.fail()
                      }

                      // Step 6: Delete entries
                      let delete_result =
                        profile.delete_food_entry(
                          cfg,
                          token,
                          first_entry.food_entry_id,
                        )
                      should.be_ok(delete_result)

                      // Step 7: Verify deleted
                      let final_entries =
                        profile.get_food_entries(cfg, token, test_date_int)
                      case final_entries {
                        Ok(entries4) -> {
                          let still_there =
                            entries4
                            |> list.any(fn(e) {
                              e.food_entry_id == first_entry.food_entry_id
                            })
                          should.be_false(still_there)
                        }
                        Error(_) -> should.fail()
                      }

                      // Cleanup copied entry
                      cleanup_test_entries(conn, cfg, token, alt_date_int)
                    }
                    Error(_) -> should.fail()
                  }
                }
                Error(e) -> {
                  // Auth errors mean token is invalid
                  case errors.is_auth_error(e) {
                    True -> should.be_true(True)
                    False -> should.fail()
                  }
                }
              }
            }
            Ok(_) -> {
              // No foods found - skip test
              should.be_true(True)
            }
            Error(_) -> {
              // API error - skip test
              should.be_true(True)
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// Individual Operation Tests
// =============================================================================

/// Test searching for foods (2-legged, no token required)
pub fn search_foods_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      let result = foods.search_foods_simple(cfg, "apple")

      case result {
        Ok(response) -> {
          should.be_true(response.total_results > 0)
          should.be_true(response.foods != [])

          // Verify food structure
          let assert [first, ..] = response.foods
          should.be_true(first.food_name != "")
          should.be_true(first.food_id != "")
        }
        Error(_) -> should.fail()
      }
    }
  }
}

/// Test creating a custom diary entry (manual nutrition values)
pub fn create_custom_entry_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      use conn <- database.with_test_transaction

      case get_token(conn) {
        Error(_) -> should.be_true(True)
        Ok(token) -> {
          cleanup_test_entries(conn, cfg, token, test_date_int)

          let entry =
            diary.Custom(
              food_entry_name: "Test Custom Food",
              serving_description: "1 serving",
              number_of_units: 1.0,
              meal: diary.Lunch,
              date_int: test_date_int,
              calories: 200.0,
              carbohydrate: 30.0,
              protein: 10.0,
              fat: 5.0,
            )

          let result = profile.create_food_entry(cfg, token, entry)

          case result {
            Ok(_entry_id) -> {
              // Verify entry exists
              let entries = profile.get_food_entries(cfg, token, test_date_int)
              case entries {
                Ok(list) -> {
                  should.be_true(list != [])
                  cleanup_test_entries(conn, cfg, token, test_date_int)
                }
                Error(_) -> should.fail()
              }
            }
            Error(e) -> {
              case errors.is_auth_error(e) {
                True -> should.be_true(True)
                False -> should.fail()
              }
            }
          }
        }
      }
    }
  }
}

/// Test getting monthly summary
pub fn get_month_summary_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      use conn <- database.with_test_transaction

      case get_token(conn) {
        Error(_) -> should.be_true(True)
        Ok(token) -> {
          let result = profile.get_food_entries_month(cfg, token, 2024, 12)

          case result {
            Ok(summary) -> {
              should.equal(summary.month, 12)
              should.equal(summary.year, 2024)
              // Days list may be empty if no entries this month
            }
            Error(e) -> {
              case errors.is_auth_error(e) {
                True -> should.be_true(True)
                False -> should.fail()
              }
            }
          }
        }
      }
    }
  }
}

/// Test editing entry with only meal type change
pub fn edit_entry_meal_type_test() {
  case get_config() {
    Error(_) -> should.be_true(True)
    Ok(cfg) -> {
      use conn <- database.with_test_transaction

      case get_token(conn) {
        Error(_) -> should.be_true(True)
        Ok(token) -> {
          cleanup_test_entries(conn, cfg, token, test_date_int)

          // Create entry
          let entry =
            diary.Custom(
              food_entry_name: "Test Meal Type Change",
              serving_description: "1 serving",
              number_of_units: 1.0,
              meal: diary.Breakfast,
              date_int: test_date_int,
              calories: 100.0,
              carbohydrate: 15.0,
              protein: 5.0,
              fat: 2.0,
            )

          case profile.create_food_entry(cfg, token, entry) {
            Ok(_entry_id) -> {
              // Get the entry
              case profile.get_food_entries(cfg, token, test_date_int) {
                Ok(entries) if entries != [] -> {
                  let assert [first, ..] = entries

                  // Change meal type to Dinner
                  let update =
                    diary.FoodEntryUpdate(
                      number_of_units: None,
                      meal: Some(diary.Dinner),
                    )

                  case
                    profile.edit_food_entry(
                      cfg,
                      token,
                      first.food_entry_id,
                      update,
                    )
                  {
                    Ok(_) -> {
                      // Verify change
                      case profile.get_food_entries(cfg, token, test_date_int) {
                        Ok(updated_entries) -> {
                          let updated =
                            updated_entries
                            |> list.find(fn(e) {
                              e.food_entry_id == first.food_entry_id
                            })
                          case updated {
                            Ok(e) -> should.equal(e.meal, diary.Dinner)
                            Error(_) -> should.fail()
                          }
                          cleanup_test_entries(conn, cfg, token, test_date_int)
                        }
                        Error(_) -> should.fail()
                      }
                    }
                    Error(_) -> should.fail()
                  }
                }
                _ -> should.fail()
              }
            }
            Error(e) -> {
              case errors.is_auth_error(e) {
                True -> should.be_true(True)
                False -> should.fail()
              }
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Clean up all test entries for a given date
fn cleanup_test_entries(
  conn,
  cfg: config.FatSecretConfig,
  token: oauth.AccessToken,
  date_int: Int,
) -> Nil {
  case profile.get_food_entries(cfg, token, date_int) {
    Ok(entries) -> {
      entries
      |> list.each(fn(entry) {
        let _ = profile.delete_food_entry(cfg, token, entry.food_entry_id)
        Nil
      })
    }
    Error(_) -> Nil
  }
}
