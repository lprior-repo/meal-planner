/// Integration tests for Supermarket Category API
///
/// These tests verify the complete CRUD operations for supermarket categories.
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
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/supermarket/category
import meal_planner/tandoor/integration/test_helpers
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  SupermarketCategoryCreateRequest,
}

/// Test: List supermarket categories with default parameters
///
/// This test verifies that we can successfully list categories from Tandoor.
/// It should return a paginated response with at least the count field.
pub fn list_categories_default_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List first 10 categories
      let result =
        category.list_categories(config, limit: Some(10), offset: None)

      // Should succeed
      should.be_ok(result)

      // Should have a count (even if 0)
      let assert Ok(response) = result
      should.be_true(response.count >= 0)
    }
  }
}

/// Test: List categories with pagination (page_size)
///
/// This test verifies that pagination parameters are correctly applied.
pub fn list_categories_pagination_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List with limit=2
      let result =
        category.list_categories(config, limit: Some(2), offset: None)

      should.be_ok(result)

      let assert Ok(response) = result

      // Results should have at most 2 categories
      should.be_true(case response.results {
        [] -> True
        [_] -> True
        [_, _] -> True
        _ -> False
      })
    }
  }
}

/// Test: List categories with offset parameter
///
/// This test verifies that offset-based pagination works.
pub fn list_categories_offset_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Get first item
      let first_result =
        category.list_categories(config, limit: Some(1), offset: Some(0))
      should.be_ok(first_result)

      // Get second item
      let second_result =
        category.list_categories(config, limit: Some(1), offset: Some(1))
      should.be_ok(second_result)

      // If there are at least 2 categories, they should be different
      case first_result, second_result {
        Ok(page1), Ok(page2) -> {
          case page1.results, page2.results {
            [category1], [category2] -> {
              // Different categories should have different IDs
              should.not_equal(category1.id, category2.id)
            }
            _, _ -> {
              // Not enough categories to compare - test passes
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

/// Test: Get category by ID
///
/// This test verifies that we can retrieve a specific category.
/// We first list categories to get a valid ID, then fetch it.
pub fn get_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List categories to get a valid ID
      let assert Ok(list_response) =
        category.list_categories(config, limit: Some(1), offset: None)

      case list_response.results {
        [first_category, ..] -> {
          // Get the category by ID
          let result =
            category.get_category(config, category_id: first_category.id)

          should.be_ok(result)

          let assert Ok(cat) = result
          should.equal(cat.id, first_category.id)
          should.equal(cat.name, first_category.name)
        }
        [] -> {
          // No categories exist - skip test
          Nil
        }
      }
    }
  }
}

/// Test: Get non-existent category returns error
///
/// This test verifies error handling for invalid IDs.
pub fn get_nonexistent_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Use a very large ID that probably doesn't exist
      let result = category.get_category(config, category_id: 999_999_999)

      // Should return an error
      should.be_error(result)
      Nil
    }
  }
}

/// Test: Create category with minimal data
///
/// This test verifies that we can create a category with just a name.
pub fn create_category_minimal_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "Test Category " <> timestamp,
          description: None,
        )

      let result = category.create_category(config, request)

      should.be_ok(result)

      let assert Ok(cat) = result
      should.equal(cat.name, "Test Category " <> timestamp)
      should.equal(cat.description, None)
      should.be_true(cat.id > 0)

      // Clean up: delete the created category
      let _ = category.delete_category(config, cat.id)
      Nil
    }
  }
}

/// Test: Create category with full data
///
/// This test verifies that we can create a category with all fields.
pub fn create_category_full_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "Test Full Category " <> timestamp,
          description: Some("A test category with description"),
        )

      let result = category.create_category(config, request)

      should.be_ok(result)

      let assert Ok(cat) = result
      should.equal(cat.name, "Test Full Category " <> timestamp)
      should.equal(cat.description, Some("A test category with description"))
      should.be_true(cat.id > 0)

      // Clean up: delete the created category
      let _ = category.delete_category(config, cat.id)
      Nil
    }
  }
}

/// Test: Create category with special characters
///
/// This test verifies that we can create categories with special characters in the name.
pub fn create_category_special_chars_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "Fruits & Vegetables " <> timestamp,
          description: Some("Fresh produce section"),
        )

      let result = category.create_category(config, request)

      should.be_ok(result)

      let assert Ok(cat) = result
      should.equal(cat.name, "Fruits & Vegetables " <> timestamp)

      // Clean up
      let _ = category.delete_category(config, cat.id)
      Nil
    }
  }
}

/// Test: Update category name
///
/// This test verifies that we can update a category's name.
pub fn update_category_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test category first
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Update Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) = category.create_category(config, create_request)

      // Update the name
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "Updated Name " <> timestamp,
          description: None,
        )

      let result =
        category.update_category(
          config,
          category_id: created.id,
          category_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.id, created.id)
      should.equal(updated.name, "Updated Name " <> timestamp)

      // Clean up
      let _ = category.delete_category(config, created.id)
      Nil
    }
  }
}

/// Test: Update category description
///
/// This test verifies that we can update a category's description.
pub fn update_category_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test category first
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Description Test " <> timestamp,
          description: Some("Original description"),
        )

      let assert Ok(created) = category.create_category(config, create_request)

      // Update the description
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "Description Test " <> timestamp,
          description: Some("Updated description"),
        )

      let result =
        category.update_category(
          config,
          category_id: created.id,
          category_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.description, Some("Updated description"))

      // Clean up
      let _ = category.delete_category(config, created.id)
      Nil
    }
  }
}

/// Test: Update category to remove description
///
/// This test verifies that we can remove a description by setting it to None.
pub fn update_category_remove_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test category with description
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Remove Desc Test " <> timestamp,
          description: Some("Will be removed"),
        )

      let assert Ok(created) = category.create_category(config, create_request)

      // Update to remove description
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "Remove Desc Test " <> timestamp,
          description: None,
        )

      let result =
        category.update_category(
          config,
          category_id: created.id,
          category_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.description, None)

      // Clean up
      let _ = category.delete_category(config, created.id)
      Nil
    }
  }
}

/// Test: Delete category
///
/// This test verifies that we can delete a category.
pub fn delete_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a test category
      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Delete Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) = category.create_category(config, create_request)
      let category_id = created.id

      // Delete the category
      let delete_result = category.delete_category(config, category_id)
      should.be_ok(delete_result)

      // Verify it's deleted by trying to get it
      let get_result = category.get_category(config, category_id: category_id)
      should.be_error(get_result)
      Nil
    }
  }
}

/// Test: Delete non-existent category
///
/// This test verifies error handling when deleting an invalid ID.
pub fn delete_nonexistent_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Try to delete a non-existent category
      let result = category.delete_category(config, 999_999_999)

      // Should return an error
      should.be_error(result)
      Nil
    }
  }
}

/// Test: Complete CRUD workflow for categories
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
        SupermarketCategoryCreateRequest(
          name: "CRUD Test " <> timestamp,
          description: Some("Initial description"),
        )

      let assert Ok(created) = category.create_category(config, create_request)
      let category_id = created.id

      // Verify creation
      should.equal(created.name, "CRUD Test " <> timestamp)
      should.equal(created.description, Some("Initial description"))

      // 2. READ (GET)
      let assert Ok(retrieved) =
        category.get_category(config, category_id: category_id)
      should.equal(retrieved.id, category_id)
      should.equal(retrieved.name, created.name)

      // 3. UPDATE
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "CRUD Test Updated " <> timestamp,
          description: Some("Updated description"),
        )

      let assert Ok(updated) =
        category.update_category(
          config,
          category_id: category_id,
          category_data: update_request,
        )

      should.equal(updated.id, category_id)
      should.equal(updated.name, "CRUD Test Updated " <> timestamp)
      should.equal(updated.description, Some("Updated description"))

      // 4. DELETE
      let assert Ok(_) = category.delete_category(config, category_id)

      // Verify deletion
      let get_after_delete =
        category.get_category(config, category_id: category_id)
      should.be_error(get_after_delete)
      Nil
    }
  }
}

/// Test: List categories returns created category
///
/// This test verifies that a created category appears in the list.
pub fn list_contains_created_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "List Test " <> timestamp,
          description: Some("Should appear in list"),
        )

      // Create a category
      let assert Ok(created) = category.create_category(config, request)

      // List categories and verify it's there
      let assert Ok(list_response) =
        category.list_categories(config, limit: Some(100), offset: None)

      // Find the created category in the list
      let found =
        list_response.results
        |> list.any(fn(cat) { cat.id == created.id })

      should.be_true(found)

      // Clean up
      let _ = category.delete_category(config, created.id)
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
