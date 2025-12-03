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

// TODO: Import lustre/element, lustre/attribute when available
// import lustre/element
// import lustre/attribute

/// Text input field
///
/// Renders: <input type="text" class="input" />
pub fn input_field(
  name: String,
  placeholder: String,
  value: String,
) -> String {
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
  label: String,
  name: String,
  placeholder: String,
  value: String,
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
pub fn search_input(
  query: String,
  placeholder: String,
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- search_input: " <> query <> " -->"
}

/// Number input field
///
/// Renders: <input type="number" class="input" />
pub fn number_input(
  name: String,
  label: String,
  value: Float,
  min: option.Option(Float),
  max: option.Option(Float),
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
  label: String,
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
  input: String,
  error: option.Option(String),
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
  method: String,
  fields: List(String),
  submit_label: String,
) -> String {
  // TODO: Implement using Lustre element builder
  "<!-- form: " <> action <> " -->"
}

// ===================================================================
// INTERNAL HELPERS
// ===================================================================

// TODO: Add internal helper functions for:
// - Building CSS class strings
// - Converting types to HTML attributes
// - Input validation
