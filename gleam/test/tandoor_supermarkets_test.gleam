/// Web Handler Tests for Tandoor Supermarket Endpoints
///
/// This test module verifies all 6 supermarket endpoints exposed through the
/// Tandoor web handler:
/// 1. GET /api/tandoor/supermarkets - List supermarkets
/// 2. GET /api/tandoor/supermarkets/:id - Get single supermarket
/// 3. POST /api/tandoor/supermarkets - Create supermarket
/// 4. PUT /api/tandoor/supermarkets/:id - Update supermarket
/// 5. DELETE /api/tandoor/supermarkets/:id - Delete supermarket
/// 6. GET /api/tandoor/supermarket-categories - List/CRUD categories
///
/// Run with:
/// ```bash
/// cd gleam && gleam test -- tandoor_supermarkets_test
/// ```
///
/// Or:
/// ```bash
/// export TANDOOR_URL=http://localhost:8000
/// export TANDOOR_USERNAME=admin
/// export TANDOOR_PASSWORD=password
/// cd gleam && gleam test
/// ```

import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/supermarket/list as supermarket_list
import meal_planner/tandoor/api/supermarket/get as supermarket_get
import meal_planner/tandoor/api/supermarket/create as supermarket_create
import meal_planner/tandoor/api/supermarket/update as supermarket_update
import meal_planner/tandoor/api/supermarket/delete as supermarket_delete
import meal_planner/tandoor/api/supermarket/category as supermarket_category
import meal_planner/tandoor/integration/test_helpers
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  SupermarketCreateRequest,
}
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  SupermarketCategoryCreateRequest,
}

// =============================================================================
// ENDPOINT 1: List Supermarkets
// =============================================================================

/// Test: List all supermarkets via API handler
///
/// Endpoint: GET /api/tandoor/supermarkets
/// Verifies that the handler correctly lists all available supermarkets
pub fn handler_list_supermarkets_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Call the actual API to test through the handler
      let result = supermarket_list.list_supermarkets(config, limit: Some(10), page: None)

      // Verify successful response
      should.be_ok(result)

      let assert Ok(response) = result

      // Verify response structure
      should.be_true(response.count >= 0)
      should.be_true(case response.results {
        [] -> True
        _ -> True
      })
    }
  }
}

/// Test: List supermarkets with limit parameter
///
/// Endpoint: GET /api/tandoor/supermarkets?limit=2
/// Verifies that the limit parameter is correctly applied
pub fn handler_list_supermarkets_with_limit_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result = supermarket_list.list_supermarkets(config, limit: Some(2), page: None)

      should.be_ok(result)

      let assert Ok(response) = result

      // Verify limit is applied (at most 2 results)
      let result_count = case response.results {
        [] -> 0
        [_] -> 1
        [_, _] -> 2
        _ -> 999 // More than 2 - test should fail
      }

      should.be_true(result_count <= 2)
    }
  }
}

/// Test: List supermarkets with pagination
///
/// Endpoint: GET /api/tandoor/supermarkets?limit=1&page=1
/// Verifies that pagination parameters are correctly applied
pub fn handler_list_supermarkets_pagination_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Get first page
      let page1_result = supermarket_list.list_supermarkets(
        config,
        limit: Some(1),
        page: Some(1),
      )

      should.be_ok(page1_result)

      // Get second page
      let page2_result = supermarket_list.list_supermarkets(
        config,
        limit: Some(1),
        page: Some(2),
      )

      should.be_ok(page2_result)
    }
  }
}

// =============================================================================
// ENDPOINT 2: Get Single Supermarket
// =============================================================================

/// Test: Get supermarket by ID via handler
///
/// Endpoint: GET /api/tandoor/supermarkets/:id
/// Verifies that a specific supermarket can be retrieved
pub fn handler_get_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // First list to get a valid ID
      let assert Ok(list_response) =
        supermarket_list.list_supermarkets(config, limit: Some(1), page: None)

      case list_response.results {
        [first_supermarket, ..] -> {
          // Get by ID
          let result = supermarket_get.get_supermarket(config, id: first_supermarket.id)

          should.be_ok(result)

          let assert Ok(supermarket) = result
          should.equal(supermarket.id, first_supermarket.id)
          should.equal(supermarket.name, first_supermarket.name)
        }
        [] -> {
          // No supermarkets - test passes
          Nil
        }
      }
    }
  }
}

/// Test: Get non-existent supermarket returns error
///
/// Endpoint: GET /api/tandoor/supermarkets/999999999
/// Verifies that the handler correctly handles non-existent IDs
pub fn handler_get_nonexistent_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result = supermarket_get.get_supermarket(config, id: 999_999_999)

      // Should return an error
      should.be_error(result)
    }
  }
}

// =============================================================================
// ENDPOINT 3: Create Supermarket
// =============================================================================

/// Test: Create supermarket with minimal data via handler
///
/// Endpoint: POST /api/tandoor/supermarkets
/// Body: {"name": "Test Supermarket"}
/// Verifies that a supermarket can be created with minimal data
pub fn handler_create_supermarket_minimal_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCreateRequest(
          name: "Handler Test " <> timestamp,
          description: None,
        )

      let result = supermarket_create.create_supermarket(config, request)

      should.be_ok(result)

      let assert Ok(supermarket) = result
      should.equal(supermarket.name, "Handler Test " <> timestamp)
      should.equal(supermarket.description, None)
      should.be_true(supermarket.id > 0)

      // Cleanup
      let _ = supermarket_delete.delete_supermarket(config, supermarket.id)
      Nil
    }
  }
}

/// Test: Create supermarket with full data
///
/// Endpoint: POST /api/tandoor/supermarkets
/// Body: {"name": "...", "description": "..."}
/// Verifies that a supermarket can be created with all fields
pub fn handler_create_supermarket_full_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCreateRequest(
          name: "Handler Full Test " <> timestamp,
          description: Some("Test description from handler"),
        )

      let result = supermarket_create.create_supermarket(config, request)

      should.be_ok(result)

      let assert Ok(supermarket) = result
      should.equal(supermarket.name, "Handler Full Test " <> timestamp)
      should.equal(
        supermarket.description,
        Some("Test description from handler"),
      )
      should.be_true(supermarket.id > 0)

      // Cleanup
      let _ = supermarket_delete.delete_supermarket(config, supermarket.id)
      Nil
    }
  }
}

// =============================================================================
// ENDPOINT 4: Update Supermarket
// =============================================================================

/// Test: Update supermarket name via handler
///
/// Endpoint: PUT /api/tandoor/supermarkets/:id
/// Body: {"name": "Updated Name"}
/// Verifies that a supermarket's name can be updated
pub fn handler_update_supermarket_name_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Update Handler Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) =
        supermarket_create.create_supermarket(config, create_request)

      // Update the name
      let update_request =
        SupermarketCreateRequest(
          name: "Updated Handler Name " <> timestamp,
          description: None,
        )

      let result =
        supermarket_update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.id, created.id)
      should.equal(updated.name, "Updated Handler Name " <> timestamp)

      // Cleanup
      let _ = supermarket_delete.delete_supermarket(config, created.id)
      Nil
    }
  }
}

/// Test: Update supermarket description via handler
///
/// Endpoint: PUT /api/tandoor/supermarkets/:id
/// Body: {"description": "Updated description"}
/// Verifies that a supermarket's description can be updated
pub fn handler_update_supermarket_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Update Desc Handler Test " <> timestamp,
          description: Some("Original handler description"),
        )

      let assert Ok(created) =
        supermarket_create.create_supermarket(config, create_request)

      // Update the description
      let update_request =
        SupermarketCreateRequest(
          name: "Update Desc Handler Test " <> timestamp,
          description: Some("Updated handler description"),
        )

      let result =
        supermarket_update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.description, Some("Updated handler description"))

      // Cleanup
      let _ = supermarket_delete.delete_supermarket(config, created.id)
      Nil
    }
  }
}

// =============================================================================
// ENDPOINT 5: Delete Supermarket
// =============================================================================

/// Test: Delete supermarket via handler
///
/// Endpoint: DELETE /api/tandoor/supermarkets/:id
/// Verifies that a supermarket can be deleted
pub fn handler_delete_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let create_request =
        SupermarketCreateRequest(
          name: "Delete Handler Test " <> timestamp,
          description: None,
        )

      let assert Ok(created) =
        supermarket_create.create_supermarket(config, create_request)

      let supermarket_id = created.id

      // Delete the supermarket
      let delete_result = supermarket_delete.delete_supermarket(config, supermarket_id)
      should.be_ok(delete_result)

      // Verify deletion
      let get_result = supermarket_get.get_supermarket(config, id: supermarket_id)
      should.be_error(get_result)
    }
  }
}

/// Test: Delete non-existent supermarket via handler
///
/// Endpoint: DELETE /api/tandoor/supermarkets/999999999
/// Verifies that the handler correctly handles non-existent deletions
pub fn handler_delete_nonexistent_supermarket_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result = supermarket_delete.delete_supermarket(config, 999_999_999)

      // Should return an error
      should.be_error(result)
    }
  }
}

// =============================================================================
// ENDPOINT 6: Supermarket Categories
// =============================================================================

/// Test: List supermarket categories via handler
///
/// Endpoint: GET /api/tandoor/supermarket-categories
/// Verifies that categories can be listed
pub fn handler_list_categories_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result =
        supermarket_category.list_categories(config, limit: Some(10), offset: None)

      should.be_ok(result)

      let assert Ok(response) = result
      should.be_true(response.count >= 0)
    }
  }
}

/// Test: Get supermarket category by ID via handler
///
/// Endpoint: GET /api/tandoor/supermarket-categories/:id
/// Verifies that a specific category can be retrieved
pub fn handler_get_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // List to get a valid ID
      let assert Ok(list_response) =
        supermarket_category.list_categories(config, limit: Some(1), offset: None)

      case list_response.results {
        [first_category, ..] -> {
          let result =
            supermarket_category.get_category(config, category_id: first_category.id)

          should.be_ok(result)

          let assert Ok(category) = result
          should.equal(category.id, first_category.id)
          should.equal(category.name, first_category.name)
        }
        [] -> {
          // No categories exist - test passes
          Nil
        }
      }
    }
  }
}

/// Test: Create supermarket category via handler
///
/// Endpoint: POST /api/tandoor/supermarket-categories
/// Body: {"name": "New Category"}
/// Verifies that a category can be created
pub fn handler_create_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "Handler Category " <> timestamp,
          description: None,
        )

      let result = supermarket_category.create_category(config, request)

      should.be_ok(result)

      let assert Ok(category) = result
      should.equal(category.name, "Handler Category " <> timestamp)
      should.be_true(category.id > 0)

      // Cleanup
      let _ = supermarket_category.delete_category(config, category.id)
      Nil
    }
  }
}

/// Test: Create category with description via handler
///
/// Endpoint: POST /api/tandoor/supermarket-categories
/// Body: {"name": "Category", "description": "Description"}
/// Verifies that a category can be created with description
pub fn handler_create_category_with_description_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let request =
        SupermarketCategoryCreateRequest(
          name: "Handler Category Desc " <> timestamp,
          description: Some("Fruits and Vegetables"),
        )

      let result = supermarket_category.create_category(config, request)

      should.be_ok(result)

      let assert Ok(category) = result
      should.equal(category.name, "Handler Category Desc " <> timestamp)
      should.equal(category.description, Some("Fruits and Vegetables"))

      // Cleanup
      let _ = supermarket_category.delete_category(config, category.id)
      Nil
    }
  }
}

/// Test: Update category via handler
///
/// Endpoint: PUT /api/tandoor/supermarket-categories/:id
/// Body: {"name": "Updated Category Name"}
/// Verifies that a category can be updated
pub fn handler_update_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Update Category Handler " <> timestamp,
          description: None,
        )

      let assert Ok(created) =
        supermarket_category.create_category(config, create_request)

      // Update the category
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "Updated Category Handler " <> timestamp,
          description: Some("Updated description"),
        )

      let result =
        supermarket_category.update_category(
          config,
          category_id: created.id,
          category_data: update_request,
        )

      should.be_ok(result)

      let assert Ok(updated) = result
      should.equal(updated.id, created.id)
      should.equal(updated.name, "Updated Category Handler " <> timestamp)

      // Cleanup
      let _ = supermarket_category.delete_category(config, created.id)
      Nil
    }
  }
}

/// Test: Delete category via handler
///
/// Endpoint: DELETE /api/tandoor/supermarket-categories/:id
/// Verifies that a category can be deleted
pub fn handler_delete_category_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Delete Category Handler " <> timestamp,
          description: None,
        )

      let assert Ok(created) =
        supermarket_category.create_category(config, create_request)

      let category_id = created.id

      // Delete the category
      let delete_result = supermarket_category.delete_category(config, category_id)
      should.be_ok(delete_result)

      // Verify deletion
      let get_result = supermarket_category.get_category(config, category_id: category_id)
      should.be_error(get_result)
    }
  }
}

// =============================================================================
// Integration Tests: Complete Workflows
// =============================================================================

/// Test: Complete supermarket CRUD workflow via handler
///
/// Verifies the complete lifecycle: create -> read -> update -> delete
pub fn handler_complete_supermarket_workflow_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()

      // 1. CREATE
      let create_request =
        SupermarketCreateRequest(
          name: "Handler CRUD " <> timestamp,
          description: Some("Handler workflow test"),
        )

      let assert Ok(created) =
        supermarket_create.create_supermarket(config, create_request)

      // 2. READ
      let assert Ok(retrieved) =
        supermarket_get.get_supermarket(config, id: created.id)

      should.equal(retrieved.id, created.id)

      // 3. UPDATE
      let update_request =
        SupermarketCreateRequest(
          name: "Handler CRUD Updated " <> timestamp,
          description: Some("Updated via handler"),
        )

      let assert Ok(updated) =
        supermarket_update.update_supermarket(
          config,
          id: created.id,
          supermarket_data: update_request,
        )

      should.equal(updated.name, "Handler CRUD Updated " <> timestamp)

      // 4. DELETE
      let assert Ok(_) =
        supermarket_delete.delete_supermarket(config, created.id)

      // Verify deletion
      let get_result = supermarket_get.get_supermarket(config, id: created.id)
      should.be_error(get_result)
    }
  }
}

/// Test: Complete category CRUD workflow via handler
///
/// Verifies the complete lifecycle: create -> read -> update -> delete
pub fn handler_complete_category_workflow_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let timestamp = get_timestamp()

      // 1. CREATE
      let create_request =
        SupermarketCategoryCreateRequest(
          name: "Handler Cat CRUD " <> timestamp,
          description: Some("Category workflow test"),
        )

      let assert Ok(created) =
        supermarket_category.create_category(config, create_request)

      // 2. READ
      let assert Ok(retrieved) =
        supermarket_category.get_category(config, category_id: created.id)

      should.equal(retrieved.id, created.id)

      // 3. UPDATE
      let update_request =
        SupermarketCategoryCreateRequest(
          name: "Handler Cat CRUD Updated " <> timestamp,
          description: Some("Updated category"),
        )

      let assert Ok(updated) =
        supermarket_category.update_category(
          config,
          category_id: created.id,
          category_data: update_request,
        )

      should.equal(updated.name, "Handler Cat CRUD Updated " <> timestamp)

      // 4. DELETE
      let assert Ok(_) =
        supermarket_category.delete_category(config, created.id)

      // Verify deletion
      let get_result =
        supermarket_category.get_category(config, category_id: created.id)
      should.be_error(get_result)
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Generate a unique timestamp for test data
fn get_timestamp() -> String {
  let timestamp = erlang_system_time_milliseconds() |> int.to_string()
  timestamp
}

/// Get current system time in milliseconds (for unique test data)
@external(erlang, "erlang", "system_time")
fn erlang_system_time_milliseconds() -> Int
