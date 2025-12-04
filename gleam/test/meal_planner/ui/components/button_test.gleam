/// UI Component Tests for Button Components
///
/// Test coverage for Cronometer-style button components includes:
/// - Primary orange button (#FF6734)
/// - Hover transform scale(1.05)
/// - Border radius 1.5rem (--radius-2xl)
/// - All button variants (Primary, Secondary, Danger, Success, Warning, Ghost)
/// - Button sizes (Small, Medium, Large)
/// - Submit buttons
/// - Disabled state
/// - Button groups
/// - HTML structure validation
/// - Edge cases and robustness
///
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ui/components/button
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// PRIMARY BUTTON TESTS - Cronometer Orange
// ===================================================================

pub fn primary_button_has_correct_class_test() {
  button.button("Click Me", "/action", ui_types.Primary)
  |> string.contains("btn-primary")
  |> should.be_true
}

pub fn primary_button_renders_complete_html_test() {
  button.button("Submit", "/submit", ui_types.Primary)
  |> should.equal(
    "<a href=\"/submit\" class=\"btn btn-primary\" role=\"button\">Submit</a>",
  )
}

pub fn primary_button_has_role_attribute_test() {
  button.button("Action", "/path", ui_types.Primary)
  |> string.contains("role=\"button\"")
  |> should.be_true
}

// ===================================================================
// ALL BUTTON VARIANTS TESTS
// ===================================================================

pub fn secondary_button_variant_test() {
  button.button("Secondary", "/path", ui_types.Secondary)
  |> string.contains("btn-secondary")
  |> should.be_true
}

pub fn danger_button_variant_test() {
  button.button("Delete", "/delete", ui_types.Danger)
  |> string.contains("btn-danger")
  |> should.be_true
}

pub fn success_button_variant_test() {
  button.button("Save", "/save", ui_types.Success)
  |> string.contains("btn-success")
  |> should.be_true
}

pub fn warning_button_variant_test() {
  button.button("Warning", "/warn", ui_types.Warning)
  |> string.contains("btn-warning")
  |> should.be_true
}

pub fn ghost_button_variant_test() {
  button.button("Ghost", "/ghost", ui_types.Ghost)
  |> string.contains("btn-ghost")
  |> should.be_true
}

pub fn all_variants_have_base_btn_class_test() {
  let variants = [
    ui_types.Primary,
    ui_types.Secondary,
    ui_types.Danger,
    ui_types.Success,
    ui_types.Warning,
    ui_types.Ghost,
  ]

  variants
  |> check_all_have_base_class
}

fn check_all_have_base_class(variants: List(ui_types.ButtonVariant)) -> Nil {
  case variants {
    [] -> Nil
    [variant, ..rest] -> {
      button.button("Test", "/test", variant)
      |> string.contains("class=\"btn ")
      |> should.be_true

      check_all_have_base_class(rest)
    }
  }
}

// ===================================================================
// BUTTON SIZES TESTS
// ===================================================================

pub fn small_button_size_test() {
  button.button_sized("Small", "/path", ui_types.Primary, ui_types.Small)
  |> string.contains("btn-sm")
  |> should.be_true
}

pub fn medium_button_size_test() {
  button.button_sized("Medium", "/path", ui_types.Primary, ui_types.Medium)
  |> string.contains("btn-md")
  |> should.be_true
}

pub fn large_button_size_test() {
  button.button_sized("Large", "/path", ui_types.Primary, ui_types.Large)
  |> string.contains("btn-lg")
  |> should.be_true
}

pub fn sized_button_has_both_variant_and_size_classes_test() {
  let result =
    button.button_sized("Test", "/test", ui_types.Danger, ui_types.Large)

  result |> string.contains("btn-danger") |> should.be_true
  result |> string.contains("btn-lg") |> should.be_true
  result |> string.contains("class=\"btn btn-danger btn-lg\"") |> should.be_true
}

// ===================================================================
// SUBMIT BUTTON TESTS
// ===================================================================

pub fn submit_button_has_correct_type_test() {
  button.submit_button("Submit", ui_types.Primary)
  |> string.contains("type=\"submit\"")
  |> should.be_true
}

pub fn submit_button_renders_button_element_test() {
  button.submit_button("Save", ui_types.Success)
  |> should.equal(
    "<button type=\"submit\" class=\"btn btn-success\">Save</button>",
  )
}

pub fn submit_button_has_variant_class_test() {
  button.submit_button("Delete", ui_types.Danger)
  |> string.contains("btn-danger")
  |> should.be_true
}

// ===================================================================
// DISABLED BUTTON TESTS
// ===================================================================

pub fn disabled_button_has_disabled_attribute_test() {
  button.button_disabled("Disabled", ui_types.Primary)
  |> string.contains("disabled")
  |> should.be_true
}

pub fn disabled_button_has_disabled_class_test() {
  button.button_disabled("Disabled", ui_types.Primary)
  |> string.contains("btn-disabled")
  |> should.be_true
}

pub fn disabled_button_has_aria_disabled_test() {
  button.button_disabled("Disabled", ui_types.Primary)
  |> string.contains("aria-disabled=\"true\"")
  |> should.be_true
}

pub fn disabled_button_renders_complete_html_test() {
  button.button_disabled("Can't Click", ui_types.Secondary)
  |> should.equal(
    "<button disabled class=\"btn btn-secondary btn-disabled\" aria-disabled=\"true\">Can't Click</button>",
  )
}

// ===================================================================
// BUTTON GROUP TESTS
// ===================================================================

pub fn button_group_wraps_buttons_in_container_test() {
  let buttons = [
    button.button("First", "/first", ui_types.Primary),
    button.button("Second", "/second", ui_types.Secondary),
  ]

  button.button_group(buttons)
  |> string.contains("<div class=\"button-group\">")
  |> should.be_true
}

pub fn button_group_contains_all_buttons_test() {
  let buttons = [
    button.button("One", "/one", ui_types.Primary),
    button.button("Two", "/two", ui_types.Secondary),
    button.button("Three", "/three", ui_types.Danger),
  ]

  let result = button.button_group(buttons)

  result |> string.contains("One") |> should.be_true
  result |> string.contains("Two") |> should.be_true
  result |> string.contains("Three") |> should.be_true
}

pub fn button_group_handles_empty_list_test() {
  button.button_group([])
  |> should.equal("<div class=\"button-group\"></div>")
}

pub fn button_group_handles_single_button_test() {
  let buttons = [button.button("Solo", "/solo", ui_types.Primary)]

  button.button_group(buttons)
  |> string.contains("Solo")
  |> should.be_true
}

// ===================================================================
// HTML STRUCTURE VALIDATION TESTS
// ===================================================================

pub fn button_has_valid_html_anchor_structure_test() {
  let result = button.button("Link", "/path", ui_types.Primary)

  // Must start with <a
  result |> string.starts_with("<a ") |> should.be_true

  // Must have href attribute
  result |> string.contains("href=") |> should.be_true

  // Must have class attribute
  result |> string.contains("class=") |> should.be_true

  // Must close with </a>
  result |> string.ends_with("</a>") |> should.be_true
}

pub fn submit_button_has_valid_html_button_structure_test() {
  let result = button.submit_button("Submit", ui_types.Primary)

  // Must start with <button
  result |> string.starts_with("<button ") |> should.be_true

  // Must close with </button>
  result |> string.ends_with("</button>") |> should.be_true
}

pub fn disabled_button_has_valid_html_structure_test() {
  let result = button.button_disabled("Disabled", ui_types.Primary)

  result |> string.starts_with("<button ") |> should.be_true
  result |> string.ends_with("</button>") |> should.be_true
}

// ===================================================================
// EDGE CASES AND ROBUSTNESS TESTS
// ===================================================================

pub fn button_handles_empty_label_test() {
  button.button("", "/path", ui_types.Primary)
  |> string.contains("><")
  |> should.be_true
}

pub fn button_handles_empty_href_test() {
  button.button("Click", "", ui_types.Primary)
  |> string.contains("href=\"\"")
  |> should.be_true
}

pub fn button_handles_special_characters_in_label_test() {
  button.button("Save & Exit", "/save", ui_types.Primary)
  |> string.contains("Save & Exit")
  |> should.be_true
}

pub fn button_preserves_label_exactly_test() {
  let label = "Complex Label <>&\""
  let result = button.button(label, "/path", ui_types.Primary)

  result |> string.contains(label) |> should.be_true
}

pub fn button_handles_url_with_query_params_test() {
  button.button("Link", "/path?id=123&name=test", ui_types.Primary)
  |> string.contains("href=\"/path?id=123&name=test\"")
  |> should.be_true
}

// ===================================================================
// PROPERTY-BASED TESTS FOR HTML VALIDITY
// ===================================================================

pub fn all_button_variants_produce_valid_html_test() {
  let variants = [
    ui_types.Primary,
    ui_types.Secondary,
    ui_types.Danger,
    ui_types.Success,
    ui_types.Warning,
    ui_types.Ghost,
  ]

  variants
  |> check_all_variants_valid_html
}

fn check_all_variants_valid_html(variants: List(ui_types.ButtonVariant)) -> Nil {
  case variants {
    [] -> Nil
    [variant, ..rest] -> {
      let result = button.button("Test", "/test", variant)

      // All buttons must have proper HTML structure
      result |> string.contains("<a ") |> should.be_true
      result |> string.contains("href=") |> should.be_true
      result |> string.contains("class=") |> should.be_true
      result |> string.contains("role=\"button\"") |> should.be_true
      result |> string.ends_with("</a>") |> should.be_true

      check_all_variants_valid_html(rest)
    }
  }
}

pub fn all_button_sizes_produce_valid_html_test() {
  let sizes = [ui_types.Small, ui_types.Medium, ui_types.Large]

  sizes
  |> check_all_sizes_valid_html
}

fn check_all_sizes_valid_html(sizes: List(ui_types.ButtonSize)) -> Nil {
  case sizes {
    [] -> Nil
    [size, ..rest] -> {
      let result = button.button_sized("Test", "/test", ui_types.Primary, size)

      // All sized buttons must have proper HTML structure
      result |> string.contains("<a ") |> should.be_true
      result |> string.contains("href=") |> should.be_true
      result |> string.contains("class=") |> should.be_true
      result |> string.ends_with("</a>") |> should.be_true

      check_all_sizes_valid_html(rest)
    }
  }
}

// ===================================================================
// CRONOMETER STYLE VALIDATION TESTS
// ===================================================================

pub fn buttons_use_cronometer_orange_for_primary_test() {
  // This test verifies that the CSS class for primary buttons is applied
  // The actual orange color (#FF6734) and styling will be tested via CSS tests
  button.button("Orange", "/path", ui_types.Primary)
  |> string.contains("btn-primary")
  |> should.be_true
}

pub fn button_class_structure_supports_cronometer_styling_test() {
  // Verifies the HTML structure allows for:
  // - border-radius: var(--radius-2xl) = 1.5rem
  // - hover: transform scale(1.05)
  // - Primary uses orange color
  let result = button.button("Styled", "/path", ui_types.Primary)

  // Base btn class for global button styles
  result |> string.contains("class=\"btn ") |> should.be_true

  // Variant class for specific styling
  result |> string.contains("btn-primary") |> should.be_true
}

pub fn all_button_types_have_styling_hooks_test() {
  // All button rendering functions should produce elements
  // that can be styled with CSS (have proper classes)

  button.button("Basic", "/p", ui_types.Primary)
  |> string.contains("class=\"btn ")
  |> should.be_true

  button.button_sized("Sized", "/p", ui_types.Primary, ui_types.Large)
  |> string.contains("class=\"btn ")
  |> should.be_true

  button.submit_button("Submit", ui_types.Primary)
  |> string.contains("class=\"btn ")
  |> should.be_true

  button.button_disabled("Disabled", ui_types.Primary)
  |> string.contains("class=\"btn ")
  |> should.be_true
}
