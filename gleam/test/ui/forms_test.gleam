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
