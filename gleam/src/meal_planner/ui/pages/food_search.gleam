/// Food Search Page Component
///
/// This page component displays a search interface for finding foods
/// from the USDA FoodData Central database.
///
/// Features:
/// - Search input with autocomplete
/// - Results list with food details
/// - Keyboard navigation (arrow keys, Enter, Escape)
/// - Loading and empty states
/// - WCAG 2.1 AA accessibility
///
/// See: docs/UI_REQUIREMENTS_ANALYSIS.md (Bead 2)
/// See: docs/component_signatures.md (Food Search Page)
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, header, main, p}
import meal_planner/ui/components/forms

/// Food search page state
pub type SearchState {
  SearchState(
    query: option.Option(String),
    results: List(#(Int, String, String, String)),
    // (id, name, type, category)
    total_count: Int,
    loading: Bool,
    categories: List(String),
    // Available categories from database
    selected_category: option.Option(String),
    // Currently selected category filter
  )
}

/// Render the complete food search page
///
/// Returns HTML for the full page including:
/// - Page header
/// - Category filter dropdown
/// - Search form with input (keyboard navigation enabled)
/// - Results list or empty/loading state
/// - Integrated with components from meal-planner-rvz.1, rvz.2, rvz.3
pub fn render_food_search_page(state: SearchState) -> Element(msg) {
  let SearchState(
    query: query_opt,
    results: results,
    total_count: _,
    loading: loading,
    categories: categories,
    selected_category: selected_category,
  ) = state

  let query = case query_opt {
    option.Some(q) -> q
    option.None -> ""
  }

  // Determine if results dropdown should be expanded
  let has_query = string.length(query) > 0
  let expanded = has_query && { loading || list.length(results) > 0 }

  let search_widget = case loading {
    True ->
      // Show search input + loading state
      div([class("search-container")], [
        forms.search_input_with_autofocus(query, "Search foods...", True),
        forms.search_results_loading(),
      ])
    False ->
      // Show search input + results (using combobox for keyboard nav)
      forms.search_combobox(query, "Search foods...", results, expanded)
  }

  div([class("food-search-page")], [
    header([class("page-header")], [
      h1([], [text("Food Search")]),
      p([class("subtitle")], [text("Search USDA FoodData Central database")]),
    ]),
    main([class("page-content")], [
      div([class("search-filters")], [
        forms.category_filter_group(
          categories,
          selected_category,
          "handleCategoryChange",
        ),
      ]),
      search_widget,
    ]),
  ])
}
