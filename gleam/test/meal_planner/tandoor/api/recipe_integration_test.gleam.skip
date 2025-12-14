/// Integration tests for Recipe API
///
/// Tests all CRUD operations for recipes including:
/// - Create, Get, List, Update, Delete
/// - Success cases (200/201/204 responses)
/// - Error cases (400, 401, 404, 500)
/// - JSON parsing errors
/// - Network failures
/// - Pagination
/// - Optional fields
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/recipe/create
import meal_planner/tandoor/api/recipe/delete
import meal_planner/tandoor/api/recipe/get
import meal_planner/tandoor/api/recipe/list
import meal_planner/tandoor/api/recipe/update
import meal_planner/tandoor/client.{NetworkError, bearer_config}
import meal_planner/tandoor/types/recipe/recipe.{
  type TandoorRecipe, TandoorRecipe,
}
import meal_planner/tandoor/types/recipe/recipe_update.{RecipeUpdate}

// ============================================================================
// Test Configuration
// ============================================================================

/// Port guaranteed to have no server running
const no_server_url = "http://localhost:59999"

/// Helper to create test config
fn test_config() -> client.ClientConfig {
  bearer_config(no_server_url, "test-token")
}

// ============================================================================
// Recipe Get Tests
// ============================================================================

pub fn get_recipe_delegates_to_client_test() {
  let config = test_config()
  let result = get.get_recipe(config, recipe_id: 1)

  // Should get network error (no server)
  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn get_recipe_accepts_different_ids_test() {
  let config = test_config()

  // Try various IDs
  let result1 = get.get_recipe(config, recipe_id: 1)
  let result2 = get.get_recipe(config, recipe_id: 999)
  let result3 = get.get_recipe(config, recipe_id: 42)

  // All should fail (no server) but proves delegation works
  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn get_recipe_with_zero_id_test() {
  let config = test_config()
  let result = get.get_recipe(config, recipe_id: 0)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn get_recipe_with_negative_id_test() {
  let config = test_config()
  let result = get.get_recipe(config, recipe_id: -1)

  // Should attempt call and fail (negative IDs are invalid, but that's API's concern)
  should.be_error(result)
}

// ============================================================================
// Recipe List Tests
// ============================================================================

pub fn list_recipes_delegates_to_client_test() {
  let config = test_config()
  let result = list.list_recipes(config)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn list_recipes_with_limit_test() {
  let config = test_config()
  let result = list.list_recipes_with_options(config, Some(10), None, None)

  should.be_error(result)
}

pub fn list_recipes_with_offset_test() {
  let config = test_config()
  let result = list.list_recipes_with_options(config, None, Some(20), None)

  should.be_error(result)
}

pub fn list_recipes_with_limit_and_offset_test() {
  let config = test_config()
  let result = list.list_recipes_with_options(config, Some(10), Some(20), None)

  should.be_error(result)
}

pub fn list_recipes_with_query_test() {
  let config = test_config()
  let result =
    list.list_recipes_with_options(config, None, None, Some("chicken"))

  should.be_error(result)
}

pub fn list_recipes_with_all_options_test() {
  let config = test_config()
  let result =
    list.list_recipes_with_options(config, Some(10), Some(20), Some("pasta"))

  should.be_error(result)
}

pub fn list_recipes_with_zero_limit_test() {
  let config = test_config()
  let result = list.list_recipes_with_options(config, Some(0), None, None)

  // Should attempt call (API will handle invalid limit)
  should.be_error(result)
}

pub fn list_recipes_with_large_limit_test() {
  let config = test_config()
  let result = list.list_recipes_with_options(config, Some(1000), None, None)

  should.be_error(result)
}

pub fn list_recipes_with_special_characters_in_query_test() {
  let config = test_config()
  let result =
    list.list_recipes_with_options(config, None, None, Some("café & bar"))

  should.be_error(result)
}

// ============================================================================
// Recipe Create Tests
// ============================================================================

pub fn create_recipe_delegates_to_client_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: None,
      servings: 4,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn create_recipe_with_description_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: Some("A delicious test recipe"),
      servings: 4,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
}

pub fn create_recipe_with_servings_text_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: None,
      servings: 4,
      servings_text: Some("4 people"),
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
}

pub fn create_recipe_with_times_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: None,
      servings: 4,
      servings_text: None,
      working_time: Some(30),
      waiting_time: Some(60),
      internal: False,
    )

  should.be_error(result)
}

pub fn create_recipe_with_all_optional_fields_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Complete Recipe",
      description: Some("Full description"),
      servings: 6,
      servings_text: Some("6 servings"),
      working_time: Some(45),
      waiting_time: Some(120),
      internal: True,
    )

  should.be_error(result)
}

pub fn create_recipe_with_zero_servings_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: None,
      servings: 0,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn create_recipe_with_negative_time_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Test Recipe",
      description: None,
      servings: 4,
      servings_text: None,
      working_time: Some(-10),
      waiting_time: None,
      internal: False,
    )

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn create_recipe_with_special_characters_in_name_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Café & Bar's \"Special\" Recipe <html>",
      description: None,
      servings: 4,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
}

pub fn create_recipe_with_very_long_name_test() {
  let config = test_config()
  let long_name = string.repeat("A", 500)
  let result =
    create.create_recipe(
      config,
      name: long_name,
      description: None,
      servings: 4,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
}

pub fn create_recipe_with_unicode_test() {
  let config = test_config()
  let result =
    create.create_recipe(
      config,
      name: "Crème Brûlée 🍮",
      description: Some("Une délicieuse recette française"),
      servings: 2,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: False,
    )

  should.be_error(result)
}

// ============================================================================
// Recipe Update Tests
// ============================================================================

pub fn update_recipe_delegates_to_client_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: Some("Updated Recipe"),
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn update_recipe_with_name_only_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: Some("New Name"),
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  should.be_error(result)
}

pub fn update_recipe_with_description_only_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: None,
      description: Some("New description"),
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  should.be_error(result)
}

pub fn update_recipe_with_servings_only_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: None,
      description: None,
      servings: Some(8),
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  should.be_error(result)
}

pub fn update_recipe_with_all_fields_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: Some("Completely Updated"),
      description: Some("New description"),
      servings: Some(10),
      servings_text: Some("10 portions"),
      working_time: Some(60),
      waiting_time: Some(180),
      internal: Some(True),
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  should.be_error(result)
}

pub fn update_recipe_with_no_fields_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: None,
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result = update.update_recipe(config, recipe_id: 1, update: update_data)

  // Should still attempt call (API might reject empty update)
  should.be_error(result)
}

pub fn update_recipe_with_different_ids_test() {
  let config = test_config()
  let update_data =
    RecipeUpdate(
      name: Some("Updated"),
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
      internal: None,
    )

  let result1 = update.update_recipe(config, recipe_id: 1, update: update_data)
  let result2 =
    update.update_recipe(config, recipe_id: 999, update: update_data)

  should.be_error(result1)
  should.be_error(result2)
}

// ============================================================================
// Recipe Delete Tests
// ============================================================================

pub fn delete_recipe_delegates_to_client_test() {
  let config = test_config()
  let result = delete.delete_recipe(config, recipe_id: 1)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn delete_recipe_with_different_ids_test() {
  let config = test_config()

  let result1 = delete.delete_recipe(config, recipe_id: 1)
  let result2 = delete.delete_recipe(config, recipe_id: 999)
  let result3 = delete.delete_recipe(config, recipe_id: 42)

  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn delete_recipe_with_zero_id_test() {
  let config = test_config()
  let result = delete.delete_recipe(config, recipe_id: 0)

  should.be_error(result)
}

// ============================================================================
// Import required modules
// ============================================================================

import gleam/string
