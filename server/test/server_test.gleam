//// Integration tests for the meal planner web server API endpoints
//// Following TDD methodology: write tests first, then verify implementation

import gleam/list
import gleam/option
import gleeunit
import gleeunit/should
import server/storage
import shared/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Storage Integration Tests (TDD: Test database operations)
// ============================================================================

pub fn storage_init_db_test() {
  // TDD Red: Test that we can initialize the database
  storage.with_connection(":memory:", fn(conn) {
    storage.init_db(conn)
    |> should.be_ok()
  })
}

pub fn storage_get_all_recipes_empty_test() {
  // TDD Red: Test that empty database returns empty list
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    storage.get_all_recipes(conn)
    |> should.be_ok()
    |> should.equal([])
  })
}

pub fn storage_save_and_get_recipe_test() {
  // TDD Red: Test save and retrieve recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "test-recipe",
        name: "Test Recipe",
        ingredients: [types.Ingredient("Chicken", "8 oz")],
        instructions: ["Cook it"],
        macros: types.Macros(protein: 40.0, fat: 10.0, carbs: 0.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    storage.save_recipe(conn, recipe)
    |> should.be_ok()

    storage.get_recipe_by_id(conn, "test-recipe")
    |> should.be_ok()
    |> fn(r) { r.name }
    |> should.equal("Test Recipe")
  })
}

pub fn storage_get_recipe_not_found_test() {
  // TDD Red: Test recipe not found returns error
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    storage.get_recipe_by_id(conn, "nonexistent")
    |> should.be_error()
    |> should.equal(storage.NotFound)
  })
}

pub fn storage_user_profile_default_test() {
  // TDD Red: Test default profile when none exists
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let profile = storage.get_user_profile_or_default(conn)

    // Default should be 180 lbs, Moderate, Maintain, 3 meals
    profile.bodyweight
    |> should.equal(180.0)

    profile.meals_per_day
    |> should.equal(3)
  })
}

pub fn storage_save_and_get_user_profile_test() {
  // TDD Red: Test save and retrieve user profile
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let profile =
      types.UserProfile(
        id: "user-1",
        bodyweight: 200.0,
        activity_level: types.Active,
        goal: types.Gain,
        meals_per_day: 5,
      )

    storage.save_user_profile(conn, profile)
    |> should.be_ok()

    storage.get_user_profile(conn)
    |> should.be_ok()
    |> fn(p) { p.bodyweight }
    |> should.equal(200.0)
  })
}

pub fn storage_daily_log_empty_test() {
  // TDD Red: Test empty daily log
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    storage.get_daily_log(conn, "2024-01-15")
    |> should.be_ok()
    |> fn(log) { log.entries }
    |> should.equal([])
  })
}

pub fn storage_save_and_get_food_log_test() {
  // TDD Red: Test save and retrieve food log entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let entry =
      types.FoodLogEntry(
        id: "entry-1",
        recipe_id: "chicken-rice",
        recipe_name: "Chicken and Rice",
        servings: 1.5,
        macros: types.Macros(protein: 67.5, fat: 12.0, carbs: 67.5),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    storage.save_food_log_entry(conn, "2024-01-15", entry)
    |> should.be_ok()

    storage.get_daily_log(conn, "2024-01-15")
    |> should.be_ok()
    |> fn(log) { list.length(log.entries) }
    |> should.equal(1)
  })
}

pub fn storage_delete_food_log_entry_test() {
  // TDD Red: Test delete food log entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let entry =
      types.FoodLogEntry(
        id: "entry-to-delete",
        recipe_id: "test",
        recipe_name: "Test",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)

    storage.delete_food_log_entry(conn, "entry-to-delete")
    |> should.be_ok()

    storage.get_daily_log(conn, "2024-01-15")
    |> should.be_ok()
    |> fn(log) { list.length(log.entries) }
    |> should.equal(0)
  })
}

pub fn storage_daily_log_calculates_total_macros_test() {
  // TDD Red: Test that daily log correctly sums macros
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let entry1 =
      types.FoodLogEntry(
        id: "e1",
        recipe_id: "r1",
        recipe_name: "Meal 1",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "e2",
        recipe_id: "r2",
        recipe_name: "Meal 2",
        servings: 1.0,
        macros: types.Macros(protein: 45.0, fat: 15.0, carbs: 50.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry2)

    storage.get_daily_log(conn, "2024-01-15")
    |> should.be_ok()
    |> fn(log) { log.total_macros.protein }
    |> should.equal(75.0)
  })
}

// ============================================================================
// Additional User Profile Edge Case Tests
// ============================================================================

pub fn storage_get_user_profile_not_found_test() {
  // Test that get_user_profile returns NotFound when no profile exists
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    storage.get_user_profile(conn)
    |> should.be_error()
    |> should.equal(storage.NotFound)
  })
}

pub fn storage_update_user_profile_test() {
  // Test that saving a profile twice updates it
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let profile1 =
      types.UserProfile(
        id: "user-1",
        bodyweight: 180.0,
        activity_level: types.Moderate,
        goal: types.Maintain,
        meals_per_day: 3,
      )

    let profile2 =
      types.UserProfile(
        id: "user-1",
        bodyweight: 175.0,
        activity_level: types.Active,
        goal: types.Lose,
        meals_per_day: 4,
      )

    let assert Ok(_) = storage.save_user_profile(conn, profile1)
    let assert Ok(_) = storage.save_user_profile(conn, profile2)

    // Should have updated values
    let assert Ok(retrieved) = storage.get_user_profile(conn)
    retrieved.bodyweight |> should.equal(175.0)
    retrieved.meals_per_day |> should.equal(4)
  })
}

pub fn storage_user_profile_sedentary_test() {
  // Test Sedentary activity level roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let profile =
      types.UserProfile(
        id: "user-1",
        bodyweight: 160.0,
        activity_level: types.Sedentary,
        goal: types.Gain,
        meals_per_day: 4,
      )

    let assert Ok(_) = storage.save_user_profile(conn, profile)
    let assert Ok(retrieved) = storage.get_user_profile(conn)

    retrieved.activity_level |> should.equal(types.Sedentary)
    retrieved.goal |> should.equal(types.Gain)
  })
}

pub fn storage_user_profile_lose_goal_test() {
  // Test Lose goal roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let profile =
      types.UserProfile(
        id: "user-1",
        bodyweight: 220.0,
        activity_level: types.Moderate,
        goal: types.Lose,
        meals_per_day: 3,
      )

    let assert Ok(_) = storage.save_user_profile(conn, profile)
    let assert Ok(retrieved) = storage.get_user_profile(conn)

    retrieved.goal |> should.equal(types.Lose)
    retrieved.bodyweight |> should.equal(220.0)
  })
}

// ============================================================================
// Recipe Edge Case Tests
// ============================================================================

pub fn storage_recipe_fodmap_medium_test() {
  // Test Medium FODMAP level roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "medium-fodmap",
        name: "Medium FODMAP Recipe",
        ingredients: [types.Ingredient("Beans", "1 cup")],
        instructions: ["Cook"],
        macros: types.Macros(protein: 15.0, fat: 1.0, carbs: 40.0),
        servings: 2,
        category: "legumes",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "medium-fodmap")

    retrieved.fodmap_level |> should.equal(types.Medium)
    retrieved.vertical_compliant |> should.equal(False)
  })
}

pub fn storage_recipe_high_fodmap_test() {
  // Test High FODMAP level roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "high-fodmap",
        name: "High FODMAP Recipe",
        ingredients: [
          types.Ingredient("Garlic", "4 cloves"),
          types.Ingredient("Onion", "1 whole"),
        ],
        instructions: ["Saute garlic", "Add onion"],
        macros: types.Macros(protein: 2.0, fat: 5.0, carbs: 10.0),
        servings: 1,
        category: "aromatics",
        fodmap_level: types.High,
        vertical_compliant: False,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "high-fodmap")

    retrieved.fodmap_level |> should.equal(types.High)
    list.length(retrieved.ingredients) |> should.equal(2)
  })
}

pub fn storage_recipe_empty_ingredients_string_test() {
  // Test recipe with empty ingredients serialization
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "minimal",
        name: "Minimal Recipe",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe)
    let assert Ok(retrieved) = storage.get_recipe_by_id(conn, "minimal")

    retrieved.ingredients |> should.equal([])
    retrieved.instructions |> should.equal([])
  })
}

// ============================================================================
// Food Log Meal Type Tests
// ============================================================================

pub fn storage_food_log_breakfast_type_test() {
  // Test Breakfast meal type roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let entry =
      types.FoodLogEntry(
        id: "breakfast-entry",
        recipe_id: "eggs",
        recipe_name: "Eggs",
        servings: 1.0,
        macros: types.Macros(protein: 12.0, fat: 10.0, carbs: 1.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)
    let assert Ok(log) = storage.get_daily_log(conn, "2024-01-15")
    let assert [retrieved] = log.entries

    retrieved.meal_type |> should.equal(types.Breakfast)
  })
}

pub fn storage_food_log_snack_type_test() {
  // Test Snack meal type roundtrip
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let entry =
      types.FoodLogEntry(
        id: "snack-entry",
        recipe_id: "nuts",
        recipe_name: "Mixed Nuts",
        servings: 0.5,
        macros: types.Macros(protein: 5.0, fat: 15.0, carbs: 3.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:30:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)
    let assert Ok(log) = storage.get_daily_log(conn, "2024-01-15")
    let assert [retrieved] = log.entries

    retrieved.meal_type |> should.equal(types.Snack)
    retrieved.servings |> should.equal(0.5)
  })
}
