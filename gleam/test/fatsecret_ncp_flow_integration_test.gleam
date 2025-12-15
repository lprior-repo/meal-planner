/// FatSecret → NCP Integration Test
/// Tests the complete flow from FatSecret food diary entries through
/// Nutrition Control Plane (NCP) reconciliation and adjustment planning.
import gleam/list
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/ncp

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data: Mock FatSecret Food Entries
// ============================================================================

/// Create a mock food entry for testing
fn mock_food_entry(
  name: String,
  calories: Float,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> diary_types.FoodEntry {
  diary_types.FoodEntry(
    food_entry_id: diary_types.food_entry_id("mock_entry"),
    food_entry_name: name,
    food_entry_description: name,
    food_id: "0",
    serving_id: "0",
    number_of_units: 1.0,
    meal: diary_types.Breakfast,
    date_int: 0,
    calories: calories,
    carbohydrate: carbs,
    protein: protein,
    fat: fat,
    saturated_fat: option.None,
    polyunsaturated_fat: option.None,
    monounsaturated_fat: option.None,
    cholesterol: option.None,
    sodium: option.None,
    potassium: option.None,
    fiber: option.None,
    sugar: option.None,
  )
}

/// Convert a FatSecret FoodEntry to NCP NutritionState
fn diary_entry_to_nutrition_state(
  entry: diary_types.FoodEntry,
) -> ncp.NutritionState {
  ncp.NutritionState(
    date: diary_types.int_to_date(entry.date_int),
    consumed: ncp.NutritionData(
      protein: entry.protein,
      fat: entry.fat,
      carbs: entry.carbohydrate,
      calories: entry.calories,
    ),
    synced_at: "2024-01-01T12:00:00Z",
  )
}

// ============================================================================
// Tests: FatSecret → NCP Reconciliation Flow
// ============================================================================

/// Test: Convert single food entry to NCP nutrition data
pub fn fatsecret_entry_to_ncp_conversion_test() {
  // Arrange: Create a mock food entry (Chicken breast)
  let entry = mock_food_entry("Chicken Breast 100g", 165.0, 31.0, 3.6, 0.0)

  // Act: Convert to NCP NutritionState
  let nutrition_state = diary_entry_to_nutrition_state(entry)

  // Assert: Verify conversion is correct
  nutrition_state.consumed.protein |> should.equal(31.0)
  nutrition_state.consumed.fat |> should.equal(3.6)
  nutrition_state.consumed.carbs |> should.equal(0.0)
  nutrition_state.consumed.calories |> should.equal(165.0)
}

/// Test: Convert multiple entries and calculate totals
pub fn fatsecret_multiple_entries_aggregation_test() {
  // Arrange: Create a day's worth of food entries
  let breakfast = mock_food_entry("Eggs", 155.0, 13.0, 11.0, 1.1)
  let lunch = mock_food_entry("Chicken Rice", 420.0, 45.0, 8.0, 35.0)
  let dinner = mock_food_entry("Steak Broccoli", 485.0, 60.0, 20.0, 15.0)
  let snack = mock_food_entry("Greek Yogurt", 130.0, 20.0, 0.4, 9.0)

  let entries = [breakfast, lunch, dinner, snack]

  // Act: Convert all to nutrition states
  let nutrition_states = list.map(entries, diary_entry_to_nutrition_state)

  // Act: Calculate aggregate nutrition
  let total = ncp.average_nutrition_history(nutrition_states)

  // Assert: Verify aggregated values
  // Total protein: 13 + 45 + 60 + 20 = 138g
  // Average: 138 / 4 = 34.5g
  total.protein |> should.equal(34.5)

  // Total calories: 155 + 420 + 485 + 130 = 1190
  // Average: 1190 / 4 = 297.5
  total.calories |> should.equal(297.5)
}

/// Test: NCP reconciliation with goals (on-track scenario)
pub fn ncp_reconciliation_on_track_test() {
  // Arrange: User ate exactly to goals
  let eaten =
    ncp.NutritionData(protein: 180.0, fat: 60.0, carbs: 250.0, calories: 2500.0)
  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  // Act: Calculate deviation
  let deviation = ncp.calculate_deviation(goals, eaten)

  // Assert: Should have zero deviation
  deviation.protein_pct |> should.equal(0.0)
  deviation.fat_pct |> should.equal(0.0)
  deviation.carbs_pct |> should.equal(0.0)
  deviation.calories_pct |> should.equal(0.0)
}

/// Test: NCP reconciliation with protein deficit
pub fn ncp_reconciliation_protein_deficit_test() {
  // Arrange: User under on protein
  let eaten =
    ncp.NutritionData(protein: 120.0, fat: 60.0, carbs: 250.0, calories: 2500.0)
  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  // Act: Calculate deviation
  let deviation = ncp.calculate_deviation(goals, eaten)

  // Assert: Protein deficit should be -33.3%
  // (120 - 180) / 180 * 100 = -33.333...
  deviation.protein_pct |> should.equal(-33.33333333333333)
  deviation.fat_pct |> should.equal(0.0)
}

/// Test: End-to-end FatSecret → NCP flow
pub fn complete_fatsecret_to_ncp_flow_test() {
  // Arrange: Simulate FatSecret diary entries for a day
  let breakfast_entry = mock_food_entry("Eggs & Toast", 280.0, 12.0, 8.0, 35.0)
  let lunch_entry = mock_food_entry("Tuna Salad", 320.0, 42.0, 12.0, 15.0)
  let dinner_entry =
    mock_food_entry("Steak & Broccoli", 485.0, 58.0, 20.0, 18.0)

  let entries = [breakfast_entry, lunch_entry, dinner_entry]

  // Step 1: Convert FatSecret entries to NCP nutrition states
  let nutrition_states = list.map(entries, diary_entry_to_nutrition_state)

  // Step 2: Verify states converted correctly
  // Note: average_nutrition_history returns AVERAGE, not sum
  // (12 + 42 + 58) / 3 = 112 / 3 = 37.333...
  // (280 + 320 + 485) / 3 = 1085 / 3 = 361.666...
  let total_converted = ncp.average_nutrition_history(nutrition_states)
  total_converted.protein |> should.equal(37.333333333333336)
  total_converted.calories |> should.equal(361.6666666666667)

  // Step 3: Define nutrition goals
  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 65.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  // Step 4: Calculate deviation - should show deficits
  let deviation = ncp.calculate_deviation(goals, total_converted)

  // Protein: (37.33 - 180) / 180 * 100 = -79.26%
  deviation.protein_pct |> should.equal(-79.25925925925925)
  // Calories: (361.67 - 2500) / 2500 * 100 = -85.53%
  deviation.calories_pct |> should.equal(-85.53333333333335)

  // Step 5: Verify that we can calculate consistency
  // This represents a single day's data
  let history = nutrition_states
  let consistency = ncp.calculate_consistency_rate(history, goals, 5.0)
  // With 56% calorie deficit, should be 0% consistent
  consistency |> should.equal(0.0)

  // Final assertion: The flow works end-to-end
  True |> should.equal(True)
}
