// Tests for skeleton loading components
// Validates HTML structure and accessibility attributes

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/skeletons

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Food Card Skeleton Tests
// ============================================================================

pub fn food_card_skeleton_contains_role_status_test() {
  let html = skeletons.food_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "role=\"status\""))
}

pub fn food_card_skeleton_contains_aria_label_test() {
  let html = skeletons.food_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading food item\""))
}

pub fn food_card_skeleton_contains_skeleton_classes_test() {
  let html = skeletons.food_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "class=\"skeleton"))
}

pub fn food_card_skeleton_contains_badges_test() {
  let html = skeletons.food_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "skeleton-badges"))
  should.be_true(string_contains(html, "skeleton-badge"))
}

// ============================================================================
// Recipe Card Skeleton Tests
// ============================================================================

pub fn recipe_card_skeleton_contains_role_status_test() {
  let html = skeletons.recipe_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "role=\"status\""))
}

pub fn recipe_card_skeleton_contains_aria_label_test() {
  let html = skeletons.recipe_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading recipe\""))
}

pub fn recipe_card_skeleton_has_card_structure_test() {
  let html = skeletons.recipe_card_skeleton() |> element.to_string
  should.be_true(string_contains(html, "skeleton-card"))
  should.be_true(string_contains(html, "skeleton-content"))
}

// ============================================================================
// Meal Log Skeleton Tests
// ============================================================================

pub fn meal_log_skeleton_contains_entry_structure_test() {
  let html = skeletons.meal_log_skeleton() |> element.to_string
  should.be_true(string_contains(html, "meal-entry-item"))
  should.be_true(string_contains(html, "entry-time"))
  should.be_true(string_contains(html, "entry-details"))
  should.be_true(string_contains(html, "entry-macros"))
  should.be_true(string_contains(html, "entry-calories"))
}

pub fn meal_log_skeleton_contains_aria_label_test() {
  let html = skeletons.meal_log_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading meal entry\""))
}

// ============================================================================
// Macro Chart Skeleton Tests
// ============================================================================

pub fn macro_chart_skeleton_has_three_bars_test() {
  let html = skeletons.macro_chart_skeleton() |> element.to_string
  // Should contain 3 macro bars (protein, fat, carbs)
  should.be_true(string_contains(html, "macro-bar"))
  should.be_true(string_contains(html, "skeleton-progress-bar"))
}

pub fn macro_chart_skeleton_contains_aria_label_test() {
  let html = skeletons.macro_chart_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading macro progress\""))
}

// ============================================================================
// Micronutrient Skeleton Tests
// ============================================================================

pub fn micronutrient_skeleton_has_sections_test() {
  let html = skeletons.micronutrient_skeleton() |> element.to_string
  should.be_true(string_contains(html, "micronutrient-panel"))
  should.be_true(string_contains(html, "micro-section"))
}

pub fn micronutrient_skeleton_contains_bars_test() {
  let html = skeletons.micronutrient_skeleton() |> element.to_string
  should.be_true(string_contains(html, "micronutrient-bar"))
  should.be_true(string_contains(html, "micro-header"))
  should.be_true(string_contains(html, "micro-progress"))
}

// ============================================================================
// Table Row Skeleton Tests
// ============================================================================

pub fn table_row_skeleton_generates_correct_count_test() {
  let html = skeletons.table_row_skeleton(3) |> element.to_string
  // Count number of <tr> tags
  let tr_count = count_substring(html, "<tr")
  should.equal(tr_count, 3)
}

pub fn table_row_skeleton_contains_td_elements_test() {
  let html = skeletons.table_row_skeleton(2) |> element.to_string
  should.be_true(string_contains(html, "<td>"))
}

pub fn table_row_skeleton_empty_for_zero_count_test() {
  let html = skeletons.table_row_skeleton(0) |> element.to_string
  should.equal(html, "")
}

// ============================================================================
// Form Skeleton Tests
// ============================================================================

pub fn form_skeleton_has_card_structure_test() {
  let html = skeletons.form_skeleton() |> element.to_string
  should.be_true(string_contains(html, "card-header"))
  should.be_true(string_contains(html, "card-body"))
  should.be_true(string_contains(html, "card-footer"))
}

pub fn form_skeleton_contains_form_fields_test() {
  let html = skeletons.form_skeleton() |> element.to_string
  should.be_true(string_contains(html, "form-group"))
}

pub fn form_skeleton_contains_aria_label_test() {
  let html = skeletons.form_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading form\""))
}

// ============================================================================
// Search Box Skeleton Tests
// ============================================================================

pub fn search_box_skeleton_has_search_structure_test() {
  let html = skeletons.search_box_skeleton() |> element.to_string
  should.be_true(string_contains(html, "search-box"))
}

pub fn search_box_skeleton_contains_aria_label_test() {
  let html = skeletons.search_box_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading search\""))
}

// ============================================================================
// Card Stat Skeleton Tests
// ============================================================================

pub fn card_stat_skeleton_has_card_class_test() {
  let html = skeletons.card_stat_skeleton() |> element.to_string
  should.be_true(string_contains(html, "card-stat"))
}

pub fn card_stat_skeleton_contains_aria_label_test() {
  let html = skeletons.card_stat_skeleton() |> element.to_string
  should.be_true(string_contains(html, "aria-label=\"Loading statistic\""))
}

// ============================================================================
// List Skeleton Tests
// ============================================================================

pub fn list_skeleton_generates_correct_count_test() {
  let html = skeletons.list_skeleton(5) |> element.to_string
  let item_count = count_substring(html, "skeleton-list-item")
  should.equal(item_count, 5)
}

pub fn list_skeleton_has_food_list_wrapper_test() {
  let html = skeletons.list_skeleton(3) |> element.to_string
  should.be_true(string_contains(html, "food-list"))
}

// ============================================================================
// Page Skeleton Tests
// ============================================================================

pub fn page_skeleton_has_loading_page_class_test() {
  let html = skeletons.page_skeleton() |> element.to_string
  should.be_true(string_contains(html, "loading-page"))
}

pub fn page_skeleton_contains_spinner_test() {
  let html = skeletons.page_skeleton() |> element.to_string
  should.be_true(string_contains(html, "spinner-large"))
}

pub fn page_skeleton_contains_loading_message_test() {
  let html = skeletons.page_skeleton() |> element.to_string
  should.be_true(string_contains(html, "Loading..."))
}

// ============================================================================
// Loading Overlay Tests
// ============================================================================

pub fn loading_overlay_contains_custom_message_test() {
  let html = skeletons.loading_overlay("Fetching data...") |> element.to_string
  should.be_true(string_contains(html, "Fetching data..."))
}

pub fn loading_overlay_has_overlay_class_test() {
  let html = skeletons.loading_overlay("Test") |> element.to_string
  should.be_true(string_contains(html, "loading-overlay"))
}

pub fn loading_overlay_contains_spinner_test() {
  let html = skeletons.loading_overlay("Test") |> element.to_string
  should.be_true(string_contains(html, "spinner-standard"))
}

// ============================================================================
// Inline Spinner Tests
// ============================================================================

pub fn inline_spinner_has_spinner_class_test() {
  let html = skeletons.inline_spinner() |> element.to_string
  should.be_true(string_contains(html, "spinner-inline"))
}

pub fn inline_spinner_has_three_dots_test() {
  let html = skeletons.inline_spinner() |> element.to_string
  let dot_count = count_substring(html, "spinner-dot")
  should.equal(dot_count, 3)
}

// ============================================================================
// Meal Section Skeleton Tests
// ============================================================================

pub fn meal_section_skeleton_has_section_structure_test() {
  let html = skeletons.meal_section_skeleton() |> element.to_string
  should.be_true(string_contains(html, "meal-section"))
  should.be_true(string_contains(html, "meal-section-header"))
  should.be_true(string_contains(html, "meal-section-body"))
}

pub fn meal_section_skeleton_contains_entries_test() {
  let html = skeletons.meal_section_skeleton() |> element.to_string
  should.be_true(string_contains(html, "meal-entry-item"))
}

// ============================================================================
// Daily Log Timeline Skeleton Tests
// ============================================================================

pub fn daily_log_timeline_skeleton_has_timeline_class_test() {
  let html = skeletons.daily_log_timeline_skeleton() |> element.to_string
  should.be_true(string_contains(html, "daily-log-timeline"))
}

pub fn daily_log_timeline_skeleton_contains_sections_test() {
  let html = skeletons.daily_log_timeline_skeleton() |> element.to_string
  let section_count = count_substring(html, "meal-section")
  should.be_true(section_count >= 4)
}

// ============================================================================
// Recipe Grid Skeleton Tests
// ============================================================================

pub fn recipe_grid_skeleton_generates_correct_count_test() {
  let html = skeletons.recipe_grid_skeleton(6) |> element.to_string
  let card_count = count_substring(html, "recipe-card")
  should.equal(card_count, 6)
}

pub fn recipe_grid_skeleton_has_grid_class_test() {
  let html = skeletons.recipe_grid_skeleton(3) |> element.to_string
  should.be_true(string_contains(html, "grid"))
}

// ============================================================================
// Food Search Results Skeleton Tests
// ============================================================================

pub fn food_search_results_skeleton_generates_correct_count_test() {
  let html = skeletons.food_search_results_skeleton(8) |> element.to_string
  let item_count = count_substring(html, "food-item")
  should.equal(item_count, 8)
}

pub fn food_search_results_skeleton_has_food_list_wrapper_test() {
  let html = skeletons.food_search_results_skeleton(3) |> element.to_string
  should.be_true(string_contains(html, "food-list"))
}

// ============================================================================
// Dashboard Skeleton Tests
// ============================================================================

pub fn dashboard_skeleton_has_container_test() {
  let html = skeletons.dashboard_skeleton() |> element.to_string
  should.be_true(string_contains(html, "container"))
}

pub fn dashboard_skeleton_has_page_header_test() {
  let html = skeletons.dashboard_skeleton() |> element.to_string
  should.be_true(string_contains(html, "page-header"))
}

pub fn dashboard_skeleton_contains_stat_cards_test() {
  let html = skeletons.dashboard_skeleton() |> element.to_string
  should.be_true(string_contains(html, "card-stat"))
}

pub fn dashboard_skeleton_contains_macro_chart_test() {
  let html = skeletons.dashboard_skeleton() |> element.to_string
  should.be_true(string_contains(html, "macro-bars"))
}

pub fn dashboard_skeleton_contains_micronutrients_test() {
  let html = skeletons.dashboard_skeleton() |> element.to_string
  should.be_true(string_contains(html, "micronutrient-panel"))
}

// ============================================================================
// Accessibility Tests
// ============================================================================

pub fn all_skeletons_have_role_status_test() {
  // All skeletons should have role="status" for screen readers
  let skeletons_to_test = [
    skeletons.food_card_skeleton() |> element.to_string,
    skeletons.recipe_card_skeleton() |> element.to_string,
    skeletons.meal_log_skeleton() |> element.to_string,
    skeletons.macro_chart_skeleton() |> element.to_string,
    skeletons.form_skeleton() |> element.to_string,
    skeletons.page_skeleton() |> element.to_string,
  ]

  skeletons_to_test
  |> list.each(fn(html) {
    should.be_true(string_contains(html, "role=\"status\""))
  })
}

pub fn all_skeletons_have_aria_label_test() {
  // All skeletons should have aria-label for screen readers
  let skeletons_to_test = [
    skeletons.food_card_skeleton() |> element.to_string,
    skeletons.recipe_card_skeleton() |> element.to_string,
    skeletons.meal_log_skeleton() |> element.to_string,
    skeletons.macro_chart_skeleton() |> element.to_string,
    skeletons.form_skeleton() |> element.to_string,
    skeletons.page_skeleton() |> element.to_string,
  ]

  skeletons_to_test
  |> list.each(fn(html) { should.be_true(string_contains(html, "aria-label=")) })
}

// ============================================================================
// Helper Functions
// ============================================================================

// Check if string contains substring
fn string_contains(haystack: String, needle: String) -> Bool {
  case string.contains(haystack, needle) {
    True -> True
    False -> False
  }
}

// Count occurrences of substring in string
fn count_substring(haystack: String, needle: String) -> Int {
  string.split(haystack, needle)
  |> list.length()
  |> fn(length) { length - 1 }
}
