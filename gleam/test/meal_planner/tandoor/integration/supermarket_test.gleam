/// Integration tests for Supermarket API
///
/// These tests verify the complete CRUD operations for supermarkets.
/// They require a running Tandoor instance.
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
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/supermarket/create
import meal_planner/tandoor/api/supermarket/delete
import meal_planner/tandoor/api/supermarket/get
import meal_planner/tandoor/api/supermarket/list
import meal_planner/tandoor/api/supermarket/update
import meal_planner/tandoor/integration/test_helpers
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  SupermarketCreateRequest,
}

/// Test: List supermarkets with default parameters
///
/// This test verifies that we can successfully list supermarkets from Tandoor.
/// It should return a paginated response with at least the count field.
pub fn list_supermarkets_default_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List first 10 supermarkets
      let result = list.list_supermarkets(config, limit: Some(10), page: None)

      // Should succeed
      should.be_ok(result)

      // Should have a count (even if 0)
      let assert Ok(response) = result
      should.be_true(response.count >= 0)
    }
  }
}

/// Test: List supermarkets with pagination (page_size)
///
/// This test verifies that pagination parameters are correctly applied.
pub fn list_supermarkets_pagination_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List with limit=2
      let result = list.list_supermarkets(config, limit: Some(2), page: None)

      should.be_ok(result)

      let assert Ok(response) = result

      // Results should have at most 2 supermarkets
      should.be_true(case response.results {
        [] -> True
        [_] -> True
        [_, _] -> True
        _ -> False
      })
    }
  }
}

/// Test: List supermarkets with page parameter
///
/// This test verifies that page-based pagination works.
pub fn list_supermarkets_page_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Get first page
      let first_page =
        list.list_supermarkets(config, limit: Some(1), page: Some(1))
      should.be_ok(first_page)

      // Get second page
      let second_page =
        list.list_supermarkets(config, limit: Some(1), page: Some(2))
      should.be_ok(second_page)

      // If there are at least 2 supermarkets, they should be different
      case first_page, second_page {
        Ok(page1), Ok(page2) -> {
          case page1.results, page2.results {
            [supermarket1], [supermarket2] -> {
              // Different supermarkets should have different IDs
              should.not_equal(supermarket1.id, supermarket2.id)
            }
            _, _ -> {
              // Not enough supermarkets to compare - test passes
              Nil
            }
          }
        }
        _, _ -> {
          // Shouldn't happen since we checked be_ok
          Nil
        }
      }
    }
  }
}

/// Test: Get supermarket by ID
///
/// This test verifies that we can retrieve a specific supermarket.
/// We first list supermarkets to get a valid ID, then fetch it.
pub fn get_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List supermarkets to get a valid ID
      let assert Ok(list_response) =
        list.list_supermarkets(config, limit: Some(1), page: None)

      case list_response.results {
        [first_supermarket, ..] -> {
          // Get the supermarket by ID
          let result = get.get_supermarket(config, id: first_supermarket.id)

          should.be_ok(result)

          let assert Ok(supermarket) = result
          should.equal(supermarket.id, first_supermarket.id)
          should.equal(supermarket.name, first_supermarket.name)
        }
        [] -> {
          // No supermarkets exist - skip test
          Nil
        }
      }
    }
  }
}

/// Test: Get non-existent supermarket returns error
///
/// This test verifies error handling for invalid IDs.
pub fn get_nonexistent_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Use a very large ID that probably doesn't exist
      let result = get.get_supermarket(config, id: 999_999_999)

      // Should return an error
      should.be_error(result)
      Nil
    }
  }
}

/// Test: Create supermarket with minimal data
///
/// This test verifies that we can create a supermarket with just a name.
pub fn create_supermarket_minimal_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCreateRequest(
          name: "Test Supermarket " <> timestamp,
          description: None,
        )

      let result = create.create_supermarket(config, request)

      should.be_ok(result)

      let assert Ok(supermarket) = result
      should.equal(supermarket.name, "Test Supermarket " <> timestamp)
      should.equal(supermarket.description, None)
      should.be_true(supermarket.id > 0)

      // Clean up: delete the created supermarket
      let _ = delete.delete_supermarket(config, supermarket.id)
      Nil
    }
  }
}

/// Test: Create supermarket with full data
///
/// This test verifies that we can create a supermarket with all fields.
pub fn create_supermarket_full_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCreateRequest(
          name: "Test Full Supermarket " <> timestamp,
          description: Some("A test supermarket with description"),
        )

      let result = create.create_supermarket(config, request)

      should.be_ok(result)

      let assert Ok(supermarket) = result
      should.equal(supermarket.name, "Test Full Supermarket " <> timestamp)
      should.equal(
        supermarket.description,
        Some("A test supermarket with description"),
      )
      should.be_true(supermarket.id > 0)

      // Clean up: delete the created supermarket
      let _ = delete.delete_supermarket(config, supermarket.id)
      Nil
    }
  }
}

/// Test: Update supermarket name
///
/// This test verifies that we can update a supermarket's name.
pub fn update_supermarket_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test supermarket first
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Update Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) = create.create_supermarket(config, create_request)

      // Update the name
      let update_request =
        SupermarketCreateRequest(
          name: "Updated Name " <> timestamp,
          description: None,
        )

      let result =
        update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.id, created.id)
      should.equal(updated.name, "Updated Name " <> timestamp)

      // Clean up
      let _ = delete.delete_supermarket(config, created.id)
      Nil
    }
  }
}

/// Test: Update supermarket description
///
/// This test verifies that we can update a supermarket's description.
pub fn update_supermarket_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test supermarket first
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Description Test " <> timestamp,
          description: Some("Original description"),
        )

      let assert Ok(created) = create.create_supermarket(config, create_request)

      // Update the description
      let update_request =
        SupermarketCreateRequest(
          name: "Description Test " <> timestamp,
          description: Some("Updated description"),
        )

      let result =
        update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.description, Some("Updated description"))

      // Clean up
      let _ = delete.delete_supermarket(config, created.id)
      Nil
    }
  }
}

/// Test: Update supermarket to remove description
///
/// This test verifies that we can remove a description by setting it to None.
pub fn update_supermarket_remove_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test supermarket with description
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Remove Desc Test " <> timestamp,
          description: Some("Will be removed"),
        )

      let assert Ok(created) = create.create_supermarket(config, create_request)

      // Update to remove description
      let update_request =
        SupermarketCreateRequest(
          name: "Remove Desc Test " <> timestamp,
          description: None,
        )

      let result =
        update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.description, None)

      // Clean up
      let _ = delete.delete_supermarket(config, created.id)
      Nil
    }
  }
}

/// Test: Delete supermarket
///
/// This test verifies that we can delete a supermarket.
pub fn delete_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test supermarket
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Delete Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) = create.create_supermarket(config, create_request)
      let supermarket_id = created.id

      // Delete the supermarket
      let delete_result = delete.delete_supermarket(config, supermarket_id)
      should.be_ok(delete_result)

      // Verify it's deleted by trying to get it
      let get_result = get.get_supermarket(config, id: supermarket_id)
      should.be_error(get_result)
      Nil
    }
  }
}

/// Test: Delete non-existent supermarket
///
/// This test verifies error handling when deleting an invalid ID.
pub fn delete_nonexistent_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Try to delete a non-existent supermarket
      let result = delete.delete_supermarket(config, 999_999_999)

      // Should return an error
      should.be_error(result)
      Nil
    }
  }
}

/// Test: Complete CRUD workflow
///
/// This test verifies the entire lifecycle: create, read, update, delete.
pub fn complete_crud_workflow_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()

      // 1. CREATE
      let create_request =
        SupermarketCreateRequest(
          name: "CRUD Test " <> timestamp,
          description: Some("Initial description"),
        )

      let assert Ok(created) = create.create_supermarket(config, create_request)
      let supermarket_id = created.id

      // Verify creation
      should.equal(created.name, "CRUD Test " <> timestamp)
      should.equal(created.description, Some("Initial description"))

      // 2. READ (GET)
      let assert Ok(retrieved) = get.get_supermarket(config, id: supermarket_id)
      should.equal(retrieved.id, supermarket_id)
      should.equal(retrieved.name, created.name)

      // 3. UPDATE
      let update_request =
        SupermarketCreateRequest(
          name: "CRUD Test Updated " <> timestamp,
          description: Some("Updated description"),
        )

      let assert Ok(updated) =
        update.update_supermarket(
          config,
          id: supermarket_id,
          supermarket_data: update_request,
        )

      should.equal(updated.id, supermarket_id)
      should.equal(updated.name, "CRUD Test Updated " <> timestamp)
      should.equal(updated.description, Some("Updated description"))

      // 4. DELETE
      let assert Ok(_) = delete.delete_supermarket(config, supermarket_id)

      // Verify deletion
      let get_after_delete = get.get_supermarket(config, id: supermarket_id)
      should.be_error(get_after_delete)
      Nil
    }
  }
}

/// Helper function to generate a timestamp for unique test data
fn get_timestamp() -> String {
  let timestamp = erlang_system_time_milliseconds() |> int.to_string()
  timestamp
}

/// Get current system time in milliseconds (for unique test data)
@external(erlang, "erlang", "system_time")
fn erlang_system_time_milliseconds() -> Int
