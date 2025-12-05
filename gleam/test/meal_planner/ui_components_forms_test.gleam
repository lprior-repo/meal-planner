/// UI Forms Component Tests
///
/// Comprehensive test suite following Martin Fowler's form testing principles:
/// 1. Test user workflows and interactions
/// 2. Validate error messages and states
/// 3. Test edge cases (empty, invalid, boundary values)
/// 4. Verify data binding and rendering
/// 5. Ensure accessibility (labels, ARIA attributes)
///
/// Test Categories:
/// - Basic input rendering
/// - Form validation and error display
/// - Field interactions and state management
/// - Accessibility compliance
/// - Search functionality with debouncing
/// - Keyboard navigation
/// - Edge cases and boundary conditions
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import lustre/attribute
import lustre/element
import meal_planner/ui/components/forms

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// BASIC INPUT FIELD TESTS
// ===================================================================

/// Test basic text input renders correctly
pub fn input_field_renders_correctly_test() {
  let html = forms.input_field("username", "Enter username", "john_doe") |> element.to_string

  // Should contain input element with correct type
  should.be_true(html |> contains("<input type=\"text\""))

  // Should have correct class
  should.be_true(html |> contains("class=\"input\""))

  // Should have correct name attribute
  should.be_true(html |> contains("name=\"username\""))

  // Should have correct placeholder
  should.be_true(html |> contains("placeholder=\"Enter username\""))

  // Should have correct value
  should.be_true(html |> contains("value=\"john_doe\""))
}

/// Test input field with empty value
pub fn input_field_empty_value_test() {
  let html = forms.input_field("email", "Enter email", "") |> element.to_string

  // Should render with empty value attribute
  should.be_true(html |> contains("value=\"\""))

  // Should still have placeholder
  should.be_true(html |> contains("placeholder=\"Enter email\""))
}

/// Test input field with special characters
pub fn input_field_special_characters_test() {
  let html = forms.input_field("note", "Enter note", "Test & \"quote\"") |> element.to_string

  // Should contain the value (HTML escaping handled by browser)
  should.be_true(html |> contains("value=\"Test & \"quote\"\""))
}

// ===================================================================
// INPUT WITH LABEL TESTS (Accessibility)
// ===================================================================

/// Test input with label renders with proper accessibility
pub fn input_with_label_accessibility_test() {
  let html =
    forms.input_with_label("Email Address", "email", "you@example.com", "")
    |> element.to_string

  // Should have form-group wrapper
  should.be_true(html |> contains("<div class=\"form-group\">"))

  // Should have label with for attribute matching input id
  should.be_true(html |> contains("<label for=\"email\">"))
  should.be_true(html |> contains("Email Address</label>"))

  // Should have input with matching id
  should.be_true(html |> contains("id=\"email\""))

  // Should close form-group
  should.be_true(html |> contains("</div>"))
}

/// Test input with label preserves value
pub fn input_with_label_preserves_value_test() {
  let html =
    forms.input_with_label(
      "Username",
      "user",
      "Choose username",
      "existing_user",
    )
    |> element.to_string

  // Should have the provided value
  should.be_true(html |> contains("value=\"existing_user\""))
}

// ===================================================================
// SEARCH INPUT TESTS
// ===================================================================

/// Test search input renders correctly
pub fn search_input_basic_rendering_test() {
  let html = forms.search_input("chicken recipes", "Search recipes...") |> element.to_string

  // Should have search-box container
  should.be_true(html |> contains("<div class=\"search-box\">"))

  // Should have search input type
  should.be_true(html |> contains("<input type=\"search\""))

  // Should have input-search class
  should.be_true(html |> contains("class=\"input-search\""))

  // Should have query value
  should.be_true(html |> contains("value=\"chicken recipes\""))

  // Should have placeholder
  should.be_true(html |> contains("placeholder=\"Search recipes...\""))

  // Should have search button
  should.be_true(html |> contains("<button class=\"btn btn-primary\""))
  should.be_true(html |> contains(">Search</button>"))
}

/// Test search input with empty query
pub fn search_input_empty_query_test() {
  let html = forms.search_input("", "Search...") |> element.to_string

  // Should render with empty value
  should.be_true(html |> contains("value=\"\""))

  // Button should still be present
  should.be_true(html |> contains(">Search</button>"))
}

// ===================================================================
// NUMBER INPUT TESTS (Edge Cases)
// ===================================================================

/// Test number input with min and max constraints
pub fn number_input_with_constraints_test() {
  let html =
    forms.number_input(
      "calories",
      "Calories",
      500.0,
      option.Some(0.0),
      option.Some(5000.0),
    )
    |> element.to_string

  // Should have form-group wrapper
  should.be_true(html |> contains("<div class=\"form-group\">"))

  // Should have label
  should.be_true(html |> contains("<label for=\"calories\">Calories</label>"))

  // Should be number input type
  should.be_true(html |> contains("<input type=\"number\""))

  // Should have value
  should.be_true(html |> contains("value=\"500.0\""))

  // Should have min attribute
  should.be_true(html |> contains("min=\"0.0\""))

  // Should have max attribute
  should.be_true(html |> contains("max=\"5000.0\""))
}

/// Test number input without constraints
pub fn number_input_no_constraints_test() {
  let html =
    forms.number_input("servings", "Servings", 4.0, option.None, option.None)
    |> element.to_string

  // Should have value
  should.be_true(html |> contains("value=\"4.0\""))

  // Should NOT have min attribute
  should.be_false(html |> contains("min="))

  // Should NOT have max attribute
  should.be_false(html |> contains("max="))
}

/// Test number input with zero value (boundary)
pub fn number_input_zero_value_test() {
  let html =
    forms.number_input("amount", "Amount", 0.0, option.None, option.None)
    |> element.to_string

  // Should handle zero correctly
  should.be_true(html |> contains("value=\"0.0\""))
}

/// Test number input with decimal value
pub fn number_input_decimal_value_test() {
  let html =
    forms.number_input("weight", "Weight (kg)", 1.5, option.None, option.None)
    |> element.to_string

  // Should preserve decimal
  should.be_true(html |> contains("value=\"1.5\""))
}

// ===================================================================
// SELECT FIELD TESTS
// ===================================================================

/// Test select field with multiple options
pub fn select_field_with_options_test() {
  let options = [
    #("breakfast", "Breakfast"),
    #("lunch", "Lunch"),
    #("dinner", "Dinner"),
  ]

  let html = forms.select_field("meal_type", "Meal Type", options) |> element.to_string

  // Should have form-group
  should.be_true(html |> contains("<div class=\"form-group\">"))

  // Should have label
  should.be_true(
    html |> contains("<label for=\"meal_type\">Meal Type</label>"),
  )

  // Should have select element
  should.be_true(html |> contains("<select id=\"meal_type\""))
  should.be_true(html |> contains("name=\"meal_type\""))

  // Should have all options
  should.be_true(
    html |> contains("<option value=\"breakfast\">Breakfast</option>"),
  )
  should.be_true(html |> contains("<option value=\"lunch\">Lunch</option>"))
  should.be_true(html |> contains("<option value=\"dinner\">Dinner</option>"))
}

/// Test select field with empty options list
pub fn select_field_empty_options_test() {
  let html = forms.select_field("empty", "Empty Select", []) |> element.to_string

  // Should still render select element
  should.be_true(html |> contains("<select"))

  // Should have no options
  should.be_false(html |> contains("<option"))
}

/// Test select field with special characters in options
pub fn select_field_special_chars_test() {
  let options = [#("test", "Test & \"Value\"")]

  let html = forms.select_field("special", "Special", options) |> element.to_string

  // Should contain the option text
  should.be_true(html |> contains("Test & \"Value\""))
}

// ===================================================================
// FORM FIELD WITH ERROR TESTS (Validation)
// ===================================================================

/// Test form field without error
pub fn form_field_no_error_test() {
  let input = element.element("input", [attribute.type_("text"), attribute.name("test")], [])
  let html = forms.form_field("Test Label", input, option.None) |> element.to_string

  // Should have form-group
  should.be_true(html |> contains("<div class=\"form-group\">"))

  // Should have label
  should.be_true(html |> contains("<label>Test Label</label>"))

  // Should have input element
  should.be_true(html |> contains("<input"))
  should.be_true(html |> contains("type=\"text\""))
  should.be_true(html |> contains("name=\"test\""))

  // Should NOT have error div
  should.be_false(html |> contains("form-error"))
}

/// Test form field with error message
pub fn form_field_with_error_test() {
  let input = element.element("input", [attribute.type_("email"), attribute.name("email")], [])
  let html =
    forms.form_field("Email", input, option.Some("Invalid email address"))
    |> element.to_string

  // Should have label
  should.be_true(html |> contains("<label>Email</label>"))

  // Should have input element
  should.be_true(html |> contains("<input"))
  should.be_true(html |> contains("type=\"email\""))
  should.be_true(html |> contains("name=\"email\""))

  // Should have error div with message
  should.be_true(html |> contains("<div class=\"form-error\">"))
  should.be_true(html |> contains("Invalid email address</div>"))
}

/// Test form field with multiple error scenarios
pub fn form_field_required_error_test() {
  let input = element.element("input", [attribute.type_("text"), attribute.name("name")], [])
  let html =
    forms.form_field("Name", input, option.Some("This field is required"))
    |> element.to_string

  // Should show required error
  should.be_true(html |> contains("This field is required"))
}

/// Test form field with length validation error
pub fn form_field_length_error_test() {
  let input = element.element("input", [attribute.type_("text"), attribute.name("password")], [])
  let html =
    forms.form_field(
      "Password",
      input,
      option.Some("Password must be at least 8 characters"),
    )
    |> element.to_string

  // Should show length error
  should.be_true(html |> contains("Password must be at least 8 characters"))
}

// ===================================================================
// COMPLETE FORM TESTS (User Workflow)
// ===================================================================

/// Test complete form rendering
pub fn form_complete_rendering_test() {
  let fields = [
    forms.input_with_label("Name", "name", "Enter name", ""),
    forms.input_with_label("Email", "email", "Enter email", ""),
  ]

  let html = forms.form("/submit", "POST", fields, "Submit") |> element.to_string

  // Should have form element
  should.be_true(html |> contains("<form"))

  // Should have correct action
  should.be_true(html |> contains("action=\"/submit\""))

  // Should have correct method
  should.be_true(html |> contains("method=\"POST\""))

  // Should contain all fields
  should.be_true(html |> contains("name=\"name\""))
  should.be_true(html |> contains("name=\"email\""))

  // Should have submit button
  should.be_true(html |> contains("<button type=\"submit\""))
  should.be_true(html |> contains(">Submit</button>"))
}

/// Test form with GET method
pub fn form_get_method_test() {
  let html = forms.form("/search", "GET", [], "Search") |> element.to_string

  // Should use GET method
  should.be_true(html |> contains("method=\"GET\""))
}

/// Test form with empty fields
pub fn form_empty_fields_test() {
  let html = forms.form("/test", "POST", [], "Save") |> element.to_string

  // Should still render form
  should.be_true(html |> contains("<form"))

  // Should have submit button
  should.be_true(html |> contains(">Save</button>"))
}

// ===================================================================
// SEARCH WITH CLEAR BUTTON TESTS (Interactive Features)
// ===================================================================

/// Test search input with clear button when empty
pub fn search_with_clear_empty_test() {
  let html = forms.search_input_with_clear("", "Search foods...") |> element.to_string

  // Should have search container with debounce
  should.be_true(html |> contains("<div class=\"search-input-container\""))
  should.be_true(html |> contains("data-debounce=\"300\""))

  // Should have search input
  should.be_true(html |> contains("<input type=\"search\""))

  // Should have empty value
  should.be_true(html |> contains("value=\"\""))

  // Clear button should be hidden
  should.be_true(html |> contains("class=\"search-clear-btn hidden\""))
}

/// Test search input with clear button when query has value
pub fn search_with_clear_has_value_test() {
  let html = forms.search_input_with_clear("chicken", "Search foods...") |> element.to_string

  // Should have value
  should.be_true(html |> contains("value=\"chicken\""))

  // Clear button should be visible (no hidden class)
  should.be_true(html |> contains("class=\"search-clear-btn\""))
  should.be_false(html |> contains("search-clear-btn hidden"))

  // Should have × symbol
  should.be_true(html |> contains(">×</button>"))
}

/// Test search input ARIA label
pub fn search_with_clear_aria_test() {
  let html = forms.search_input_with_clear("", "Search foods...") |> element.to_string

  // Should have aria-label matching placeholder
  should.be_true(html |> contains("aria-label=\"Search foods...\""))
}

// ===================================================================
// SEARCH WITH AUTOFOCUS TESTS
// ===================================================================

/// Test search with autofocus enabled
pub fn search_autofocus_enabled_test() {
  let html = forms.search_input_with_autofocus("", "Search...", True) |> element.to_string

  // Should have autofocus attribute
  should.be_true(html |> contains(" autofocus"))
}

/// Test search with autofocus disabled
pub fn search_autofocus_disabled_test() {
  let html = forms.search_input_with_autofocus("test", "Search...", False) |> element.to_string

  // Should NOT have autofocus attribute
  should.be_false(html |> contains("autofocus"))
}

// ===================================================================
// SEARCH RESULTS LIST TESTS
// ===================================================================

/// Test search results list rendering
pub fn search_results_list_rendering_test() {
  let items = [
    #(1, "Chicken Breast", "Foundation", "Poultry"),
    #(2, "Brown Rice", "Foundation", "Grains"),
    #(3, "Broccoli", "Foundation", "Vegetables"),
  ]

  let html = forms.search_results_list(items, False) |> element.to_string

  // Should have listbox role for accessibility
  should.be_true(html |> contains("role=\"listbox\""))

  // Should have results list class
  should.be_true(html |> contains("class=\"search-results-list"))

  // Should have max-height and overflow
  should.be_true(html |> contains("max-h-96 overflow-y-auto"))

  // Should render all items with proper structure
  should.be_true(html |> contains("role=\"option\""))
  should.be_true(html |> contains("data-food-id=\"1\""))
  should.be_true(html |> contains("Chicken Breast"))
  should.be_true(html |> contains("Foundation • Poultry"))

  should.be_true(html |> contains("data-food-id=\"2\""))
  should.be_true(html |> contains("Brown Rice"))

  should.be_true(html |> contains("data-food-id=\"3\""))
  should.be_true(html |> contains("Broccoli"))
}

/// Test search results list with empty items
pub fn search_results_list_empty_test() {
  let html = forms.search_results_list([], False) |> element.to_string

  // Should still have listbox container
  should.be_true(html |> contains("role=\"listbox\""))

  // Should have no result items
  should.be_false(html |> contains("search-result-item"))
}

/// Test search result item IDs for keyboard navigation
pub fn search_results_unique_ids_test() {
  let items = [#(100, "Test Food", "Type", "Category")]

  let html = forms.search_results_list(items, False) |> element.to_string

  // Should have unique ID for aria-activedescendant
  should.be_true(html |> contains("id=\"search-result-100\""))
}

// ===================================================================
// SEARCH RESULTS LOADING STATE TESTS
// ===================================================================

/// Test search results loading skeleton
pub fn search_results_loading_test() {
  let html = forms.search_results_loading() |> element.to_string

  // Should have loading container with aria-busy
  should.be_true(html |> contains("class=\"search-results-loading\""))
  should.be_true(html |> contains("aria-busy=\"true\""))

  // Should have skeleton items (3 skeletons for visual feedback)
  should.be_true(html |> contains("class=\"skeleton skeleton-item\""))

  // Count skeleton divs (should have 3)
  let skeleton_count = count_occurrences(html, "skeleton-item")
  should.equal(skeleton_count, 3)
}

// ===================================================================
// SEARCH RESULTS EMPTY STATE TESTS
// ===================================================================

/// Test search results empty message
pub fn search_results_empty_test() {
  let html = forms.search_results_empty("xyz123") |> element.to_string

  // Should have empty state container with role
  should.be_true(html |> contains("class=\"search-results-empty\""))
  should.be_true(html |> contains("role=\"status\""))

  // Should show the query in message
  should.be_true(html |> contains("No results found for \"xyz123\""))
}

/// Test empty state with empty query
pub fn search_results_empty_no_query_test() {
  let html = forms.search_results_empty("") |> element.to_string

  // Should handle empty query
  should.be_true(html |> contains("No results found for \"\""))
}

// ===================================================================
// CLEAR ALL FILTERS BUTTON TESTS
// ===================================================================

/// Test clear all filters button with HTMX attributes
pub fn search_results_with_count_clear_all_button_test() {
  let items = [#(1, "Chicken", "Foundation", "Poultry")]
  let active_filters = [
    #("verified", "Verified Only"),
    #("category", "Vegetables"),
  ]

  let html = forms.search_results_with_count(items, 1, active_filters, True) |> element.to_string

  // Should have clear all button with HTMX attributes
  should.be_true(html |> contains("btn-clear-all-filters"))
  should.be_true(html |> contains("Clear All Filters"))

  // Should have HTMX get attribute to reset filters
  should.be_true(html |> contains("hx-get=\"/api/foods/search?q=\""))

  // Should have correct target
  should.be_true(html |> contains("hx-target=\"#search-results\""))

  // Should have correct swap
  should.be_true(html |> contains("hx-swap=\"innerHTML\""))

  // Should push URL to clear query params
  should.be_true(html |> contains("hx-push-url=\"true\""))
}

/// Test clear all filters button hidden when no filters
pub fn search_results_with_count_no_filters_test() {
  let items = [#(1, "Chicken", "Foundation", "Poultry")]
  let active_filters: List(#(String, String)) = []

  let html = forms.search_results_with_count(items, 1, active_filters, True) |> element.to_string

  // Should NOT have clear all button when no filters
  should.be_false(html |> contains("Clear All Filters"))
}

/// Test search results with filters visible
pub fn search_results_with_count_filters_visible_test() {
  let items = [
    #(1, "Apple", "Foundation", "Fruits"),
    #(2, "Banana", "Foundation", "Fruits"),
  ]
  let active_filters = [#("category", "Fruits")]

  let html = forms.search_results_with_count(items, 2, active_filters, True) |> element.to_string

  // Should have active filters section
  should.be_true(html |> contains("active-filters-container"))
  should.be_true(html |> contains("Active filters:"))

  // Should have filter tag
  should.be_true(html |> contains("filter-tag"))
  should.be_true(html |> contains("Fruits"))

  // Should have remove filter indicator
  should.be_true(html |> contains("remove-filter"))
}

// ===================================================================
// KEYBOARD NAVIGATION COMBOBOX TESTS
// ===================================================================

/// Test search combobox collapsed state
pub fn search_combobox_collapsed_test() {
  let html = forms.search_combobox("", "Search...", [], False) |> element.to_string

  // Should have combobox role
  should.be_true(html |> contains("role=\"combobox\""))

  // Should be collapsed
  should.be_true(html |> contains("aria-expanded=\"false\""))

  // Should have controls attribute
  should.be_true(html |> contains("aria-controls=\"search-results-listbox\""))

  // Should have keyboard nav flag
  should.be_true(html |> contains("data-keyboard-nav=\"true\""))

  // Should have autocomplete list
  should.be_true(html |> contains("aria-autocomplete=\"list\""))

  // Should NOT show results when collapsed
  should.be_false(html |> contains("search-results-list"))
}

/// Test search combobox expanded with results
pub fn search_combobox_expanded_with_results_test() {
  let results = [#(1, "Chicken", "Foundation", "Poultry")]

  let html = forms.search_combobox("chi", "Search...", results, True) |> element.to_string

  // Should be expanded
  should.be_true(html |> contains("aria-expanded=\"true\""))

  // Should show results
  should.be_true(html |> contains("search-results-list"))
  should.be_true(html |> contains("Chicken"))
}

/// Test search combobox expanded with no results
pub fn search_combobox_expanded_empty_test() {
  let html = forms.search_combobox("xyz", "Search...", [], True) |> element.to_string

  // Should be expanded
  should.be_true(html |> contains("aria-expanded=\"true\""))

  // Should show empty state
  should.be_true(html |> contains("search-results-empty"))
  should.be_true(html |> contains("No results found"))
}

// ===================================================================
// KEYBOARD SELECTION TESTS (aria-activedescendant)
// ===================================================================

/// Test combobox with active selection
pub fn search_combobox_with_selection_test() {
  let results = [
    #(1, "Apple", "Foundation", "Fruit"),
    #(2, "Apricot", "Foundation", "Fruit"),
  ]

  let html =
    forms.search_combobox_with_selection("ap", "Search...", results, True, 2)
    |> element.to_string

  // Should have aria-activedescendant pointing to selected item
  should.be_true(
    html |> contains("aria-activedescendant=\"search-result-2\""),
  )

  // Should show results
  should.be_true(html |> contains("Apple"))
  should.be_true(html |> contains("Apricot"))
}

/// Test combobox selection accessibility
pub fn search_combobox_selection_accessibility_test() {
  let results = [#(42, "Test Food", "Type", "Category")]

  let html =
    forms.search_combobox_with_selection("test", "Search...", results, True, 42)
    |> element.to_string

  // Should link input to selected result via ARIA
  should.be_true(
    html |> contains("aria-activedescendant=\"search-result-42\""),
  )

  // Result item should have matching ID
  should.be_true(html |> contains("id=\"search-result-42\""))
}

// ===================================================================
// INTEGRATION TESTS (Complete User Workflows)
// ===================================================================

/// Test complete search workflow: empty -> typing -> results
pub fn search_workflow_test() {
  // Step 1: Empty search (collapsed)
  let step1 = forms.search_combobox("", "Search foods...", [], False) |> element.to_string
  should.be_true(step1 |> contains("aria-expanded=\"false\""))

  // Step 2: User types query (expanded, with results)
  let results = [#(1, "Chicken Breast", "Foundation", "Poultry")]
  let step2 = forms.search_combobox("chick", "Search foods...", results, True) |> element.to_string
  should.be_true(step2 |> contains("aria-expanded=\"true\""))
  should.be_true(step2 |> contains("Chicken Breast"))

  // Step 3: User clears search (expanded, empty state)
  let step3 = forms.search_combobox("xyz", "Search foods...", [], True) |> element.to_string
  should.be_true(step3 |> contains("No results found"))
}

/// Test form submission workflow with validation
pub fn form_validation_workflow_test() {
  // Step 1: Initial form (no errors)
  let name_field =
    forms.form_field(
      "Name",
      forms.input_field("name", "Enter name", ""),
      option.None,
    )
    |> element.to_string
  should.be_false(name_field |> contains("form-error"))

  // Step 2: Submit with empty name (validation error)
  let name_error =
    forms.form_field(
      "Name",
      forms.input_field("name", "Enter name", ""),
      option.Some("Name is required"),
    )
    |> element.to_string
  should.be_true(name_error |> contains("Name is required"))

  // Step 3: Submit with valid name (no error)
  let name_valid =
    forms.form_field(
      "Name",
      forms.input_field("name", "Enter name", "John"),
      option.None,
    )
    |> element.to_string
  should.be_false(name_valid |> contains("form-error"))
}

// ===================================================================
// EDGE CASES & BOUNDARY CONDITIONS
// ===================================================================

/// Test form with very long input value
pub fn form_long_input_test() {
  let long_value = string_repeat("a", 500)
  let html = forms.input_field("test", "Test", long_value) |> element.to_string

  // Should handle long values
  should.be_true(html |> contains("value=\"" <> long_value <> "\""))
}

/// Test select with many options (performance edge case)
pub fn select_many_options_test() {
  let options =
    list.range(1, 100)
    |> list.map(fn(i) {
      let val = "option" <> int.to_string(i)
      #(val, "Option " <> int.to_string(i))
    })

  let html = forms.select_field("many", "Many Options", options) |> element.to_string

  // Should render all options
  should.be_true(html |> contains("<select"))

  // Should have first and last options
  should.be_true(html |> contains("option1"))
  should.be_true(html |> contains("option100"))
}

/// Test number input with very large value
pub fn number_input_large_value_test() {
  let html =
    forms.number_input(
      "big",
      "Big Number",
      999_999.99,
      option.None,
      option.None,
    )
    |> element.to_string

  // Should handle large numbers
  should.be_true(html |> contains("value=\"999999.99\""))
}

/// Test number input with very small (negative) value
pub fn number_input_negative_value_test() {
  let html =
    forms.number_input(
      "negative",
      "Negative",
      -100.5,
      option.Some(-1000.0),
      option.None,
    )
    |> element.to_string

  // Should handle negative numbers
  should.be_true(html |> contains("value=\"-100.5\""))
  should.be_true(html |> contains("min=\"-1000.0\""))
}

/// Test search with Unicode characters
pub fn search_unicode_test() {
  let html = forms.search_input_with_clear("寿司 🍣", "Search...") |> element.to_string

  // Should handle Unicode
  should.be_true(html |> contains("value=\"寿司 🍣\""))
}

/// Test empty error message edge case
pub fn form_field_empty_error_message_test() {
  let input = element.element("input", [attribute.type_("text")], [])
  let html = forms.form_field("Label", input, option.Some("")) |> element.to_string

  // Should render error div even with empty message
  should.be_true(html |> contains("<div class=\"form-error\">"))
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Check if string contains substring
fn contains(haystack: String, needle: String) -> Bool {
  case string.contains(haystack, needle) {
    True -> True
    False -> False
  }
}

/// Count occurrences of substring in string
fn count_occurrences(haystack: String, needle: String) -> Int {
  haystack
  |> string.split(needle)
  |> list.length()
  |> fn(len) { len - 1 }
}

/// Repeat string n times
fn string_repeat(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> string_repeat(s, n - 1)
  }
}
