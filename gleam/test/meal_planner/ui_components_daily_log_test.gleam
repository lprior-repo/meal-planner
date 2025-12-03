/// Daily Log Component Tests
///
/// Comprehensive test suite for daily log UI components following Martin Fowler's
/// UI testing principles:
/// - Test behavior, not implementation
/// - Use semantic queries (verify HTML output)
/// - Verify user-facing output
/// - Keep tests maintainable
///
/// Test Categories:
/// 1. Meal Entry Item Tests - Single entry rendering
/// 2. Meal Section Tests - Grouped entries by meal type
/// 3. Daily Log Timeline Tests - Complete daily view
/// 4. Data Formatting Tests - Time, macros, calories display
/// 5. Accessibility Tests - Semantic HTML and attributes
/// 6. Edge Case Tests - Empty states, special values
/// 7. Integration Tests - Multiple entries, filtering
import gleam/string
import gleeunit/should
import meal_planner/ui/components/daily_log
import meal_planner/ui/types/ui_types

// ===================================================================
// TEST DATA FIXTURES
// ===================================================================

/// Helper to create a sample meal entry
fn sample_entry(
  id: String,
  time: String,
  food_name: String,
  meal_type: String,
) -> ui_types.MealEntryData {
  ui_types.MealEntryData(
    id: id,
    time: time,
    food_name: food_name,
    portion: "1 serving",
    protein: 20.0,
    fat: 10.0,
    carbs: 30.0,
    calories: 290.0,
    meal_type: meal_type,
  )
}

/// Helper to create breakfast entry
fn breakfast_entry(id: String, food_name: String) -> ui_types.MealEntryData {
  sample_entry(id, "08:00 AM", food_name, "breakfast")
}

/// Helper to create lunch entry
fn lunch_entry(id: String, food_name: String) -> ui_types.MealEntryData {
  sample_entry(id, "12:30 PM", food_name, "lunch")
}

/// Helper to create dinner entry
fn dinner_entry(id: String, food_name: String) -> ui_types.MealEntryData {
  sample_entry(id, "06:00 PM", food_name, "dinner")
}

/// Helper to create snack entry
fn snack_entry(id: String, food_name: String) -> ui_types.MealEntryData {
  sample_entry(id, "03:00 PM", food_name, "snack")
}

// ===================================================================
// MEAL ENTRY ITEM - BASIC RENDERING TESTS
// ===================================================================

/// Test meal entry item renders with correct HTML structure
pub fn meal_entry_item_renders_basic_html_test() {
  // GIVEN: A meal entry with basic data
  let entry =
    ui_types.MealEntryData(
      id: "entry-1",
      time: "08:30 AM",
      food_name: "Scrambled Eggs",
      portion: "2 servings",
      protein: 24.0,
      fat: 18.0,
      carbs: 4.0,
      calories: 320.0,
      meal_type: "breakfast",
    )

  // WHEN: Rendering the entry
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should render meal-entry-item container
  html
  |> string.contains("<div class=\"meal-entry-item\"")
  |> should.be_true()
}

/// Test meal entry item displays entry ID as data attribute
pub fn meal_entry_item_displays_entry_id_test() {
  let entry = breakfast_entry("breakfast-001", "Oatmeal")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should have data-entry-id attribute
  html
  |> string.contains("data-entry-id=\"breakfast-001\"")
  |> should.be_true()
}

/// Test meal entry item displays time correctly
pub fn meal_entry_item_displays_time_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "07:45 AM",
      food_name: "Coffee",
      portion: "1 cup",
      protein: 0.0,
      fat: 0.0,
      carbs: 0.0,
      calories: 5.0,
      meal_type: "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display time in entry-time div
  html
  |> string.contains("<div class=\"entry-time\">07:45 AM</div>")
  |> should.be_true()
}

/// Test meal entry item displays food name correctly
pub fn meal_entry_item_displays_food_name_test() {
  let entry = breakfast_entry("1", "Greek Yogurt with Berries")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display food name in food-name div
  html
  |> string.contains("<div class=\"food-name\">Greek Yogurt with Berries</div>")
  |> should.be_true()
}

/// Test meal entry item displays portion size
pub fn meal_entry_item_displays_portion_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "08:00 AM",
      food_name: "Banana",
      portion: "1 medium (118g)",
      protein: 1.0,
      fat: 0.5,
      carbs: 27.0,
      calories: 105.0,
      meal_type: "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display portion in portion div
  html
  |> string.contains("<div class=\"portion\">1 medium (118g)</div>")
  |> should.be_true()
}

// ===================================================================
// MEAL ENTRY ITEM - MACRO DISPLAY TESTS
// ===================================================================

/// Test meal entry item displays protein correctly
pub fn meal_entry_item_displays_protein_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Chicken Breast",
      portion: "150g",
      protein: 31.0,
      fat: 3.5,
      carbs: 0.0,
      calories: 165.0,
      meal_type: "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display protein with macro-protein class
  html
  |> string.contains("<span class=\"macro macro-protein\">P: 31g</span>")
  |> should.be_true()
}

/// Test meal entry item displays fat correctly
pub fn meal_entry_item_displays_fat_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Avocado",
      portion: "1/2 medium",
      protein: 2.0,
      fat: 15.0,
      carbs: 9.0,
      calories: 161.0,
      meal_type: "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display fat with macro-fat class
  html
  |> string.contains("<span class=\"macro macro-fat\">F: 15g</span>")
  |> should.be_true()
}

/// Test meal entry item displays carbs correctly
pub fn meal_entry_item_displays_carbs_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Brown Rice",
      portion: "1 cup cooked",
      protein: 5.0,
      fat: 2.0,
      carbs: 45.0,
      calories: 218.0,
      meal_type: "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display carbs with macro-carbs class
  html
  |> string.contains("<span class=\"macro macro-carbs\">C: 45g</span>")
  |> should.be_true()
}

/// Test meal entry item displays all macros together
pub fn meal_entry_item_displays_all_macros_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Salmon Fillet",
      portion: "150g",
      protein: 30.0,
      fat: 12.0,
      carbs: 0.0,
      calories: 234.0,
      meal_type: "dinner",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display all three macros in entry-macros div
  html
  |> string.contains("<div class=\"entry-macros\">")
  |> should.be_true()

  html
  |> string.contains("P: 30g")
  |> should.be_true()

  html
  |> string.contains("F: 12g")
  |> should.be_true()

  html
  |> string.contains("C: 0g")
  |> should.be_true()
}

// ===================================================================
// MEAL ENTRY ITEM - CALORIES AND ACTIONS
// ===================================================================

/// Test meal entry item displays calories correctly
pub fn meal_entry_item_displays_calories_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "03:00 PM",
      food_name: "Protein Shake",
      portion: "1 scoop",
      protein: 24.0,
      fat: 3.0,
      carbs: 5.0,
      calories: 140.0,
      meal_type: "snack",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display calories in entry-calories div
  html
  |> string.contains("<div class=\"entry-calories\">140 kcal</div>")
  |> should.be_true()
}

/// Test meal entry item renders edit button
pub fn meal_entry_item_renders_edit_button_test() {
  let entry = breakfast_entry("edit-test-1", "Toast")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should have edit button with correct class and data attribute
  html
  |> string.contains("<button class=\"btn-icon btn-edit\"")
  |> should.be_true()

  html
  |> string.contains("data-entry-id=\"edit-test-1\"")
  |> should.be_true()

  html
  |> string.contains("✏️")
  |> should.be_true()
}

/// Test meal entry item renders delete button
pub fn meal_entry_item_renders_delete_button_test() {
  let entry = lunch_entry("delete-test-1", "Salad")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should have delete button with correct class and data attribute
  html
  |> string.contains("<button class=\"btn-icon btn-delete\"")
  |> should.be_true()

  html
  |> string.contains("data-entry-id=\"delete-test-1\"")
  |> should.be_true()

  html
  |> string.contains("🗑️")
  |> should.be_true()
}

/// Test meal entry item action buttons have entry actions container
pub fn meal_entry_item_has_actions_container_test() {
  let entry = breakfast_entry("1", "Cereal")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should wrap action buttons in entry-actions div
  html
  |> string.contains("<div class=\"entry-actions\">")
  |> should.be_true()
}

// ===================================================================
// MEAL ENTRY ITEM - DATA FORMATTING TESTS
// ===================================================================

/// Test meal entry item truncates decimal macros
pub fn meal_entry_item_truncates_decimal_macros_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "08:00 AM",
      food_name: "Almonds",
      portion: "28g",
      protein: 6.5,
      fat: 14.3,
      carbs: 6.1,
      calories: 164.7,
      meal_type: "snack",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should truncate decimals to whole numbers
  html
  |> string.contains("P: 6g")
  |> should.be_true()

  html
  |> string.contains("F: 14g")
  |> should.be_true()

  html
  |> string.contains("C: 6g")
  |> should.be_true()

  html
  |> string.contains("164 kcal")
  |> should.be_true()
}

/// Test meal entry item handles zero macros
pub fn meal_entry_item_handles_zero_macros_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "10:00 AM",
      food_name: "Black Coffee",
      portion: "1 cup",
      protein: 0.0,
      fat: 0.0,
      carbs: 0.0,
      calories: 2.0,
      meal_type: "snack",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should display zeros correctly
  html
  |> string.contains("P: 0g")
  |> should.be_true()

  html
  |> string.contains("F: 0g")
  |> should.be_true()

  html
  |> string.contains("C: 0g")
  |> should.be_true()
}

// ===================================================================
// MEAL SECTION - BASIC RENDERING TESTS
// ===================================================================

/// Test meal section renders with correct HTML structure
pub fn meal_section_renders_basic_html_test() {
  // GIVEN: A list of breakfast entries
  let entries = [breakfast_entry("1", "Eggs"), breakfast_entry("2", "Toast")]

  // WHEN: Rendering the meal section
  let html = daily_log.meal_section("Breakfast", entries)

  // THEN: Should render meal-section container
  html
  |> string.contains("<div class=\"meal-section\"")
  |> should.be_true()
}

/// Test meal section displays meal type as data attribute
pub fn meal_section_displays_meal_type_attribute_test() {
  let entries = [breakfast_entry("1", "Pancakes")]
  let html = daily_log.meal_section("Breakfast", entries)

  // THEN: Should have data-meal-type attribute with lowercase value
  html
  |> string.contains("data-meal-type=\"breakfast\"")
  |> should.be_true()
}

/// Test meal section displays meal type header
pub fn meal_section_displays_meal_type_header_test() {
  let entries = [lunch_entry("1", "Sandwich")]
  let html = daily_log.meal_section("Lunch", entries)

  // THEN: Should display meal type in h3 header
  html
  |> string.contains("<h3>Lunch")
  |> should.be_true()
}

/// Test meal section displays entry count
pub fn meal_section_displays_entry_count_test() {
  let entries = [
    dinner_entry("1", "Steak"),
    dinner_entry("2", "Vegetables"),
    dinner_entry("3", "Potato"),
  ]
  let html = daily_log.meal_section("Dinner", entries)

  // THEN: Should display count of entries in parentheses
  html
  |> string.contains("<span class=\"entry-count\">(3)</span>")
  |> should.be_true()
}

/// Test meal section displays total calories
pub fn meal_section_displays_total_calories_test() {
  let entries = [
    ui_types.MealEntryData(
      id: "1",
      time: "08:00 AM",
      food_name: "Food 1",
      portion: "1 serving",
      protein: 10.0,
      fat: 5.0,
      carbs: 20.0,
      calories: 165.0,
      meal_type: "breakfast",
    ),
    ui_types.MealEntryData(
      id: "2",
      time: "08:30 AM",
      food_name: "Food 2",
      portion: "1 serving",
      protein: 5.0,
      fat: 3.0,
      carbs: 15.0,
      calories: 107.0,
      meal_type: "breakfast",
    ),
  ]
  let html = daily_log.meal_section("Breakfast", entries)

  // THEN: Should display sum of calories (165 + 107 = 272)
  html
  |> string.contains("<span class=\"section-calories\">272 kcal</span>")
  |> should.be_true()
}

/// Test meal section has collapse toggle button
pub fn meal_section_has_collapse_toggle_test() {
  let entries = [snack_entry("1", "Apple")]
  let html = daily_log.meal_section("Snack", entries)

  // THEN: Should have collapse toggle button
  html
  |> string.contains("<button class=\"collapse-toggle\">▼</button>")
  |> should.be_true()
}

// ===================================================================
// MEAL SECTION - ENTRY LIST TESTS
// ===================================================================

/// Test meal section contains all meal entries
pub fn meal_section_contains_all_entries_test() {
  let entries = [
    breakfast_entry("1", "Oatmeal"),
    breakfast_entry("2", "Banana"),
    breakfast_entry("3", "Coffee"),
  ]
  let html = daily_log.meal_section("Breakfast", entries)

  // THEN: Should contain all food names
  html
  |> string.contains("Oatmeal")
  |> should.be_true()

  html
  |> string.contains("Banana")
  |> should.be_true()

  html
  |> string.contains("Coffee")
  |> should.be_true()
}

/// Test meal section wraps entries in meal-section-body
pub fn meal_section_has_body_container_test() {
  let entries = [lunch_entry("1", "Soup")]
  let html = daily_log.meal_section("Lunch", entries)

  // THEN: Should wrap entries in meal-section-body div
  html
  |> string.contains("<div class=\"meal-section-body\">")
  |> should.be_true()
}

/// Test meal section with single entry shows count of 1
pub fn meal_section_single_entry_count_test() {
  let entries = [dinner_entry("1", "Pizza")]
  let html = daily_log.meal_section("Dinner", entries)

  // THEN: Should show (1) as entry count
  html
  |> string.contains("(1)")
  |> should.be_true()
}

/// Test meal section with empty list shows count of 0
pub fn meal_section_empty_list_count_test() {
  let html = daily_log.meal_section("Breakfast", [])

  // THEN: Should show (0) as entry count
  html
  |> string.contains("(0)")
  |> should.be_true()

  // AND: Should show 0 kcal
  html
  |> string.contains("0 kcal")
  |> should.be_true()
}

// ===================================================================
// DAILY LOG TIMELINE - BASIC RENDERING TESTS
// ===================================================================

/// Test daily log timeline renders with correct HTML structure
pub fn daily_log_timeline_renders_basic_html_test() {
  // GIVEN: A list of entries
  let entries = [breakfast_entry("1", "Eggs")]

  // WHEN: Rendering the timeline
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should render daily-log-timeline container
  html
  |> string.contains("<div class=\"daily-log-timeline\">")
  |> should.be_true()
}

/// Test daily log timeline groups breakfast entries
pub fn daily_log_timeline_groups_breakfast_test() {
  let entries = [
    breakfast_entry("1", "Eggs"),
    breakfast_entry("2", "Toast"),
    lunch_entry("3", "Salad"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should have Breakfast section with 2 entries
  html
  |> string.contains("Breakfast")
  |> should.be_true()

  html
  |> string.contains("Eggs")
  |> should.be_true()

  html
  |> string.contains("Toast")
  |> should.be_true()
}

/// Test daily log timeline groups lunch entries
pub fn daily_log_timeline_groups_lunch_test() {
  let entries = [
    lunch_entry("1", "Sandwich"),
    lunch_entry("2", "Apple"),
    dinner_entry("3", "Steak"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should have Lunch section with 2 entries
  html
  |> string.contains("Lunch")
  |> should.be_true()

  html
  |> string.contains("Sandwich")
  |> should.be_true()

  html
  |> string.contains("Apple")
  |> should.be_true()
}

/// Test daily log timeline groups dinner entries
pub fn daily_log_timeline_groups_dinner_test() {
  let entries = [
    dinner_entry("1", "Chicken"),
    dinner_entry("2", "Rice"),
    snack_entry("3", "Nuts"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should have Dinner section with 2 entries
  html
  |> string.contains("Dinner")
  |> should.be_true()

  html
  |> string.contains("Chicken")
  |> should.be_true()

  html
  |> string.contains("Rice")
  |> should.be_true()
}

/// Test daily log timeline groups snack entries
pub fn daily_log_timeline_groups_snack_test() {
  let entries = [
    snack_entry("1", "Protein Bar"),
    snack_entry("2", "Apple"),
    breakfast_entry("3", "Oatmeal"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should have Snack section with 2 entries
  html
  |> string.contains("Snack")
  |> should.be_true()

  html
  |> string.contains("Protein Bar")
  |> should.be_true()

  html
  |> string.contains("Apple")
  |> should.be_true()
}

// ===================================================================
// DAILY LOG TIMELINE - FILTERING TESTS
// ===================================================================

/// Test daily log timeline excludes empty meal types
pub fn daily_log_timeline_excludes_empty_sections_test() {
  // GIVEN: Only breakfast entries, no lunch/dinner/snack
  let entries = [breakfast_entry("1", "Eggs"), breakfast_entry("2", "Toast")]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should only show Breakfast section
  html
  |> string.contains("Breakfast")
  |> should.be_true()

  // AND: Should not show empty Lunch, Dinner, or Snack sections
  // Check that meal-section with these data-meal-types don't exist
  let has_lunch_section = string.contains(html, "data-meal-type=\"lunch\"")
  let has_dinner_section = string.contains(html, "data-meal-type=\"dinner\"")
  let has_snack_section = string.contains(html, "data-meal-type=\"snack\"")

  has_lunch_section
  |> should.be_false()

  has_dinner_section
  |> should.be_false()

  has_snack_section
  |> should.be_false()
}

/// Test daily log timeline with all meal types
pub fn daily_log_timeline_all_meal_types_test() {
  let entries = [
    breakfast_entry("1", "Breakfast Food"),
    lunch_entry("2", "Lunch Food"),
    dinner_entry("3", "Dinner Food"),
    snack_entry("4", "Snack Food"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should show all four meal sections
  html
  |> string.contains("Breakfast")
  |> should.be_true()

  html
  |> string.contains("Lunch")
  |> should.be_true()

  html
  |> string.contains("Dinner")
  |> should.be_true()

  html
  |> string.contains("Snack")
  |> should.be_true()
}

/// Test daily log timeline with empty list
pub fn daily_log_timeline_empty_list_test() {
  let html = daily_log.daily_log_timeline([])

  // THEN: Should render empty timeline container
  html
  |> should.equal("<div class=\"daily-log-timeline\"></div>")
}

// ===================================================================
// DAILY LOG TIMELINE - INTEGRATION TESTS
// ===================================================================

/// Test daily log timeline with complete day of meals
pub fn daily_log_timeline_complete_day_test() {
  let entries = [
    ui_types.MealEntryData(
      id: "1",
      time: "07:00 AM",
      food_name: "Oatmeal",
      portion: "1 cup",
      protein: 5.0,
      fat: 3.0,
      carbs: 27.0,
      calories: 150.0,
      meal_type: "breakfast",
    ),
    ui_types.MealEntryData(
      id: "2",
      time: "08:00 AM",
      food_name: "Coffee",
      portion: "1 cup",
      protein: 0.0,
      fat: 0.0,
      carbs: 0.0,
      calories: 5.0,
      meal_type: "breakfast",
    ),
    ui_types.MealEntryData(
      id: "3",
      time: "12:30 PM",
      food_name: "Chicken Salad",
      portion: "1 bowl",
      protein: 35.0,
      fat: 10.0,
      carbs: 15.0,
      calories: 290.0,
      meal_type: "lunch",
    ),
    ui_types.MealEntryData(
      id: "4",
      time: "03:00 PM",
      food_name: "Protein Shake",
      portion: "1 scoop",
      protein: 25.0,
      fat: 2.0,
      carbs: 5.0,
      calories: 135.0,
      meal_type: "snack",
    ),
    ui_types.MealEntryData(
      id: "5",
      time: "06:30 PM",
      food_name: "Salmon with Vegetables",
      portion: "1 plate",
      protein: 40.0,
      fat: 15.0,
      carbs: 20.0,
      calories: 380.0,
      meal_type: "dinner",
    ),
  ]

  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should render all meals in their respective sections
  html
  |> string.contains("Breakfast")
  |> should.be_true()

  html
  |> string.contains("Lunch")
  |> should.be_true()

  html
  |> string.contains("Dinner")
  |> should.be_true()

  html
  |> string.contains("Snack")
  |> should.be_true()

  // AND: All food items should be present
  html
  |> string.contains("Oatmeal")
  |> should.be_true()

  html
  |> string.contains("Coffee")
  |> should.be_true()

  html
  |> string.contains("Chicken Salad")
  |> should.be_true()

  html
  |> string.contains("Protein Shake")
  |> should.be_true()

  html
  |> string.contains("Salmon with Vegetables")
  |> should.be_true()
}

/// Test daily log timeline with multiple snacks throughout day
pub fn daily_log_timeline_multiple_snacks_test() {
  let entries = [
    snack_entry("1", "Morning Snack"),
    snack_entry("2", "Afternoon Snack"),
    snack_entry("3", "Evening Snack"),
  ]
  let html = daily_log.daily_log_timeline(entries)

  // THEN: Should have Snack section with 3 entries
  html
  |> string.contains("Snack")
  |> should.be_true()

  html
  |> string.contains("(3)")
  |> should.be_true()
}

// ===================================================================
// ACCESSIBILITY TESTS
// ===================================================================

/// Test meal entry uses semantic div structure
pub fn meal_entry_semantic_structure_test() {
  let entry = breakfast_entry("1", "Toast")
  let html = daily_log.meal_entry_item(entry)

  // THEN: Should use semantic div elements for structure
  html
  |> string.contains("<div class=\"meal-entry-item\"")
  |> should.be_true()

  html
  |> string.contains("<div class=\"entry-time\">")
  |> should.be_true()

  html
  |> string.contains("<div class=\"entry-details\">")
  |> should.be_true()

  html
  |> string.contains("<div class=\"entry-macros\">")
  |> should.be_true()

  html
  |> string.contains("<div class=\"entry-calories\">")
  |> should.be_true()

  html
  |> string.contains("<div class=\"entry-actions\">")
  |> should.be_true()
}

/// Test meal section uses semantic h3 for header
pub fn meal_section_semantic_header_test() {
  let entries = [lunch_entry("1", "Pasta")]
  let html = daily_log.meal_section("Lunch", entries)

  // THEN: Should use h3 for meal type heading
  html
  |> string.contains("<h3>Lunch")
  |> should.be_true()
}

/// Test action buttons have data attributes for accessibility
pub fn action_buttons_have_data_attributes_test() {
  let entry =
    ui_types.MealEntryData(
      id: "action-test-123",
      time: "08:00 AM",
      food_name: "Test Food",
      portion: "1 serving",
      protein: 10.0,
      fat: 5.0,
      carbs: 15.0,
      calories: 145.0,
      meal_type: "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Both buttons should have data-entry-id for identification
  // Count occurrences of data-entry-id="action-test-123"
  let has_edit_id =
    string.contains(html, "btn-edit\" data-entry-id=\"action-test-123\"")
  let has_delete_id =
    string.contains(html, "btn-delete\" data-entry-id=\"action-test-123\"")

  has_edit_id
  |> should.be_true()

  has_delete_id
  |> should.be_true()
}

// ===================================================================
// EDGE CASE TESTS
// ===================================================================

/// Test meal entry with very long food name
pub fn meal_entry_long_food_name_test() {
  let long_name =
    "Grilled Chicken Breast with Roasted Vegetables and Quinoa Salad with Lemon Vinaigrette"
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: long_name,
      portion: "1 plate",
      protein: 40.0,
      fat: 10.0,
      carbs: 30.0,
      calories: 370.0,
      meal_type: "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should preserve full food name
  html
  |> string.contains(long_name)
  |> should.be_true()
}

/// Test meal entry with special characters in food name
pub fn meal_entry_special_chars_food_name_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "08:00 AM",
      food_name: "Ben & Jerry's Ice Cream",
      portion: "1/2 cup",
      protein: 4.0,
      fat: 14.0,
      carbs: 28.0,
      calories: 250.0,
      meal_type: "snack",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should preserve special characters
  html
  |> string.contains("Ben & Jerry's Ice Cream")
  |> should.be_true()
}

/// Test meal entry with high calorie values
pub fn meal_entry_high_calories_test() {
  let entry =
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Large Pizza",
      portion: "1 whole pizza",
      protein: 80.0,
      fat: 100.0,
      carbs: 200.0,
      calories: 2000.0,
      meal_type: "lunch",
    )

  let html = daily_log.meal_entry_item(entry)

  // THEN: Should handle large calorie values
  html
  |> string.contains("2000 kcal")
  |> should.be_true()
}

/// Test meal section with very high total calories
pub fn meal_section_high_total_calories_test() {
  let entries = [
    ui_types.MealEntryData(
      id: "1",
      time: "12:00 PM",
      food_name: "Food 1",
      portion: "1 serving",
      protein: 50.0,
      fat: 60.0,
      carbs: 100.0,
      calories: 1100.0,
      meal_type: "lunch",
    ),
    ui_types.MealEntryData(
      id: "2",
      time: "12:30 PM",
      food_name: "Food 2",
      portion: "1 serving",
      protein: 40.0,
      fat: 50.0,
      carbs: 80.0,
      calories: 900.0,
      meal_type: "lunch",
    ),
  ]
  let html = daily_log.meal_section("Lunch", entries)

  // THEN: Should correctly sum high calorie values (1100 + 900 = 2000)
  html
  |> string.contains("2000 kcal")
  |> should.be_true()
}

// ===================================================================
// SNAPSHOT TESTS (Full HTML Output Verification)
// ===================================================================

/// Test complete HTML snapshot for meal entry item
pub fn snapshot_meal_entry_item_test() {
  let entry =
    ui_types.MealEntryData(
      id: "snap-1",
      time: "08:00 AM",
      food_name: "Eggs",
      portion: "2 large",
      protein: 12.0,
      fat: 10.0,
      carbs: 1.0,
      calories: 143.0,
      meal_type: "breakfast",
    )

  let html = daily_log.meal_entry_item(entry)
  let expected =
    "<div class=\"meal-entry-item\" data-entry-id=\"snap-1\">"
    <> "<div class=\"entry-time\">08:00 AM</div>"
    <> "<div class=\"entry-details\">"
    <> "<div class=\"food-name\">Eggs</div>"
    <> "<div class=\"portion\">2 large</div>"
    <> "</div>"
    <> "<div class=\"entry-macros\">"
    <> "<span class=\"macro macro-protein\">P: 12g</span>"
    <> "<span class=\"macro macro-fat\">F: 10g</span>"
    <> "<span class=\"macro macro-carbs\">C: 1g</span>"
    <> "</div>"
    <> "<div class=\"entry-calories\">143 kcal</div>"
    <> "<div class=\"entry-actions\">"
    <> "<button class=\"btn-icon btn-edit\" data-entry-id=\"snap-1\">✏️</button>"
    <> "<button class=\"btn-icon btn-delete\" data-entry-id=\"snap-1\">🗑️</button>"
    <> "</div>"
    <> "</div>"

  html
  |> should.equal(expected)
}
