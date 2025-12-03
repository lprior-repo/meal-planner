/// Button Component Tests
///
/// Comprehensive test suite for button UI components following Martin Fowler's
/// UI testing principles:
/// - Test behavior, not implementation
/// - Use semantic queries (verify HTML output)
/// - Verify user-facing output
/// - Keep tests maintainable
///
/// Test Categories:
/// 1. Rendering Tests - Verify correct HTML output
/// 2. Property Tests - Validate all variants and sizes
/// 3. Accessibility Tests - Check semantic HTML and attributes
/// 4. State Tests - Default, disabled states
/// 5. Integration Tests - Button groups and composition
import gleam/string
import gleeunit/should
import meal_planner/ui/components/button
import meal_planner/ui/types/ui_types

// ===================================================================
// BASIC RENDERING TESTS
// ===================================================================

/// Test basic button renders with correct HTML structure
pub fn button_renders_basic_html_test() {
  // GIVEN: A button with Primary variant
  let html = button.button("Click Me", "/action", ui_types.Primary)

  // THEN: Should render anchor tag with correct attributes
  html
  |> should.equal("<a href=\"/action\" class=\"btn btn-primary\">Click Me</a>")
}

/// Test button preserves label text exactly
pub fn button_renders_label_correctly_test() {
  // GIVEN: A button with special characters in label
  let html = button.button("Save & Continue", "/save", ui_types.Success)

  // THEN: Should preserve label text without escaping
  html
  |> string.contains("Save & Continue")
  |> should.be_true()
}

/// Test button renders href attribute correctly
pub fn button_renders_href_correctly_test() {
  // GIVEN: A button with URL path
  let html = button.button("Navigate", "/dashboard/meals", ui_types.Secondary)

  // THEN: Should contain correct href attribute
  html
  |> string.contains("href=\"/dashboard/meals\"")
  |> should.be_true()
}

// ===================================================================
// VARIANT PROPERTY TESTS (All ButtonVariant cases)
// ===================================================================

/// Test Primary variant renders correct CSS class
pub fn button_primary_variant_test() {
  let html = button.button("Primary", "/", ui_types.Primary)

  html
  |> string.contains("btn-primary")
  |> should.be_true()
}

/// Test Secondary variant renders correct CSS class
pub fn button_secondary_variant_test() {
  let html = button.button("Secondary", "/", ui_types.Secondary)

  html
  |> string.contains("btn-secondary")
  |> should.be_true()
}

/// Test Danger variant renders correct CSS class
pub fn button_danger_variant_test() {
  let html = button.button("Danger", "/", ui_types.Danger)

  html
  |> string.contains("btn-danger")
  |> should.be_true()
}

/// Test Success variant renders correct CSS class
pub fn button_success_variant_test() {
  let html = button.button("Success", "/", ui_types.Success)

  html
  |> string.contains("btn-success")
  |> should.be_true()
}

/// Test Warning variant renders correct CSS class
pub fn button_warning_variant_test() {
  let html = button.button("Warning", "/", ui_types.Warning)

  html
  |> string.contains("btn-warning")
  |> should.be_true()
}

/// Test Ghost variant renders correct CSS class
pub fn button_ghost_variant_test() {
  let html = button.button("Ghost", "/", ui_types.Ghost)

  html
  |> string.contains("btn-ghost")
  |> should.be_true()
}

// ===================================================================
// SIZE PROPERTY TESTS (All ButtonSize cases)
// ===================================================================

/// Test Small size renders correct CSS class
pub fn button_small_size_test() {
  let html =
    button.button_sized("Small", "/", ui_types.Primary, ui_types.Small)

  html
  |> string.contains("btn-sm")
  |> should.be_true()
}

/// Test Medium size renders correct CSS class
pub fn button_medium_size_test() {
  let html =
    button.button_sized("Medium", "/", ui_types.Primary, ui_types.Medium)

  html
  |> string.contains("btn-md")
  |> should.be_true()
}

/// Test Large size renders correct CSS class
pub fn button_large_size_test() {
  let html =
    button.button_sized("Large", "/", ui_types.Primary, ui_types.Large)

  html
  |> string.contains("btn-lg")
  |> should.be_true()
}

/// Test sized button combines variant and size classes
pub fn button_sized_combines_classes_test() {
  let html =
    button.button_sized("Test", "/test", ui_types.Danger, ui_types.Large)

  // THEN: Should have both variant and size classes
  html
  |> string.contains("btn-danger")
  |> should.be_true()

  html
  |> string.contains("btn-lg")
  |> should.be_true()
}

/// Test sized button maintains base btn class
pub fn button_sized_has_base_class_test() {
  let html =
    button.button_sized("Test", "/", ui_types.Secondary, ui_types.Small)

  html
  |> string.contains("class=\"btn")
  |> should.be_true()
}

// ===================================================================
// SUBMIT BUTTON TESTS
// ===================================================================

/// Test submit button renders button element
pub fn submit_button_renders_button_element_test() {
  let html = button.submit_button("Submit", ui_types.Primary)

  // THEN: Should render <button> element, not <a>
  html
  |> string.starts_with("<button")
  |> should.be_true()

  html
  |> string.ends_with("</button>")
  |> should.be_true()
}

/// Test submit button has correct type attribute
pub fn submit_button_has_type_submit_test() {
  let html = button.submit_button("Submit Form", ui_types.Success)

  // THEN: Should have type="submit" attribute
  html
  |> string.contains("type=\"submit\"")
  |> should.be_true()
}

/// Test submit button renders variant class
pub fn submit_button_renders_variant_test() {
  let html = button.submit_button("Save", ui_types.Success)

  html
  |> string.contains("btn-success")
  |> should.be_true()
}

/// Test submit button does not have href attribute
pub fn submit_button_no_href_test() {
  let html = button.submit_button("Submit", ui_types.Primary)

  // THEN: Should not contain href (since it's a button, not anchor)
  html
  |> string.contains("href")
  |> should.be_false()
}

// ===================================================================
// DISABLED STATE TESTS
// ===================================================================

/// Test disabled button has disabled attribute
pub fn disabled_button_has_disabled_attribute_test() {
  let html = button.button_disabled("Disabled", ui_types.Primary)

  // THEN: Should have disabled attribute
  html
  |> string.contains("disabled")
  |> should.be_true()
}

/// Test disabled button has disabled CSS class
pub fn disabled_button_has_disabled_class_test() {
  let html = button.button_disabled("Can't Click", ui_types.Secondary)

  // THEN: Should have btn-disabled class
  html
  |> string.contains("btn-disabled")
  |> should.be_true()
}

/// Test disabled button renders as button element
pub fn disabled_button_renders_button_element_test() {
  let html = button.button_disabled("Disabled", ui_types.Danger)

  // THEN: Should render <button> element
  html
  |> string.starts_with("<button")
  |> should.be_true()
}

/// Test disabled button maintains variant class
pub fn disabled_button_maintains_variant_test() {
  let html = button.button_disabled("Disabled", ui_types.Warning)

  // THEN: Should have both variant and disabled classes
  html
  |> string.contains("btn-warning")
  |> should.be_true()

  html
  |> string.contains("btn-disabled")
  |> should.be_true()
}

// ===================================================================
// BUTTON GROUP TESTS
// ===================================================================

/// Test button group wraps buttons in container
pub fn button_group_renders_container_test() {
  let btn1 = button.button("First", "/1", ui_types.Primary)
  let btn2 = button.button("Second", "/2", ui_types.Secondary)
  let html = button.button_group([btn1, btn2])

  // THEN: Should wrap in div with button-group class
  html
  |> string.starts_with("<div class=\"button-group\">")
  |> should.be_true()

  html
  |> string.ends_with("</div>")
  |> should.be_true()
}

/// Test button group contains all buttons
pub fn button_group_contains_all_buttons_test() {
  let btn1 = button.button("One", "/1", ui_types.Primary)
  let btn2 = button.button("Two", "/2", ui_types.Secondary)
  let btn3 = button.button("Three", "/3", ui_types.Success)
  let html = button.button_group([btn1, btn2, btn3])

  // THEN: Should contain all three buttons
  html
  |> string.contains("One")
  |> should.be_true()

  html
  |> string.contains("Two")
  |> should.be_true()

  html
  |> string.contains("Three")
  |> should.be_true()
}

/// Test button group handles empty list
pub fn button_group_empty_list_test() {
  let html = button.button_group([])

  // THEN: Should render empty container
  html
  |> should.equal("<div class=\"button-group\"></div>")
}

/// Test button group preserves button order
pub fn button_group_preserves_order_test() {
  let btn1 = button.button("First", "/", ui_types.Primary)
  let btn2 = button.button("Second", "/", ui_types.Secondary)
  let html = button.button_group([btn1, btn2])

  // THEN: Both buttons should be present in the group
  html
  |> string.contains("First")
  |> should.be_true()

  html
  |> string.contains("Second")
  |> should.be_true()

  // AND: Should be concatenated (First appears before Second in source)
  html
  |> string.contains("First</a><a")
  |> should.be_true()
}

/// Test button group with mixed button types
pub fn button_group_mixed_types_test() {
  let link_btn = button.button("Link", "/link", ui_types.Primary)
  let submit_btn = button.submit_button("Submit", ui_types.Success)
  let disabled_btn = button.button_disabled("Disabled", ui_types.Secondary)
  let html = button.button_group([link_btn, submit_btn, disabled_btn])

  // THEN: Should contain all button types
  html
  |> string.contains("href=\"/link\"")
  |> should.be_true()

  html
  |> string.contains("type=\"submit\"")
  |> should.be_true()

  html
  |> string.contains("disabled")
  |> should.be_true()
}

// ===================================================================
// ACCESSIBILITY TESTS
// ===================================================================

/// Test button link uses semantic anchor tag
pub fn button_link_semantic_element_test() {
  let html = button.button("Navigate", "/page", ui_types.Primary)

  // THEN: Should use <a> tag for navigation
  html
  |> string.contains("<a href")
  |> should.be_true()
}

/// Test submit button uses semantic button tag
pub fn submit_button_semantic_element_test() {
  let html = button.submit_button("Submit", ui_types.Primary)

  // THEN: Should use <button> tag for form submission
  html
  |> string.contains("<button type=\"submit\"")
  |> should.be_true()
}

/// Test disabled button uses button tag not anchor
pub fn disabled_button_semantic_element_test() {
  let html = button.button_disabled("Disabled", ui_types.Primary)

  // THEN: Should use <button> tag (can't disable anchors properly)
  html
  |> string.starts_with("<button")
  |> should.be_true()
}

// ===================================================================
// EDGE CASE TESTS
// ===================================================================

/// Test button with empty label
pub fn button_empty_label_test() {
  let html = button.button("", "/action", ui_types.Primary)

  // THEN: Should render but with empty label
  html
  |> string.contains("><")
  |> should.be_true()
}

/// Test button with URL containing query params
pub fn button_url_with_query_params_test() {
  let html = button.button("Search", "/search?q=test&page=1", ui_types.Primary)

  // THEN: Should preserve query parameters
  html
  |> string.contains("href=\"/search?q=test&page=1\"")
  |> should.be_true()
}

/// Test button with URL containing anchors
pub fn button_url_with_anchor_test() {
  let html = button.button("Jump", "/page#section", ui_types.Primary)

  // THEN: Should preserve anchor fragment
  html
  |> string.contains("href=\"/page#section\"")
  |> should.be_true()
}

/// Test button with special characters in label
pub fn button_special_chars_label_test() {
  let html = button.button("<script>alert('xss')</script>", "/", ui_types.Primary)

  // THEN: Label should be included as-is (HTML escaping is client responsibility)
  html
  |> string.contains("<script>alert('xss')</script>")
  |> should.be_true()
}

/// Test button with long label text
pub fn button_long_label_test() {
  let long_label =
    "This is a very long button label that might wrap or truncate in the UI"
  let html = button.button(long_label, "/", ui_types.Primary)

  // THEN: Should preserve full label
  html
  |> string.contains(long_label)
  |> should.be_true()
}

// ===================================================================
// INTEGRATION TESTS (Component Composition)
// ===================================================================

/// Test creating action button group (Save, Cancel)
pub fn action_button_group_test() {
  let save_btn = button.submit_button("Save Changes", ui_types.Success)
  let cancel_btn = button.button("Cancel", "/back", ui_types.Secondary)
  let html = button.button_group([save_btn, cancel_btn])

  // THEN: Should have proper form action group structure
  html
  |> string.contains("button-group")
  |> should.be_true()

  html
  |> string.contains("type=\"submit\"")
  |> should.be_true()

  html
  |> string.contains("href=\"/back\"")
  |> should.be_true()
}

/// Test pagination button group
pub fn pagination_button_group_test() {
  let prev = button.button_sized("← Previous", "/page/1", ui_types.Ghost, ui_types.Small)
  let next = button.button_sized("Next →", "/page/3", ui_types.Ghost, ui_types.Small)
  let html = button.button_group([prev, next])

  // THEN: Should render pagination controls
  html
  |> string.contains("Previous")
  |> should.be_true()

  html
  |> string.contains("Next")
  |> should.be_true()

  html
  |> string.contains("btn-sm")
  |> should.be_true()
}

/// Test button group with single button
pub fn button_group_single_button_test() {
  let btn = button.button("Single", "/action", ui_types.Primary)
  let html = button.button_group([btn])

  // THEN: Should still wrap in container
  html
  |> string.contains("<div class=\"button-group\">")
  |> should.be_true()

  html
  |> string.contains("Single")
  |> should.be_true()
}

// ===================================================================
// SNAPSHOT TESTS (Full HTML Output Verification)
// ===================================================================

/// Test complete HTML snapshot for primary button
pub fn snapshot_primary_button_test() {
  let html = button.button("Sign In", "/auth/login", ui_types.Primary)

  html
  |> should.equal(
    "<a href=\"/auth/login\" class=\"btn btn-primary\">Sign In</a>",
  )
}

/// Test complete HTML snapshot for sized button
pub fn snapshot_sized_button_test() {
  let html =
    button.button_sized("Download", "/download", ui_types.Success, ui_types.Large)

  html
  |> should.equal(
    "<a href=\"/download\" class=\"btn btn-success btn-lg\">Download</a>",
  )
}

/// Test complete HTML snapshot for submit button
pub fn snapshot_submit_button_test() {
  let html = button.submit_button("Create Account", ui_types.Primary)

  html
  |> should.equal(
    "<button type=\"submit\" class=\"btn btn-primary\">Create Account</button>",
  )
}

/// Test complete HTML snapshot for disabled button
pub fn snapshot_disabled_button_test() {
  let html = button.button_disabled("Processing...", ui_types.Primary)

  html
  |> should.equal(
    "<button disabled class=\"btn btn-primary btn-disabled\">Processing...</button>",
  )
}

/// Test complete HTML snapshot for button group
pub fn snapshot_button_group_test() {
  let btn1 = button.button("Edit", "/edit", ui_types.Primary)
  let btn2 = button.button("Delete", "/delete", ui_types.Danger)
  let html = button.button_group([btn1, btn2])

  html
  |> should.equal(
    "<div class=\"button-group\"><a href=\"/edit\" class=\"btn btn-primary\">Edit</a><a href=\"/delete\" class=\"btn btn-danger\">Delete</a></div>",
  )
}

// ===================================================================
// CLASS COMPOSITION TESTS
// ===================================================================

/// Test all buttons have base 'btn' class
pub fn all_buttons_have_base_class_test() {
  let basic = button.button("Test", "/", ui_types.Primary)
  let sized = button.button_sized("Test", "/", ui_types.Primary, ui_types.Large)
  let submit = button.submit_button("Test", ui_types.Primary)
  let disabled = button.button_disabled("Test", ui_types.Primary)

  // THEN: All should contain base 'btn' class
  basic
  |> string.contains("class=\"btn")
  |> should.be_true()

  sized
  |> string.contains("class=\"btn")
  |> should.be_true()

  submit
  |> string.contains("class=\"btn")
  |> should.be_true()

  disabled
  |> string.contains("class=\"btn")
  |> should.be_true()
}

/// Test variant classes are mutually exclusive
pub fn variant_classes_mutually_exclusive_test() {
  let html = button.button("Test", "/", ui_types.Primary)

  // THEN: Should only have one variant class
  let has_primary = string.contains(html, "btn-primary")
  let has_secondary = string.contains(html, "btn-secondary")
  let has_danger = string.contains(html, "btn-danger")

  has_primary
  |> should.be_true()

  has_secondary
  |> should.be_false()

  has_danger
  |> should.be_false()
}

/// Test size classes don't appear on basic buttons
pub fn basic_button_no_size_class_test() {
  let html = button.button("Test", "/", ui_types.Primary)

  // THEN: Should not have size classes
  html
  |> string.contains("btn-sm")
  |> should.be_false()

  html
  |> string.contains("btn-md")
  |> should.be_false()

  html
  |> string.contains("btn-lg")
  |> should.be_false()
}
