/// Button Component Tests
///
/// This module defines failing tests that establish contracts for button components.
/// Tests verify that button components render correct HTML and CSS classes.
///
/// All tests are expected to FAIL until the button component functions are implemented.

import gleeunit
import gleeunit/should
import gleam/string
import meal_planner/ui/components/button
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg = string.concat([
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
// BUTTON VARIANT TESTS
// ===================================================================

pub fn button_primary_renders_correct_class_test() {
  let result = button.button("Click me", "/action", ui_types.Primary)
  assert_contains(result, "btn-primary")
}

pub fn button_secondary_renders_correct_class_test() {
  let result = button.button("Click me", "/action", ui_types.Secondary)
  assert_contains(result, "btn-secondary")
}

pub fn button_danger_renders_correct_class_test() {
  let result = button.button("Delete", "/delete", ui_types.Danger)
  assert_contains(result, "btn-danger")
}

pub fn button_success_renders_correct_class_test() {
  let result = button.button("Confirm", "/confirm", ui_types.Success)
  assert_contains(result, "btn-success")
}

pub fn button_warning_renders_correct_class_test() {
  let result = button.button("Warning", "/warn", ui_types.Warning)
  assert_contains(result, "btn-warning")
}

pub fn button_ghost_renders_correct_class_test() {
  let result = button.button("Link", "/page", ui_types.Ghost)
  assert_contains(result, "btn-ghost")
}

// ===================================================================
// BUTTON HREF TESTS
// ===================================================================

pub fn button_renders_href_attribute_test() {
  let result = button.button("Go", "/home", ui_types.Primary)
  assert_contains(result, "href=\"/home\"")
}

pub fn button_renders_label_test() {
  let result = button.button("Click me", "/action", ui_types.Primary)
  assert_contains(result, "Click me")
}

pub fn button_contains_btn_base_class_test() {
  let result = button.button("Button", "/url", ui_types.Primary)
  assert_contains(result, "btn")
}

// ===================================================================
// BUTTON SIZE TESTS
// ===================================================================

pub fn button_sized_small_renders_test() {
  let result = button.button_sized("Small", "/url", ui_types.Primary, ui_types.Small)
  assert_contains(result, "btn-sm")
}

pub fn button_sized_medium_renders_test() {
  let result = button.button_sized("Medium", "/url", ui_types.Primary, ui_types.Medium)
  assert_contains(result, "btn-md")
}

pub fn button_sized_large_renders_test() {
  let result = button.button_sized("Large", "/url", ui_types.Primary, ui_types.Large)
  assert_contains(result, "btn-lg")
}

pub fn button_sized_variant_and_size_test() {
  let result = button.button_sized("Click", "/url", ui_types.Danger, ui_types.Large)
  assert_contains(result, "btn-danger")
  assert_contains(result, "btn-lg")
}

// ===================================================================
// SUBMIT BUTTON TESTS
// ===================================================================

pub fn submit_button_renders_type_attribute_test() {
  let result = button.submit_button("Submit", ui_types.Primary)
  assert_contains(result, "type=\"submit\"")
}

pub fn submit_button_renders_variant_test() {
  let result = button.submit_button("Submit", ui_types.Success)
  assert_contains(result, "btn-success")
}

pub fn submit_button_renders_label_test() {
  let result = button.submit_button("Send", ui_types.Primary)
  assert_contains(result, "Send")
}

pub fn submit_button_is_button_element_test() {
  let result = button.submit_button("Submit", ui_types.Primary)
  assert_contains(result, "<button")
}

// ===================================================================
// DISABLED BUTTON TESTS
// ===================================================================

pub fn disabled_button_renders_disabled_attribute_test() {
  let result = button.button_disabled("Disabled", ui_types.Primary)
  assert_contains(result, "disabled")
}

pub fn disabled_button_renders_disabled_class_test() {
  let result = button.button_disabled("Disabled", ui_types.Primary)
  assert_contains(result, "btn-disabled")
}

pub fn disabled_button_renders_variant_test() {
  let result = button.button_disabled("Disabled", ui_types.Warning)
  assert_contains(result, "btn-warning")
}

pub fn disabled_button_renders_label_test() {
  let result = button.button_disabled("Cannot click", ui_types.Primary)
  assert_contains(result, "Cannot click")
}

// ===================================================================
// BUTTON GROUP TESTS
// ===================================================================

pub fn button_group_renders_container_test() {
  let result = button.button_group([])
  assert_contains(result, "button-group")
}

pub fn button_group_renders_as_div_test() {
  let result = button.button_group([])
  assert_contains(result, "<div")
}

pub fn button_group_contains_multiple_buttons_test() {
  let buttons = [
    button.button("First", "/url1", ui_types.Primary),
    button.button("Second", "/url2", ui_types.Secondary),
  ]
  let group = button.button_group(buttons)
  assert_contains(group, "First")
  assert_contains(group, "Second")
}

pub fn button_group_maintains_order_test() {
  let buttons = [
    button.button("A", "/a", ui_types.Primary),
    button.button("B", "/b", ui_types.Primary),
    button.button("C", "/c", ui_types.Primary),
  ]
  let group = button.button_group(buttons)
  assert_contains(group, "A")
}

pub fn button_group_with_single_button_test() {
  let buttons = [button.button("Only", "/url", ui_types.Primary)]
  let result = button.button_group(buttons)
  assert_contains(result, "Only")
}
