/// Tests for food storage module - specifically testing for duplicate results
/// and custom foods functionality with unified search
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/foods
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

/// Test that search_foods returns no duplicate FDC IDs
///
/// This test verifies that the DISTINCT ON (fdc_id) clause in the SQL
/// query successfully prevents duplicate food entries in search results.
pub fn search_foods_no_duplicates_test() {
  // Setup: Connect to test database
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  // Search for a common food that matches both full-text search and ILIKE
  // Using "chicken" as it's likely to have many matches in the database
  let query = "chicken"
  let limit = 50

  // Execute search
  let assert Ok(results) = foods.search_foods(conn, query, limit)

  // Collect all FDC IDs
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })

  // Check for duplicates by comparing length of list vs length of unique set
  let unique_ids = fdc_ids |> list.unique()
  let total_count = list.length(fdc_ids)
  let unique_count = list.length(unique_ids)

  // Assert no duplicates: unique count should equal total count
  unique_count
  |> should.equal(total_count)
}

/// Test that search_foods_filtered also has no duplicates
pub fn search_foods_filtered_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let query = "chicken"
  let limit = 20
  let filters =
    types.SearchFilters(
      branded_only: False,
      category: None,
      verified_only: False,
    )

  let assert Ok(results) =
    foods.search_foods_filtered(conn, query, filters, limit)

  // Check for duplicates
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })
  let unique_ids = fdc_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(fdc_ids))
}

/// Test that search_foods_filtered_with_offset has no duplicates
pub fn search_foods_filtered_with_offset_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let query = "beef"
  let limit = 15
  let offset = 0
  let filters =
    types.SearchFilters(
      branded_only: False,
      category: None,
      verified_only: False,
    )

  let assert Ok(results) =
    foods.search_foods_filtered_with_offset(conn, query, filters, limit, offset)

  // Check for duplicates
  let fdc_ids = results |> list.map(fn(food) { food.fdc_id })
  let unique_ids = fdc_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(fdc_ids))
}

/// Test that search_custom_foods has no duplicates
pub fn search_custom_foods_no_duplicates_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  // Create a test user ID
  let user_id = id.user_id("test-user-1")

  let query = "test"
  let limit = 20

  // Note: This test assumes custom foods exist for the test user
  // In a real test environment, you'd set up test data first
  let assert Ok(results) =
    foods.search_custom_foods(conn, user_id, query, limit)

  // Check for duplicates
  let food_ids = results |> list.map(fn(food) { food.id })
  let unique_ids = food_ids |> list.unique()

  list.length(unique_ids)
  |> should.equal(list.length(food_ids))
}

// ============================================================================
// Custom Foods CRUD Tests
// ============================================================================

/// Test create custom food
pub fn create_custom_food_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-custom-food")
  let food_id = id.custom_food_id("test-custom-food-001")

  let custom_food =
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: "Test Protein Shake",
      brand: Some("MyBrand"),
      description: Some("Homemade protein shake"),
      serving_size: 250.0,
      serving_unit: "ml",
      macros: types.Macros(protein: 30.0, fat: 5.0, carbs: 10.0),
      calories: 205.0,
      micronutrients: None,
    )

  // Create the custom food
  let assert Ok(created) =
    storage.create_custom_food(conn, user_id, custom_food)

  // Verify it was created correctly
  created.name |> should.equal("Test Protein Shake")
  created.brand |> should.equal(Some("MyBrand"))
  created.serving_size |> should.equal(250.0)
  created.macros.protein |> should.equal(30.0)

  // Cleanup
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id)
}

/// Test get custom food by ID
pub fn get_custom_food_by_id_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-get-food")
  let food_id = id.custom_food_id("test-custom-food-002")

  let custom_food =
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: "Test Energy Bar",
      brand: None,
      description: Some("Homemade energy bar"),
      serving_size: 50.0,
      serving_unit: "g",
      macros: types.Macros(protein: 10.0, fat: 8.0, carbs: 20.0),
      calories: 188.0,
      micronutrients: None,
    )

  // Create and retrieve
  let assert Ok(_) = storage.create_custom_food(conn, user_id, custom_food)
  let assert Ok(retrieved) =
    storage.get_custom_food_by_id(conn, user_id, food_id)

  // Verify
  retrieved.name |> should.equal("Test Energy Bar")
  retrieved.brand |> should.equal(None)
  retrieved.serving_unit |> should.equal("g")

  // Cleanup
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id)
}

/// Test update custom food
pub fn update_custom_food_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-update-food")
  let food_id = id.custom_food_id("test-custom-food-003")

  let custom_food =
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: "Original Name",
      brand: Some("OriginalBrand"),
      description: None,
      serving_size: 100.0,
      serving_unit: "g",
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      calories: 290.0,
      micronutrients: None,
    )

  // Create
  let assert Ok(_) = storage.create_custom_food(conn, user_id, custom_food)

  // Update with new values
  let updated_food =
    types.CustomFood(
      ..custom_food,
      name: "Updated Name",
      brand: Some("NewBrand"),
      macros: types.Macros(protein: 25.0, fat: 12.0, carbs: 35.0),
      calories: 332.0,
    )

  let assert Ok(result) =
    storage.update_custom_food(conn, user_id, updated_food)

  // Verify update
  result.name |> should.equal("Updated Name")
  result.brand |> should.equal(Some("NewBrand"))
  result.macros.protein |> should.equal(25.0)

  // Cleanup
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id)
}

/// Test delete custom food
pub fn delete_custom_food_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-delete-food")
  let food_id = id.custom_food_id("test-custom-food-004")

  let custom_food =
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: "To Be Deleted",
      brand: None,
      description: None,
      serving_size: 100.0,
      serving_unit: "g",
      macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      calories: 145.0,
      micronutrients: None,
    )

  // Create and delete
  let assert Ok(_) = storage.create_custom_food(conn, user_id, custom_food)
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id)

  // Verify it's deleted
  let result = storage.get_custom_food_by_id(conn, user_id, food_id)
  result |> should.be_error()
}

/// Test get custom foods for user
pub fn get_custom_foods_for_user_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-list-foods")
  let food_id_1 = id.custom_food_id("test-custom-food-005")
  let food_id_2 = id.custom_food_id("test-custom-food-006")

  let food_1 =
    types.CustomFood(
      id: food_id_1,
      user_id: user_id,
      name: "Food A",
      brand: None,
      description: None,
      serving_size: 100.0,
      serving_unit: "g",
      macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      calories: 145.0,
      micronutrients: None,
    )

  let food_2 =
    types.CustomFood(
      id: food_id_2,
      user_id: user_id,
      name: "Food B",
      brand: None,
      description: None,
      serving_size: 200.0,
      serving_unit: "g",
      macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      calories: 290.0,
      micronutrients: None,
    )

  // Create multiple foods
  let assert Ok(_) = storage.create_custom_food(conn, user_id, food_1)
  let assert Ok(_) = storage.create_custom_food(conn, user_id, food_2)

  // Get all foods for user
  let assert Ok(foods) = storage.get_custom_foods_for_user(conn, user_id)

  // Verify we have at least our 2 test foods
  list.length(foods) |> should.be_at_least(2)

  // Cleanup
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id_1)
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id_2)
}

// ============================================================================
// Unified Search Tests
// ============================================================================

/// Test unified search returns both custom and USDA foods
pub fn unified_search_foods_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-unified-search")
  let food_id = id.custom_food_id("test-custom-chicken")

  // Create a custom food matching "chicken"
  let custom_food =
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: "My Custom Chicken Breast",
      brand: Some("HomeMade"),
      description: Some("Grilled chicken breast"),
      serving_size: 100.0,
      serving_unit: "g",
      macros: types.Macros(protein: 31.0, fat: 3.6, carbs: 0.0),
      calories: 165.0,
      micronutrients: None,
    )

  let assert Ok(_) = storage.create_custom_food(conn, user_id, custom_food)

  // Search for "chicken" - should get custom food + USDA foods
  let assert Ok(response) =
    storage.unified_search_foods(conn, user_id, "chicken", 20)

  // Verify we have results
  response.total_count |> should.be_at_least(1)

  // Verify custom count is at least 1
  response.custom_count |> should.be_at_least(1)

  // Verify USDA count is positive (chicken is common in USDA DB)
  response.usda_count |> should.be_at_least(1)

  // Verify total equals sum
  response.total_count
  |> should.equal(response.custom_count + response.usda_count)

  // Verify first result is custom food (prioritized)
  case list.first(response.results) {
    Ok(types.CustomFoodResult(food)) -> {
      food.name |> should.equal("My Custom Chicken Breast")
    }
    _ -> should.fail()
  }

  // Cleanup
  let assert Ok(_) = storage.delete_custom_food(conn, user_id, food_id)
}

/// Test unified search with no custom foods
pub fn unified_search_usda_only_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-no-custom-foods")

  // Search for something uncommon for this user
  let assert Ok(response) =
    storage.unified_search_foods(conn, user_id, "beef", 10)

  // Should have USDA results
  response.usda_count |> should.be_at_least(1)

  // Custom count should be 0 (no custom foods for this user)
  response.custom_count |> should.equal(0)

  // All results should be USDA
  response.results
  |> list.all(fn(result) {
    case result {
      types.UsdaFoodResult(_, _, _, _, _) -> True
      _ -> False
    }
  })
  |> should.be_true()
}

/// Test unified search respects limit
pub fn unified_search_respects_limit_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-limit-test")

  let limit = 5

  let assert Ok(response) =
    storage.unified_search_foods(conn, user_id, "chicken", limit)

  // Total count should not exceed limit
  response.total_count |> should.be_at_most(limit)

  // Results list length should match total_count
  list.length(response.results) |> should.equal(response.total_count)
}

/// Test unified search with custom foods filling the limit
pub fn unified_search_custom_fills_limit_test() {
  let assert Ok(conn) = postgres.connect(postgres.default_config())

  let user_id = id.user_id("test-user-custom-fills-limit")

  // Create multiple custom foods
  let food_ids = [
    id.custom_food_id("test-custom-protein-1"),
    id.custom_food_id("test-custom-protein-2"),
    id.custom_food_id("test-custom-protein-3"),
  ]

  let create_custom_food = fn(food_id, name) {
    types.CustomFood(
      id: food_id,
      user_id: user_id,
      name: name,
      brand: None,
      description: None,
      serving_size: 100.0,
      serving_unit: "g",
      macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 10.0),
      calories: 165.0,
      micronutrients: None,
    )
  }

  // Create 3 custom foods with "protein" in the name
  let assert Ok(_) =
    storage.create_custom_food(
      conn,
      user_id,
      create_custom_food(
        id.custom_food_id("test-custom-protein-1"),
        "My Protein Shake",
      ),
    )
  let assert Ok(_) =
    storage.create_custom_food(
      conn,
      user_id,
      create_custom_food(
        id.custom_food_id("test-custom-protein-2"),
        "Protein Bar",
      ),
    )
  let assert Ok(_) =
    storage.create_custom_food(
      conn,
      user_id,
      create_custom_food(
        id.custom_food_id("test-custom-protein-3"),
        "Protein Powder",
      ),
    )

  // Search with limit of 3 - should only return custom foods
  let assert Ok(response) =
    storage.unified_search_foods(conn, user_id, "protein", 3)

  // Should have exactly 3 custom foods
  response.custom_count |> should.equal(3)

  // Should have 0 USDA foods (limit filled by custom)
  response.usda_count |> should.equal(0)

  // Total should be 3
  response.total_count |> should.equal(3)

  // Cleanup
  let assert Ok(_) =
    storage.delete_custom_food(
      conn,
      user_id,
      id.custom_food_id("test-custom-protein-1"),
    )
  let assert Ok(_) =
    storage.delete_custom_food(
      conn,
      user_id,
      id.custom_food_id("test-custom-protein-2"),
    )
  let assert Ok(_) =
    storage.delete_custom_food(
      conn,
      user_id,
      id.custom_food_id("test-custom-protein-3"),
    )
}
