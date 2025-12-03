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
import gleam/option
import gleam/string
import meal_planner/ui/components/forms

/// Food search page state
pub type SearchState {
  SearchState(
    query: option.Option(String),
    results: List(#(Int, String, String, String)),
    // (id, name, type, category)
    total_count: Int,
    loading: Bool,
  )
}

/// Render the complete food search page
///
/// Returns HTML for the full page including:
/// - Page header
/// - Search form with input (keyboard navigation enabled)
/// - Results list or empty/loading state
/// - Integrated with components from meal-planner-rvz.1, rvz.2, rvz.3
pub fn render_food_search_page(state: SearchState) -> String {
  let SearchState(
    query: query_opt,
    results: results,
    total_count: _,
    loading: loading,
  ) = state

  let query = case query_opt {
    option.Some(q) -> q
    option.None -> ""
  }

  // Determine if results dropdown should be expanded
  let has_query = string.length(query) > 0
  let expanded = has_query && { loading || list_length(results) > 0 }

  let search_widget = case loading {
    True ->
      // Show search input + loading state
      "<div class=\"search-container\">"
      <> forms.search_input_with_autofocus(query, "Search foods...", True)
      <> forms.search_results_loading()
      <> "</div>"
    False ->
      // Show search input + results (using combobox for keyboard nav)
      forms.search_combobox(query, "Search foods...", results, expanded)
  }

  "<div class=\"food-search-page\">"
  <> "<header class=\"page-header\">"
  <> "<h1>Food Search</h1>"
  <> "<p class=\"subtitle\">Search USDA FoodData Central database</p>"
  <> "</header>"
  <> "<main class=\"page-content\">"
  <> search_widget
  <> "</main>"
  <> "</div>"
}

/// Helper to get list length
fn list_length(items: List(a)) -> Int {
  case items {
    [] -> 0
    [_first, ..rest] -> 1 + list_length(rest)
  }
}
/// Search form component (deprecated - use forms.search_combobox instead)
///
/// Renders the search input with:
/// - Text input with placeholder
/// - Clear button when input has text
/// - Loading indicator during search
