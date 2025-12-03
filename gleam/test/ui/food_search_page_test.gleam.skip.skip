/// Food Search Page Component Tests
///
/// Tests for the complete food search page component that integrates
/// search input, results list, and keyboard navigation.
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ui/pages/food_search

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg =
        string.concat([
          "\n",
          haystack,
          "\nshould contain\n",
          needle,
        ])
      should.fail()
    }
  }
}

// ===================================================================
// PAGE STRUCTURE TESTS (Bead meal-planner-qfnc)
// ===================================================================

pub fn food_search_page_renders_container_test() {
  let state =
    food_search.SearchState(
      query: option.None,
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "food-search-page")
}

pub fn food_search_page_renders_header_test() {
  let state =
    food_search.SearchState(
      query: option.None,
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "page-header")
  assert_contains(result, "Food Search")
}

pub fn food_search_page_renders_main_content_test() {
  let state =
    food_search.SearchState(
      query: option.None,
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "page-content")
}

pub fn food_search_page_includes_search_input_test() {
  let state =
    food_search.SearchState(
      query: option.Some("chicken"),
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "type=\"search\"")
}

// ===================================================================
// LOADING STATE TESTS
// ===================================================================

pub fn food_search_page_loading_shows_skeleton_test() {
  let state =
    food_search.SearchState(
      query: option.Some("chicken"),
      results: [],
      total_count: 0,
      loading: True,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "search-results-loading")
}

pub fn food_search_page_loading_has_aria_busy_test() {
  let state =
    food_search.SearchState(
      query: option.Some("test"),
      results: [],
      total_count: 0,
      loading: True,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "aria-busy=\"true\"")
}

// ===================================================================
// RESULTS DISPLAY TESTS
// ===================================================================

pub fn food_search_page_displays_results_test() {
  let state =
    food_search.SearchState(
      query: option.Some("chicken"),
      results: [#(1, "Chicken breast", "Protein", "Poultry")],
      total_count: 1,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "Chicken breast")
}

pub fn food_search_page_uses_combobox_for_keyboard_nav_test() {
  let state =
    food_search.SearchState(
      query: option.Some("test"),
      results: [#(1, "Test food", "Type", "Category")],
      total_count: 1,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "role=\"combobox\"")
}

pub fn food_search_page_empty_query_no_results_test() {
  let state =
    food_search.SearchState(
      query: option.None,
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  // Should show search input but not results dropdown
  assert_contains(result, "Search foods...")
}

pub fn food_search_page_has_subtitle_test() {
  let state =
    food_search.SearchState(
      query: option.None,
      results: [],
      total_count: 0,
      loading: False,
    )
  let result = food_search.render_food_search_page(state)
  assert_contains(result, "subtitle")
  assert_contains(result, "USDA FoodData Central")
}
