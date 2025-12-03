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
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string

/// Text input field
///
/// Renders: <input type="text" class="input" />
pub fn input_field(name: String, placeholder: String, value: String) -> String {
  "<input type=\"text\" class=\"input\" "
  <> "name=\""
  <> name
  <> "\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> value
  <> "\" />"
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
  "<div class=\"form-group\">"
  <> "<label for=\""
  <> name
  <> "\">"
  <> label
  <> "</label>"
  <> "<input type=\"text\" class=\"input\" "
  <> "id=\""
  <> name
  <> "\" "
  <> "name=\""
  <> name
  <> "\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> value
  <> "\" />"
  <> "</div>"
}

/// Search input with integrated button
///
/// Renders:
/// <div class="search-box">
///   <input type="search" class="input-search" />
///   <button class="btn btn-primary">Search</button>
/// </div>
pub fn search_input(query: String, placeholder: String) -> String {
  "<div class=\"search-box\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" />"
  <> "<button class=\"btn btn-primary\" type=\"submit\">Search</button>"
  <> "</div>"
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
  let value_str = float.to_string(value)
  let min_attr = case min {
    option.Some(m) -> " min=\"" <> float.to_string(m) <> "\""
    option.None -> ""
  }
  let max_attr = case max {
    option.Some(m) -> " max=\"" <> float.to_string(m) <> "\""
    option.None -> ""
  }

  "<div class=\"form-group\">"
  <> "<label for=\""
  <> name
  <> "\">"
  <> label
  <> "</label>"
  <> "<input type=\"number\" class=\"input\" "
  <> "id=\""
  <> name
  <> "\" "
  <> "name=\""
  <> name
  <> "\" "
  <> "value=\""
  <> value_str
  <> "\""
  <> min_attr
  <> max_attr
  <> " />"
  <> "</div>"
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
  options: List(#(String, String)),
) -> String {
  let options_html =
    options
    |> list.map(fn(opt) {
      let #(value, text) = opt
      "<option value=\"" <> value <> "\">" <> text <> "</option>"
    })
    |> string.concat()

  "<div class=\"form-group\">"
  <> "<label for=\""
  <> name
  <> "\">"
  <> label
  <> "</label>"
  <> "<select id=\""
  <> name
  <> "\" "
  <> "name=\""
  <> name
  <> "\" "
  <> "class=\"input\">"
  <> options_html
  <> "</select>"
  <> "</div>"
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
  let error_html = case error {
    option.Some(err_msg) -> "<div class=\"form-error\">" <> err_msg <> "</div>"
    option.None -> ""
  }

  "<div class=\"form-group\">"
  <> "<label>"
  <> label
  <> "</label>"
  <> input
  <> error_html
  <> "</div>"
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
  let fields_html = string.concat(fields)

  "<form action=\""
  <> action
  <> "\" "
  <> "method=\""
  <> method
  <> "\">"
  <> fields_html
  <> "<button type=\"submit\" class=\"btn btn-primary\">"
  <> submit_label
  <> "</button>"
  <> "</form>"
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
// SEARCH RESULTS LIST COMPONENTS (Bead meal-planner-rvz.2)
// ===================================================================

/// Search results list item
///
/// Renders a single result item with hover/click interaction
/// Includes unique ID for aria-activedescendant support
fn render_result_item(
  id: Int,
  name: String,
  data_type: String,
  category: String,
) -> String {
  "<div class=\"search-result-item\" role=\"option\" "
  <> "id=\"search-result-"
  <> int.to_string(id)
  <> "\" "
  <> "data-food-id=\""
  <> int.to_string(id)
  <> "\">"
  <> "<div class=\"result-name\">"
  <> name
  <> "</div>"
  <> "<div class=\"result-meta\">"
  <> data_type
  <> " • "
  <> category
  <> "</div>"
  <> "</div>"
}

/// Search results list
///
/// Features:
/// - Displays list of search results with hover/click selection
/// - Responsive sizing with max-height and scroll
/// - ARIA listbox role for accessibility
/// - Each item shows name, type, and category
///
/// Renders:
/// <div class="search-results-list max-h-96 overflow-y-auto" role="listbox">
///   <div class="search-result-item" role="option" data-food-id="123">...</div>
/// </div>
pub fn search_results_list(
  items: List(#(Int, String, String, String)),
  _show_scroll: Bool,
) -> String {
  let items_html =
    items
    |> list.map(fn(item) {
      let #(id, name, data_type, category) = item
      render_result_item(id, name, data_type, category)
    })
    |> string.concat()

  "<div class=\"search-results-list max-h-96 overflow-y-auto\" role=\"listbox\">"
  <> items_html
  <> "</div>"
}

/// Search results loading state
///
/// Shows skeleton loading UI while search is in progress
/// 
/// Renders:
/// <div class="search-results-loading" aria-busy="true">
///   <div class="skeleton skeleton-item">...</div>
///   <div class="skeleton skeleton-item">...</div>
///   <div class="skeleton skeleton-item">...</div>
/// </div>
pub fn search_results_loading() -> String {
  "<div class=\"search-results-loading\" aria-busy=\"true\">"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "<div class=\"skeleton skeleton-item\"></div>"
  <> "</div>"
}

/// Search results empty state
///
/// Shows "no results" message when search returns empty
///
/// Renders:
/// <div class="search-results-empty" role="status">
///   <p>No results found for "query"</p>
/// </div>
pub fn search_results_empty(query: String) -> String {
  "<div class=\"search-results-empty\" role=\"status\">"
  <> "<p>No results found for \""
  <> query
  <> "\"</p>"
  <> "</div>"
}

// ===================================================================
// KEYBOARD NAVIGATION COMPONENTS (Bead meal-planner-rvz.3)
// ===================================================================

/// Search combobox with keyboard navigation
///
/// Features:
/// - ARIA combobox role with proper attributes
/// - aria-expanded indicates dropdown state
/// - aria-controls links to results listbox
/// - aria-autocomplete indicates list completion
/// - Keyboard navigation data attribute for JS handlers
/// - Combines search input + results list
///
/// Renders full search widget with keyboard support
pub fn search_combobox(
  query: String,
  placeholder: String,
  results: List(#(Int, String, String, String)),
  expanded: Bool,
) -> String {
  let expanded_str = case expanded {
    True -> "true"
    False -> "false"
  }

  let results_html = case expanded, results {
    True, [] -> search_results_empty(query)
    True, items -> search_results_list(items, False)
    False, _ -> ""
  }

  "<div class=\"search-combobox\" role=\"combobox\" "
  <> "aria-expanded=\""
  <> expanded_str
  <> "\" "
  <> "aria-controls=\"search-results-listbox\" "
  <> "data-keyboard-nav=\"true\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" "
  <> "aria-autocomplete=\"list\" />"
  <> results_html
  <> "</div>"
}

/// Search combobox with active selection
///
/// Same as search_combobox but includes aria-activedescendant
/// to indicate which result item has keyboard focus
pub fn search_combobox_with_selection(
  query: String,
  placeholder: String,
  results: List(#(Int, String, String, String)),
  expanded: Bool,
  selected_id: Int,
) -> String {
  let expanded_str = case expanded {
    True -> "true"
    False -> "false"
  }

  let results_html = case expanded, results {
    True, [] -> search_results_empty(query)
    True, items -> search_results_list(items, False)
    False, _ -> ""
  }

  "<div class=\"search-combobox\" role=\"combobox\" "
  <> "aria-expanded=\""
  <> expanded_str
  <> "\" "
  <> "aria-controls=\"search-results-listbox\" "
  <> "data-keyboard-nav=\"true\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" "
  <> "aria-autocomplete=\"list\" "
  <> "aria-activedescendant=\"search-result-"
  <> int.to_string(selected_id)
  <> "\" />"
  <> results_html
  <> "</div>"
}
// ===================================================================
// INTERNAL HELPERS
// ===================================================================
// Helper functions will be added as needed during implementation
