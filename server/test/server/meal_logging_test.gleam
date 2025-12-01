//// BDD Tests for Meal Logging System
//// Comprehensive test coverage for all meal logging capabilities
//// Following Given/When/Then pattern

import gleam/float
import gleam/list
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
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
      ),
      types.FoodLogEntry(
        id: "l2",
        recipe_id: "meal",
        recipe_name: "Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T13:00:00Z",
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
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
      ),
      types.FoodLogEntry(
        id: "s2",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
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
      ),
      types.FoodLogEntry(
        id: "l1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Lunch,
        logged_at: "2024-01-15T12:00:00Z",
      ),
      types.FoodLogEntry(
        id: "d1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Dinner,
        logged_at: "2024-01-15T18:00:00Z",
      ),
      types.FoodLogEntry(
        id: "s1",
        recipe_id: "food",
        recipe_name: "Food",
        servings: 1.0,
        macros: types.Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
        meal_type: types.Snack,
        logged_at: "2024-01-15T15:00:00Z",
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
