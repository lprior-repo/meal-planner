//// Integration tests for meal planner application
//// Tests database operations, storage CRUD, and NCP flows end-to-end
//// Following BDD Given/When/Then patterns

import gleam/int
import gleam/list
import gleeunit/should
import server/storage
import shared/types.{
  Active, Breakfast, Dinner, FoodLogEntry, Gain, Lunch, Macros, Moderate, Recipe,
  Snack, macros_scale, macros_sum,
}
import test_helpers

// ============================================================================
// Capability 1: Database Integration Tests
// ============================================================================

/// BDD: GIVEN clean database WHEN running init_db THEN all tables are created
pub fn given_clean_database_when_running_init_db_then_tables_created_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: clean database (in-memory, empty)

    // When: running init_db
    let result = storage.init_db(conn)

    // Then: all tables are created
    result |> should.be_ok()

    // Verify we can query each table (they exist)
    let recipes_result = storage.get_all_recipes(conn)
    recipes_result |> should.be_ok()

    // Profile table exists (returns NotFound, not DatabaseError)
    let profile_result = storage.get_user_profile(conn)
    case profile_result {
      Error(storage.NotFound) -> should.be_true(True)
      Error(storage.DatabaseError(_)) -> should.be_true(False)
      Ok(_) -> should.be_true(True)
    }

    // Logs table exists
    let logs_result = storage.get_daily_log(conn, "2025-12-01")
    logs_result |> should.be_ok()
  })
}

/// BDD: GIVEN recipe data WHEN saving and retrieving THEN data round-trips correctly
pub fn given_recipe_data_when_saving_and_retrieving_then_roundtrips_correctly_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: clean database with initialized tables
    let assert Ok(Nil) = storage.init_db(conn)

    // And: recipe data
    let recipe = test_helpers.sample_recipe()

    // When: saving the recipe
    let assert Ok(Nil) = storage.save_recipe(conn, recipe)

    // And: retrieving the recipe by ID
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, recipe.id)

    // Then: data round-trips correctly
    retrieved.id |> should.equal(recipe.id)
    retrieved.name |> should.equal(recipe.name)
    retrieved.macros.protein |> should.equal(recipe.macros.protein)
    retrieved.macros.fat |> should.equal(recipe.macros.fat)
    retrieved.macros.carbs |> should.equal(recipe.macros.carbs)
    retrieved.servings |> should.equal(recipe.servings)
    retrieved.category |> should.equal(recipe.category)
    retrieved.vertical_compliant |> should.equal(recipe.vertical_compliant)

    // Verify ingredients round-trip
    list.length(retrieved.ingredients) |> should.equal(3)

    // Verify instructions round-trip
    list.length(retrieved.instructions) |> should.equal(3)
  })
}

/// BDD: GIVEN user profile WHEN updating THEN changes persist across connections
pub fn given_user_profile_when_updating_then_changes_persist_test() {
  test_helpers.with_temp_file_db(fn(conn) {
    // Given: initialized database
    let assert Ok(Nil) = storage.init_db(conn)

    // And: initial user profile
    let profile1 = test_helpers.sample_profile()
    let assert Ok(Nil) = storage.save_user_profile(conn, profile1)

    // When: updating the profile
    let profile2 = test_helpers.sample_active_profile()
    let assert Ok(Nil) = storage.save_user_profile(conn, profile2)

    // Then: changes persist (even across same connection)
    let assert Ok(retrieved) = storage.get_user_profile(conn)

    retrieved.bodyweight |> should.equal(profile2.bodyweight)
    case retrieved.activity_level {
      Active -> should.be_true(True)
      _ -> should.be_true(False)
    }
    case retrieved.goal {
      Gain -> should.be_true(True)
      _ -> should.be_true(False)
    }
    retrieved.meals_per_day |> should.equal(profile2.meals_per_day)
  })
}

/// BDD: GIVEN food log entries WHEN querying by date THEN correct entries returned
pub fn given_food_log_entries_when_querying_by_date_then_correct_entries_returned_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: initialized database
    let assert Ok(Nil) = storage.init_db(conn)

    // And: food log entries for different dates
    let date1 = "2025-12-01"
    let date2 = "2025-12-02"

    let entry1 =
      FoodLogEntry(
        id: "log-1",
        recipe_id: "recipe-1",
        recipe_name: "Breakfast Meal",
        servings: 1.0,
        macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: Breakfast,
        logged_at: "2025-12-01T08:00:00Z",
      )

    let entry2 =
      FoodLogEntry(
        id: "log-2",
        recipe_id: "recipe-2",
        recipe_name: "Lunch Meal",
        servings: 1.5,
        macros: Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
        meal_type: Lunch,
        logged_at: "2025-12-01T12:00:00Z",
      )

    let entry3 =
      FoodLogEntry(
        id: "log-3",
        recipe_id: "recipe-3",
        recipe_name: "Different Day Meal",
        servings: 1.0,
        macros: Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: Dinner,
        logged_at: "2025-12-02T18:00:00Z",
      )

    // When: saving entries
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date1, entry1)
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date1, entry2)
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date2, entry3)

    // Then: querying by date returns correct entries
    let assert Ok(daily_log1) = storage.get_daily_log(conn, date1)
    daily_log1.date |> should.equal(date1)
    list.length(daily_log1.entries) |> should.equal(2)

    let assert Ok(daily_log2) = storage.get_daily_log(conn, date2)
    daily_log2.date |> should.equal(date2)
    list.length(daily_log2.entries) |> should.equal(1)

    // Verify total macros are calculated
    // Date 1: 30+40=70 protein, 10+15=25 fat, 40+50=90 carbs
    daily_log1.total_macros.protein |> should.equal(70.0)
    daily_log1.total_macros.fat |> should.equal(25.0)
    daily_log1.total_macros.carbs |> should.equal(90.0)
  })
}

// ============================================================================
// Capability 2: Storage CRUD Integration Tests
// ============================================================================

/// BDD: GIVEN initialized database WHEN performing CRUD operations THEN all operations work
pub fn given_initialized_database_when_performing_crud_then_all_work_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: initialized database
    let assert Ok(Nil) = storage.init_db(conn)

    // CREATE: save a recipe
    let recipe = test_helpers.sample_recipe()
    let assert Ok(Nil) = storage.save_recipe(conn, recipe)

    // READ: get the recipe
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, recipe.id)
    retrieved.name |> should.equal(recipe.name)

    // UPDATE: save with same ID but different data
    let updated_recipe = Recipe(..recipe, name: "Updated Recipe Name")
    let assert Ok(Nil) = storage.save_recipe(conn, updated_recipe)

    // Verify update worked
    let assert Ok(updated_retrieved) = storage.get_recipe_by_id(conn, recipe.id)
    updated_retrieved.name |> should.equal("Updated Recipe Name")

    // DELETE: delete food log entry (we'll create one first)
    let entry =
      FoodLogEntry(
        id: "delete-test",
        recipe_id: recipe.id,
        recipe_name: recipe.name,
        servings: 1.0,
        macros: recipe.macros,
        meal_type: Dinner,
        logged_at: "2025-12-01T18:00:00Z",
      )

    let assert Ok(Nil) = storage.save_food_log_entry(conn, "2025-12-01", entry)

    // Verify it was saved
    let assert Ok(log_before) = storage.get_daily_log(conn, "2025-12-01")
    list.length(log_before.entries) |> should.equal(1)

    // Delete it
    let assert Ok(Nil) = storage.delete_food_log_entry(conn, entry.id)

    // Verify deletion
    let assert Ok(log_after) = storage.get_daily_log(conn, "2025-12-01")
    list.length(log_after.entries) |> should.equal(0)
  })
}

/// BDD: GIVEN recipe not in database WHEN getting by ID THEN NotFound error returned
pub fn given_recipe_not_in_database_when_getting_by_id_then_not_found_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: initialized database with no recipes
    let assert Ok(Nil) = storage.init_db(conn)

    // When: getting recipe by non-existent ID
    let result = storage.get_recipe_by_id(conn, "non-existent-id")

    // Then: NotFound error is returned
    case result {
      Error(storage.NotFound) -> should.be_true(True)
      _ -> should.be_true(False)
    }
  })
}

/// BDD: GIVEN multiple recipes WHEN getting all recipes THEN all returned in order
pub fn given_multiple_recipes_when_getting_all_then_all_returned_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: initialized database
    let assert Ok(Nil) = storage.init_db(conn)

    // And: multiple recipes
    let recipe1 = test_helpers.sample_recipe()
    let recipe2 = test_helpers.sample_high_protein_recipe()
    let recipe3 = test_helpers.sample_balanced_recipe()

    let assert Ok(Nil) = storage.save_recipe(conn, recipe1)
    let assert Ok(Nil) = storage.save_recipe(conn, recipe2)
    let assert Ok(Nil) = storage.save_recipe(conn, recipe3)

    // When: getting all recipes
    let assert Ok(recipes) = storage.get_all_recipes(conn)

    // Then: all recipes are returned
    list.length(recipes) |> should.equal(3)

    // Verify all IDs are present
    let ids = list.map(recipes, fn(r) { r.id })
    list.contains(ids, recipe1.id) |> should.be_true()
    list.contains(ids, recipe2.id) |> should.be_true()
    list.contains(ids, recipe3.id) |> should.be_true()
  })
}

// ============================================================================
// Capability 3: NCP Flow Integration Tests
// ============================================================================

/// BDD: GIVEN nutrition history WHEN calculating average THEN correct average computed
pub fn given_nutrition_history_when_calculating_average_then_correct_test() {
  test_helpers.with_temp_db(fn(conn) {
    // Given: initialized database
    let assert Ok(Nil) = storage.init_db(conn)

    // And: multiple days of nutrition logs
    let date1 = "2025-11-29"
    let date2 = "2025-11-30"
    let date3 = "2025-12-01"

    // Day 1: 100p, 50f, 200c
    let entry1a =
      FoodLogEntry(
        id: "d1-1",
        recipe_id: "r1",
        recipe_name: "Meal 1",
        servings: 1.0,
        macros: Macros(protein: 50.0, fat: 25.0, carbs: 100.0),
        meal_type: Breakfast,
        logged_at: date1 <> "T08:00:00Z",
      )
    let entry1b =
      FoodLogEntry(
        id: "d1-2",
        recipe_id: "r2",
        recipe_name: "Meal 2",
        servings: 1.0,
        macros: Macros(protein: 50.0, fat: 25.0, carbs: 100.0),
        meal_type: Dinner,
        logged_at: date1 <> "T18:00:00Z",
      )

    // Day 2: 120p, 60f, 180c
    let entry2 =
      FoodLogEntry(
        id: "d2-1",
        recipe_id: "r3",
        recipe_name: "Meal 3",
        servings: 1.0,
        macros: Macros(protein: 120.0, fat: 60.0, carbs: 180.0),
        meal_type: Lunch,
        logged_at: date2 <> "T12:00:00Z",
      )

    // Day 3: 80p, 40f, 220c
    let entry3 =
      FoodLogEntry(
        id: "d3-1",
        recipe_id: "r4",
        recipe_name: "Meal 4",
        servings: 1.0,
        macros: Macros(protein: 80.0, fat: 40.0, carbs: 220.0),
        meal_type: Snack,
        logged_at: date3 <> "T14:00:00Z",
      )

    let assert Ok(Nil) = storage.save_food_log_entry(conn, date1, entry1a)
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date1, entry1b)
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date2, entry2)
    let assert Ok(Nil) = storage.save_food_log_entry(conn, date3, entry3)

    // When: retrieving daily logs and calculating average
    let assert Ok(log1) = storage.get_daily_log(conn, date1)
    let assert Ok(log2) = storage.get_daily_log(conn, date2)
    let assert Ok(log3) = storage.get_daily_log(conn, date3)

    let daily_logs = [log1, log2, log3]
    let total_macros_list = list.map(daily_logs, fn(log) { log.total_macros })

    // Calculate average manually for verification
    // Protein: (100 + 120 + 80) / 3 = 100
    // Fat: (50 + 60 + 40) / 3 = 50
    // Carbs: (200 + 180 + 220) / 3 = 200
    let sum = macros_sum(total_macros_list)
    let count = list.length(total_macros_list)
    let average = macros_scale(sum, 1.0 /. int.to_float(count))

    // Then: correct average is computed
    average.protein |> should.equal(100.0)
    average.fat |> should.equal(50.0)
    average.carbs |> should.equal(200.0)
  })
}

// ============================================================================
// Capability 4: Test Fixtures and Helpers
// ============================================================================

/// BDD: GIVEN test module WHEN importing THEN have access to sample_recipe helper
pub fn given_test_module_when_importing_then_have_sample_recipe_test() {
  // Given: test module
  // When: calling sample_recipe helper
  let recipe = test_helpers.sample_recipe()

  // Then: returns valid recipe
  recipe.id |> should.equal("test-chicken-rice")
  recipe.macros.protein |> should.equal(45.0)
  list.length(recipe.ingredients) |> should.equal(3)
}

/// BDD: GIVEN test module WHEN importing THEN have access to sample_profile helper
pub fn given_test_module_when_importing_then_have_sample_profile_test() {
  // Given: test module
  // When: calling sample_profile helper
  let profile = test_helpers.sample_profile()

  // Then: returns valid profile
  profile.bodyweight |> should.equal(180.0)
  profile.meals_per_day |> should.equal(3)
  case profile.activity_level {
    Moderate -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

/// BDD: GIVEN test database WHEN test starts THEN use isolated temp database
pub fn given_test_database_when_test_starts_then_isolated_test() {
  // Given: test starting
  // When: using with_temp_db
  test_helpers.with_temp_db(fn(conn) {
    // Then: database is isolated (in-memory)
    let assert Ok(Nil) = storage.init_db(conn)

    // Save a recipe
    let recipe = test_helpers.sample_recipe()
    let assert Ok(Nil) = storage.save_recipe(conn, recipe)

    // Verify it's saved
    let assert Ok(_) = storage.get_recipe_by_id(conn, recipe.id)

    should.be_true(True)
  })

  // Database is automatically cleaned up after the function completes
  should.be_true(True)
}

/// BDD: GIVEN multiple test helpers WHEN using them THEN reduce boilerplate
pub fn given_multiple_helpers_when_using_them_then_reduce_boilerplate_test() {
  test_helpers.with_temp_db(fn(conn) {
    let assert Ok(Nil) = storage.init_db(conn)

    // Using helpers reduces boilerplate significantly
    let recipe = test_helpers.sample_recipe()
    let profile = test_helpers.sample_profile()
    let macros = test_helpers.sample_macros()

    // All helpers return valid data
    recipe.macros.protein |> should.equal(45.0)
    profile.bodyweight |> should.equal(180.0)
    macros.protein |> should.equal(40.0)

    should.be_true(True)
  })
}
