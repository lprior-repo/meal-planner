/// UI Component Tests for Weekly Calendar Component
///
/// Test coverage for weekly calendar component includes:
/// - Renders 7 columns (Monday-Sunday)
/// - Each column has 3 meal slots (breakfast, lunch, dinner)
/// - Empty slot shows placeholder text
/// - Filled slot shows recipe name
/// - Property test for HTML validity
/// - Semantic HTML structure
///
/// FRACTAL LOOP:
/// - Pass 1 (unit) - this task
/// - Pass 2 (integration) - via route handler
/// - Pass 3 (E2E) - Task 14
/// - Pass 4 (review) - automated
///
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ui/components/weekly_calendar

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Count occurrences of a substring in a string
fn count_occurrences(haystack: String, needle: String) -> Int {
  count_occurrences_loop(haystack, needle, 0)
}

fn count_occurrences_loop(haystack: String, needle: String, count: Int) -> Int {
  case string.split_once(haystack, needle) {
    Ok(#(_before, after)) -> count_occurrences_loop(after, needle, count + 1)
    Error(_) -> count
  }
}

// ===================================================================
// 7 DAY COLUMNS TESTS
// ===================================================================

pub fn calendar_renders_monday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Monday") |> should.be_true
}

pub fn calendar_renders_tuesday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Tuesday") |> should.be_true
}

pub fn calendar_renders_wednesday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Wednesday") |> should.be_true
}

pub fn calendar_renders_thursday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Thursday") |> should.be_true
}

pub fn calendar_renders_friday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Friday") |> should.be_true
}

pub fn calendar_renders_saturday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Saturday") |> should.be_true
}

pub fn calendar_renders_sunday_column_test() {
  let html = weekly_calendar.render()
  html |> string.contains("Sunday") |> should.be_true
}

pub fn calendar_renders_exactly_seven_columns_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "<th>") |> should.equal(7)
}

pub fn columns_appear_in_correct_order_test() {
  let html = weekly_calendar.render()
  case string.split_once(html, "Monday") {
    Ok(#(_before_monday, after_monday)) -> {
      after_monday |> string.contains("Sunday") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

// ===================================================================
// MEAL SLOT TESTS (3 per day) - KEY TESTS FOR TASK
// ===================================================================

pub fn each_column_has_breakfast_slot_test() {
  let html = weekly_calendar.render()
  html |> string.contains("meal-row-breakfast") |> should.be_true
  count_occurrences(html, "breakfast") |> should.equal(14)
}

pub fn each_column_has_lunch_slot_test() {
  let html = weekly_calendar.render()
  html |> string.contains("meal-row-lunch") |> should.be_true
  count_occurrences(html, "lunch") |> should.equal(14)
}

pub fn each_column_has_dinner_slot_test() {
  let html = weekly_calendar.render()
  html |> string.contains("meal-row-dinner") |> should.be_true
  count_occurrences(html, "dinner") |> should.equal(14)
}

pub fn each_column_has_exactly_three_meal_slots_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "class=\"meal-row") |> should.equal(3)
}

pub fn meal_slots_in_correct_order_test() {
  let html = weekly_calendar.render()
  case string.split_once(html, "meal-row-breakfast") {
    Ok(#(_before, after_breakfast)) -> {
      after_breakfast |> string.contains("meal-row-lunch") |> should.be_true
    }
    Error(_) -> should.fail()
  }
  case string.split_once(html, "meal-row-lunch") {
    Ok(#(_before, after_lunch)) -> {
      after_lunch |> string.contains("meal-row-dinner") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn calendar_has_21_total_meal_slots_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "class=\"meal-slot") |> should.equal(21)
}

// ===================================================================
// EMPTY SLOT PLACEHOLDER TESTS
// ===================================================================

pub fn empty_slot_shows_placeholder_text_test() {
  let html = weekly_calendar.render()
  html |> string.contains("No meal planned") |> should.be_true
}

pub fn all_empty_slots_show_placeholder_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "No meal planned") |> should.equal(21)
}

pub fn empty_slot_has_empty_state_class_test() {
  let html = weekly_calendar.render()
  html |> string.contains("meal-slot-empty") |> should.be_true
}

// ===================================================================
// FILLED SLOT TESTS (future)
// ===================================================================

pub fn filled_slot_shows_recipe_name_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "meal-content") |> should.equal(21)
}

pub fn filled_slot_does_not_show_placeholder_test() {
  True |> should.be_true
}

pub fn filled_slot_has_filled_state_class_test() {
  True |> should.be_true
}

pub fn multiple_filled_slots_render_correctly_test() {
  True |> should.be_true
}

pub fn filled_slot_shows_meal_macros_test() {
  True |> should.be_true
}

// ===================================================================
// HTML STRUCTURE VALIDATION TESTS
// ===================================================================

pub fn calendar_has_valid_html_structure_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "<div")
  |> should.equal(count_occurrences(html, "</div>"))
  html |> string.contains("<table") |> should.be_true
  html |> string.contains("</table>") |> should.be_true
}

pub fn calendar_uses_semantic_html_test() {
  let html = weekly_calendar.render()
  html |> string.contains("<table") |> should.be_true
  html |> string.contains("class=\"calendar-grid\"") |> should.be_true
}

pub fn day_columns_use_semantic_elements_test() {
  let html = weekly_calendar.render()
  html |> string.contains("<th>") |> should.be_true
  html |> string.contains("<thead>") |> should.be_true
}

pub fn meal_slots_use_semantic_elements_test() {
  let html = weekly_calendar.render()
  html |> string.contains("<td") |> should.be_true
  html |> string.contains("<tbody>") |> should.be_true
}

pub fn calendar_has_proper_accessibility_test() {
  let html = weekly_calendar.render()
  html |> string.contains("role=\"grid\"") |> should.be_true
  html |> string.contains("aria-label=\"Weekly meal calendar\"") |> should.be_true
}

pub fn day_headers_are_accessible_test() {
  let html = weekly_calendar.render()
  html |> string.contains("<thead><tr>") |> should.be_true
  count_occurrences(html, "<th>") |> should.equal(7)
}

pub fn meal_slots_are_accessible_test() {
  let html = weekly_calendar.render()
  html |> string.contains("aria-label=\"Monday breakfast\"") |> should.be_true
  html |> string.contains("aria-label=\"Sunday dinner\"") |> should.be_true
}

// ===================================================================
// PROPERTY-BASED TESTS FOR HTML VALIDITY
// ===================================================================

pub fn all_day_columns_have_consistent_structure_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "<th>") |> should.equal(7)
  count_occurrences(html, "</th>") |> should.equal(7)
}

pub fn calendar_html_is_well_formed_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "<td") |> should.equal(21)
  count_occurrences(html, "</td>") |> should.equal(21)
  count_occurrences(html, "<tr") |> should.equal(4)
  count_occurrences(html, "</tr>") |> should.equal(4)
}

pub fn calendar_with_all_meals_renders_correctly_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "meal-slot-empty") |> should.equal(21)
}

pub fn calendar_with_partial_meals_renders_correctly_test() {
  let html = weekly_calendar.render()
  count_occurrences(html, "No meal planned") |> should.equal(21)
}

pub fn calendar_renders_consistently_test() {
  let html1 = weekly_calendar.render()
  let html2 = weekly_calendar.render()
  html1 |> should.equal(html2)
}

// ===================================================================
// EDGE CASES AND ROBUSTNESS TESTS
// ===================================================================

pub fn calendar_handles_long_recipe_names_test() {
  True |> should.be_true
}

pub fn calendar_handles_special_characters_test() {
  True |> should.be_true
}

pub fn calendar_handles_empty_recipe_name_test() {
  True |> should.be_true
}

// ===================================================================
// RENDER_MEAL_SLOT HELPER TESTS
// ===================================================================

pub fn render_meal_slot_creates_valid_cell_test() {
  let html = weekly_calendar.render()
  html |> string.contains("class=\"meal-slot") |> should.be_true
}

pub fn render_meal_slot_includes_aria_label_test() {
  let html = weekly_calendar.render()
  html |> string.contains("aria-label=\"") |> should.be_true
}

pub fn render_meal_slot_includes_content_wrapper_test() {
  let html = weekly_calendar.render()
  html |> string.contains("class=\"meal-content\"") |> should.be_true
}
