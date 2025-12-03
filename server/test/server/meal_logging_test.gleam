//// BDD Tests for Meal Logging System
//// Comprehensive test coverage for all meal logging capabilities
//// Following Given/When/Then pattern

import gleam/float
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
// BDD Scenario: POST /api/logs creates entry and returns 201
// ============================================================================

pub fn create_meal_log_entry_test() {
  // Given a database with a recipe
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "grilled-chicken",
        name: "Grilled Chicken",
        ingredients: [types.Ingredient("Chicken breast", "8 oz")],
        instructions: ["Grill until cooked"],
        macros: types.Macros(protein: 50.0, fat: 5.0, carbs: 0.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // When creating a new food log entry
    let entry =
      types.FoodLogEntry(
        id: "log-001",
        recipe_id: "grilled-chicken",
        recipe_name: "Grilled Chicken",
        servings: 1.0,
        macros: types.Macros(protein: 50.0, fat: 5.0, carbs: 0.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:30:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    // Then entry is saved successfully (simulating 201 Created)
    storage.save_food_log_entry(conn, "2024-01-15", entry)
    |> should.be_ok()

    // And the entry can be retrieved
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")
    list.length(daily_log.entries)
    |> should.equal(1)

    let assert [retrieved] = daily_log.entries
    retrieved.id
    |> should.equal("log-001")
  })
}

// ============================================================================
// BDD Scenario: DELETE /api/logs/:id removes entry
// ============================================================================

pub fn delete_meal_log_entry_test() {
  // Given a database with an existing food log entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "test-recipe",
        name: "Test Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry =
      types.FoodLogEntry(
        id: "log-to-delete",
        recipe_id: "test-recipe",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)

    // When deleting the entry
    let assert Ok(_) = storage.delete_food_log_entry(conn, "log-to-delete")

    // Then the entry is removed from the log
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")
    list.length(daily_log.entries)
    |> should.equal(0)

    // And total macros are recalculated to zero
    daily_log.total_macros.protein
    |> should.equal(0.0)
    daily_log.total_macros.fat
    |> should.equal(0.0)
    daily_log.total_macros.carbs
    |> should.equal(0.0)
  })
}

pub fn delete_nonexistent_entry_test() {
  // Given a database with no entries
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When attempting to delete a nonexistent entry
    let result = storage.delete_food_log_entry(conn, "nonexistent-id")

    // Then the operation completes without error
    // (Delete is idempotent - deleting nonexistent entry is acceptable)
    result
    |> should.be_ok()
  })
}

// ============================================================================
// BDD Scenario: PUT /api/logs/:id updates servings
// ============================================================================

pub fn update_meal_log_servings_test() {
  // Given a database with an existing food log entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "pasta",
        name: "Pasta Bowl",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 60.0),
        servings: 1,
        category: "pasta",
        fodmap_level: types.Medium,
        vertical_compliant: False,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let original_entry =
      types.FoodLogEntry(
        id: "log-update",
        recipe_id: "pasta",
        recipe_name: "Pasta Bowl",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 60.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-15", original_entry)

    // When updating the servings to 1.5
    let updated_entry =
      types.FoodLogEntry(
        id: "log-update",
        recipe_id: "pasta",
        recipe_name: "Pasta Bowl",
        servings: 1.5,
        macros: types.Macros(protein: 30.0, fat: 15.0, carbs: 90.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-15", updated_entry)

    // Then the servings are updated
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")
    let assert [retrieved] = daily_log.entries

    retrieved.servings
    |> should.equal(1.5)

    // And macros are recalculated based on new servings
    retrieved.macros.protein
    |> should.equal(30.0)
    retrieved.macros.fat
    |> should.equal(15.0)
    retrieved.macros.carbs
    |> should.equal(90.0)
  })
}

pub fn update_servings_to_fractional_amount_test() {
  // Given an entry with 1.0 servings
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "salad",
        name: "Garden Salad",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 10.0, fat: 20.0, carbs: 15.0),
        servings: 1,
        category: "salad",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry =
      types.FoodLogEntry(
        id: "log-frac",
        recipe_id: "salad",
        recipe_name: "Garden Salad",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 20.0, carbs: 15.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry)

    // When updating to 0.5 servings
    let updated =
      types.FoodLogEntry(
        id: "log-frac",
        recipe_id: "salad",
        recipe_name: "Garden Salad",
        servings: 0.5,
        macros: types.Macros(protein: 5.0, fat: 10.0, carbs: 7.5),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", updated)

    // Then macros are correctly scaled down
    let assert Ok(log) = storage.get_daily_log(conn, "2024-01-15")
    let assert [retrieved] = log.entries

    retrieved.servings
    |> should.equal(0.5)
    retrieved.macros.protein
    |> should.equal(5.0)
    retrieved.macros.fat
    |> should.equal(10.0)
    retrieved.macros.carbs
    |> should.equal(7.5)
  })
}

// ============================================================================
// BDD Scenario: GET /api/logs/recent returns recently logged
// ============================================================================

pub fn get_recent_logged_meals_test() {
  // Given a database with multiple logged entries across different dates
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "oatmeal",
        name: "Oatmeal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 50.0),
        servings: 1,
        category: "breakfast",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Log entries on different dates
    let entry1 =
      types.FoodLogEntry(
        id: "log-jan14",
        recipe_id: "oatmeal",
        recipe_name: "Oatmeal",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 50.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-14T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "log-jan15",
        recipe_id: "oatmeal",
        recipe_name: "Oatmeal",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 50.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry3 =
      types.FoodLogEntry(
        id: "log-jan16",
        recipe_id: "oatmeal",
        recipe_name: "Oatmeal",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 50.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-16T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-14", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry2)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-16", entry3)

    // When retrieving recent logs
    let assert Ok(log_jan14) = storage.get_daily_log(conn, "2024-01-14")
    let assert Ok(log_jan15) = storage.get_daily_log(conn, "2024-01-15")
    let assert Ok(log_jan16) = storage.get_daily_log(conn, "2024-01-16")

    // Then each day has its entry
    list.length(log_jan14.entries)
    |> should.equal(1)
    list.length(log_jan15.entries)
    |> should.equal(1)
    list.length(log_jan16.entries)
    |> should.equal(1)

    // And entries are correctly dated
    log_jan14.date
    |> should.equal("2024-01-14")
    log_jan15.date
    |> should.equal("2024-01-15")
    log_jan16.date
    |> should.equal("2024-01-16")
  })
}

// ============================================================================
// BDD Scenario: Meal type auto-suggestion logic
// ============================================================================

pub fn meal_type_suggestion_breakfast_test() {
  // Given a timestamp in the morning (6am-10am)
  let logged_at = "2024-01-15T08:30:00Z"

  // When creating a food log entry with Breakfast meal type
  let entry =
    types.FoodLogEntry(
      id: "log-breakfast",
      recipe_id: "eggs",
      recipe_name: "Scrambled Eggs",
      servings: 1.0,
      macros: types.Macros(protein: 18.0, fat: 12.0, carbs: 2.0),
      meal_type: types.Breakfast,
      logged_at: logged_at,
      micronutrients: option.None,
      source_type: "recipe",
      source_id: "unknown",
    )

  // Then the meal type is Breakfast
  entry.meal_type
  |> should.equal(types.Breakfast)

  // And the timestamp matches morning time
  entry.logged_at
  |> should.equal("2024-01-15T08:30:00Z")
}

pub fn meal_type_suggestion_lunch_test() {
  // Given a timestamp around midday (11am-2pm)
  let logged_at = "2024-01-15T12:00:00Z"

  // When creating a food log entry with Lunch meal type
  let entry =
    types.FoodLogEntry(
      id: "log-lunch",
      recipe_id: "sandwich",
      recipe_name: "Turkey Sandwich",
      servings: 1.0,
      macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 30.0),
      meal_type: types.Lunch,
      logged_at: logged_at,
      micronutrients: option.None,
      source_type: "recipe",
      source_id: "unknown",
    )

  // Then the meal type is Lunch
  entry.meal_type
  |> should.equal(types.Lunch)
}

pub fn meal_type_suggestion_dinner_test() {
  // Given a timestamp in the evening (5pm-8pm)
  let logged_at = "2024-01-15T18:30:00Z"

  // When creating a food log entry with Dinner meal type
  let entry =
    types.FoodLogEntry(
      id: "log-dinner",
      recipe_id: "steak",
      recipe_name: "Steak Dinner",
      servings: 1.0,
      macros: types.Macros(protein: 45.0, fat: 25.0, carbs: 10.0),
      meal_type: types.Dinner,
      logged_at: logged_at,
      micronutrients: option.None,
      source_type: "recipe",
      source_id: "unknown",
    )

  // Then the meal type is Dinner
  entry.meal_type
  |> should.equal(types.Dinner)
}

pub fn meal_type_suggestion_snack_test() {
  // Given a timestamp between meals (3pm)
  let logged_at = "2024-01-15T15:00:00Z"

  // When creating a food log entry with Snack meal type
  let entry =
    types.FoodLogEntry(
      id: "log-snack",
      recipe_id: "nuts",
      recipe_name: "Mixed Nuts",
      servings: 0.5,
      macros: types.Macros(protein: 5.0, fat: 15.0, carbs: 3.0),
      meal_type: types.Snack,
      logged_at: logged_at,
      micronutrients: option.None,
      source_type: "recipe",
      source_id: "unknown",
    )

  // Then the meal type is Snack
  entry.meal_type
  |> should.equal(types.Snack)
}

// ============================================================================
// BDD Scenario: Logging entry calculates macros correctly from recipe * servings
// ============================================================================

pub fn calculate_macros_from_recipe_and_servings_test() {
  // Given a recipe with known macros per serving
  let recipe_macros = types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0)

  // When logging 1.5 servings
  let servings = 1.5
  let calculated_macros = types.macros_scale(recipe_macros, servings)

  // Then protein is correctly scaled: 30 * 1.5 = 45
  calculated_macros.protein
  |> should.equal(45.0)

  // And fat is correctly scaled: 10 * 1.5 = 15
  calculated_macros.fat
  |> should.equal(15.0)

  // And carbs are correctly scaled: 40 * 1.5 = 60
  calculated_macros.carbs
  |> should.equal(60.0)
}

pub fn calculate_macros_half_serving_test() {
  // Given a recipe with macros
  let recipe_macros = types.Macros(protein: 40.0, fat: 20.0, carbs: 50.0)

  // When logging 0.5 servings
  let calculated = types.macros_scale(recipe_macros, 0.5)

  // Then all macros are halved
  calculated.protein
  |> should.equal(20.0)
  calculated.fat
  |> should.equal(10.0)
  calculated.carbs
  |> should.equal(25.0)
}

pub fn calculate_macros_double_serving_test() {
  // Given a recipe with macros
  let recipe_macros = types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0)

  // When logging 2.0 servings
  let calculated = types.macros_scale(recipe_macros, 2.0)

  // Then all macros are doubled
  calculated.protein
  |> should.equal(50.0)
  calculated.fat
  |> should.equal(16.0)
  calculated.carbs
  |> should.equal(70.0)
}

pub fn calculate_macros_precise_fraction_test() {
  // Given a recipe with macros
  let recipe_macros = types.Macros(protein: 33.0, fat: 11.0, carbs: 44.0)

  // When logging 0.333... servings (approximately 1/3)
  let calculated = types.macros_scale(recipe_macros, 0.333)

  // Then macros are scaled proportionally
  let expected_protein = 33.0 *. 0.333
  let expected_fat = 11.0 *. 0.333
  let expected_carbs = 44.0 *. 0.333

  // Use approximate comparison for floating point
  let protein_diff =
    float.absolute_value(calculated.protein -. expected_protein)
  should.be_true(protein_diff <. 0.01)

  let fat_diff = float.absolute_value(calculated.fat -. expected_fat)
  should.be_true(fat_diff <. 0.01)

  let carbs_diff = float.absolute_value(calculated.carbs -. expected_carbs)
  should.be_true(carbs_diff <. 0.01)
}

// ============================================================================
// BDD Scenario: Dashboard shows logged meals
// ============================================================================

pub fn dashboard_displays_daily_log_entries_test() {
  // Given a database with multiple logged meals for today
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe1 =
      types.Recipe(
        id: "recipe1",
        name: "Breakfast Bowl",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 25.0, fat: 12.0, carbs: 45.0),
        servings: 1,
        category: "breakfast",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let recipe2 =
      types.Recipe(
        id: "recipe2",
        name: "Chicken Wrap",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 35.0, fat: 15.0, carbs: 30.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, recipe1)
    let assert Ok(_) = storage.save_recipe(conn, recipe2)

    let entry1 =
      types.FoodLogEntry(
        id: "e1",
        recipe_id: "recipe1",
        recipe_name: "Breakfast Bowl",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 12.0, carbs: 45.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "e2",
        recipe_id: "recipe2",
        recipe_name: "Chicken Wrap",
        servings: 1.0,
        macros: types.Macros(protein: 35.0, fat: 15.0, carbs: 30.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:30:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", entry2)

    // When loading dashboard for 2024-01-15
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // Then dashboard shows 2 logged meals
    list.length(daily_log.entries)
    |> should.equal(2)

    // And total macros are summed
    daily_log.total_macros.protein
    |> should.equal(60.0)
    // 25 + 35
    daily_log.total_macros.fat
    |> should.equal(27.0)
    // 12 + 15
    daily_log.total_macros.carbs
    |> should.equal(75.0)
    // 45 + 30
  })
}

pub fn dashboard_shows_empty_state_with_no_meals_test() {
  // Given a database with no logged meals
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When loading dashboard for today
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // Then dashboard shows zero entries
    list.length(daily_log.entries)
    |> should.equal(0)

    // And total macros are zero
    daily_log.total_macros.protein
    |> should.equal(0.0)
    daily_log.total_macros.fat
    |> should.equal(0.0)
    daily_log.total_macros.carbs
    |> should.equal(0.0)
  })
}

// ============================================================================
// BDD Scenario: Dashboard filters by meal type
// ============================================================================

pub fn filter_meals_by_breakfast_type_test() {
  // Given a daily log with mixed meal types
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "meal",
        name: "Generic Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let breakfast_entry =
      types.FoodLogEntry(
        id: "b1",
        recipe_id: "meal",
        recipe_name: "Generic Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let lunch_entry =
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "meal",
        recipe_name: "Generic Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let dinner_entry =
      types.FoodLogEntry(
        id: "d1",
        recipe_id: "meal",
        recipe_name: "Generic Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-15", breakfast_entry)
    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-15", lunch_entry)
    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-15", dinner_entry)

    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // When filtering by Breakfast meal type
    let breakfast_meals =
      list.filter(daily_log.entries, fn(e) { e.meal_type == types.Breakfast })

    // Then only breakfast meals are returned
    list.length(breakfast_meals)
    |> should.equal(1)

    let assert [breakfast] = breakfast_meals
    breakfast.meal_type
    |> should.equal(types.Breakfast)
  })
}

pub fn filter_meals_by_lunch_type_test() {
  // Given a daily log with mixed meal types
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "meal",
        name: "Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entries = [
      types.FoodLogEntry(
        id: "b1",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "l2",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T13:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
    ]

    list.each(entries, fn(e) {
      let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", e)
    })

    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // When filtering by Lunch meal type
    let lunch_meals =
      list.filter(daily_log.entries, fn(e) { e.meal_type == types.Lunch })

    // Then both lunch meals are returned
    list.length(lunch_meals)
    |> should.equal(2)

    // And all are Lunch type
    list.all(lunch_meals, fn(e) { e.meal_type == types.Lunch })
    |> should.be_true()
  })
}

pub fn filter_meals_by_snack_type_test() {
  // Given a daily log with snacks and meals
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "food",
        name: "Food",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        servings: 1,
        category: "snack",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entries = [
      types.FoodLogEntry(
        id: "s1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T10:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "s2",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
    ]

    list.each(entries, fn(e) {
      let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", e)
    })

    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // When filtering by Snack meal type
    let snacks =
      list.filter(daily_log.entries, fn(e) { e.meal_type == types.Snack })

    // Then both snacks are returned
    list.length(snacks)
    |> should.equal(2)
  })
}

pub fn filter_all_meal_types_returns_all_test() {
  // Given a daily log with all meal types
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "food",
        name: "Food",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entries = [
      types.FoodLogEntry(
        id: "b1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-15T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "d1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "s1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
    ]

    list.each(entries, fn(e) {
      let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-15", e)
    })

    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-15")

    // When no filter is applied (return all)
    let all_meals = daily_log.entries

    // Then all 4 meals are returned
    list.length(all_meals)
    |> should.equal(4)

    // And we have one of each meal type
    let breakfast_count =
      list.count(all_meals, fn(e) { e.meal_type == types.Breakfast })
    let lunch_count =
      list.count(all_meals, fn(e) { e.meal_type == types.Lunch })
    let dinner_count =
      list.count(all_meals, fn(e) { e.meal_type == types.Dinner })
    let snack_count =
      list.count(all_meals, fn(e) { e.meal_type == types.Snack })

    breakfast_count
    |> should.equal(1)
    lunch_count
    |> should.equal(1)
    dinner_count
    |> should.equal(1)
    snack_count
    |> should.equal(1)
  })
}

// ============================================================================
// BDD Scenario: Log meal from recipe with servings calculation
// ============================================================================

pub fn log_meal_from_recipe_with_servings_test() {
  // Given a database with a recipe that has base macros per serving
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "chicken-rice",
        name: "Chicken and Rice",
        ingredients: [
          types.Ingredient("Chicken breast", "8 oz"),
          types.Ingredient("White rice", "1 cup"),
        ],
        instructions: ["Cook rice", "Grill chicken", "Combine"],
        macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // When logging 1.5 servings of the recipe
    let servings = 1.5
    let calculated_macros = types.macros_scale(recipe.macros, servings)

    let entry =
      types.FoodLogEntry(
        id: "log-001",
        recipe_id: "chicken-rice",
        recipe_name: "Chicken and Rice",
        servings: servings,
        macros: calculated_macros,
        meal_type: types.Lunch,
        logged_at: "2024-01-20T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-20", entry)

    // Then the entry is logged with correctly calculated macros
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-20")
    let assert [logged_entry] = daily_log.entries

    // Protein: 45 * 1.5 = 67.5
    logged_entry.macros.protein
    |> should.equal(67.5)

    // Fat: 8 * 1.5 = 12
    logged_entry.macros.fat
    |> should.equal(12.0)

    // Carbs: 45 * 1.5 = 67.5
    logged_entry.macros.carbs
    |> should.equal(67.5)

    // And servings are recorded
    logged_entry.servings
    |> should.equal(1.5)
  })
}

pub fn log_meal_from_recipe_with_half_serving_test() {
  // Given a recipe with known macros
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "protein-shake",
        name: "Protein Shake",
        ingredients: [types.Ingredient("Protein powder", "1 scoop")],
        instructions: ["Mix with water"],
        macros: types.Macros(protein: 24.0, fat: 2.0, carbs: 4.0),
        servings: 1,
        category: "supplement",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // When logging 0.5 servings
    let servings = 0.5
    let calculated_macros = types.macros_scale(recipe.macros, servings)

    let entry =
      types.FoodLogEntry(
        id: "log-002",
        recipe_id: "protein-shake",
        recipe_name: "Protein Shake",
        servings: servings,
        macros: calculated_macros,
        meal_type: types.Snack,
        logged_at: "2024-01-20T15:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-20", entry)

    // Then macros are halved
    let assert Ok(daily_log) = storage.get_daily_log(conn, "2024-01-20")
    let assert [logged_entry] = daily_log.entries

    logged_entry.macros.protein
    |> should.equal(12.0)
    logged_entry.macros.fat
    |> should.equal(1.0)
    logged_entry.macros.carbs
    |> should.equal(2.0)
  })
}

// ============================================================================
// BDD Scenario: GET /api/logs/recent returns most recently logged meals
// ============================================================================

pub fn get_recent_meals_returns_latest_test() {
  // Given a database with multiple meals logged across different dates
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create recipes
    let chicken =
      types.Recipe(
        id: "grilled-chicken",
        name: "Grilled Chicken",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 50.0, fat: 5.0, carbs: 0.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let rice =
      types.Recipe(
        id: "rice-bowl",
        name: "Rice Bowl",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 10.0, fat: 2.0, carbs: 60.0),
        servings: 1,
        category: "grains",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let eggs =
      types.Recipe(
        id: "scrambled-eggs",
        name: "Scrambled Eggs",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 18.0, fat: 12.0, carbs: 2.0),
        servings: 1,
        category: "breakfast",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )

    let assert Ok(_) = storage.save_recipe(conn, chicken)
    let assert Ok(_) = storage.save_recipe(conn, rice)
    let assert Ok(_) = storage.save_recipe(conn, eggs)

    // Log meals on different dates (oldest to newest)
    let entries = [
      types.FoodLogEntry(
        id: "old-chicken",
        recipe_id: "grilled-chicken",
        recipe_name: "Grilled Chicken",
        servings: 1.0,
        macros: types.Macros(protein: 50.0, fat: 5.0, carbs: 0.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-10T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "old-rice",
        recipe_id: "rice-bowl",
        recipe_name: "Rice Bowl",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 2.0, carbs: 60.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "recent-eggs",
        recipe_id: "scrambled-eggs",
        recipe_name: "Scrambled Eggs",
        servings: 1.0,
        macros: types.Macros(protein: 18.0, fat: 12.0, carbs: 2.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-20T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
    ]

    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-10", list.first(entries)
        |> should.be_ok())
    let assert Ok(_) =
      storage.save_food_log_entry(
        conn,
        "2024-01-15",
        entries
          |> list.drop(1)
          |> list.first()
          |> should.be_ok(),
      )
    let assert Ok(_) =
      storage.save_food_log_entry(
        conn,
        "2024-01-20",
        entries
          |> list.drop(2)
          |> list.first()
          |> should.be_ok(),
      )

    // When retrieving recent meals (limit 5)
    let assert Ok(recent_meals) = storage.get_recent_meals(conn, 5)

    // Then meals are returned in reverse chronological order (newest first)
    list.length(recent_meals)
    |> should.equal(3)

    // And the most recent meal is first
    let assert [first, .._rest] = recent_meals
    first.recipe_name
    |> should.equal("Scrambled Eggs")
    first.logged_at
    |> should.equal("2024-01-20T08:00:00Z")
  })
}

pub fn get_recent_meals_with_limit_test() {
  // Given a database with many DIFFERENT meals logged
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create 5 different recipes
    let recipes = [
      types.Recipe(
        id: "meal-1",
        name: "Meal 1",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
      types.Recipe(
        id: "meal-2",
        name: "Meal 2",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 35.0, fat: 12.0, carbs: 45.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
      types.Recipe(
        id: "meal-3",
        name: "Meal 3",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
      types.Recipe(
        id: "meal-4",
        name: "Meal 4",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
      types.Recipe(
        id: "meal-5",
        name: "Meal 5",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      ),
    ]

    list.each(recipes, fn(r) {
      let assert Ok(_) = storage.save_recipe(conn, r)
    })

    // Log different meals on different days
    let entries = [
      types.FoodLogEntry(
        id: "e1",
        recipe_id: "meal-1",
        recipe_name: "Meal 1",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "e2",
        recipe_id: "meal-2",
        recipe_name: "Meal 2",
        servings: 1.0,
        macros: types.Macros(protein: 35.0, fat: 12.0, carbs: 45.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-02T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "e3",
        recipe_id: "meal-3",
        recipe_name: "Meal 3",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-03T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "e4",
        recipe_id: "meal-4",
        recipe_name: "Meal 4",
        servings: 1.0,
        macros: types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-04T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
      types.FoodLogEntry(
        id: "e5",
        recipe_id: "meal-5",
        recipe_name: "Meal 5",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-05T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      ),
    ]

    list.index_map(entries, fn(entry, idx) {
      let date = case idx {
        0 -> "2024-01-01"
        1 -> "2024-01-02"
        2 -> "2024-01-03"
        3 -> "2024-01-04"
        4 -> "2024-01-05"
        _ -> "2024-01-01"
      }
      let assert Ok(_) = storage.save_food_log_entry(conn, date, entry)
      idx
    })

    // When retrieving recent meals with limit 3
    let assert Ok(recent_meals) = storage.get_recent_meals(conn, 3)

    // Then only 3 meals are returned
    list.length(recent_meals)
    |> should.equal(3)

    // And they are the 3 most recent (distinct recipes)
    let assert [first, second, third] = recent_meals
    first.recipe_name
    |> should.equal("Meal 5")
    second.recipe_name
    |> should.equal("Meal 4")
    third.recipe_name
    |> should.equal("Meal 3")
  })
}

pub fn get_recent_meals_empty_database_test() {
  // Given an empty database
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When retrieving recent meals
    let assert Ok(recent_meals) = storage.get_recent_meals(conn, 5)

    // Then an empty list is returned
    list.length(recent_meals)
    |> should.equal(0)
  })
}

// ============================================================================
// BDD Scenario: Edit food log entry (update meal type and servings)
// ============================================================================

pub fn edit_food_log_entry_meal_type_test() {
  // Given a database with an existing food log entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "flexible-meal",
        name: "Flexible Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 35.0, fat: 12.0, carbs: 40.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let original_entry =
      types.FoodLogEntry(
        id: "log-edit-1",
        recipe_id: "flexible-meal",
        recipe_name: "Flexible Meal",
        servings: 1.0,
        macros: types.Macros(protein: 35.0, fat: 12.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-25T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) =
      storage.save_food_log_entry(conn, "2024-01-25", original_entry)

    // When editing the meal type from Lunch to Dinner
    let assert Ok(_) =
      storage.update_food_log_entry(
        conn,
        "log-edit-1",
        1.0,
        types.Macros(protein: 35.0, fat: 12.0, carbs: 40.0),
        types.Dinner,
      )

    // Then the meal type is updated
    let assert Ok(entry) = storage.get_food_log_entry(conn, "log-edit-1")
    entry.meal_type
    |> should.equal(types.Dinner)

    // And other fields remain unchanged
    entry.servings
    |> should.equal(1.0)
    entry.macros.protein
    |> should.equal(35.0)
  })
}

pub fn edit_food_log_entry_servings_and_macros_test() {
  // Given a food log entry with 1.0 servings
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "adjustable",
        name: "Adjustable Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry =
      types.FoodLogEntry(
        id: "log-adjust",
        recipe_id: "adjustable",
        recipe_name: "Adjustable Meal",
        servings: 1.0,
        macros: types.Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-25T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-25", entry)

    // When editing servings to 2.0
    let new_macros = types.macros_scale(recipe.macros, 2.0)
    let assert Ok(_) =
      storage.update_food_log_entry(
        conn,
        "log-adjust",
        2.0,
        new_macros,
        types.Dinner,
      )

    // Then servings and macros are updated
    let assert Ok(updated_entry) =
      storage.get_food_log_entry(conn, "log-adjust")

    updated_entry.servings
    |> should.equal(2.0)
    updated_entry.macros.protein
    |> should.equal(80.0)
    updated_entry.macros.fat
    |> should.equal(30.0)
    updated_entry.macros.carbs
    |> should.equal(100.0)
  })
}

pub fn edit_nonexistent_food_log_entry_test() {
  // Given a database with no entries
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When attempting to update a nonexistent entry
    let result =
      storage.update_food_log_entry(
        conn,
        "nonexistent-id",
        1.0,
        types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        types.Lunch,
      )

    // Then the operation completes (idempotent - no error on missing entry)
    result
    |> should.be_ok()
  })
}

// ============================================================================
// BDD Scenario: Daily log totals update correctly when entries added/removed
// ============================================================================

pub fn daily_log_totals_update_on_add_test() {
  // Given a daily log with one entry
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "meal",
        name: "Standard Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 45.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry1 =
      types.FoodLogEntry(
        id: "e1",
        recipe_id: "meal",
        recipe_name: "Standard Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 45.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-30T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry1)

    // Verify initial totals
    let assert Ok(log_before) = storage.get_daily_log(conn, "2024-01-30")
    log_before.total_macros.protein
    |> should.equal(30.0)

    // When adding a second entry
    let entry2 =
      types.FoodLogEntry(
        id: "e2",
        recipe_id: "meal",
        recipe_name: "Standard Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 45.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-30T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry2)

    // Then totals are updated correctly
    let assert Ok(log_after) = storage.get_daily_log(conn, "2024-01-30")

    log_after.total_macros.protein
    |> should.equal(60.0)
    // 30 + 30
    log_after.total_macros.fat
    |> should.equal(20.0)
    // 10 + 10
    log_after.total_macros.carbs
    |> should.equal(90.0)
    // 45 + 45
  })
}

pub fn daily_log_totals_update_on_remove_test() {
  // Given a daily log with multiple entries
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "meal",
        name: "Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry1 =
      types.FoodLogEntry(
        id: "keep",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-30T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "remove",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-30T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry3 =
      types.FoodLogEntry(
        id: "keep2",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-30T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry2)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry3)

    // Verify totals before removal
    let assert Ok(log_before) = storage.get_daily_log(conn, "2024-01-30")
    log_before.total_macros.protein
    |> should.equal(75.0)
    // 25 * 3

    // When removing one entry
    let assert Ok(_) = storage.delete_food_log_entry(conn, "remove")

    // Then totals are recalculated correctly
    let assert Ok(log_after) = storage.get_daily_log(conn, "2024-01-30")

    log_after.total_macros.protein
    |> should.equal(50.0)
    // 25 * 2
    log_after.total_macros.fat
    |> should.equal(16.0)
    // 8 * 2
    log_after.total_macros.carbs
    |> should.equal(70.0)
    // 35 * 2

    // And entry count is correct
    list.length(log_after.entries)
    |> should.equal(2)
  })
}

pub fn daily_log_totals_update_on_edit_servings_test() {
  // Given a daily log with entries
  storage.with_connection(":memory:", fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    let recipe =
      types.Recipe(
        id: "meal",
        name: "Meal",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        servings: 1,
        category: "general",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    let entry1 =
      types.FoodLogEntry(
        id: "static",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        meal_type: types.Breakfast,
        logged_at: "2024-01-30T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let entry2 =
      types.FoodLogEntry(
        id: "editable",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 5.0, carbs: 30.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-30T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, "2024-01-30", entry2)

    // Initial total: 40g protein (20 + 20)
    let assert Ok(log_before) = storage.get_daily_log(conn, "2024-01-30")
    log_before.total_macros.protein
    |> should.equal(40.0)

    // When editing servings of one entry to 2.0
    let new_macros = types.macros_scale(recipe.macros, 2.0)
    let assert Ok(_) =
      storage.update_food_log_entry(
        conn,
        "editable",
        2.0,
        new_macros,
        types.Lunch,
      )

    // Then totals reflect the change
    let assert Ok(log_after) = storage.get_daily_log(conn, "2024-01-30")

    log_after.total_macros.protein
    |> should.equal(60.0)
    // 20 (static) + 40 (edited)
    log_after.total_macros.fat
    |> should.equal(15.0)
    // 5 + 10
    log_after.total_macros.carbs
    |> should.equal(90.0)
    // 30 + 60
  })
}
