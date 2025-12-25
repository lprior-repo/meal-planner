//// TDD Tests for CLI diary command
////
//// RED PHASE: This test validates:
//// 1. Food entry formatting for display
//// 2. Nutrition calculation and aggregation
//// 3. Date string parsing to days since epoch

import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/diary/formatters
import meal_planner/cli/domains/diary/helpers
import meal_planner/cli/domains/diary/types as diary_types
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, FoodEntry, Breakfast, Snack, food_entry_id,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a sample food entry for testing
fn create_sample_entry(
  id_str: String,
  name: String,
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> FoodEntry {
  FoodEntry(
    food_entry_id: food_entry_id(id_str),
    food_entry_name: name,
    food_entry_description: "Sample description",
    food_id: "12345",
    serving_id: "1",
    number_of_units: 1.0,
    meal: Breakfast,
    date_int: 19_700,
    calories: calories,
    carbohydrate: carbs,
    protein: protein,
    fat: fat,
    saturated_fat: None,
    polyunsaturated_fat: None,
    monounsaturated_fat: None,
    cholesterol: None,
    sodium: None,
    potassium: None,
    fiber: None,
    sugar: None,
  )
}

// ============================================================================
// Food Entry Formatting Tests
// ============================================================================

/// Test: format_food_entry_row includes ID and name
pub fn format_food_entry_row_includes_id_and_name_test() {
  let entry =
    create_sample_entry("entry-123", "Chicken Salad", 350.0, 40.0, 10.0, 15.0)
  let output = formatters.format_food_entry_row(entry)

  string.contains(output, "entry-123")
  |> should.be_true()

  string.contains(output, "Chicken Salad")
  |> should.be_true()
}

/// Test: format_food_entry_row includes nutrition values
pub fn format_food_entry_row_includes_nutrition_test() {
  let entry = create_sample_entry("entry-456", "Pasta", 450.0, 15.0, 75.0, 5.0)
  let output = formatters.format_food_entry_row(entry)

  // Check for calorie value (rounded to 1 decimal)
  string.contains(output, "450")
  |> should.be_true()

  // Check for macro labels
  string.contains(output, "cal")
  |> should.be_true()

  string.contains(output, "P:")
  |> should.be_true()

  string.contains(output, "C:")
  |> should.be_true()

  string.contains(output, "F:")
  |> should.be_true()
}

/// Test: format_food_entry_row formats floats correctly
pub fn format_food_entry_row_formats_floats_test() {
  let entry = create_sample_entry("entry-789", "Apple", 95.5, 0.5, 25.3, 0.3)
  let output = formatters.format_food_entry_row(entry)

  // Values should be formatted to 1 decimal place
  string.contains(output, "95.5")
  |> should.be_true()
}

// ============================================================================
// Nutrition Calculation Tests
// ============================================================================

/// Test: calculate_day_nutrition sums empty list
pub fn calculate_day_nutrition_empty_test() {
  let nutrition = diary_types.calculate_day_nutrition([])

  nutrition.calories
  |> should.equal(0.0)

  nutrition.protein
  |> should.equal(0.0)

  nutrition.carbohydrates
  |> should.equal(0.0)

  nutrition.fat
  |> should.equal(0.0)
}

/// Test: calculate_day_nutrition sums single entry
pub fn calculate_day_nutrition_single_entry_test() {
  let entry =
    create_sample_entry("entry-1", "Breakfast", 400.0, 20.0, 50.0, 15.0)
  let nutrition = diary_types.calculate_day_nutrition([entry])

  nutrition.calories
  |> should.equal(400.0)

  nutrition.protein
  |> should.equal(20.0)

  nutrition.carbohydrates
  |> should.equal(50.0)

  nutrition.fat
  |> should.equal(15.0)
}

/// Test: calculate_day_nutrition sums multiple entries
pub fn calculate_day_nutrition_multiple_entries_test() {
  let breakfast =
    create_sample_entry("entry-1", "Breakfast", 400.0, 20.0, 50.0, 15.0)
  let lunch = create_sample_entry("entry-2", "Lunch", 650.0, 35.0, 70.0, 25.0)
  let snack = create_sample_entry("entry-3", "Snack", 150.0, 5.0, 20.0, 5.0)

  let nutrition = diary_types.calculate_day_nutrition([breakfast, lunch, snack])

  nutrition.calories
  |> should.equal(1200.0)

  nutrition.protein
  |> should.equal(60.0)

  nutrition.carbohydrates
  |> should.equal(140.0)

  nutrition.fat
  |> should.equal(45.0)
}

// ============================================================================
// Nutrition Summary Formatting Tests
// ============================================================================

/// Test: format_nutrition_summary includes all macros
pub fn format_nutrition_summary_includes_all_macros_test() {
  let nutrition =
    diary_types.DayNutrition(
      calories: 1200.0,
      protein: 60.0,
      carbohydrates: 140.0,
      fat: 45.0,
    )
  let output = formatters.format_nutrition_summary(nutrition)

  string.contains(output, "DailyTotal")
  |> should.be_true()

  string.contains(output, "1200")
  |> should.be_true()

  string.contains(output, "60")
  |> should.be_true()

  string.contains(output, "140")
  |> should.be_true()

  string.contains(output, "45")
  |> should.be_true()
}

/// Test: format_nutrition_summary formats floats correctly
pub fn format_nutrition_summary_formats_floats_test() {
  let nutrition =
    diary_types.DayNutrition(
      calories: 1234.5,
      protein: 56.7,
      carbohydrates: 142.3,
      fat: 45.8,
    )
  let output = formatters.format_nutrition_summary(nutrition)

  // Should have decimal values
  string.contains(output, "1234.5")
  |> should.be_true()

  string.contains(output, "56.7")
  |> should.be_true()
}

// ============================================================================
// Date Parsing Tests
// ============================================================================

/// Test: parse_date_to_int returns Some for valid dates
pub fn parse_date_to_int_valid_date_test() {
  let result = helpers.parse_date_to_int("2025-12-20")

  result
  |> should.not_equal(None)
}

/// Test: parse_date_to_int returns Some for "today"
pub fn parse_date_to_int_today_test() {
  let result = helpers.parse_date_to_int("today")

  result
  |> should.not_equal(None)
}

/// Test: parse_date_to_int returns None for invalid dates
pub fn parse_date_to_int_invalid_format_test() {
  let result = helpers.parse_date_to_int("12/20/2025")

  result
  |> should.equal(None)
}

/// Test: parse_date_to_int returns None for empty string
pub fn parse_date_to_int_empty_string_test() {
  let result = helpers.parse_date_to_int("")

  result
  |> should.equal(None)
}

/// Test: parse_date_to_int returns None for invalid day
pub fn parse_date_to_int_invalid_day_test() {
  let result = helpers.parse_date_to_int("2025-12-32")

  result
  |> should.equal(None)
}

/// Test: parse_date_to_int returns None for invalid month
pub fn parse_date_to_int_invalid_month_test() {
  let result = helpers.parse_date_to_int("2025-13-20")

  result
  |> should.equal(None)
}
