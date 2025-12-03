/// Form Components Module
///
/// This module provides reusable form components:
/// - Input fields (text, search, number)
/// - Select dropdowns
/// - Textareas
/// - Form groups with labels and error messages
/// - Search input with integrated button
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Forms)
import gleam/option
import gleam/string

/// Text input field
///
/// Renders: <input type="text" class="input" />
pub fn input_field(name: String, _placeholder: String, _value: String) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- input_field: " <> name <> " -->"
}

/// Text input with label
///
/// Renders:
/// <div class="form-group">
///   <label for="name">Label</label>
///   <input type="text" id="name" />
/// </div>
pub fn input_with_label(
  _label: String,
  name: String,
  _placeholder: String,
  _value: String,
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- input_with_label: " <> name <> " -->"
}

/// Search input with integrated button
///
/// Renders:
/// <div class="search-box">
///   <input type="search" class="input-search" />
///   <button class="btn btn-primary">Search</button>
/// </div>
pub fn search_input(query: String, _placeholder: String) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- search_input: " <> query <> " -->"
}

/// Number input field
///
/// Renders: <input type="number" class="input" />
pub fn number_input(
  name: String,
  _label: String,
  _value: Float,
  _min: option.Option(Float),
  _max: option.Option(Float),
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- number_input: " <> name <> " -->"
}

/// Select dropdown
///
/// Renders:
/// <div class="form-group">
///   <label>Label</label>
///   <select>
///     <option>...</option>
///   </select>
/// </div>
pub fn select_field(
  name: String,
  _label: String,
  _options: List(#(String, String)),
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- select_field: " <> name <> " -->"
}

/// Form group container with label and error message
///
/// Renders:
/// <div class="form-group">
///   <label>Label</label>
///   {input}
///   <div class="form-error">Error message</div>
/// </div>
pub fn form_field(
  label: String,
  _input: String,
  _error: option.Option(String),
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- form_field: " <> label <> " -->"
}

/// Form container
///
/// Renders:
/// <form action="/path" method="POST">
///   {fields}
///   <button type="submit">Label</button>
/// </form>
pub fn form(
  action: String,
  _method: String,
  _fields: List(String),
  _submit_label: String,
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- form: " <> action <> " -->"
}
// ===================================================================
// SEARCH INPUT COMPONENTS (Bead meal-planner-rvz.1)
// ===================================================================

/// Search input with clear button
///
/// Features:
/// - 300ms debouncing via data attribute (handled by client JS)
/// - Clear button visible when query has value
/// - Placeholder text
/// - Proper ARIA labels for accessibility
///
/// Renders:
/// <div class="search-input-container" data-debounce="300">
///   <input type="search" class="input-search" ... />
///   <button type="button" class="search-clear-btn [hidden]">×</button>
/// </div>
pub fn search_input_with_clear(query: String, placeholder: String) -> String {
  let has_value = string.length(query) > 0
  let clear_btn_class = case has_value {
    True -> "search-clear-btn"
    False -> "search-clear-btn hidden"
  }

  "<div class=\"search-input-container\" data-debounce=\"300\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" />"
  <> "<button type=\"button\" class=\""
  <> clear_btn_class
  <> "\">×</button>"
  <> "</div>"
}

/// Search input with autofocus control
///
/// Same as search_input_with_clear but with optional autofocus attribute
/// for keyboard focus management.
pub fn search_input_with_autofocus(
  query: String,
  placeholder: String,
  autofocus: Bool,
) -> String {
  let has_value = string.length(query) > 0
  let clear_btn_class = case has_value {
    True -> "search-clear-btn"
    False -> "search-clear-btn hidden"
  }

  let autofocus_attr = case autofocus {
    True -> " autofocus"
    False -> ""
  }

  "<div class=\"search-input-container\" data-debounce=\"300\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\""
  <> autofocus_attr
  <> " />"
  <> "<button type=\"button\" class=\""
  <> clear_btn_class
  <> "\">×</button>"
  <> "</div>"
}

// ===================================================================
// INTERNAL HELPERS
// ===================================================================
// Helper functions will be added as needed during implementation
