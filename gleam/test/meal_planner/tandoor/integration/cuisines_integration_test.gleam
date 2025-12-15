/// Integration tests for Cuisine API
///
/// This test suite validates all 5 Cuisine CRUD endpoints with comprehensive coverage:
/// - list_cuisines() - List all cuisines
/// - get_cuisine() - Get single cuisine by ID
/// - create_cuisine() - Create new cuisines
/// - update_cuisine() - Update existing cuisines
/// - delete_cuisine() - Delete cuisines
///
/// Run with:
/// ```bash
/// export TANDOOR_URL=http://localhost:8000
/// export TANDOOR_USERNAME=admin
/// export TANDOOR_PASSWORD=password
/// gleam test
/// ```
///
/// Or with bearer token:
/// ```bash
/// export TANDOOR_URL=http://localhost:8000
/// export TANDOOR_TOKEN=your_api_token
/// gleam test
/// ```
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/api/cuisine/create
import meal_planner/tandoor/api/cuisine/delete
import meal_planner/tandoor/api/cuisine/get
import meal_planner/tandoor/api/cuisine/list
import meal_planner/tandoor/api/cuisine/update
import meal_planner/tandoor/encoders/cuisine/cuisine_encoder.{
  CuisineCreateRequest, CuisineUpdateRequest,
}
import meal_planner/tandoor/integration/test_helpers
import meal_planner/tandoor/types/cuisine/cuisine

// ============================================================================
// Helper Functions
// ============================================================================

/// Create a unique test cuisine name to avoid conflicts
fn test_cuisine_name() -> String {
  let timestamp = erlang_system_time_milliseconds() |> int.to_string()
  "test-cuisine-" <> timestamp
}

/// Get current system time in milliseconds
@external(erlang, "erlang", "system_time")
fn erlang_system_time_milliseconds() -> Int

// ============================================================================
// LIST CUISINES TESTS
// ============================================================================

/// Test: List all cuisines (default)
pub fn list_cuisines_default_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: list_cuisines() - default")
      let result = list.list_cuisines(config)
      case result {
        Ok(cuisines) -> {
          io.println(
            "✅ Success: Retrieved "
            <> int.to_string(list.length(cuisines))
            <> " cuisines",
          )
          should.be_true(list.length(cuisines) >= 0)
        }
        Error(err) -> {
          io.println("❌ Failed: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: List cuisines by parent ID
pub fn list_cuisines_by_parent_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: list_cuisines_by_parent() - filter by parent")

      let parent_name = test_cuisine_name()
      let create_parent =
        CuisineCreateRequest(
          name: parent_name,
          description: Some("Test parent cuisine"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_parent) {
        Ok(parent_cuisine) -> {
          io.println("  📝 Created parent cuisine: " <> parent_cuisine.name)

          let child_name = test_cuisine_name() <> "-child"
          let create_child =
            CuisineCreateRequest(
              name: child_name,
              description: Some("Test child cuisine"),
              icon: None,
              parent: Some(parent_cuisine.id),
            )

          case create.create_cuisine(config, create_child) {
            Ok(child_cuisine) -> {
              io.println("  📝 Created child cuisine: " <> child_cuisine.name)

              let result =
                list.list_cuisines_by_parent(
                  config,
                  Some(parent_cuisine.id),
                )

              case result {
                Ok(children) -> {
                  io.println(
                    "✅ Success: Retrieved "
                    <> int.to_string(list.length(children))
                    <> " child cuisines",
                  )

                  should.be_true(list.length(children) >= 1)

                  children
                  |> list.each(fn(c) {
                    should.equal(c.parent, Some(parent_cuisine.id))
                  })

                  let found =
                    children
                    |> list.any(fn(c) { c.id == child_cuisine.id })
                  should.be_true(found)

                  let _ = delete.delete_cuisine(config, cuisine_id: child_cuisine.id)
                  let _ = delete.delete_cuisine(config, cuisine_id: parent_cuisine.id)
                  Nil
                }
                Error(err) -> {
                  io.println(
                    "❌ Failed to list children: " <> string.inspect(err),
                  )
                  let _ = delete.delete_cuisine(config, cuisine_id: child_cuisine.id)
                  let _ = delete.delete_cuisine(config, cuisine_id: parent_cuisine.id)
                  should.fail()
                }
              }
            }
            Error(err) -> {
              io.println("❌ Failed to create child: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: parent_cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create parent: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: List root cuisines explicitly
pub fn list_root_cuisines_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: list_cuisines_by_parent(None) - root cuisines")

      let result = list.list_cuisines_by_parent(config, None)

      case result {
        Ok(cuisines) -> {
          io.println(
            "✅ Success: Retrieved "
            <> int.to_string(list.length(cuisines))
            <> " root cuisines",
          )

          cuisines
          |> list.each(fn(c) { should.equal(c.parent, None) })
        }
        Error(err) -> {
          io.println("❌ Failed: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

// ============================================================================
// GET CUISINE TESTS
// ============================================================================

/// Test: Get cuisine by valid ID
pub fn get_cuisine_valid_id_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: get_cuisine() - valid ID")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Test cuisine for GET"),
          icon: Some("🍕"),
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(created_cuisine) -> {
          io.println(
            "  📝 Created cuisine ID: " <> int.to_string(created_cuisine.id),
          )

          let result = get.get_cuisine(config, cuisine_id: created_cuisine.id)

          case result {
            Ok(cuisine) -> {
              io.println("✅ Success: Retrieved cuisine: " <> cuisine.name)

              should.equal(cuisine.id, created_cuisine.id)
              should.equal(cuisine.name, name)
              should.equal(cuisine.description, Some("Test cuisine for GET"))
              should.equal(cuisine.icon, Some("🍕"))
              should.equal(cuisine.parent, None)

              let _ = delete.delete_cuisine(config, cuisine_id: created_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: created_cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Get cuisine with invalid ID (404)
pub fn get_cuisine_invalid_id_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: get_cuisine() - invalid ID (999999)")

      let result = get.get_cuisine(config, cuisine_id: 999_999)

      case result {
        Ok(_) -> {
          io.println("❌ Unexpected success - should have failed with 404")
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error (404): " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// CREATE CUISINE TESTS
// ============================================================================

/// Test: Create simple cuisine
pub fn create_cuisine_simple_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - simple cuisine")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Simple test cuisine"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("✅ Success: Created cuisine: " <> cuisine.name)

          should.equal(cuisine.name, name)
          should.equal(cuisine.description, Some("Simple test cuisine"))
          should.equal(cuisine.icon, None)
          should.equal(cuisine.parent, None)
          should.equal(cuisine.num_recipes, 0)
          should.be_true(cuisine.id > 0)
          should.be_true(string.length(cuisine.created_at) > 0)
          should.be_true(string.length(cuisine.updated_at) > 0)

          let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
          Nil
        }
        Error(err) -> {
          io.println("❌ Failed: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Create cuisine with icon
pub fn create_cuisine_with_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - with icon")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Cuisine with icon"),
          icon: Some("🍜"),
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("✅ Success: Created cuisine with icon: " <> cuisine.name)
          should.equal(cuisine.icon, Some("🍜"))
          let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
          Nil
        }
        Error(err) -> {
          io.println("❌ Failed: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Create child cuisine
pub fn create_cuisine_with_parent_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - with parent")

      let parent_name = test_cuisine_name()
      let create_parent =
        CuisineCreateRequest(
          name: parent_name,
          description: Some("Parent cuisine"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_parent) {
        Ok(parent_cuisine) -> {
          io.println("  📝 Created parent: " <> parent_cuisine.name)

          let child_name = test_cuisine_name() <> "-child"
          let create_child =
            CuisineCreateRequest(
              name: child_name,
              description: Some("Child cuisine"),
              icon: None,
              parent: Some(parent_cuisine.id),
            )

          case create.create_cuisine(config, create_child) {
            Ok(child_cuisine) -> {
              io.println("✅ Success: Created child: " <> child_cuisine.name)
              should.equal(child_cuisine.parent, Some(parent_cuisine.id))
              let _ = delete.delete_cuisine(config, cuisine_id: child_cuisine.id)
              let _ = delete.delete_cuisine(config, cuisine_id: parent_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed to create child: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: parent_cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create parent: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Create cuisine with empty name (400)
pub fn create_cuisine_empty_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - empty name (should fail with 400)")

      let create_request =
        CuisineCreateRequest(
          name: "",
          description: Some("Invalid cuisine"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("❌ Unexpected success - should have failed with 400")
          let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error (400): " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// UPDATE CUISINE TESTS
// ============================================================================

/// Test: Update cuisine name
pub fn update_cuisine_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: update_cuisine() - update name")

      let original_name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: original_name,
          description: Some("Original description"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("  📝 Created cuisine: " <> cuisine.name)

          let new_name = test_cuisine_name() <> "-updated"
          let update_request =
            CuisineUpdateRequest(
              name: Some(new_name),
              description: None,
              icon: None,
              parent: None,
            )

          case update.update_cuisine(config, cuisine_id: cuisine.id, data: update_request) {
            Ok(updated_cuisine) -> {
              io.println(
                "✅ Success: Updated name to: " <> updated_cuisine.name,
              )

              should.equal(updated_cuisine.name, new_name)
              should.equal(updated_cuisine.id, cuisine.id)
              should.equal(
                updated_cuisine.description,
                Some("Original description"),
              )

              let _ = delete.delete_cuisine(config, cuisine_id: updated_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed to update: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Update cuisine description
pub fn update_cuisine_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: update_cuisine() - update description only")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Old description"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          let update_request =
            CuisineUpdateRequest(
              name: None,
              description: Some("New description"),
              icon: None,
              parent: None,
            )

          case update.update_cuisine(config, cuisine_id: cuisine.id, data: update_request) {
            Ok(updated_cuisine) -> {
              io.println("✅ Success: Updated description")

              should.equal(updated_cuisine.description, Some("New description"))
              should.equal(updated_cuisine.name, name)

              let _ = delete.delete_cuisine(config, cuisine_id: updated_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Update cuisine add icon
pub fn update_cuisine_add_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: update_cuisine() - add icon")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("No icon initially"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          should.equal(cuisine.icon, None)

          let update_request =
            CuisineUpdateRequest(
              name: None,
              description: None,
              icon: Some(Some("🌮")),
              parent: None,
            )

          case update.update_cuisine(config, cuisine_id: cuisine.id, data: update_request) {
            Ok(updated_cuisine) -> {
              io.println("✅ Success: Added icon")
              should.equal(updated_cuisine.icon, Some("🌮"))
              let _ = delete.delete_cuisine(config, cuisine_id: updated_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Update cuisine remove icon
pub fn update_cuisine_remove_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: update_cuisine() - remove icon")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Has icon"),
          icon: Some("🍱"),
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          should.equal(cuisine.icon, Some("🍱"))

          let update_request =
            CuisineUpdateRequest(
              name: None,
              description: None,
              icon: Some(None),
              parent: None,
            )

          case update.update_cuisine(config, cuisine_id: cuisine.id, data: update_request) {
            Ok(updated_cuisine) -> {
              io.println("✅ Success: Removed icon")
              should.equal(updated_cuisine.icon, None)
              let _ = delete.delete_cuisine(config, cuisine_id: updated_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Update cuisine multiple fields
pub fn update_cuisine_multiple_fields_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: update_cuisine() - multiple fields")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("Original"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          let new_name = test_cuisine_name() <> "-multi"
          let update_request =
            CuisineUpdateRequest(
              name: Some(new_name),
              description: Some("Updated description"),
              icon: Some(Some("🍛")),
              parent: None,
            )

          case update.update_cuisine(config, cuisine_id: cuisine.id, data: update_request) {
            Ok(updated_cuisine) -> {
              io.println("✅ Success: Updated multiple fields")

              should.equal(updated_cuisine.name, new_name)
              should.equal(
                updated_cuisine.description,
                Some("Updated description"),
              )
              should.equal(updated_cuisine.icon, Some("🍛"))

              let _ = delete.delete_cuisine(config, cuisine_id: updated_cuisine.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

// ============================================================================
// DELETE CUISINE TESTS
// ============================================================================

/// Test: Delete cuisine
pub fn delete_cuisine_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: delete_cuisine() - successful deletion")

      let name = test_cuisine_name()
      let create_request =
        CuisineCreateRequest(
          name: name,
          description: Some("To be deleted"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("  📝 Created cuisine ID: " <> int.to_string(cuisine.id))

          case delete.delete_cuisine(config, cuisine_id: cuisine.id) {
            Ok(Nil) -> {
              io.println("✅ Success: Deleted cuisine")

              case get.get_cuisine(config, cuisine_id: cuisine.id) {
                Ok(_) -> {
                  io.println("❌ Cuisine still exists after deletion")
                  should.fail()
                }
                Error(_) -> {
                  io.println("  ✓ Verified: Cuisine no longer exists")
                  should.be_true(True)
                }
              }
            }
            Error(err) -> {
              io.println("❌ Failed to delete: " <> string.inspect(err))
              should.fail()
            }
          }
        }
        Error(err) -> {
          io.println("❌ Failed to create: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: Delete non-existent cuisine (404)
pub fn delete_cuisine_not_found_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: delete_cuisine() - not found (999999)")

      case delete.delete_cuisine(config, cuisine_id: 999_999) {
        Ok(_) -> {
          io.println("❌ Unexpected success - should have failed with 404")
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error (404): " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// EDGE CASES & VALIDATION TESTS
// ============================================================================

/// Test: Create cuisine with very long name
pub fn create_cuisine_long_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - very long name")

      let long_name =
        "test-very-long-cuisine-name-that-might-exceed-database-limits-"
        <> test_cuisine_name()

      let create_request =
        CuisineCreateRequest(
          name: long_name,
          description: Some("Testing long names"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println(
            "✅ Success: Created with long name ("
            <> int.to_string(string.length(cuisine.name))
            <> " chars)",
          )

          let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
          Nil
        }
        Error(err) -> {
          io.println("⚠️  Long name rejected: " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

/// Test: Create cuisine with special characters
pub fn create_cuisine_special_chars_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()
      io.println("🧪 Testing: create_cuisine() - special characters")

      let special_name =
        "test-special-@#$-" <> int.to_string(erlang_system_time_milliseconds())

      let create_request =
        CuisineCreateRequest(
          name: special_name,
          description: Some("Testing special chars"),
          icon: None,
          parent: None,
        )

      case create.create_cuisine(config, create_request) {
        Ok(cuisine) -> {
          io.println("✅ Success: Created with special chars")

          let _ = delete.delete_cuisine(config, cuisine_id: cuisine.id)
          Nil
        }
        Error(err) -> {
          io.println("⚠️  Special chars rejected: " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}
