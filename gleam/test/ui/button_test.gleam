/// Button Component Tests
///
/// This module defines failing tests that establish contracts for button components.
/// Tests verify that button components render correct HTML and CSS classes.
///
/// All tests are expected to FAIL until the button component functions are implemented.

import gleeunit
import gleeunit/should
import meal_planner/ui/components/button
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// BUTTON VARIANT TESTS
// ===================================================================

pub fn button_primary_renders_correct_class_test() {
  button.button("Click me", "/action", ui_types.Primary)
  |> should.contain("btn-primary")
}

pub fn button_secondary_renders_correct_class_test() {
  button.button("Click me", "/action", ui_types.Secondary)
  |> should.contain("btn-secondary")
}

pub fn button_danger_renders_correct_class_test() {
  button.button("Delete", "/delete", ui_types.Danger)
  |> should.contain("btn-danger")
}

pub fn button_success_renders_correct_class_test() {
  button.button("Confirm", "/confirm", ui_types.Success)
  |> should.contain("btn-success")
}

pub fn button_warning_renders_correct_class_test() {
  button.button("Warning", "/warn", ui_types.Warning)
  |> should.contain("btn-warning")
}

pub fn button_ghost_renders_correct_class_test() {
  button.button("Link", "/page", ui_types.Ghost)
  |> should.contain("btn-ghost")
}

// ===================================================================
// BUTTON HREF TESTS
// ===================================================================

pub fn button_renders_href_attribute_test() {
  button.button("Go", "/home", ui_types.Primary)
  |> should.contain("href=\"/home\"")
}

pub fn button_renders_label_test() {
  button.button("Click me", "/action", ui_types.Primary)
  |> should.contain("Click me")
}

pub fn button_contains_btn_base_class_test() {
  button.button("Button", "/url", ui_types.Primary)
  |> should.contain("btn")
}

// ===================================================================
// BUTTON SIZE TESTS
// ===================================================================

pub fn button_sized_small_renders_test() {
  button.button_sized("Small", "/url", ui_types.Primary, ui_types.Small)
  |> should.contain("btn-sm")
}

pub fn button_sized_medium_renders_test() {
  button.button_sized("Medium", "/url", ui_types.Primary, ui_types.Medium)
  |> should.contain("btn-md")
}

pub fn button_sized_large_renders_test() {
  button.button_sized("Large", "/url", ui_types.Primary, ui_types.Large)
  |> should.contain("btn-lg")
}

pub fn button_sized_variant_and_size_test() {
  button.button_sized("Click", "/url", ui_types.Danger, ui_types.Large)
  |> should.contain("btn-danger")
  |> should.contain("btn-lg")
}

// ===================================================================
// SUBMIT BUTTON TESTS
// ===================================================================

pub fn submit_button_renders_type_attribute_test() {
  button.submit_button("Submit", ui_types.Primary)
  |> should.contain("type=\"submit\"")
}

pub fn submit_button_renders_variant_test() {
  button.submit_button("Submit", ui_types.Success)
  |> should.contain("btn-success")
}

pub fn submit_button_renders_label_test() {
  button.submit_button("Send", ui_types.Primary)
  |> should.contain("Send")
}

pub fn submit_button_is_button_element_test() {
  button.submit_button("Submit", ui_types.Primary)
  |> should.contain("<button")
}

// ===================================================================
// DISABLED BUTTON TESTS
// ===================================================================

pub fn disabled_button_renders_disabled_attribute_test() {
  button.button_disabled("Disabled", ui_types.Primary)
  |> should.contain("disabled")
}

pub fn disabled_button_renders_disabled_class_test() {
  button.button_disabled("Disabled", ui_types.Primary)
  |> should.contain("btn-disabled")
}

pub fn disabled_button_renders_variant_test() {
  button.button_disabled("Disabled", ui_types.Warning)
  |> should.contain("btn-warning")
}

pub fn disabled_button_renders_label_test() {
  button.button_disabled("Cannot click", ui_types.Primary)
  |> should.contain("Cannot click")
}

// ===================================================================
// BUTTON GROUP TESTS
// ===================================================================

pub fn button_group_renders_container_test() {
  button.button_group([])
  |> should.contain("button-group")
}

pub fn button_group_renders_as_div_test() {
  button.button_group([])
  |> should.contain("<div")
}

pub fn button_group_contains_multiple_buttons_test() {
  let buttons = [
    button.button("First", "/url1", ui_types.Primary),
    button.button("Second", "/url2", ui_types.Secondary),
  ]
  let group = button.button_group(buttons)
  group
  |> should.contain("First")
  |> should.contain("Second")
}

pub fn button_group_maintains_order_test() {
  let buttons = [
    button.button("A", "/a", ui_types.Primary),
    button.button("B", "/b", ui_types.Primary),
    button.button("C", "/c", ui_types.Primary),
  ]
  let group = button.button_group(buttons)
  let a_pos = case string.contains(group, "A") {
    True -> string.length(group) - string.length(string.drop_start(group, string.length(group)))
    False -> 0
  }
  let b_pos = case string.contains(group, "B") {
    True -> string.length(group) - string.length(string.drop_start(group, string.length(group)))
    False -> 0
  }
  a_pos
  |> should.be_true
}

// Import string utility
import gleam/string

pub fn button_group_with_single_button_test() {
  let buttons = [button.button("Only", "/url", ui_types.Primary)]
  button.button_group(buttons)
  |> should.contain("Only")
}
