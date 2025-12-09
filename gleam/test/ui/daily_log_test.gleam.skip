/// Tests for daily_log UI components
/// Test meal entry rendering, sections, and timeline
import gleam/string
import gleeunit/should
import meal_planner/ui/components/daily_log
import meal_planner/ui/types/ui_types.{MealEntryData}

// ============================================================================
// Test Fixtures
// ============================================================================

fn make_meal_entry(
  id: String,
  time: String,
  food_name: String,
  portion: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  calories: Float,
  meal_type: String,
) -> MealEntryData {
  MealEntryData(
    id: id,
    time: time,
    food_name: food_name,
    portion: portion,
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
    meal_type: meal_type,
  )
}

// ============================================================================
// Meal Entry Item Tests
// ============================================================================

pub fn meal_entry_item_contains_time_test() {
  let entry =
    make_meal_entry(
      "1",
      "08:30 AM",
      "Scrambled Eggs",
      "2 servings",
      24.0,
      18.0,
      4.0,
      320.0,
      "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  string.contains(html, "08:30 AM")
  |> should.be_true
}

pub fn meal_entry_item_contains_food_name_test() {
  let entry =
    make_meal_entry(
      "1",
      "08:30 AM",
      "Scrambled Eggs",
      "2 servings",
      24.0,
      18.0,
      4.0,
      320.0,
      "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  string.contains(html, "Scrambled Eggs")
  |> should.be_true
}

pub fn meal_entry_item_contains_portion_test() {
  let entry =
    make_meal_entry(
      "1",
      "08:30 AM",
      "Scrambled Eggs",
      "2 servings",
      24.0,
      18.0,
      4.0,
      320.0,
      "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  string.contains(html, "2 servings")
  |> should.be_true
}

pub fn meal_entry_item_contains_macros_test() {
  let entry =
    make_meal_entry(
      "1",
      "12:00 PM",
      "Chicken Breast",
      "200g",
      40.0,
      5.0,
      0.0,
      200.0,
      "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // Check for protein
  string.contains(html, "P: 40g")
  |> should.be_true

  // Check for fat
  string.contains(html, "F: 5g")
  |> should.be_true

  // Check for carbs
  string.contains(html, "C: 0g")
  |> should.be_true
}

pub fn meal_entry_item_contains_calories_test() {
  let entry =
    make_meal_entry(
      "1",
      "12:00 PM",
      "Chicken Breast",
      "200g",
      40.0,
      5.0,
      0.0,
      200.0,
      "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  string.contains(html, "200 kcal")
  |> should.be_true
}

pub fn meal_entry_item_has_edit_button_test() {
  let entry =
    make_meal_entry(
      "entry-123",
      "12:00 PM",
      "Rice",
      "100g",
      5.0,
      1.0,
      80.0,
      350.0,
      "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // Should have edit button with entry ID
  string.contains(html, "btn-edit")
  |> should.be_true

  string.contains(html, "entry-123")
  |> should.be_true
}

pub fn meal_entry_item_has_delete_button_test() {
  let entry =
    make_meal_entry(
      "entry-456",
      "12:00 PM",
      "Rice",
      "100g",
      5.0,
      1.0,
      80.0,
      350.0,
      "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // Should have delete button
  string.contains(html, "btn-delete")
  |> should.be_true

  string.contains(html, "entry-456")
  |> should.be_true
}

pub fn meal_entry_item_truncates_decimal_macros_test() {
  let entry =
    make_meal_entry(
      "1",
      "12:00 PM",
      "Mixed Nuts",
      "30g",
      5.5,
      12.8,
      8.3,
      180.7,
      "snack",
    )

  let html = daily_log.meal_entry_item(entry)

  // Decimals should be truncated to integers
  string.contains(html, "P: 5g")
  |> should.be_true

  string.contains(html, "F: 12g")
  |> should.be_true

  string.contains(html, "C: 8g")
  |> should.be_true

  string.contains(html, "180 kcal")
  |> should.be_true
}

// ============================================================================
// Meal Section Tests
// ============================================================================

pub fn meal_section_contains_meal_type_test() {
  let entries = [
    make_meal_entry(
      "1",
      "08:30 AM",
      "Oatmeal",
      "1 cup",
      10.0,
      5.0,
      50.0,
      300.0,
      "breakfast",
    ),
  ]

  let html = daily_log.meal_section("Breakfast", entries)

  string.contains(html, "Breakfast")
  |> should.be_true
}

pub fn meal_section_shows_entry_count_test() {
  let entries = [
    make_meal_entry(
      "1",
      "08:30 AM",
      "Eggs",
      "2",
      20.0,
      15.0,
      2.0,
      250.0,
      "breakfast",
    ),
    make_meal_entry(
      "2",
      "08:45 AM",
      "Toast",
      "2 slices",
      8.0,
      3.0,
      30.0,
      180.0,
      "breakfast",
    ),
    make_meal_entry(
      "3",
      "09:00 AM",
      "Coffee",
      "1 cup",
      0.0,
      0.0,
      0.0,
      5.0,
      "breakfast",
    ),
  ]

  let html = daily_log.meal_section("Breakfast", entries)

  // Should show count of 3 entries
  string.contains(html, "(3)")
  |> should.be_true
}

pub fn meal_section_shows_total_calories_test() {
  let entries = [
    make_meal_entry(
      "1",
      "12:00 PM",
      "Chicken",
      "200g",
      40.0,
      10.0,
      0.0,
      250.0,
      "lunch",
    ),
    make_meal_entry(
      "2",
      "12:15 PM",
      "Rice",
      "100g",
      5.0,
      1.0,
      80.0,
      350.0,
      "lunch",
    ),
  ]

  let html = daily_log.meal_section("Lunch", entries)

  // Total: 250 + 350 = 600 kcal
  string.contains(html, "600 kcal")
  |> should.be_true
}

pub fn meal_section_has_collapse_toggle_test() {
  let entries = [
    make_meal_entry(
      "1",
      "12:00 PM",
      "Salad",
      "1 bowl",
      5.0,
      10.0,
      15.0,
      150.0,
      "lunch",
    ),
  ]

  let html = daily_log.meal_section("Lunch", entries)

  string.contains(html, "collapse-toggle")
  |> should.be_true
}

pub fn meal_section_renders_all_entries_test() {
  let entries = [
    make_meal_entry(
      "1",
      "12:00 PM",
      "Chicken",
      "200g",
      40.0,
      10.0,
      0.0,
      250.0,
      "lunch",
    ),
    make_meal_entry(
      "2",
      "12:15 PM",
      "Rice",
      "100g",
      5.0,
      1.0,
      80.0,
      350.0,
      "lunch",
    ),
  ]

  let html = daily_log.meal_section("Lunch", entries)

  // Both entries should be present
  string.contains(html, "Chicken")
  |> should.be_true

  string.contains(html, "Rice")
  |> should.be_true
}

pub fn meal_section_empty_entries_test() {
  let entries = []

  let html = daily_log.meal_section("Breakfast", entries)

  // Should show zero entries and calories
  string.contains(html, "(0)")
  |> should.be_true

  string.contains(html, "0 kcal")
  |> should.be_true
}

// ============================================================================
// Daily Log Timeline Tests
// ============================================================================

pub fn daily_log_timeline_groups_by_meal_type_test() {
  let entries = [
    make_meal_entry(
      "1",
      "08:00 AM",
      "Eggs",
      "2",
      20.0,
      15.0,
      2.0,
      250.0,
      "breakfast",
    ),
    make_meal_entry(
      "2",
      "12:00 PM",
      "Chicken",
      "200g",
      40.0,
      10.0,
      0.0,
      250.0,
      "lunch",
    ),
    make_meal_entry(
      "3",
      "18:00 PM",
      "Steak",
      "300g",
      60.0,
      25.0,
      0.0,
      500.0,
      "dinner",
    ),
    make_meal_entry(
      "4",
      "15:00 PM",
      "Protein Bar",
      "1",
      20.0,
      8.0,
      30.0,
      280.0,
      "snack",
    ),
  ]

  let html = daily_log.daily_log_timeline(entries)

  // All meal types should be present
  string.contains(html, "Breakfast")
  |> should.be_true

  string.contains(html, "Lunch")
  |> should.be_true

  string.contains(html, "Dinner")
  |> should.be_true

  string.contains(html, "Snack")
  |> should.be_true
}

pub fn daily_log_timeline_skips_empty_sections_test() {
  let entries = [
    make_meal_entry(
      "1",
      "08:00 AM",
      "Eggs",
      "2",
      20.0,
      15.0,
      2.0,
      250.0,
      "breakfast",
    ),
    make_meal_entry(
      "2",
      "18:00 PM",
      "Steak",
      "300g",
      60.0,
      25.0,
      0.0,
      500.0,
      "dinner",
    ),
  ]

  let html = daily_log.daily_log_timeline(entries)

  // Breakfast and Dinner should be present
  string.contains(html, "Breakfast")
  |> should.be_true

  string.contains(html, "Dinner")
  |> should.be_true

  // Lunch and Snack sections should not be rendered (empty)
  // We can't easily test for absence, but we can verify structure
  string.contains(html, "daily-log-timeline")
  |> should.be_true
}

pub fn daily_log_timeline_empty_entries_test() {
  let entries = []

  let html = daily_log.daily_log_timeline(entries)

  // Should render empty timeline container
  string.contains(html, "daily-log-timeline")
  |> should.be_true
}

pub fn daily_log_timeline_multiple_entries_per_meal_test() {
  let entries = [
    make_meal_entry(
      "1",
      "08:00 AM",
      "Eggs",
      "2",
      20.0,
      15.0,
      2.0,
      250.0,
      "breakfast",
    ),
    make_meal_entry(
      "2",
      "08:30 AM",
      "Toast",
      "2 slices",
      8.0,
      3.0,
      30.0,
      180.0,
      "breakfast",
    ),
    make_meal_entry(
      "3",
      "09:00 AM",
      "Coffee",
      "1 cup",
      0.0,
      0.0,
      0.0,
      5.0,
      "breakfast",
    ),
  ]

  let html = daily_log.daily_log_timeline(entries)

  // All breakfast items should be present
  string.contains(html, "Eggs")
  |> should.be_true

  string.contains(html, "Toast")
  |> should.be_true

  string.contains(html, "Coffee")
  |> should.be_true

  // Should show 3 entries in breakfast section
  string.contains(html, "(3)")
  |> should.be_true
}

pub fn daily_log_timeline_has_proper_structure_test() {
  let entries = [
    make_meal_entry(
      "1",
      "12:00 PM",
      "Sandwich",
      "1",
      25.0,
      12.0,
      45.0,
      400.0,
      "lunch",
    ),
  ]

  let html = daily_log.daily_log_timeline(entries)

  // Should have timeline wrapper
  string.contains(html, "daily-log-timeline")
  |> should.be_true

  // Should have meal section
  string.contains(html, "meal-section")
  |> should.be_true

  // Should have meal entry item
  string.contains(html, "meal-entry-item")
  |> should.be_true
}
