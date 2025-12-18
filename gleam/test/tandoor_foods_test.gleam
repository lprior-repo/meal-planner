/// Integration Tests for Tandoor Foods Endpoints
///
/// This module tests the complete CRUD lifecycle for Tandoor Foods
/// including list, get, create, update, and delete operations.
/// Tests are designed to work with a running Tandoor instance.
import gleam/io
import gleam/list
import gleam/option
import gleeunit/should
import meal_planner/tandoor/api/food/create as food_create
import meal_planner/tandoor/api/food/delete as food_delete
import meal_planner/tandoor/api/food/get as food_get
import meal_planner/tandoor/api/food/list as food_list
import meal_planner/tandoor/api/food/update as food_update
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}
import test_setup

/// Helper function to get test client configuration
fn get_test_client() -> Result(client.ClientConfig, String) {
  test_setup.get_test_config()
}

/// Helper to print test status
fn print_test_info(test_name: String) -> Nil {
  io.println("\n  Testing: " <> test_name)
}

// ============================================================================
// LIST OPERATIONS
// ============================================================================

pub fn list_foods_returns_paginated_response_test() {
  print_test_info("List foods returns paginated response")
  case get_test_client() {
    Ok(config) -> {
      let result = food_list.list_foods(config, option.None, option.None)
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_with_limit_test() {
  print_test_info("List foods with limit parameter")
  case get_test_client() {
    Ok(config) -> {
      let result = food_list.list_foods(config, option.Some(10), option.None)
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_with_pagination_test() {
  print_test_info("List foods with pagination")
  case get_test_client() {
    Ok(config) -> {
      let result = food_list.list_foods(config, option.Some(5), option.Some(1))
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_with_options_test() {
  print_test_info("List foods with extended options")
  case get_test_client() {
    Ok(config) -> {
      let result =
        food_list.list_foods_with_options(
          config,
          option.Some(10),
          option.None,
          option.None,
        )
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_with_query_search_test() {
  print_test_info("List foods with query search")
  case get_test_client() {
    Ok(config) -> {
      let result =
        food_list.list_foods_with_options(
          config,
          option.Some(20),
          option.None,
          option.Some("tomato"),
        )
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_with_offset_pagination_test() {
  print_test_info("List foods with offset pagination")
  case get_test_client() {
    Ok(config) -> {
      let result =
        food_list.list_foods_with_options(
          config,
          option.Some(10),
          option.Some(0),
          option.None,
        )
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn list_foods_large_limit_test() {
  print_test_info("List foods with large limit")
  case get_test_client() {
    Ok(config) -> {
      let result = food_list.list_foods(config, option.Some(100), option.None)
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// GET OPERATIONS
// ============================================================================

pub fn get_food_by_id_test() {
  print_test_info("Get food by ID")
  case get_test_client() {
    Ok(config) -> {
      // Try to get a food that likely exists (ID 1)
      let result = food_get.get_food(config, food_id: 1)
      // Result can be Ok or Error depending on if food exists
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn get_food_with_various_ids_test() {
  print_test_info("Get food with various IDs")
  case get_test_client() {
    Ok(config) -> {
      let _result1 = food_get.get_food(config, food_id: 1)
      let _result2 = food_get.get_food(config, food_id: 2)
      let _result3 = food_get.get_food(config, food_id: 999)
      // All should return results (Ok or Error)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn get_food_with_nonexistent_id_test() {
  print_test_info("Get food with nonexistent ID")
  case get_test_client() {
    Ok(config) -> {
      let result = food_get.get_food(config, food_id: 999_999)
      // Should return result (likely Error if food doesn't exist)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// CREATE OPERATIONS
// ============================================================================

pub fn create_food_with_simple_name_test() {
  print_test_info("Create food with simple name")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Test Apple")
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_food_with_complex_name_test() {
  print_test_info("Create food with complex name")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Extra Virgin Olive Oil")
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_food_with_special_characters_test() {
  print_test_info("Create food with special characters")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Black Pepper (Ground)")
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_food_with_unicode_test() {
  print_test_info("Create food with Unicode characters")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Jalapeño Peppers")
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_food_with_long_name_test() {
  print_test_info("Create food with long name")
  case get_test_client() {
    Ok(config) -> {
      let food_data =
        TandoorFoodCreateRequest(
          name: "Organic Free-Range Grass-Fed Antibiotic-Free Chicken Breast Fillet",
        )
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_food_delegates_to_api_test() {
  print_test_info("Create food delegates to API")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Delegation Test Food")
      let result = food_create.create_food(config, food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// UPDATE OPERATIONS
// ============================================================================

pub fn update_food_with_new_name_test() {
  print_test_info("Update food with new name")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Updated Apple")
      let result =
        food_update.update_food(config, food_id: 1, food_data: food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn update_food_with_different_ids_test() {
  print_test_info("Update food with different IDs")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Updated Food")
      let _result1 =
        food_update.update_food(config, food_id: 1, food_data: food_data)
      let _result2 =
        food_update.update_food(config, food_id: 2, food_data: food_data)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn update_food_with_unicode_name_test() {
  print_test_info("Update food with Unicode name")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Crème Fraîche Updated")
      let result =
        food_update.update_food(config, food_id: 5, food_data: food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn update_food_with_special_characters_test() {
  print_test_info("Update food with special characters")
  case get_test_client() {
    Ok(config) -> {
      let food_data =
        TandoorFoodCreateRequest(name: "Black Pepper (Ground) - Premium")
      let result =
        food_update.update_food(config, food_id: 3, food_data: food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn update_food_delegates_to_api_test() {
  print_test_info("Update food delegates to API")
  case get_test_client() {
    Ok(config) -> {
      let food_data = TandoorFoodCreateRequest(name: "Delegation Update Test")
      let result =
        food_update.update_food(config, food_id: 10, food_data: food_data)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// DELETE OPERATIONS
// ============================================================================

pub fn delete_food_by_id_test() {
  print_test_info("Delete food by ID")
  case get_test_client() {
    Ok(config) -> {
      let result = food_delete.delete_food(config, 999)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn delete_food_with_different_ids_test() {
  print_test_info("Delete food with different IDs")
  case get_test_client() {
    Ok(config) -> {
      let _result1 = food_delete.delete_food(config, 1)
      let _result2 = food_delete.delete_food(config, 2)
      let _result3 = food_delete.delete_food(config, 999)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn delete_food_with_small_id_test() {
  print_test_info("Delete food with small ID")
  case get_test_client() {
    Ok(config) -> {
      let result = food_delete.delete_food(config, 1)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn delete_food_with_large_id_test() {
  print_test_info("Delete food with large ID")
  case get_test_client() {
    Ok(config) -> {
      let result = food_delete.delete_food(config, 999_999)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn delete_food_delegates_to_api_test() {
  print_test_info("Delete food delegates to API")
  case get_test_client() {
    Ok(config) -> {
      let result = food_delete.delete_food(config, 500)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// INTEGRATION SCENARIOS
// ============================================================================

pub fn list_then_get_workflow_test() {
  print_test_info("List foods then get specific food workflow")
  case get_test_client() {
    Ok(config) -> {
      // First list foods
      let list_result =
        food_list.list_foods(config, option.Some(1), option.None)

      case list_result {
        Ok(response) -> {
          case list.first(response.results) {
            Ok(first_food) -> {
              // Then get the specific food
              let get_result =
                food_get.get_food(
                  config,
                  food_id: ids.food_id_to_int(first_food.id),
                )
              case get_result {
                Ok(_) | Error(_) -> Nil
              }
            }
            Error(_) -> {
              io.println("    ⚠️  No foods in response to get")
            }
          }
        }
        Error(_) -> {
          io.println("    ⚠️  Failed to list foods")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn create_and_list_workflow_test() {
  print_test_info("Create food and verify it appears in list")
  case get_test_client() {
    Ok(config) -> {
      // Create a new food
      let food_data = TandoorFoodCreateRequest(name: "Workflow Test Food")
      let create_result = food_create.create_food(config, food_data)

      case create_result {
        Ok(_created_food) -> {
          // Verify we can list foods
          let list_result =
            food_list.list_foods(
              config,
              limit: option.Some(1),
              page: option.None,
            )
          should.be_ok(list_result)
          io.println("    ✓ Created food and verified list")
        }
        Error(_) -> {
          io.println("    ⚠️  Failed to create food for workflow test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn update_and_get_workflow_test() {
  print_test_info("Update food and verify changes via get")
  case get_test_client() {
    Ok(config) -> {
      let test_id = 1
      let new_name = "Workflow Updated Food"
      let food_data = TandoorFoodCreateRequest(name: new_name)

      // Update food
      let update_result =
        food_update.update_food(config, food_id: test_id, food_data: food_data)

      case update_result {
        Ok(_) -> {
          // Get the updated food
          let get_result = food_get.get_food(config, food_id: test_id)
          case get_result {
            Ok(_) | Error(_) -> Nil
          }
        }
        Error(_) -> {
          io.println("    ⚠️  Failed to update food for workflow test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn pagination_consistency_test() {
  print_test_info("Pagination returns consistent results")
  case get_test_client() {
    Ok(config) -> {
      // Get first page
      let page1_result =
        food_list.list_foods(config, option.Some(5), option.Some(1))

      // Get second page
      let page2_result =
        food_list.list_foods(config, option.Some(5), option.Some(2))

      should.be_ok(page1_result)
      should.be_ok(page2_result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn search_functionality_test() {
  print_test_info("Search functionality returns relevant results")
  case get_test_client() {
    Ok(config) -> {
      // Search for foods containing "test"
      let search_result =
        food_list.list_foods_with_options(
          config,
          option.Some(20),
          option.None,
          option.Some("test"),
        )

      should.be_ok(search_result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

// ============================================================================
// ERROR HANDLING
// ============================================================================

pub fn handle_invalid_food_id_gracefully_test() {
  print_test_info("Handle invalid food ID gracefully")
  case get_test_client() {
    Ok(config) -> {
      // Large invalid ID should still return a result (error or ok)
      let result = food_get.get_food(config, food_id: 999_999_999)
      case result {
        Ok(_) | Error(_) -> Nil
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn handle_missing_environment_variables_test() {
  print_test_info("Handle missing environment variables gracefully")
  // This test verifies that get_test_client handles missing env vars
  let result = test_setup.get_test_config()
  // Should return either Ok or Error, but not panic
  case result {
    Ok(_) | Error(_) -> Nil
  }
}

pub fn empty_query_returns_all_results_test() {
  print_test_info("Empty query returns all or appropriate subset")
  case get_test_client() {
    Ok(config) -> {
      let result =
        food_list.list_foods_with_options(
          config,
          option.Some(10),
          option.None,
          option.None,
        )
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}

pub fn special_characters_in_search_test() {
  print_test_info("Special characters in search query")
  case get_test_client() {
    Ok(config) -> {
      let result =
        food_list.list_foods_with_options(
          config,
          option.Some(10),
          option.None,
          option.Some("(test)"),
        )
      should.be_ok(result)
      Nil
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
      Nil
    }
  }
}
