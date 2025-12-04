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
/// Renders: <input type="text" class="input" id="name" aria-label="placeholder" />
pub fn input_field(name: String, placeholder: String, value: String) -> String {
  "<input type=\"text\" class=\"input\" "
  <> "id=\""
  <> name
  <> "\" "
  <> "name=\""
  <> name
  <> "\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "aria-label=\""
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

/// Search input with integrated button and HTMX
///
/// Renders:
/// <div class="search-box" role="search">
///   <input type="search" class="input-search" aria-label="placeholder"
///          hx-get="/api/foods/search" hx-trigger="input changed delay:300ms"
///          hx-target="#food-results" hx-swap="innerHTML" hx-push-url="true"
///          hx-indicator="#search-loading" />
///   <button class="btn btn-primary" type="submit">Search</button>
///   <span id="search-loading" class="htmx-indicator">Loading...</span>
/// </div>
pub fn search_input(query: String, placeholder: String) -> String {
  "<div class=\"search-box\" role=\"search\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "id=\"search-input\" "
  <> "name=\"q\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-indicator=\"#search-loading\" />"
  <> "<button class=\"btn btn-primary\" type=\"submit\" aria-label=\"Submit search\">Search</button>"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\" aria-label=\"Loading search results\">Loading...</span>"
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
///   <div class="form-error" role="alert" aria-live="polite">Error message</div>
/// </div>
pub fn form_field(
  label: String,
  input: String,
  error: option.Option(String),
) -> String {
  let error_html = case error {
    option.Some(err_msg) ->
      "<div class=\"form-error\" role=\"alert\" aria-live=\"polite\">"
      <> err_msg
      <> "</div>"
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

/// Search input with clear button and HTMX
///
/// Features:
/// - 300ms debouncing via HTMX trigger delay
/// - Clear button visible when query has value
/// - Placeholder text
/// - Proper ARIA labels for accessibility
/// - HTMX attributes for dynamic search
/// - Loading indicator during requests
///
/// Renders:
/// <div class="search-input-container">
///   <input type="search" class="input-search"
///          hx-get="/api/foods/search" hx-trigger="input changed delay:300ms"
///          hx-target="#food-results" hx-swap="innerHTML"
///          hx-indicator="#search-loading" ... />
///   <button type="button" class="search-clear-btn [hidden]">×</button>
///   <span id="search-loading" class="htmx-indicator">Loading...</span>
/// </div>
pub fn search_input_with_clear(query: String, placeholder: String) -> String {
  let has_value = string.length(query) > 0
  let clear_btn_class = case has_value {
    True -> "search-clear-btn"
    False -> "search-clear-btn hidden"
  }

  "<div class=\"search-input-container\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "id=\"search-input\" "
  <> "name=\"q\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms from:#search-input\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-indicator=\"#search-loading\" />"
  <> "<button type=\"button\" class=\""
  <> clear_btn_class
  <> "\">×</button>"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\" aria-label=\"Loading search results\">Loading...</span>"
  <> "</div>"
}

/// Search input with autofocus control and HTMX
///
/// Same as search_input_with_clear but with optional autofocus attribute
/// for keyboard focus management and HTMX for dynamic search.
/// Includes loading indicator for user feedback.
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

  "<div class=\"search-input-container\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "id=\"search-input\" "
  <> "name=\"q\" "
  <> "placeholder=\""
  <> placeholder
  <> "\" "
  <> "value=\""
  <> query
  <> "\" "
  <> "aria-label=\""
  <> placeholder
  <> "\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms from:#search-input\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-indicator=\"#search-loading\""
  <> autofocus_attr
  <> " />"
  <> "<button type=\"button\" class=\""
  <> clear_btn_class
  <> "\">×</button>"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\" aria-label=\"Loading search results\">Loading...</span>"
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

/// Search results with count header
///
/// Shows the number of results and active filters
/// Displays removable filter tags with clear button for all filters
///
/// Renders:
/// <div class="search-results-container">
///   <div class="search-results-header">
///     <div class="search-results-count">X results</div>
///     <div class="active-filters">
///       <button class="filter-tag" data-filter="verified">Verified<span class="remove-filter">×</span></button>
///     </div>
///     <button class="btn-clear-all-filters">Clear All</button>
///   </div>
///   <div class="search-results-list">...</div>
/// </div>
pub fn search_results_with_count(
  items: List(#(Int, String, String, String)),
  result_count: Int,
  active_filters: List(#(String, String)),
  show_clear_all: Bool,
) -> String {
  let items_html =
    items
    |> list.map(fn(item) {
      let #(id, name, data_type, category) = item
      render_result_item(id, name, data_type, category)
    })
    |> string.concat()

  let count_text = case result_count {
    1 -> "1 result"
    _ -> int.to_string(result_count) <> " results"
  }

  // Render active filter tags
  let filter_tags_html =
    active_filters
    |> list.map(fn(filter) {
      let #(filter_name, filter_value) = filter
      "<button class=\"filter-tag\" data-filter-name=\""
      <> escape_html(filter_name)
      <> "\" data-filter-value=\""
      <> escape_html(filter_value)
      <> "\" type=\"button\" aria-label=\"Remove "
      <> escape_html(filter_value)
      <> " filter\">"
      <> escape_html(filter_value)
      <> "<span class=\"remove-filter\" aria-hidden=\"true\">×</span>"
      <> "</button>"
    })
    |> string.concat()

  let clear_all_btn = case show_clear_all && list.length(active_filters) > 0 {
    True ->
      "<button class=\"btn-clear-all-filters btn btn-ghost btn-sm\" type=\"button\" hx-get=\"/api/foods/search?q=\" hx-target=\"#search-results\" hx-swap=\"innerHTML\" hx-push-url=\"true\">Clear All Filters</button>"
    False -> ""
  }

  let filters_section = case list.length(active_filters) > 0 {
    True ->
      "<div class=\"active-filters-container\">"
      <> "<div class=\"active-filters-label\">Active filters:</div>"
      <> "<div class=\"active-filters\">"
      <> filter_tags_html
      <> "</div>"
      <> clear_all_btn
      <> "</div>"
    False -> ""
  }

  "<div class=\"search-results-container\">"
  <> "<div class=\"search-results-header\">"
  <> "<div class=\"search-results-count\" role=\"status\" aria-live=\"polite\">"
  <> count_text
  <> "</div>"
  <> filters_section
  <> "</div>"
  <> "<div class=\"search-results-list max-h-96 overflow-y-auto\" role=\"listbox\">"
  <> items_html
  <> "</div>"
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

/// Search combobox with keyboard navigation and HTMX
///
/// Features:
/// - ARIA combobox role with proper attributes
/// - aria-expanded indicates dropdown state
/// - aria-controls links to results listbox
/// - aria-autocomplete indicates list completion
/// - HTMX for dynamic search (no JavaScript required)
/// - Loading indicator during requests
/// - Combines search input + results list
///
/// Renders full search widget with keyboard support and HTMX
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
  <> "aria-controls=\"search-results-listbox\">"
  <> "<input type=\"search\" class=\"input-search\" "
  <> "id=\"search-input\" "
  <> "name=\"q\" "
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
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms from:#search-input\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-indicator=\"#search-loading\" />"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\" aria-label=\"Loading search results\">Loading...</span>"
  <> results_html
  <> "</div>"
}

/// Search combobox with active selection
///
/// Same as search_combobox but includes aria-activedescendant
/// to indicate which result item has keyboard focus.
/// Includes loading indicator for user feedback.
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
  <> ">"
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
  <> "\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"input changed delay:300ms from:.input-search\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-indicator=\"#search-loading\" />"
  <> "<span id=\"search-loading\" class=\"htmx-indicator\" aria-label=\"Loading search results\">Loading...</span>"
  <> results_html
  <> "</div>"
}

/// Category dropdown selector
///
/// Renders a dropdown with:
/// - "All Categories" as default option
/// - All available categories sorted alphabetically
/// - Currently selected category highlighted
///
/// Parameters:
/// - `categories`: List of category strings from database
/// - `selected_category`: Currently selected category (None = "All Categories")
/// - `on_change_handler`: DEPRECATED - HTMX handles changes automatically
///
/// Returns: HTML string for the select element
///
/// Example:
/// ```gleam
/// category_dropdown(
///   ["Dairy and Egg Products", "Spices and Herbs"],
///   Some("Dairy and Egg Products"),
///   "handleCategoryChange"
/// )
/// ```
pub fn category_dropdown(
  categories: List(String),
  selected_category: option.Option(String),
  on_change_handler: String,
) -> String {
  // Build option elements for all categories
  let category_options =
    categories
    |> list.map(fn(category) {
      let is_selected = case selected_category {
        option.Some(selected) if selected == category -> True
        _ -> False
      }
      let selected_attr = case is_selected {
        True -> " selected"
        False -> ""
      }
      "<option value=\""
      <> escape_html(category)
      <> "\""
      <> selected_attr
      <> ">"
      <> escape_html(category)
      <> "</option>"
    })
    |> string.join("")

  // Determine if "All Categories" should be selected
  let all_selected = case selected_category {
    option.None -> " selected"
    option.Some(_) -> ""
  }

  "<select class=\"category-dropdown\" "
  <> "id=\"category-filter\" "
  <> "name=\"category\" "
  <> "aria-label=\"Filter by category\" "
  <> "hx-get=\"/api/foods/search\" "
  <> "hx-trigger=\"change\" "
  <> "hx-target=\"#food-results\" "
  <> "hx-swap=\"innerHTML\" "
  <> "hx-push-url=\"true\" "
  <> "hx-include=\"[name='category']\" "
  <> "hx-indicator=\"#category-loading\">"
  <> "<option value=\"\""
  <> all_selected
  <> ">All Categories</option>"
  <> category_options
  <> "</select>"
  <> "<span id=\"category-loading\" class=\"htmx-indicator\" aria-label=\"Loading category results\">Loading...</span>"
}

/// Category filter group with label
///
/// Renders a complete filter group with:
/// - Label: "Food Category"
/// - Dropdown with categories
/// - Form group wrapper for styling
///
/// Parameters:
/// - `categories`: List of available categories
/// - `selected_category`: Currently selected category
/// - `on_change_handler`: JavaScript change handler function name
///
/// Returns: HTML string for the complete filter group
pub fn category_filter_group(
  categories: List(String),
  selected_category: option.Option(String),
  on_change_handler: String,
) -> String {
  "<div class=\"form-group category-filter\">"
  <> "<label for=\"category-filter\">Food Category</label>"
  <> category_dropdown(categories, selected_category, on_change_handler)
  <> "</div>"
}

// ===================================================================
// INTERNAL HELPERS
// ===================================================================

/// Escape HTML special characters to prevent XSS attacks
fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}
