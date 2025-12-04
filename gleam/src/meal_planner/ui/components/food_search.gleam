/// Food Search Components Module
///
/// This module provides components for food search functionality:
/// - Filter chips (All, Verified Only, Branded, By Category)
/// - Search result filters
/// - Category dropdown filters
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Food Search)
import gleam/list
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

pub type FilterType {
  All
  VerifiedOnly
  Branded
  ByCategory
}

pub type FilterChip {
  FilterChip(label: String, filter_type: FilterType, selected: Bool)
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Convert FilterType to string identifier for data attributes
fn filter_type_to_string(filter_type: FilterType) -> String {
  case filter_type {
    All -> "all"
    VerifiedOnly -> "verified"
    Branded -> "branded"
    ByCategory -> "category"
  }
}

/// Build CSS classes for a chip based on selection state
fn chip_classes(selected: Bool) -> String {
  let base = "filter-chip"
  case selected {
    True -> base <> " filter-chip-selected"
    False -> base
  }
}

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Render a single filter chip
///
/// Usage:
/// ```gleam
/// render_filter_chip(FilterChip("All", All, True))
/// ```
///
/// Renders:
/// <button class="filter-chip filter-chip-selected" data-filter="all">
///   All
/// </button>
pub fn render_filter_chip(
  chip: FilterChip,
) -> element.Element(msg) {
  let FilterChip(label: label, filter_type: filter_type, selected: selected) =
    chip
  let classes = chip_classes(selected)
  let filter_str = filter_type_to_string(filter_type)

  html.button(
    [
      attribute.class(classes),
      attribute.attribute("data-filter", filter_str),
      attribute.attribute("aria-selected", case selected {
        True -> "true"
        False -> "false"
      }),
      attribute.type_("button"),
    ],
    [element.text(label)],
  )
}

/// Render filter chips container with standard filters
///
/// Features:
/// - "All" chip (typically default selected)
/// - "Verified Only" chip (filters to verified foods)
/// - "Branded" chip (filters to branded foods)
/// - "By Category" chip (enables category dropdown)
///
/// Usage:
/// ```gleam
/// render_filter_chips([
///   FilterChip("All", All, True),
///   FilterChip("Verified Only", VerifiedOnly, False),
///   FilterChip("Branded", Branded, False),
/// ])
/// ```
///
/// Renders:
/// <div class="filter-chips-container">
///   <div class="filter-chips">
///     <button class="filter-chip filter-chip-selected" data-filter="all">All</button>
///     <button class="filter-chip" data-filter="verified">Verified Only</button>
///     <button class="filter-chip" data-filter="branded">Branded</button>
///   </div>
/// </div>
pub fn render_filter_chips(chips: List(FilterChip)) -> element.Element(msg) {
  let chip_elements = list.map(chips, render_filter_chip)

  html.div([attribute.class("filter-chips-container")], [
    html.div(
      [
        attribute.class("filter-chips"),
        attribute.attribute("role", "group"),
        attribute.attribute("aria-label", "Food search filters"),
      ],
      chip_elements,
    ),
  ])
}

/// Render filter chips with integrated category dropdown
///
/// Features:
/// - All standard filter chips
/// - Category dropdown for additional filtering
/// - Dropdown only enabled when "By Category" chip is selected
///
/// Usage:
/// ```gleam
/// render_filter_chips_with_dropdown(
///   [
///     FilterChip("All", All, True),
///     FilterChip("Verified Only", VerifiedOnly, False),
///     FilterChip("Branded", Branded, False),
///     FilterChip("By Category", ByCategory, False),
///   ],
///   ["Vegetables", "Fruits", "Proteins", "Grains"]
/// )
/// ```
///
/// Renders:
/// <div class="filter-chips-container">
///   <div class="filter-chips">...</div>
///   <div class="filter-dropdown-container">
///     <select class="filter-dropdown" data-filter="category">
///       <option value="">Select Category...</option>
///       <option value="vegetables">Vegetables</option>
///     </select>
///   </div>
/// </div>
pub fn render_filter_chips_with_dropdown(
  chips: List(FilterChip),
  categories: List(String),
) -> element.Element(msg) {
  let chip_elements = list.map(chips, render_filter_chip)

  // Find if "By Category" chip is selected
  let category_selected =
    list.find(chips, fn(chip) {
      let FilterChip(filter_type: ft, ..) = chip
      ft == ByCategory
    })
    |> result.map(fn(chip) {
      let FilterChip(selected: sel, ..) = chip
      sel
    })
    |> result.unwrap(False)

  // Build category options
  let default_option =
    html.option(
      [attribute.value(""), attribute.disabled(False)],
      "Select Category...",
    )

  let category_options =
    list.map(categories, fn(category) {
      html.option([attribute.value(category)], category)
    })

  let all_options = [default_option] |> list.append(category_options)

  // Build dropdown classes
  let dropdown_classes = case category_selected {
    True -> "filter-dropdown filter-dropdown-active"
    False -> "filter-dropdown"
  }

  html.div([attribute.class("filter-chips-container")], [
    html.div(
      [
        attribute.class("filter-chips"),
        attribute.attribute("role", "group"),
        attribute.attribute("aria-label", "Food search filters"),
      ],
      chip_elements,
    ),
    html.div([attribute.class("filter-dropdown-container")], [
      html.select(
        [
          attribute.class(dropdown_classes),
          attribute.attribute("data-filter", "category"),
          attribute.disabled(!category_selected),
          attribute.attribute("aria-label", "Filter by category"),
        ],
        all_options,
      ),
    ]),
  ])
}

/// Create default filter chips for food search
///
/// Returns a list of standard filter chips with "All" selected by default
///
/// Usage:
/// ```gleam
/// default_filter_chips()
/// ```
pub fn default_filter_chips() -> List(FilterChip) {
  [
    FilterChip("All", All, True),
    FilterChip("Verified Only", VerifiedOnly, False),
    FilterChip("Branded", Branded, False),
    FilterChip("By Category", ByCategory, False),
  ]
}

/// Create default category list for food search
///
/// Returns a list of common food categories
pub fn default_categories() -> List(String) {
  [
    "Vegetables",
    "Fruits",
    "Proteins",
    "Grains",
    "Dairy",
    "Oils & Fats",
    "Condiments",
    "Beverages",
    "Snacks",
    "Prepared Foods",
  ]
}

/// Update filter chip selection state
///
/// Marks the specified filter as selected and deselects others
/// (assumes single-selection behavior)
///
/// Usage:
/// ```gleam
/// update_selected_filter(chips, All)
/// ```
pub fn update_selected_filter(
  chips: List(FilterChip),
  target_filter: FilterType,
) -> List(FilterChip) {
  list.map(chips, fn(chip) {
    let FilterChip(label: label, filter_type: filter_type, selected: _) = chip
    let is_selected = filter_type == target_filter
    FilterChip(label: label, filter_type: filter_type, selected: is_selected)
  })
}
