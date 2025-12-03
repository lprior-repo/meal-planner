/// Forms Component Tests
///
/// This module defines tests for form input components including search input.
/// Tests verify that components render correct HTML, attributes, and classes.
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ui/components/forms

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg =
        string.concat([
          "\n",
          haystack,
          "\nshould contain\n",
          needle,
        ])
      should.fail()
    }
  }
}

// ===================================================================
// SEARCH INPUT TESTS (Bead meal-planner-rvz.1)
// ===================================================================

pub fn search_input_renders_input_element_test() {
  let result = forms.search_input_with_clear("test", "Search foods...")
  assert_contains(result, "<input")
}

pub fn search_input_renders_type_search_test() {
  let result = forms.search_input_with_clear("", "Search foods...")
  assert_contains(result, "type=\"search\"")
}

pub fn search_input_renders_placeholder_test() {
  let result = forms.search_input_with_clear("", "Search foods...")
  assert_contains(result, "placeholder=\"Search foods...\"")
}

pub fn search_input_renders_query_value_test() {
  let result = forms.search_input_with_clear("chicken", "Search...")
  assert_contains(result, "value=\"chicken\"")
}

pub fn search_input_has_container_div_test() {
  let result = forms.search_input_with_clear("", "Search...")
  assert_contains(result, "class=\"search-input-container\"")
}

pub fn search_input_has_clear_button_when_value_present_test() {
  let result = forms.search_input_with_clear("chicken", "Search...")
  assert_contains(result, "search-clear-btn")
}

pub fn search_input_clear_button_has_type_button_test() {
  let result = forms.search_input_with_clear("test", "Search...")
  assert_contains(result, "type=\"button\"")
}

pub fn search_input_clear_button_hidden_when_empty_test() {
  let result = forms.search_input_with_clear("", "Search...")
  // Clear button should have hidden class when query is empty
  assert_contains(result, "hidden")
}

pub fn search_input_has_debounce_data_attribute_test() {
  let result = forms.search_input_with_clear("", "Search...")
  // Component should have data attribute for JavaScript debouncing (300ms)
  assert_contains(result, "data-debounce=\"300\"")
}

pub fn search_input_has_proper_css_classes_test() {
  let result = forms.search_input_with_clear("test", "Search...")
  assert_contains(result, "class=\"input-search\"")
}

pub fn search_input_has_aria_label_test() {
  let result = forms.search_input_with_clear("", "Search foods...")
  // Should have aria-label for accessibility
  assert_contains(result, "aria-label=")
}

pub fn search_input_autofocus_attribute_test() {
  let result = forms.search_input_with_autofocus("", "Search...", True)
  assert_contains(result, "autofocus")
}

pub fn search_input_no_autofocus_when_false_test() {
  let result = forms.search_input_with_autofocus("", "Search...", False)
  // Should NOT contain autofocus attribute
  case string.contains(result, "autofocus") {
    True -> should.fail()
    False -> Nil
  }
}

// ===================================================================
// SEARCH RESULTS LIST TESTS (Bead meal-planner-rvz.2)
// ===================================================================

pub fn results_list_renders_container_test() {
  let items = [#(1, "Chicken breast", "Protein", "Poultry")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "class=\"search-results-list\"")
}

pub fn results_list_renders_items_test() {
  let items = [
    #(1, "Chicken breast", "Protein", "Poultry"),
    #(2, "Brown rice", "Carbs", "Grains"),
  ]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "Chicken breast")
  assert_contains(result, "Brown rice")
}

pub fn results_list_item_has_data_id_test() {
  let items = [#(123, "Chicken breast", "Protein", "Poultry")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "data-food-id=\"123\"")
}

pub fn results_list_item_shows_type_and_category_test() {
  let items = [#(1, "Chicken breast", "Protein", "Poultry")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "Protein")
  assert_contains(result, "Poultry")
}

pub fn results_list_has_role_listbox_test() {
  let items = [#(1, "Test", "Type", "Cat")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "role=\"listbox\"")
}

pub fn results_list_items_have_role_option_test() {
  let items = [#(1, "Test", "Type", "Cat")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "role=\"option\"")
}

pub fn results_list_has_max_height_class_test() {
  let items = [#(1, "Test", "Type", "Cat")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "max-h-")
}

pub fn results_list_loading_state_test() {
  let result = forms.search_results_loading()
  assert_contains(result, "search-results-loading")
}

pub fn results_list_loading_has_skeleton_items_test() {
  let result = forms.search_results_loading()
  assert_contains(result, "skeleton")
}

pub fn results_list_loading_has_aria_busy_test() {
  let result = forms.search_results_loading()
  assert_contains(result, "aria-busy=\"true\"")
}

pub fn results_list_empty_state_test() {
  let result = forms.search_results_empty("chicken")
  assert_contains(result, "search-results-empty")
}

pub fn results_list_empty_shows_query_test() {
  let result = forms.search_results_empty("chicken")
  assert_contains(result, "chicken")
}

pub fn results_list_empty_has_no_results_message_test() {
  let result = forms.search_results_empty("test")
  assert_contains(result, "No results")
}

pub fn results_list_empty_has_role_status_test() {
  let result = forms.search_results_empty("test")
  assert_contains(result, "role=\"status\"")
}

// ===================================================================
// KEYBOARD NAVIGATION TESTS (Bead meal-planner-rvz.3)
// ===================================================================

pub fn search_combobox_has_role_combobox_test() {
  let result = forms.search_combobox("", "Search...", [], False)
  assert_contains(result, "role=\"combobox\"")
}

pub fn search_combobox_has_aria_expanded_test() {
  let result = forms.search_combobox("test", "Search...", [], True)
  assert_contains(result, "aria-expanded=\"true\"")
}

pub fn search_combobox_aria_expanded_false_when_closed_test() {
  let result = forms.search_combobox("test", "Search...", [], False)
  assert_contains(result, "aria-expanded=\"false\"")
}

pub fn search_combobox_has_aria_controls_test() {
  let result = forms.search_combobox("", "Search...", [], False)
  assert_contains(result, "aria-controls=\"search-results-listbox\"")
}

pub fn search_combobox_input_has_aria_autocomplete_test() {
  let result = forms.search_combobox("", "Search...", [], False)
  assert_contains(result, "aria-autocomplete=\"list\"")
}

pub fn search_combobox_has_keyboard_nav_attributes_test() {
  let result = forms.search_combobox("", "Search...", [], False)
  // Should have data attributes for keyboard event handlers
  assert_contains(result, "data-keyboard-nav=\"true\"")
}

pub fn search_combobox_input_has_aria_activedescendant_test() {
  let result = forms.search_combobox_with_selection("", "Search...", [], False, 2)
  // Should include aria-activedescendant pointing to the selected item
  assert_contains(result, "aria-activedescendant=\"search-result-2\"")
}

pub fn search_result_item_has_unique_id_test() {
  let items = [#(42, "Chicken", "Protein", "Poultry")]
  let result = forms.search_results_list(items, False)
  assert_contains(result, "id=\"search-result-42\"")
}

pub fn search_combobox_renders_input_and_results_test() {
  let items = [#(1, "Test", "Type", "Cat")]
  let result = forms.search_combobox("test", "Search...", items, True)
  // Should contain both input and results
  assert_contains(result, "type=\"search\"")
  assert_contains(result, "search-results-list")
}
