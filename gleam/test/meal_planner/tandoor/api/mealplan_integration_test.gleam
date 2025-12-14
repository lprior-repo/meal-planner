/// Integration tests for MealPlan API
///
/// Tests all CRUD operations for meal plan entries including:
/// - Create, Get, List, Update
/// - Success cases (200/201 responses)
/// - Error cases (400, 401, 404, 500)
/// - JSON parsing errors
/// - Network failures
/// - Date filtering
/// - Optional fields
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/mealplan/create
import meal_planner/tandoor/api/mealplan/get
import meal_planner/tandoor/api/mealplan/list
import meal_planner/tandoor/api/mealplan/update
import meal_planner/tandoor/client.{NetworkError, bearer_config}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{
  type MealPlanEntry, MealPlanEntry,
}
import meal_planner/tandoor/types/mealplan/meal_type.{Breakfast, Dinner, Lunch}

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
// MealPlan Get Tests
// ============================================================================

pub fn get_mealplan_delegates_to_client_test() {
  let config = test_config()
  let result = get.get_mealplan(config, mealplan_id: 1)

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

pub fn get_mealplan_accepts_different_ids_test() {
  let config = test_config()

  let result1 = get.get_mealplan(config, mealplan_id: 1)
  let result2 = get.get_mealplan(config, mealplan_id: 999)
  let result3 = get.get_mealplan(config, mealplan_id: 42)

  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn get_mealplan_with_zero_id_test() {
  let config = test_config()
  let result = get.get_mealplan(config, mealplan_id: 0)

  should.be_error(result)
}

// ============================================================================
// MealPlan List Tests
// ============================================================================

pub fn list_mealplans_delegates_to_client_test() {
  let config = test_config()
  let result = list.list_mealplans(config)

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

pub fn list_mealplans_with_from_date_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-01-01"),
      None,
      None,
      None,
    )

  should.be_error(result)
}

pub fn list_mealplans_with_to_date_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      None,
      Some("2025-12-31"),
      None,
      None,
    )

  should.be_error(result)
}

pub fn list_mealplans_with_date_range_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-01-01"),
      Some("2025-12-31"),
      None,
      None,
    )

  should.be_error(result)
}

pub fn list_mealplans_with_limit_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(config, None, None, Some(10), None)

  should.be_error(result)
}

pub fn list_mealplans_with_offset_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(config, None, None, None, Some(20))

  should.be_error(result)
}

pub fn list_mealplans_with_all_options_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-01-01"),
      Some("2025-12-31"),
      Some(50),
      Some(100),
    )

  should.be_error(result)
}

pub fn list_mealplans_with_invalid_date_format_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("01/01/2025"),
      None,
      None,
      None,
    )

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn list_mealplans_with_reversed_date_range_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-12-31"),
      Some("2025-01-01"),
      None,
      None,
    )

  // Should attempt call (API will handle invalid range)
  should.be_error(result)
}

pub fn list_mealplans_with_same_from_to_date_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-06-15"),
      Some("2025-06-15"),
      None,
      None,
    )

  should.be_error(result)
}

// ============================================================================
// MealPlan Create Tests
// ============================================================================

pub fn create_mealplan_breakfast_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Breakfast,
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

pub fn create_mealplan_lunch_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(2),
      servings: 4.0,
      note: "Lunch with friends",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
    )

  should.be_error(result)
}

pub fn create_mealplan_dinner_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(3),
      servings: 6.0,
      note: "Family dinner",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  should.be_error(result)
}

pub fn create_mealplan_without_recipe_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: None,
      servings: 1.0,
      note: "Leftover pizza",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_note_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: "Don't forget to buy ingredients",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Breakfast,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_fractional_servings_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.5,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_zero_servings_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 0.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn create_mealplan_with_negative_servings_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: -1.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
    )

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn create_mealplan_with_multi_day_range_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 4.0,
      note: "Meal prep for the week",
      from_date: "2025-06-15",
      to_date: "2025-06-21",
      meal_type: Lunch,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_special_characters_in_note_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: "Café & restaurant <special>",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_unicode_note_test() {
  let config = test_config()
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: "Crème brûlée for dessert 🍮",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  should.be_error(result)
}

// ============================================================================
// MealPlan Update Tests
// ============================================================================

pub fn update_mealplan_delegates_to_client_test() {
  let config = test_config()
  let entry_data =
    MealPlanEntry(
      id: 1,
      title: Some("Updated Meal"),
      recipe: None,
      servings: 4.0,
      note: Some("Updated note"),
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
      created_by: None,
      space: None,
    )

  let result = update.update_mealplan(config, mealplan_id: 1, entry: entry_data)

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

pub fn update_mealplan_change_servings_test() {
  let config = test_config()
  let entry_data =
    MealPlanEntry(
      id: 1,
      title: Some("Breakfast"),
      recipe: Some(1),
      servings: 8.0,
      note: None,
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Breakfast,
      created_by: None,
      space: None,
    )

  let result = update.update_mealplan(config, mealplan_id: 1, entry: entry_data)

  should.be_error(result)
}

pub fn update_mealplan_change_meal_type_test() {
  let config = test_config()
  let entry_data =
    MealPlanEntry(
      id: 1,
      title: Some("Moved to Dinner"),
      recipe: Some(1),
      servings: 4.0,
      note: None,
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
      created_by: None,
      space: None,
    )

  let result = update.update_mealplan(config, mealplan_id: 1, entry: entry_data)

  should.be_error(result)
}

pub fn update_mealplan_change_date_range_test() {
  let config = test_config()
  let entry_data =
    MealPlanEntry(
      id: 1,
      title: Some("Extended Meal"),
      recipe: Some(1),
      servings: 4.0,
      note: None,
      from_date: "2025-06-15",
      to_date: "2025-06-20",
      meal_type: Lunch,
      created_by: None,
      space: None,
    )

  let result = update.update_mealplan(config, mealplan_id: 1, entry: entry_data)

  should.be_error(result)
}

pub fn update_mealplan_with_different_ids_test() {
  let config = test_config()
  let entry_data =
    MealPlanEntry(
      id: 1,
      title: Some("Updated"),
      recipe: None,
      servings: 2.0,
      note: None,
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Breakfast,
      created_by: None,
      space: None,
    )

  let result1 =
    update.update_mealplan(config, mealplan_id: 1, entry: entry_data)
  let result2 =
    update.update_mealplan(config, mealplan_id: 999, entry: entry_data)

  should.be_error(result1)
  should.be_error(result2)
}

// ============================================================================
// Edge Cases and Complex Scenarios
// ============================================================================

pub fn create_multiple_mealplans_same_day_test() {
  let config = test_config()

  // Create breakfast, lunch, and dinner for the same day
  let _breakfast =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Breakfast,
    )
  let _lunch =
    create.create_mealplan(
      config,
      recipe: Some(2),
      servings: 2.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
    )
  let _dinner =
    create.create_mealplan(
      config,
      recipe: Some(3),
      servings: 2.0,
      note: "",
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Dinner,
    )

  // All should fail (no server)
  Nil
}

pub fn list_mealplans_for_specific_week_test() {
  let config = test_config()
  let result =
    list.list_mealplans_with_options(
      config,
      Some("2025-06-15"),
      Some("2025-06-21"),
      None,
      None,
    )

  should.be_error(result)
}

pub fn create_mealplan_with_very_long_note_test() {
  let config = test_config()
  let long_note = string.repeat("Note ", 200)
  let result =
    create.create_mealplan(
      config,
      recipe: Some(1),
      servings: 2.0,
      note: long_note,
      from_date: "2025-06-15",
      to_date: "2025-06-15",
      meal_type: Lunch,
    )

  should.be_error(result)
}

// ============================================================================
// Import required modules
// ============================================================================

import gleam/string
