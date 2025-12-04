/// Food Search Component Usage Examples
///
/// This file demonstrates how to use the food_search component
/// in your Gleam application.
import lustre/element/html
import meal_planner/ui/components/food_search as fs

// ===================================================================
// EXAMPLE 1: Basic filter chips with defaults
// ===================================================================

/// Render basic filter chips with default configuration
pub fn example_basic_chips() {
  fs.default_filter_chips()
  |> fs.render_filter_chips
}

// ===================================================================
// EXAMPLE 2: Filter chips with dropdown
// ===================================================================

/// Render filter chips with category dropdown
pub fn example_chips_with_dropdown() {
  let chips = fs.default_filter_chips()
  let categories = fs.default_categories()

  fs.render_filter_chips_with_dropdown(chips, categories)
}

// ===================================================================
// EXAMPLE 3: Custom filter chips
// ===================================================================

/// Render custom filter chips (not using defaults)
pub fn example_custom_chips() {
  let custom_chips = [
    fs.FilterChip("All Foods", fs.All, True),
    fs.FilterChip("Verified Sources Only", fs.VerifiedOnly, False),
    fs.FilterChip("Major Brands", fs.Branded, False),
  ]

  fs.render_filter_chips(custom_chips)
}

// ===================================================================
// EXAMPLE 4: Dynamic chip selection
// ===================================================================

/// Handle chip selection change
pub fn example_handle_selection(selected_filter: fs.FilterType) {
  let chips = fs.default_filter_chips()
  let updated_chips = fs.update_selected_filter(chips, selected_filter)

  fs.render_filter_chips(updated_chips)
}

// ===================================================================
// EXAMPLE 5: Custom categories
// ===================================================================

/// Use custom category list with dropdown
pub fn example_custom_categories() {
  let chips = fs.default_filter_chips()
  let custom_categories = [
    "Meat & Poultry",
    "Seafood",
    "Legumes",
    "Nuts & Seeds",
    "Whole Grains",
    "Vegetables",
    "Fruits",
  ]

  fs.render_filter_chips_with_dropdown(chips, custom_categories)
}

// ===================================================================
// EXAMPLE 6: Full food search page integration
// ===================================================================

/// Complete food search page with filters
pub fn example_full_page() {
  let chips = fs.default_filter_chips()
  let categories = fs.default_categories()

  html.div([], [
    html.h1([], [html.text("Food Search")]),

    // Filter section
    fs.render_filter_chips_with_dropdown(chips, categories),

    // Search results would go here
    html.div([], [html.text("Search results will appear here")]),
  ])
}

// ===================================================================
// EXAMPLE 7: Programmatic filter creation
// ===================================================================

/// Create chips with specific selection state
pub fn example_create_with_state() {
  let chips = [
    fs.FilterChip("All", fs.All, False),
    fs.FilterChip("Verified Only", fs.VerifiedOnly, True),
    fs.FilterChip("Branded", fs.Branded, False),
    fs.FilterChip("By Category", fs.ByCategory, False),
  ]

  fs.render_filter_chips_with_dropdown(chips, fs.default_categories())
}
/// FilterType - The types of filters available
/// - All: Show all foods
/// - VerifiedOnly: Show only verified foods
/// - Branded: Show only branded foods
/// - ByCategory: Show foods filtered by category
///
/// pub type FilterType {
///   All
///   VerifiedOnly
///   Branded
///   ByCategory
/// }
/// FilterChip - Represents a single filter chip
/// - label: Display text for the chip
/// - filter_type: Type of filter this chip represents
/// - selected: Whether this chip is currently selected
///
/// pub type FilterChip {
///   FilterChip(label: String, filter_type: FilterType, selected: Bool)
/// }
/// render_filter_chip(chip: FilterChip) -> element.Element(msg)
/// Renders a single filter chip button with data attributes.
/// Selected chips have the "filter-chip-selected" class applied.
/// render_filter_chips(chips: List(FilterChip)) -> element.Element(msg)
/// Renders multiple filter chips in a container.
/// Includes role="group" and aria-label for accessibility.
/// render_filter_chips_with_dropdown(
///   chips: List(FilterChip),
///   categories: List(String)
/// ) -> element.Element(msg)
/// Renders filter chips with an integrated category dropdown.
/// Dropdown is only enabled when "By Category" chip is selected.
/// default_filter_chips() -> List(FilterChip)
/// Returns standard filter chips with "All" selected.
/// default_categories() -> List(String)
/// Returns common food category list.
/// update_selected_filter(
///   chips: List(FilterChip),
///   target_filter: FilterType
/// ) -> List(FilterChip)
/// Updates chip selection state, selecting only the target filter.
/// .filter-chips-container
/// Main container for the filter chip UI
/// .filter-chips
/// Container for the chip buttons
/// .filter-chip
/// Individual chip button
/// .filter-chip-selected
/// Applied to selected chips
/// .filter-dropdown-container
/// Container for the category dropdown
/// .filter-dropdown
/// The select dropdown element
/// .filter-dropdown-active
/// Applied to dropdown when category filter is selected
/// data-filter="all"
/// data-filter="verified"
/// data-filter="branded"
/// data-filter="category"
///
/// Use these attributes to hook up JavaScript event listeners
/// for handling filter changes.
// ===================================================================
// TYPE REFERENCE
// ===================================================================

// ===================================================================
// FUNCTION REFERENCE
// ===================================================================

// ===================================================================
// CSS CLASSES USED (for styling)
// ===================================================================

// ===================================================================
// DATA ATTRIBUTES (for JavaScript interaction)
// ===================================================================
