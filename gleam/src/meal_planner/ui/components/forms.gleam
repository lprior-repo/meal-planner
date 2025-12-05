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
import lustre/attribute
import lustre/element
import lustre/element/html

/// Text input field
///
/// Renders: <input type="text" class="input" id="name" aria-label="placeholder" />
pub fn input_field(
  name: String,
  placeholder: String,
  value: String,
) -> element.Element(msg) {
  html.input([
    attribute.type_("text"),
    attribute.class("input"),
    attribute.id(name),
    attribute.name(name),
    attribute.placeholder(placeholder),
    attribute.attribute("aria-label", placeholder),
    attribute.value(value),
  ])
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
) -> element.Element(msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for(name)], [element.text(label)]),
    html.input([
      attribute.type_("text"),
      attribute.class("input"),
      attribute.id(name),
      attribute.name(name),
      attribute.placeholder(placeholder),
      attribute.value(value),
    ]),
  ])
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
pub fn search_input(query: String, placeholder: String) -> element.Element(msg) {
  html.div([attribute.attribute("role", "search"), attribute.class("search-box")], [
    html.input([
      attribute.type_("search"),
      attribute.class("input-search"),
      attribute.id("search-input"),
      attribute.name("q"),
      attribute.placeholder(placeholder),
      attribute.attribute("aria-label", placeholder),
      attribute.value(query),
      attribute.attribute("hx-get", "/api/foods/search"),
      attribute.attribute("hx-trigger", "input changed delay:300ms"),
      attribute.attribute("hx-target", "#food-results"),
      attribute.attribute("hx-swap", "innerHTML"),
      attribute.attribute("hx-push-url", "true"),
      attribute.attribute("hx-indicator", "#search-loading"),
    ]),
    html.button(
      [
        attribute.class("btn btn-primary"),
        attribute.type_("submit"),
        attribute.attribute("aria-label", "Submit search"),
      ],
      [element.text("Search")],
    ),
    html.span(
      [
        attribute.id("search-loading"),
        attribute.class("htmx-indicator"),
        attribute.attribute("aria-label", "Loading search results"),
      ],
      [element.text("Loading...")],
    ),
  ])
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
) -> element.Element(msg) {
  let value_str = float.to_string(value)
  let min_attrs = case min {
    option.Some(m) -> [attribute.attribute("min", float.to_string(m))]
    option.None -> []
  }
  let max_attrs = case max {
    option.Some(m) -> [attribute.attribute("max", float.to_string(m))]
    option.None -> []
  }

  html.div([attribute.class("form-group")], [
    html.label([attribute.for(name)], [element.text(label)]),
    html.input(
      [
        attribute.type_("number"),
        attribute.class("input"),
        attribute.id(name),
        attribute.name(name),
        attribute.value(value_str),
      ]
      |> list.append(min_attrs)
      |> list.append(max_attrs),
    ),
  ])
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
) -> element.Element(msg) {
  let option_elements =
    options
    |> list.map(fn(opt) {
      let #(value, text) = opt
      html.option([attribute.value(value)], text)
    })

  html.div([attribute.class("form-group")], [
    html.label([attribute.for(name)], [element.text(label)]),
    html.select([attribute.id(name), attribute.name(name), attribute.class("input")],
      option_elements
    ),
  ])
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
  input: element.Element(msg),
  error: option.Option(String),
) -> element.Element(msg) {
  let error_element = case error {
    option.Some(err_msg) ->
      html.div(
        [
          attribute.class("form-error"),
          attribute.attribute("role", "alert"),
          attribute.attribute("aria-live", "polite"),
        ],
        [element.text(err_msg)],
      )
    option.None -> element.none()
  }

  html.div([attribute.class("form-group")], [
    html.label([], [element.text(label)]),
    input,
    error_element,
  ])
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
  fields: List(element.Element(msg)),
  submit_label: String,
) -> element.Element(msg) {
  html.form([attribute.action(action), attribute.method(method)], {
    list.append(fields, [
      html.button(
        [attribute.type_("submit"), attribute.class("btn btn-primary")],
        [element.text(submit_label)],
      ),
    ])
  })
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
pub fn search_input_with_clear(
  query: String,
  placeholder: String,
) -> element.Element(msg) {
  let has_value = string.length(query) > 0
  let clear_btn_class = case has_value {
    True -> "search-clear-btn"
    False -> "search-clear-btn hidden"
  }

  html.div([attribute.class("search-input-container")], [
    html.input([
      attribute.type_("search"),
      attribute.class("input-search"),
      attribute.id("search-input"),
      attribute.name("q"),
      attribute.placeholder(placeholder),
      attribute.value(query),
      attribute.attribute("aria-label", placeholder),
      attribute.attribute("hx-get", "/api/foods/search"),
      attribute.attribute("hx-trigger", "input changed delay:300ms from:#search-input"),
      attribute.attribute("hx-target", "#food-results"),
      attribute.attribute("hx-swap", "innerHTML"),
      attribute.attribute("hx-push-url", "true"),
      attribute.attribute("hx-indicator", "#search-loading"),
    ]),
    html.button(
      [attribute.type_("button"), attribute.class(clear_btn_class)],
      [element.text("×")],
    ),
    html.span(
      [
        attribute.id("search-loading"),
        attribute.class("htmx-indicator"),
        attribute.attribute("aria-label", "Loading search results"),
      ],
      [element.text("Loading...")],
    ),
  ])
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
) -> element.Element(msg) {
  let has_value = string.length(query) > 0
  let clear_btn_class = case has_value {
    True -> "search-clear-btn"
    False -> "search-clear-btn hidden"
  }

  let autofocus_attrs = case autofocus {
    True -> [attribute.attribute("autofocus", "")]
    False -> []
  }

  html.div([attribute.class("search-input-container")], [
    html.input(
      [
        attribute.type_("search"),
        attribute.class("input-search"),
        attribute.id("search-input"),
        attribute.name("q"),
        attribute.placeholder(placeholder),
        attribute.value(query),
        attribute.attribute("aria-label", placeholder),
        attribute.attribute("hx-get", "/api/foods/search"),
        attribute.attribute("hx-trigger", "input changed delay:300ms from:#search-input"),
        attribute.attribute("hx-target", "#food-results"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-push-url", "true"),
        attribute.attribute("hx-indicator", "#search-loading"),
      ]
      |> list.append(autofocus_attrs),
    ),
    html.button(
      [attribute.type_("button"), attribute.class(clear_btn_class)],
      [element.text("×")],
    ),
    html.span(
      [
        attribute.id("search-loading"),
        attribute.class("htmx-indicator"),
        attribute.attribute("aria-label", "Loading search results"),
      ],
      [element.text("Loading...")],
    ),
  ])
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
) -> element.Element(msg) {
  html.div(
    [
      attribute.class("search-result-item"),
      attribute.attribute("role", "option"),
      attribute.id("search-result-" <> int.to_string(id)),
      attribute.attribute("data-food-id", int.to_string(id)),
    ],
    [
      html.div([attribute.class("result-name")], [element.text(name)]),
      html.div(
        [attribute.class("result-meta")],
        [element.text(data_type <> " • " <> category)],
      ),
    ],
  )
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
) -> element.Element(msg) {
  let items_elements =
    items
    |> list.map(fn(item) {
      let #(id, name, data_type, category) = item
      render_result_item(id, name, data_type, category)
    })

  html.div(
    [
      attribute.class("search-results-list max-h-96 overflow-y-auto"),
      attribute.attribute("role", "listbox"),
    ],
    items_elements,
  )
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
) -> element.Element(msg) {
  let items_elements =
    items
    |> list.map(fn(item) {
      let #(id, name, data_type, category) = item
      render_result_item(id, name, data_type, category)
    })

  let count_text = case result_count {
    1 -> "1 result"
    _ -> int.to_string(result_count) <> " results"
  }

  // Render active filter tags with HTMX delete functionality
  let filter_tag_elements =
    active_filters
    |> list.map(fn(filter) {
      let #(filter_name, filter_value) = filter
      html.button(
        [
          attribute.class("filter-tag"),
          attribute.attribute("data-filter-name", escape_html(filter_name)),
          attribute.attribute("data-filter-value", escape_html(filter_value)),
          attribute.type_("button"),
          attribute.attribute("aria-label", "Remove " <> escape_html(filter_value) <> " filter"),
          attribute.attribute("hx-get", "/api/foods/search?q=&filter=all"),
          attribute.attribute("hx-target", "#search-results"),
          attribute.attribute("hx-swap", "innerHTML"),
          attribute.attribute("hx-push-url", "true"),
        ],
        [
          element.text(escape_html(filter_value)),
          html.span(
            [attribute.class("remove-filter"), attribute.attribute("aria-hidden", "true")],
            [element.text("×")],
          ),
        ],
      )
    })

  let clear_all_btn = case show_clear_all && !list.is_empty(active_filters) {
    True ->
      html.button(
        [
          attribute.class("btn-clear-all-filters btn btn-ghost btn-sm"),
          attribute.type_("button"),
          attribute.attribute("hx-get", "/api/foods/search?q="),
          attribute.attribute("hx-target", "#search-results"),
          attribute.attribute("hx-swap", "innerHTML"),
          attribute.attribute("hx-push-url", "true"),
        ],
        [element.text("Clear All Filters")],
      )
    False -> element.none()
  }

  let filters_section = case !list.is_empty(active_filters) {
    True ->
      html.div([attribute.class("active-filters-container")], [
        html.div(
          [attribute.class("active-filters-label")],
          [element.text("Active filters:")],
        ),
        html.div([attribute.class("active-filters")], filter_tag_elements),
        clear_all_btn,
      ])
    False -> element.none()
  }

  html.div([attribute.class("search-results-container")], [
    html.div([attribute.class("search-results-header")], [
      html.div(
        [
          attribute.class("search-results-count"),
          attribute.attribute("role", "status"),
          attribute.attribute("aria-live", "polite"),
        ],
        [element.text(count_text)],
      ),
      filters_section,
    ]),
    html.div(
      [
        attribute.class("search-results-list max-h-96 overflow-y-auto"),
        attribute.attribute("role", "listbox"),
      ],
      items_elements,
    ),
  ])
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
pub fn search_results_loading() -> element.Element(msg) {
  html.div(
    [attribute.class("search-results-loading"), attribute.attribute("aria-busy", "true")],
    [
      html.div([attribute.class("skeleton skeleton-item")], []),
      html.div([attribute.class("skeleton skeleton-item")], []),
      html.div([attribute.class("skeleton skeleton-item")], []),
    ],
  )
}

/// Search results empty state
///
/// Shows "no results" message when search returns empty
///
/// Renders:
/// <div class="search-results-empty" role="status">
///   <p>No results found for "query"</p>
/// </div>
pub fn search_results_empty(query: String) -> element.Element(msg) {
  html.div(
    [attribute.class("search-results-empty"), attribute.attribute("role", "status")],
    [
      html.p([], [
        element.text("No results found for \"" <> query <> "\""),
      ]),
    ],
  )
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
) -> element.Element(msg) {
  let expanded_str = case expanded {
    True -> "true"
    False -> "false"
  }

  let results_element = case expanded, results {
    True, [] -> search_results_empty(query)
    True, items -> search_results_list(items, False)
    False, _ -> element.none()
  }

  html.div(
    [
      attribute.class("search-combobox"),
      attribute.attribute("role", "combobox"),
      attribute.attribute("aria-expanded", expanded_str),
      attribute.attribute("aria-controls", "search-results-listbox"),
    ],
    [
      html.input([
        attribute.type_("search"),
        attribute.class("input-search"),
        attribute.id("search-input"),
        attribute.name("q"),
        attribute.placeholder(placeholder),
        attribute.value(query),
        attribute.attribute("aria-label", placeholder),
        attribute.attribute("aria-autocomplete", "list"),
        attribute.attribute("hx-get", "/api/foods/search"),
        attribute.attribute("hx-trigger", "input changed delay:300ms from:#search-input"),
        attribute.attribute("hx-target", "#food-results"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-push-url", "true"),
        attribute.attribute("hx-indicator", "#search-loading"),
      ]),
      html.span(
        [
          attribute.id("search-loading"),
          attribute.class("htmx-indicator"),
          attribute.attribute("aria-label", "Loading search results"),
        ],
        [element.text("Loading...")],
      ),
      results_element,
    ],
  )
}

/// Search combobox with active selection and keyboard navigation
///
/// Same as search_combobox but includes aria-activedescendant
/// to indicate which result item has keyboard focus.
/// Adds HTMX keyboard triggers for arrow navigation and enter selection.
/// Server-side focus management via CSS classes and aria-activedescendant updates.
/// Includes loading indicator for user feedback.
///
/// Features:
/// - aria-activedescendant tracks currently focused result
/// - HTMX keyboard triggers (ArrowUp, ArrowDown, Enter)
/// - Server updates aria-activedescendant on keyboard navigation
/// - CSS .focused class indicates highlighted result
pub fn search_combobox_with_selection(
  query: String,
  placeholder: String,
  results: List(#(Int, String, String, String)),
  expanded: Bool,
  selected_id: Int,
) -> element.Element(msg) {
  let expanded_str = case expanded {
    True -> "true"
    False -> "false"
  }

  let results_element = case expanded, results {
    True, [] -> search_results_empty(query)
    True, items -> search_results_list(items, False)
    False, _ -> element.none()
  }

  html.div(
    [
      attribute.class("search-combobox"),
      attribute.attribute("role", "combobox"),
      attribute.attribute("aria-expanded", expanded_str),
      attribute.attribute("aria-controls", "search-results-listbox"),
    ],
    [
      html.input([
        attribute.type_("search"),
        attribute.class("input-search"),
        attribute.id("search-input"),
        attribute.placeholder(placeholder),
        attribute.value(query),
        attribute.attribute("aria-label", placeholder),
        attribute.attribute("aria-autocomplete", "list"),
        attribute.attribute("aria-activedescendant", "search-result-" <> int.to_string(selected_id)),
        attribute.attribute("hx-get", "/api/foods/search"),
        attribute.attribute("hx-trigger", "input changed delay:300ms from:#search-input, keydown[key=='ArrowDown'] from:#search-input, keydown[key=='ArrowUp'] from:#search-input, keydown[key=='Enter'] from:#search-input"),
        attribute.attribute("hx-target", "#food-results"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-indicator", "#search-loading"),
      ]),
      html.span(
        [
          attribute.id("search-loading"),
          attribute.class("htmx-indicator"),
          attribute.attribute("aria-label", "Loading search results"),
        ],
        [element.text("Loading...")],
      ),
      results_element,
    ],
  )
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
/// Returns: Lustre element for the select element
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
) -> element.Element(msg) {
  // Build option elements for all categories
  let category_options =
    categories
    |> list.map(fn(category) {
      let is_selected = case selected_category {
        option.Some(selected) if selected == category -> True
        _ -> False
      }
      let attrs = case is_selected {
        True -> [attribute.value(escape_html(category)), attribute.attribute("selected", "")]
        False -> [attribute.value(escape_html(category))]
      }
      html.option(attrs, escape_html(category))
    })

  // Determine if "All Categories" should be selected
  let all_selected_attrs = case selected_category {
    option.None -> [attribute.value(""), attribute.attribute("selected", "")]
    option.Some(_) -> [attribute.value("")]
  }

  let all_options = list.flatten([
    [html.option(all_selected_attrs, "All Categories")],
    category_options,
  ])

  html.div([], [
    html.select(
      [
        attribute.class("category-dropdown"),
        attribute.id("category-filter"),
        attribute.name("category"),
        attribute.attribute("aria-label", "Filter by category"),
        attribute.attribute("hx-get", "/api/foods/search"),
        attribute.attribute("hx-trigger", "change"),
        attribute.attribute("hx-target", "#food-results"),
        attribute.attribute("hx-swap", "innerHTML"),
        attribute.attribute("hx-push-url", "true"),
        attribute.attribute("hx-include", "[name='category']"),
        attribute.attribute("hx-indicator", "#category-loading"),
      ],
      all_options,
    ),
    html.span(
      [
        attribute.id("category-loading"),
        attribute.class("htmx-indicator"),
        attribute.attribute("aria-label", "Loading category results"),
      ],
      [element.text("Loading...")],
    ),
  ])
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
/// Returns: Lustre element for the complete filter group
pub fn category_filter_group(
  categories: List(String),
  selected_category: option.Option(String),
  on_change_handler: String,
) -> element.Element(msg) {
  html.div([attribute.class("form-group category-filter")], [
    html.label([attribute.for("category-filter")], [element.text("Food Category")]),
    category_dropdown(categories, selected_category, on_change_handler),
  ])
}

// ===================================================================
// INTERNAL HELPERS
// ===================================================================

/// Escape HTML special characters to prevent XSS attacks
///
/// This function is public to enable security testing.
/// Do NOT use this for actual HTML generation - use Lustre's element API instead.
pub fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}
