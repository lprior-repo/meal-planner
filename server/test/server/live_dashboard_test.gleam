//// TDD Tests for Live Dashboard Integration (meal-planner-8rh)
//// Following BDD Red-Green-Refactor with fractal loop discipline

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
// Capability 1: Load Daily Log from Storage
// ============================================================================

// Behavior: GIVEN dashboard page request WHEN loading THEN fetch today's food log from SQLite
pub fn load_todays_food_log_from_storage_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create a test recipe
    let recipe =
      types.Recipe(
        id: "chicken-rice",
        name: "Chicken and Rice",
        ingredients: [types.Ingredient(name: "Chicken", quantity: "8 oz")],
        instructions: ["Cook"],
        macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
        servings: 1,
        category: "chicken",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Log a meal for today
    let today = "2024-12-01"
    let entry =
      types.FoodLogEntry(
        id: "log-today-1",
        recipe_id: "chicken-rice",
        recipe_name: "Chicken and Rice",
        servings: 1.0,
        macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
        meal_type: types.Lunch,
        logged_at: "2024-12-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, today, entry)

    // When loading dashboard data for today
    let assert Ok(daily_log) = storage.get_daily_log(conn, today)

    // Then today's food log is fetched from storage
    daily_log.date
    |> should.equal(today)

    list.length(daily_log.entries)
    |> should.equal(1)

    let assert [loaded_entry] = daily_log.entries
    loaded_entry.recipe_name
    |> should.equal("Chicken and Rice")

    loaded_entry.macros.protein
    |> should.equal(45.0)
  })
}

// Behavior: GIVEN date parameter WHEN provided THEN load that day's food log
pub fn load_specific_date_food_log_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipe
    let recipe =
      types.Recipe(
        id: "beef-potatoes",
        name: "Beef and Potatoes",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
        servings: 1,
        category: "beef",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe)

    // Log meals on different dates
    let yesterday = "2024-11-30"
    let today = "2024-12-01"

    let entry_yesterday =
      types.FoodLogEntry(
        id: "log-yesterday",
        recipe_id: "beef-potatoes",
        recipe_name: "Beef and Potatoes",
        servings: 1.0,
        macros: types.Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
        meal_type: types.Dinner,
        logged_at: "2024-11-30T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) =
      storage.save_food_log_entry(conn, yesterday, entry_yesterday)

    let entry_today =
      types.FoodLogEntry(
        id: "log-today",
        recipe_id: "beef-potatoes",
        recipe_name: "Beef and Potatoes",
        servings: 2.0,
        macros: types.Macros(protein: 80.0, fat: 40.0, carbs: 70.0),
        meal_type: types.Lunch,
        logged_at: "2024-12-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let assert Ok(_) = storage.save_food_log_entry(conn, today, entry_today)

    // When loading yesterday's log specifically
    let assert Ok(yesterday_log) = storage.get_daily_log(conn, yesterday)

    // Then only yesterday's entries are returned
    yesterday_log.date
    |> should.equal(yesterday)

    list.length(yesterday_log.entries)
    |> should.equal(1)

    let assert [y_entry] = yesterday_log.entries
    y_entry.servings
    |> should.equal(1.0)

    // And today's log has different entries
    let assert Ok(today_log) = storage.get_daily_log(conn, today)
    today_log.date
    |> should.equal(today)

    let assert [t_entry] = today_log.entries
    t_entry.servings
    |> should.equal(2.0)
  })
}

// Behavior: GIVEN no entries for date WHEN loading THEN return empty macros (0, 0, 0)
pub fn empty_date_returns_zero_macros_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // When loading a date with no entries
    let empty_date = "2024-01-01"
    let assert Ok(daily_log) = storage.get_daily_log(conn, empty_date)

    // Then return empty macros (0, 0, 0)
    daily_log.date
    |> should.equal(empty_date)

    list.length(daily_log.entries)
    |> should.equal(0)

    daily_log.total_macros.protein
    |> should.equal(0.0)

    daily_log.total_macros.fat
    |> should.equal(0.0)

    daily_log.total_macros.carbs
    |> should.equal(0.0)
  })
}

// ============================================================================
// Capability 2: Calculate Real-Time Progress
// ============================================================================

// Behavior: GIVEN daily log entries WHEN displaying THEN sum all entry macros for totals
pub fn sum_all_entry_macros_for_totals_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipes
    let recipe1 =
      types.Recipe(
        id: "recipe-1",
        name: "Meal 1",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let recipe2 =
      types.Recipe(
        id: "recipe-2",
        name: "Meal 2",
        ingredients: [],
        instructions: [],
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        servings: 1,
        category: "test",
        fodmap_level: types.Low,
        vertical_compliant: True,
      )
    let assert Ok(_) = storage.save_recipe(conn, recipe1)
    let assert Ok(_) = storage.save_recipe(conn, recipe2)

    let date = "2024-12-01"

    // Log multiple meals
    let entry1 =
      types.FoodLogEntry(
        id: "log-1",
        recipe_id: "recipe-1",
        recipe_name: "Meal 1",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-12-01T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry2 =
      types.FoodLogEntry(
        id: "log-2",
        recipe_id: "recipe-2",
        recipe_name: "Meal 2",
        servings: 1.0,
        macros: types.Macros(protein: 25.0, fat: 8.0, carbs: 35.0),
        meal_type: types.Lunch,
        logged_at: "2024-12-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry3 =
      types.FoodLogEntry(
        id: "log-3",
        recipe_id: "recipe-1",
        recipe_name: "Meal 1",
        servings: 1.5,
        macros: types.Macros(protein: 45.0, fat: 15.0, carbs: 60.0),
        meal_type: types.Dinner,
        logged_at: "2024-12-01T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry2)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry3)

    // When loading daily log
    let assert Ok(daily_log) = storage.get_daily_log(conn, date)

    // Then total_macros should be sum of all entries
    // Protein: 30 + 25 + 45 = 100
    // Fat: 10 + 8 + 15 = 33
    // Carbs: 40 + 35 + 60 = 135
    daily_log.total_macros.protein
    |> should.equal(100.0)

    daily_log.total_macros.fat
    |> should.equal(33.0)

    daily_log.total_macros.carbs
    |> should.equal(135.0)
  })
}

// Behavior: GIVEN user profile WHEN calculating targets THEN use profile-based macro targets
pub fn use_profile_based_macro_targets_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create and save user profile
    let profile =
      types.UserProfile(
        id: "user-1",
        bodyweight: 180.0,
        activity_level: types.Moderate,
        goal: types.Maintain,
        meals_per_day: 3,
      )
    let assert Ok(_) = storage.save_user_profile(conn, profile)

    // When loading profile
    let assert Ok(loaded_profile) = storage.get_user_profile(conn)

    // Then targets are calculated from profile
    let targets = types.daily_macro_targets(loaded_profile)

    // Moderate + Maintain = 0.9 multiplier for protein
    // Protein: 180 * 0.9 = 162g
    // Fat: 180 * 0.3 = 54g
    // Calories: 180 * 15 = 2700
    // Carbs: (2700 - 162*4 - 54*9) / 4 = 391.5g
    let rounded_protein = float_round(targets.protein)
    let rounded_fat = float_round(targets.fat)
    let rounded_carbs = float_round(targets.carbs)

    rounded_protein
    |> should.equal(162)

    rounded_fat
    |> should.equal(54)

    // Carbs should be around 391-392
    should.be_true(rounded_carbs >= 391 && rounded_carbs <= 392)
  })
}

// Behavior: GIVEN current vs target WHEN rendering THEN show accurate progress percentages
pub fn show_accurate_progress_percentages_test() {
  // Given current intake
  let current = types.Macros(protein: 81.0, fat: 27.0, carbs: 196.0)

  // And targets (180 lbs, moderate, maintain)
  let profile =
    types.UserProfile(
      id: "user-1",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )
  let targets = types.daily_macro_targets(profile)

  // When calculating progress
  let protein_pct =
    calculate_progress_percentage(current.protein, targets.protein)
  let fat_pct = calculate_progress_percentage(current.fat, targets.fat)
  let carbs_pct = calculate_progress_percentage(current.carbs, targets.carbs)

  // Then show accurate percentages
  // Protein: 81/162 = 50%
  // Fat: 27/54 = 50%
  // Carbs: 196/392 = 50%
  let rounded_protein_pct = float_round(protein_pct)
  let rounded_fat_pct = float_round(fat_pct)
  let rounded_carbs_pct = float_round(carbs_pct)

  rounded_protein_pct
  |> should.equal(50)

  rounded_fat_pct
  |> should.equal(50)

  rounded_carbs_pct
  |> should.equal(50)
}

// ============================================================================
// Capability 3: Display Today's Meals
// ============================================================================

// Behavior: GIVEN food log entries WHEN rendering THEN show meal cards with name, time, macros
pub fn entries_ordered_by_logged_at_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipe
    let recipe =
      types.Recipe(
        id: "test-meal",
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

    let date = "2024-12-01"

    // Add entries in non-chronological order
    let entry_dinner =
      types.FoodLogEntry(
        id: "log-dinner",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Dinner,
        logged_at: "2024-12-01T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry_breakfast =
      types.FoodLogEntry(
        id: "log-breakfast",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-12-01T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry_lunch =
      types.FoodLogEntry(
        id: "log-lunch",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-12-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    // Save in wrong order
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry_dinner)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry_breakfast)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry_lunch)

    // When loading
    let assert Ok(daily_log) = storage.get_daily_log(conn, date)

    // Then entries should be ordered by logged_at (earliest first)
    list.length(daily_log.entries)
    |> should.equal(3)

    let assert [first, second, third] = daily_log.entries

    first.meal_type
    |> should.equal(types.Breakfast)

    second.meal_type
    |> should.equal(types.Lunch)

    third.meal_type
    |> should.equal(types.Dinner)
  })
}

// Behavior: GIVEN entry WHEN deleting THEN remove from log and update totals
pub fn delete_entry_updates_totals_test() {
  let test_db = ":memory:"

  storage.with_connection(test_db, fn(conn) {
    let assert Ok(_) = storage.init_db(conn)

    // Create test recipe
    let recipe =
      types.Recipe(
        id: "test-meal",
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

    let date = "2024-12-01"

    // Add three entries
    let entry1 =
      types.FoodLogEntry(
        id: "log-1",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Breakfast,
        logged_at: "2024-12-01T08:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry2 =
      types.FoodLogEntry(
        id: "log-2",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Lunch,
        logged_at: "2024-12-01T12:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )
    let entry3 =
      types.FoodLogEntry(
        id: "log-3",
        recipe_id: "test-meal",
        recipe_name: "Test Meal",
        servings: 1.0,
        macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
        meal_type: types.Dinner,
        logged_at: "2024-12-01T18:00:00Z",
        micronutrients: option.None,
        source_type: "recipe",
        source_id: "unknown",
      )

    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry1)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry2)
    let assert Ok(_) = storage.save_food_log_entry(conn, date, entry3)

    // Verify initial totals (3 entries * 30/10/40 = 90/30/120)
    let assert Ok(log_before) = storage.get_daily_log(conn, date)
    log_before.total_macros.protein
    |> should.equal(90.0)
    log_before.total_macros.fat
    |> should.equal(30.0)
    log_before.total_macros.carbs
    |> should.equal(120.0)

    // When deleting one entry
    let assert Ok(_) = storage.delete_food_log_entry(conn, "log-2")

    // Then totals are updated (2 entries * 30/10/40 = 60/20/80)
    let assert Ok(log_after) = storage.get_daily_log(conn, date)

    list.length(log_after.entries)
    |> should.equal(2)

    log_after.total_macros.protein
    |> should.equal(60.0)

    log_after.total_macros.fat
    |> should.equal(20.0)

    log_after.total_macros.carbs
    |> should.equal(80.0)
  })
}

// ============================================================================
// Helper Functions
// ============================================================================

fn calculate_progress_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> current /. target *. 100.0
    False -> 0.0
  }
}

@external(erlang, "erlang", "round")
fn float_round(f: Float) -> Int
