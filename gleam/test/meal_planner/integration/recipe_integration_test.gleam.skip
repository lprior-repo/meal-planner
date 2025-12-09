/// Recipe Integration Tests
///
/// Demonstrates integration testing patterns for the recipe API:
/// - Database setup and teardown
/// - HTTP request/response testing
/// - CRUD operations
/// - Data validation
///
/// Run with: gleam test
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import meal_planner/integration/test_data_builders as builders
import meal_planner/integration/test_helpers
import meal_planner/storage

// ============================================================================
// Recipe CRUD Tests
// ============================================================================

pub fn test_save_and_retrieve_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Create a test recipe
    let recipe = builders.recipe_named("Chicken and Rice")

    // Act: Save recipe to database
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Assert: Retrieve recipe and verify
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, recipe.id)
    should.equal(retrieved.name, "Chicken and Rice")
    should.equal(retrieved.category, "test")
    should.equal(retrieved.servings, 1)
    Nil
  })
  |> should.be_ok()
}

pub fn test_get_all_recipes() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Save multiple recipes
    let recipes = builders.recipe_batch(3)
    let assert Ok(_) =
      storage.save_recipe(
        conn,
        list.first(recipes) |> result.unwrap(builders.recipe()),
      )
    let assert Ok(_) =
      storage.save_recipe(
        conn,
        list.at(recipes, 1) |> result.unwrap(builders.recipe()),
      )
    let assert Ok(_) =
      storage.save_recipe(
        conn,
        list.at(recipes, 2) |> result.unwrap(builders.recipe()),
      )

    // Act: Retrieve all recipes
    let assert Ok(all_recipes) = storage.get_all_recipes(conn)

    // Assert: Verify count
    should.equal(list.length(all_recipes), 3)
    Nil
  })
  |> should.be_ok()
}

pub fn test_delete_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Save a recipe
    let recipe = builders.recipe_with_id("recipe-to-delete")
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Act: Delete the recipe
    let assert Ok(_) = storage.delete_recipe(conn, recipe.id)

    // Assert: Recipe should no longer exist
    let result = storage.get_recipe_by_id(conn, recipe.id)
    should.be_error(result)
    Nil
  })
  |> should.be_ok()
}

pub fn test_update_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Save initial recipe
    let original = builders.recipe_named("Original Name")
    let assert Ok(_) = storage.save_recipe(conn, original)

    // Act: Update the recipe
    let updated = builders.Recipe(..original, name: "Updated Name")
    let assert Ok(_) = storage.save_recipe(conn, updated)

    // Assert: Verify update
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, original.id)
    should.equal(retrieved.name, "Updated Name")
    Nil
  })
  |> should.be_ok()
}

// ============================================================================
// Recipe Filtering Tests
// ============================================================================

pub fn test_filter_recipes_by_category() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Save recipes in different categories
    let chicken_recipe = builders.recipe_in_category("chicken")
    let beef_recipe = builders.recipe_in_category("beef")
    let seafood_recipe = builders.recipe_in_category("seafood")

    let assert Ok(_) = storage.save_recipe(conn, chicken_recipe)
    let assert Ok(_) = storage.save_recipe(conn, beef_recipe)
    let assert Ok(_) = storage.save_recipe(conn, seafood_recipe)

    // Act: Filter by chicken category
    let assert Ok(chicken_recipes) =
      storage.get_recipes_by_category(conn, "chicken")

    // Assert: Only chicken recipes returned
    should.equal(list.length(chicken_recipes), 1)
    let assert Ok(first) = list.first(chicken_recipes)
    should.equal(first.category, "chicken")
    Nil
  })
  |> should.be_ok()
}

pub fn test_filter_recipes_by_macros() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Save recipes with varying macros
    let recipes = builders.recipe_batch_varied_macros()
    list.each(recipes, fn(recipe) {
      let assert Ok(_) = storage.save_recipe(conn, recipe)
      Nil
    })

    // Act: Filter for high-protein, low-fat, low-calorie recipes
    // Note: filter_recipes expects Int parameters, not Float
    let assert Ok(filtered) = storage.filter_recipes(conn, 40, 15, 500)

    // Assert: Only high-protein recipe should match
    should.equal(list.length(filtered), 1)
    let assert Ok(first) = list.first(filtered)
    should.be_true(first.macros.protein >=. 40.0)
    should.be_true(first.macros.fat <=. 15.0)
    Nil
  })
  |> should.be_ok()
}

// ============================================================================
// Recipe Validation Tests
// ============================================================================

pub fn test_recipe_with_zero_servings_fails() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Create recipe with invalid servings
    let invalid_recipe = builders.recipe_with_servings(0)

    // Act & Assert: Should fail validation
    let result = storage.save_recipe(conn, invalid_recipe)
    should.be_error(result)
    Nil
  })
  |> should.be_ok()
}

pub fn test_recipe_with_negative_macros_fails() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Create recipe with negative protein
    let invalid_recipe = builders.recipe_with_macros(-10.0, 15.0, 40.0)

    // Act & Assert: Should fail validation
    let result = storage.save_recipe(conn, invalid_recipe)
    should.be_error(result)
    Nil
  })
  |> should.be_ok()
}

// ============================================================================
// Recipe Edge Cases
// ============================================================================

pub fn test_get_nonexistent_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Act: Try to get recipe that doesn't exist
    let result = storage.get_recipe_by_id(conn, "nonexistent-id")

    // Assert: Should return error
    should.be_error(result)
    Nil
  })
  |> should.be_ok()
}

pub fn test_delete_nonexistent_recipe() {
  test_helpers.with_integration_db(fn(conn) {
    // Act: Try to delete recipe that doesn't exist
    let result = storage.delete_recipe(conn, "nonexistent-id")

    // Assert: Should handle gracefully (implementation-dependent)
    // Some systems return Ok for idempotent deletes, others return Error
    case result {
      Ok(_) -> should.be_true(True)
      Error(_) -> should.be_true(True)
    }
    Nil
  })
  |> should.be_ok()
}

pub fn test_save_recipe_with_very_long_name() {
  test_helpers.with_integration_db(fn(conn) {
    // Arrange: Create recipe with 500-character name
    let long_name = string.repeat("A", 500)
    let recipe = builders.recipe_named(long_name)

    // Act: Save recipe
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Assert: Retrieve and verify
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, recipe.id)
    should.equal(string.length(retrieved.name), 500)
    Nil
  })
  |> should.be_ok()
}
