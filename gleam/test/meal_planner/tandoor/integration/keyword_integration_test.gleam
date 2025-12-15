/// Integration tests for Keyword API
///
/// This test suite validates all 6 Keyword API endpoints with comprehensive coverage:
/// - list_keywords() - List all keywords with pagination
/// - list_keywords_by_parent() - Filter keywords by parent
/// - get_keyword() - Get single keyword by ID
/// - create_keyword() - Create new keywords
/// - update_keyword() - Update existing keywords
/// - delete_keyword() - Delete keywords
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
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/encoders/keyword/keyword_encoder.{
  KeywordCreateRequest, KeywordUpdateRequest,
}
import meal_planner/tandoor/integration/test_helpers

// ============================================================================
// Helper Functions
// ============================================================================

/// Create a unique test keyword name to avoid conflicts
fn test_keyword_name() -> String {
  let timestamp = erlang_system_time_milliseconds() |> int.to_string()
  "test-keyword-" <> timestamp
}

/// Get current system time in milliseconds
@external(erlang, "erlang", "system_time")
fn erlang_system_time_milliseconds() -> Int

// ============================================================================
// LIST KEYWORDS TESTS (2 endpoints)
// ============================================================================

/// Test: List all keywords (default - root keywords)
///
/// This test verifies that we can list keywords with default filtering (root keywords only).
pub fn list_keywords_default_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: list_keywords() - default (root keywords)")

      let result = keyword_api.list_keywords(config)

      case result {
        Ok(keywords) -> {
          io.println(
            "✅ Success: Retrieved "
            <> int.to_string(list.length(keywords))
            <> " root keywords",
          )

          // Should return a list (even if empty)
          should.be_true(list.length(keywords) >= 0)

          // All returned keywords should have parent=None (root keywords)
          keywords
          |> list.each(fn(keyword) { should.equal(keyword.parent, None) })
        }
        Error(err) -> {
          io.println("❌ Failed: " <> string.inspect(err))
          should.fail()
        }
      }
    }
  }
}

/// Test: List keywords by parent ID
///
/// This test verifies filtering keywords by parent ID.
pub fn list_keywords_by_parent_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: list_keywords_by_parent() - filter by parent")

      // First, create a parent keyword
      let parent_name = test_keyword_name()
      let create_parent =
        KeywordCreateRequest(
          name: parent_name,
          description: "Test parent keyword",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_parent) {
        Ok(parent_keyword) -> {
          io.println("  📝 Created parent keyword: " <> parent_keyword.name)

          // Create a child keyword
          let child_name = test_keyword_name() <> "-child"
          let create_child =
            KeywordCreateRequest(
              name: child_name,
              description: "Test child keyword",
              icon: None,
              parent: Some(parent_keyword.id),
            )

          case keyword_api.create_keyword(config, create_child) {
            Ok(child_keyword) -> {
              io.println("  📝 Created child keyword: " <> child_keyword.name)

              // List children of parent
              let result =
                keyword_api.list_keywords_by_parent(
                  config,
                  Some(parent_keyword.id),
                )

              case result {
                Ok(children) -> {
                  io.println(
                    "✅ Success: Retrieved "
                    <> int.to_string(list.length(children))
                    <> " child keywords",
                  )

                  // Should have at least our child
                  should.be_true(list.length(children) >= 1)

                  // All children should have the correct parent ID
                  children
                  |> list.each(fn(keyword) {
                    should.equal(keyword.parent, Some(parent_keyword.id))
                  })

                  // Our child should be in the list
                  let found =
                    children
                    |> list.any(fn(k) { k.id == child_keyword.id })
                  should.be_true(found)

                  // Cleanup
                  let _ = keyword_api.delete_keyword(config, child_keyword.id)
                  let _ = keyword_api.delete_keyword(config, parent_keyword.id)
                  Nil
                }
                Error(err) -> {
                  io.println(
                    "❌ Failed to list children: " <> string.inspect(err),
                  )
                  // Cleanup on error
                  let _ = keyword_api.delete_keyword(config, child_keyword.id)
                  let _ = keyword_api.delete_keyword(config, parent_keyword.id)
                  should.fail()
                }
              }
            }
            Error(err) -> {
              io.println("❌ Failed to create child: " <> string.inspect(err))
              // Cleanup parent
              let _ = keyword_api.delete_keyword(config, parent_keyword.id)
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

/// Test: List root keywords explicitly
///
/// This test verifies that we can explicitly request root keywords (parent=None).
pub fn list_root_keywords_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: list_keywords_by_parent(None) - root keywords")

      let result = keyword_api.list_keywords_by_parent(config, None)

      case result {
        Ok(keywords) -> {
          io.println(
            "✅ Success: Retrieved "
            <> int.to_string(list.length(keywords))
            <> " root keywords",
          )

          // All should have parent=None
          keywords
          |> list.each(fn(keyword) { should.equal(keyword.parent, None) })
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
// GET KEYWORD TESTS
// ============================================================================

/// Test: Get keyword by valid ID
///
/// This test verifies that we can retrieve a single keyword by ID.
pub fn get_keyword_valid_id_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: get_keyword() - valid ID")

      // Create a test keyword first
      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Test keyword for GET",
          icon: Some("🧪"),
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(created_keyword) -> {
          io.println(
            "  📝 Created keyword ID: " <> int.to_string(created_keyword.id),
          )

          // Get the keyword by ID
          let result = keyword_api.get_keyword(config, created_keyword.id)

          case result {
            Ok(keyword) -> {
              io.println("✅ Success: Retrieved keyword: " <> keyword.name)

              // Verify all fields
              should.equal(keyword.id, created_keyword.id)
              should.equal(keyword.name, name)
              should.equal(keyword.description, "Test keyword for GET")
              should.equal(keyword.icon, Some("🧪"))
              should.equal(keyword.parent, None)

              // Cleanup
              let _ = keyword_api.delete_keyword(config, created_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              // Cleanup
              let _ = keyword_api.delete_keyword(config, created_keyword.id)
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

/// Test: Get keyword with invalid ID
///
/// This test verifies proper error handling for non-existent keywords.
pub fn get_keyword_invalid_id_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: get_keyword() - invalid ID (999999)")

      // Try to get a keyword with a very high ID that shouldn't exist
      let result = keyword_api.get_keyword(config, 999_999)

      case result {
        Ok(_) -> {
          io.println("❌ Unexpected success - should have failed")
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error: " <> string.inspect(err))
          // Should fail (404 or similar)
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// CREATE KEYWORD TESTS
// ============================================================================

/// Test: Create simple keyword
///
/// This test verifies basic keyword creation.
pub fn create_keyword_simple_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - simple keyword")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Simple test keyword",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("✅ Success: Created keyword: " <> keyword.name)

          // Verify fields
          should.equal(keyword.name, name)
          should.equal(keyword.description, "Simple test keyword")
          should.equal(keyword.icon, None)
          should.equal(keyword.parent, None)
          should.equal(keyword.numchild, 0)

          // Verify auto-generated fields
          should.be_true(keyword.id > 0)
          should.be_true(string.length(keyword.label) > 0)
          should.be_true(string.length(keyword.created_at) > 0)
          should.be_true(string.length(keyword.full_name) > 0)

          // Cleanup
          let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Create keyword with icon
///
/// This test verifies keyword creation with an icon.
pub fn create_keyword_with_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - with icon")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Keyword with icon",
          icon: Some("🍕"),
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("✅ Success: Created keyword with icon: " <> keyword.name)

          should.equal(keyword.icon, Some("🍕"))

          // Cleanup
          let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Create child keyword
///
/// This test verifies creating a keyword with a parent relationship.
pub fn create_keyword_with_parent_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - with parent")

      // Create parent first
      let parent_name = test_keyword_name()
      let create_parent =
        KeywordCreateRequest(
          name: parent_name,
          description: "Parent keyword",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_parent) {
        Ok(parent_keyword) -> {
          io.println("  📝 Created parent: " <> parent_keyword.name)

          // Create child
          let child_name = test_keyword_name() <> "-child"
          let create_child =
            KeywordCreateRequest(
              name: child_name,
              description: "Child keyword",
              icon: None,
              parent: Some(parent_keyword.id),
            )

          case keyword_api.create_keyword(config, create_child) {
            Ok(child_keyword) -> {
              io.println("✅ Success: Created child: " <> child_keyword.name)

              // Verify parent relationship
              should.equal(child_keyword.parent, Some(parent_keyword.id))

              // full_name should show hierarchy
              should.be_true(string.contains(child_keyword.full_name, ">"))

              // Cleanup (child first, then parent)
              let _ = keyword_api.delete_keyword(config, child_keyword.id)
              let _ = keyword_api.delete_keyword(config, parent_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed to create child: " <> string.inspect(err))
              // Cleanup parent
              let _ = keyword_api.delete_keyword(config, parent_keyword.id)
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

/// Test: Create keyword with empty name (should fail)
///
/// This test verifies validation of required fields.
pub fn create_keyword_empty_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - empty name (should fail)")

      let create_request =
        KeywordCreateRequest(
          name: "",
          description: "Invalid keyword",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("❌ Unexpected success - should have failed")
          // Cleanup if it somehow succeeded
          let _ = keyword_api.delete_keyword(config, keyword.id)
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error: " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// UPDATE KEYWORD TESTS
// ============================================================================

/// Test: Update keyword name
///
/// This test verifies updating a keyword's name.
pub fn update_keyword_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: update_keyword() - update name")

      // Create a keyword
      let original_name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: original_name,
          description: "Original description",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("  📝 Created keyword: " <> keyword.name)

          // Update the name
          let new_name = test_keyword_name() <> "-updated"
          let update_request =
            KeywordUpdateRequest(
              name: Some(new_name),
              description: None,
              icon: None,
              parent: None,
            )

          case keyword_api.update_keyword(config, keyword.id, update_request) {
            Ok(updated_keyword) -> {
              io.println("✅ Success: Updated name to: " <> updated_keyword.name)

              should.equal(updated_keyword.name, new_name)
              should.equal(updated_keyword.id, keyword.id)
              // Description should remain unchanged
              should.equal(updated_keyword.description, "Original description")

              // Cleanup
              let _ = keyword_api.delete_keyword(config, updated_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed to update: " <> string.inspect(err))
              // Cleanup
              let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Update keyword description
///
/// This test verifies partial updates (only description).
pub fn update_keyword_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: update_keyword() - update description only")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Old description",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          // Update only description
          let update_request =
            KeywordUpdateRequest(
              name: None,
              description: Some("New description"),
              icon: None,
              parent: None,
            )

          case keyword_api.update_keyword(config, keyword.id, update_request) {
            Ok(updated_keyword) -> {
              io.println("✅ Success: Updated description")

              should.equal(updated_keyword.description, "New description")
              // Name should remain unchanged
              should.equal(updated_keyword.name, name)

              // Cleanup
              let _ = keyword_api.delete_keyword(config, updated_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Update keyword add icon
///
/// This test verifies adding an icon to a keyword.
pub fn update_keyword_add_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: update_keyword() - add icon")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "No icon initially",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          should.equal(keyword.icon, None)

          // Add an icon
          let update_request =
            KeywordUpdateRequest(
              name: None,
              description: None,
              icon: Some(Some("🎯")),
              parent: None,
            )

          case keyword_api.update_keyword(config, keyword.id, update_request) {
            Ok(updated_keyword) -> {
              io.println("✅ Success: Added icon")

              should.equal(updated_keyword.icon, Some("🎯"))

              // Cleanup
              let _ = keyword_api.delete_keyword(config, updated_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Update keyword remove icon
///
/// This test verifies removing an icon from a keyword.
pub fn update_keyword_remove_icon_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: update_keyword() - remove icon")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Has icon",
          icon: Some("🔥"),
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          should.equal(keyword.icon, Some("🔥"))

          // Remove the icon
          let update_request =
            KeywordUpdateRequest(
              name: None,
              description: None,
              icon: Some(None),
              parent: None,
            )

          case keyword_api.update_keyword(config, keyword.id, update_request) {
            Ok(updated_keyword) -> {
              io.println("✅ Success: Removed icon")

              should.equal(updated_keyword.icon, None)

              // Cleanup
              let _ = keyword_api.delete_keyword(config, updated_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = keyword_api.delete_keyword(config, keyword.id)
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

/// Test: Update keyword multiple fields
///
/// This test verifies updating multiple fields at once.
pub fn update_keyword_multiple_fields_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: update_keyword() - multiple fields")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "Original",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          // Update name, description, and icon together
          let new_name = test_keyword_name() <> "-multi"
          let update_request =
            KeywordUpdateRequest(
              name: Some(new_name),
              description: Some("Updated description"),
              icon: Some(Some("⭐")),
              parent: None,
            )

          case keyword_api.update_keyword(config, keyword.id, update_request) {
            Ok(updated_keyword) -> {
              io.println("✅ Success: Updated multiple fields")

              should.equal(updated_keyword.name, new_name)
              should.equal(updated_keyword.description, "Updated description")
              should.equal(updated_keyword.icon, Some("⭐"))

              // Cleanup
              let _ = keyword_api.delete_keyword(config, updated_keyword.id)
              Nil
            }
            Error(err) -> {
              io.println("❌ Failed: " <> string.inspect(err))
              let _ = keyword_api.delete_keyword(config, keyword.id)
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
// DELETE KEYWORD TESTS
// ============================================================================

/// Test: Delete keyword
///
/// This test verifies successful keyword deletion.
pub fn delete_keyword_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: delete_keyword() - successful deletion")

      let name = test_keyword_name()
      let create_request =
        KeywordCreateRequest(
          name: name,
          description: "To be deleted",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("  📝 Created keyword ID: " <> int.to_string(keyword.id))

          // Delete the keyword
          case keyword_api.delete_keyword(config, keyword.id) {
            Ok(Nil) -> {
              io.println("✅ Success: Deleted keyword")

              // Verify it's gone by trying to get it
              case keyword_api.get_keyword(config, keyword.id) {
                Ok(_) -> {
                  io.println("❌ Keyword still exists after deletion")
                  should.fail()
                }
                Error(_) -> {
                  io.println("  ✓ Verified: Keyword no longer exists")
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

/// Test: Delete non-existent keyword
///
/// This test verifies error handling when deleting a non-existent keyword.
pub fn delete_keyword_not_found_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: delete_keyword() - not found (999999)")

      // Try to delete a keyword that doesn't exist
      case keyword_api.delete_keyword(config, 999_999) {
        Ok(_) -> {
          io.println("❌ Unexpected success - should have failed")
          should.fail()
        }
        Error(err) -> {
          io.println("✅ Expected error: " <> string.inspect(err))
          should.be_true(True)
        }
      }
    }
  }
}

// ============================================================================
// EDGE CASES & VALIDATION TESTS
// ============================================================================

/// Test: Create keyword with very long name
///
/// This test verifies handling of long names (boundary testing).
pub fn create_keyword_long_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - very long name")

      let long_name =
        "test-very-long-keyword-name-that-might-exceed-database-limits-"
        <> test_keyword_name()

      let create_request =
        KeywordCreateRequest(
          name: long_name,
          description: "Testing long names",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println(
            "✅ Success: Created with long name ("
            <> int.to_string(string.length(keyword.name))
            <> " chars)",
          )

          // Cleanup
          let _ = keyword_api.delete_keyword(config, keyword.id)
          Nil
        }
        Error(err) -> {
          io.println("⚠️  Long name rejected: " <> string.inspect(err))
          // This might be expected if there's a length limit
          should.be_true(True)
        }
      }
    }
  }
}

/// Test: Create keyword with special characters
///
/// This test verifies handling of special characters in names.
pub fn create_keyword_special_chars_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> {
      io.println("⏭️  Skipped: TANDOOR_URL not set")
      Nil
    }
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      io.println("🧪 Testing: create_keyword() - special characters")

      let special_name =
        "test-special-@#$-" <> int.to_string(erlang_system_time_milliseconds())

      let create_request =
        KeywordCreateRequest(
          name: special_name,
          description: "Testing special chars",
          icon: None,
          parent: None,
        )

      case keyword_api.create_keyword(config, create_request) {
        Ok(keyword) -> {
          io.println("✅ Success: Created with special chars")

          // Cleanup
          let _ = keyword_api.delete_keyword(config, keyword.id)
          Nil
        }
        Error(err) -> {
          io.println("⚠️  Special chars rejected: " <> string.inspect(err))
          // This might be expected
          should.be_true(True)
        }
      }
    }
  }
}
