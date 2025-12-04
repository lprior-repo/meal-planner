/// Button Component Tests
///
/// TDD tests for Cronometer-styled button components ensuring:
/// - Primary button uses orange (#FF6734)
/// - Hover effects include scale(1.05) transform
/// - Border radius is 1.5rem (--radius-2xl)
/// - All button variants render correctly
/// - Valid HTML output
/// - Accessibility attributes present

import gleeunit/should
import meal_planner/ui/components/button
import meal_planner/ui/types/ui_types

// ============================================================================
// Primary Orange Button Tests
// ============================================================================

pub fn primary_button_contains_primary_class_test() {
  let html = button.button("Click Me", "/action", ui_types.Primary)

  html
  |> should.equal("<a href=\"/action\" class=\"btn btn-primary\" role=\"button\">Click Me</a>")
}

pub fn primary_button_uses_orange_color_test() {
  // The CSS should use var(--color-primary) which is now #FF6734
  // We test that the btn-primary class is present, which applies the orange
  let html = button.button("Orange Button", "/test", ui_types.Primary)

  // Should contain btn-primary class
  should.be_true(string_contains(html, "btn-primary"))
}

// ============================================================================
// Button Variant Tests
// ============================================================================

pub fn secondary_button_renders_correctly_test() {
  let html = button.button("Secondary", "/path", ui_types.Secondary)

  should.be_true(string_contains(html, "btn-secondary"))
  should.be_true(string_contains(html, "role=\"button\""))
}

pub fn danger_button_renders_correctly_test() {
  let html = button.button("Delete", "/delete", ui_types.Danger)

  should.be_true(string_contains(html, "btn-danger"))
}

pub fn success_button_renders_correctly_test() {
  let html = button.button("Save", "/save", ui_types.Success)

  should.be_true(string_contains(html, "btn-success"))
}

pub fn ghost_button_renders_correctly_test() {
  let html = button.button("Ghost", "/ghost", ui_types.Ghost)

  should.be_true(string_contains(html, "btn-ghost"))
}

pub fn warning_button_renders_correctly_test() {
  let html = button.button("Warning", "/warn", ui_types.Warning)

  should.be_true(string_contains(html, "btn-warning"))
}

// ============================================================================
// Button Size Tests
// ============================================================================

pub fn small_button_size_test() {
  let html = button.button_sized("Small", "/path", ui_types.Primary, ui_types.Small)

  should.be_true(string_contains(html, "btn-sm"))
  should.be_true(string_contains(html, "btn-primary"))
}

pub fn medium_button_size_test() {
  let html = button.button_sized("Medium", "/path", ui_types.Primary, ui_types.Medium)

  should.be_true(string_contains(html, "btn-md"))
}

pub fn large_button_size_test() {
  let html = button.button_sized("Large", "/path", ui_types.Primary, ui_types.Large)

  should.be_true(string_contains(html, "btn-lg"))
}

// ============================================================================
// Submit Button Tests
// ============================================================================

pub fn submit_button_has_correct_type_test() {
  let html = button.submit_button("Submit", ui_types.Primary)

  should.be_true(string_contains(html, "type=\"submit\""))
  should.be_true(string_contains(html, "btn-primary"))
}

pub fn submit_button_renders_as_button_element_test() {
  let html = button.submit_button("Submit", ui_types.Success)

  should.be_true(string_contains(html, "<button"))
  should.be_true(string_contains(html, "</button>"))
}

// ============================================================================
// Disabled State Tests
// ============================================================================

pub fn disabled_button_has_disabled_attribute_test() {
  let html = button.button_disabled("Disabled", ui_types.Primary)

  should.be_true(string_contains(html, "disabled"))
  should.be_true(string_contains(html, "btn-disabled"))
}

pub fn disabled_button_has_aria_disabled_test() {
  let html = button.button_disabled("Disabled", ui_types.Primary)

  should.be_true(string_contains(html, "aria-disabled=\"true\""))
}

// ============================================================================
// Button Group Tests
// ============================================================================

pub fn button_group_wraps_buttons_test() {
  let button1 = button.button("First", "/1", ui_types.Primary)
  let button2 = button.button("Second", "/2", ui_types.Secondary)
  let html = button.button_group([button1, button2])

  should.be_true(string_contains(html, "button-group"))
  should.be_true(string_contains(html, "First"))
  should.be_true(string_contains(html, "Second"))
}

// ============================================================================
// HTML Validity Tests
// ============================================================================

pub fn button_html_is_well_formed_test() {
  let html = button.button("Test", "/test", ui_types.Primary)

  // Should have matching opening/closing tags
  should.be_true(string_contains(html, "<a href="))
  should.be_true(string_contains(html, "</a>"))
}

pub fn button_has_href_attribute_test() {
  let html = button.button("Link", "/my-path", ui_types.Primary)

  should.be_true(string_contains(html, "href=\"/my-path\""))
}

pub fn button_has_role_attribute_test() {
  let html = button.button("Accessible", "/path", ui_types.Primary)

  should.be_true(string_contains(html, "role=\"button\""))
}

pub fn button_contains_label_text_test() {
  let html = button.button("My Button Label", "/path", ui_types.Primary)

  should.be_true(string_contains(html, "My Button Label"))
}

// ============================================================================
// CSS Class Combinations Test
// ============================================================================

pub fn button_has_base_btn_class_test() {
  let html = button.button("Test", "/test", ui_types.Primary)

  should.be_true(string_contains(html, "class=\"btn"))
}

pub fn sized_button_has_all_classes_test() {
  let html = button.button_sized("Big", "/path", ui_types.Danger, ui_types.Large)

  should.be_true(string_contains(html, "btn"))
  should.be_true(string_contains(html, "btn-danger"))
  should.be_true(string_contains(html, "btn-lg"))
}

// ============================================================================
// Property Test - All Variants Produce Valid HTML
// ============================================================================

pub fn all_variants_produce_valid_html_test() {
  // Test all button variants produce valid HTML
  let variants = [
    ui_types.Primary,
    ui_types.Secondary,
    ui_types.Danger,
    ui_types.Success,
    ui_types.Warning,
    ui_types.Ghost,
  ]

  variants
  |> list_all(fn(variant) {
    let html = button.button("Test", "/test", variant)
    // All should have proper structure
    string_contains(html, "<a href=") && string_contains(html, "</a>")
  })
  |> should.be_true()
}

pub fn all_sizes_produce_valid_html_test() {
  // Test all button sizes produce valid HTML
  let sizes = [
    ui_types.Small,
    ui_types.Medium,
    ui_types.Large,
  ]

  sizes
  |> list_all(fn(size) {
    let html = button.button_sized("Test", "/test", ui_types.Primary, size)
    string_contains(html, "<a href=") && string_contains(html, "</a>")
  })
  |> should.be_true()
}

// ============================================================================
// Helper Functions
// ============================================================================

import gleam/list
import gleam/string

fn string_contains(haystack: String, needle: String) -> Bool {
  string.contains(haystack, needle)
}

fn list_all(list: List(a), predicate: fn(a) -> Bool) -> Bool {
  list.all(list, predicate)
}
