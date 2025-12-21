/// Food Search Popup Component - TUI Food Search Interface
///
/// This module provides a popup search interface for finding foods
/// using the FatSecret API, following Elm Architecture patterns.
///
/// FEATURES:
/// - Incremental search with debouncing
/// - Keyboard navigation (arrows, numbers 1-9)
/// - Result limiting (max 9 for quick selection)
/// - Error handling and display
/// - Loading state management
import gleam/int
import gleam/list
import gleam/option.{type Option}
import meal_planner/fatsecret/foods/types

// ============================================================================
// Types
// ============================================================================

/// Search state for the popup
pub type SearchState {
  SearchState(
    /// Whether the popup is visible
    active: Bool,
    /// Current search query
    query: String,
    /// Search results (max 9)
    results: List(types.FoodSearchResult),
    /// Error message if any
    error: Option(String),
    /// Whether a search is in progress
    loading: Bool,
    /// Currently selected result index (0-based)
    selected_index: Int,
  )
}

/// Effect type for Elm Architecture - function that returns a Msg
pub type Effect =
  fn() -> Msg

/// Messages for the search popup
pub type Msg {
  /// Activate the search popup
  SearchActivate
  /// Update the search query and trigger search
  SearchQuery(String)
  /// Received search results from API
  GotSearchResults(Result(List(types.FoodSearchResult), String))
  /// Select item by number (1-9)
  SelectByNumber(Int)
  /// Select item by arrow key
  SelectByArrow(Direction)
  /// Confirm the current selection
  SearchConfirm
  /// Cancel and close the popup
  SearchCancel
  /// Clear any error message
  ClearError
  /// Food was selected (produced by effects)
  FoodSelected(food_id: String, food_name: String)
}

/// Arrow direction for navigation
pub type Direction {
  Up
  Down
}

// ============================================================================
// Constants
// ============================================================================

/// Maximum number of results to display (for quick number selection)
const max_results = 9

// ============================================================================
// Initialization
// ============================================================================

/// Initialize search state
pub fn init() -> SearchState {
  SearchState(
    active: False,
    query: "",
    results: [],
    error: option.None,
    loading: False,
    selected_index: 0,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// No effects helper
fn no_effects() -> List(Effect) {
  []
}

/// Get element at index (helper function)
fn get_result_at(
  results: List(types.FoodSearchResult),
  index: Int,
) -> Option(types.FoodSearchResult) {
  case results, index {
    [], _ -> option.None
    [head, ..], 0 -> option.Some(head)
    [_, ..tail], n if n > 0 -> get_result_at(tail, n - 1)
    _, _ -> option.None
  }
}

/// Truncate list to max length
fn truncate(items: List(a), max_len: Int) -> List(a) {
  list.take(items, max_len)
}

/// Calculate wrapped index for cyclic navigation
fn wrap_index(current: Int, delta: Int, length: Int) -> Int {
  case length <= 0 {
    True -> 0
    False -> {
      let new_index = current + delta
      case new_index < 0 {
        True -> length - 1
        False ->
          case new_index >= length {
            True -> 0
            False -> new_index
          }
      }
    }
  }
}

/// Create a search effect (placeholder - would trigger actual API call)
fn create_search_effect(_query: String) -> Effect {
  fn() { GotSearchResults(Ok([])) }
}

// ============================================================================
// Update Function
// ============================================================================

/// Update search popup state
pub fn update(state: SearchState, msg: Msg) -> #(SearchState, List(Effect)) {
  case msg {
    // Activate the popup and reset state
    SearchActivate -> {
      let new_state = SearchState(
        active: True,
        query: "",
        results: [],
        error: option.None,
        loading: False,
        selected_index: 0,
      )
      #(new_state, no_effects())
    }

    // Update query and trigger search
    SearchQuery(query) -> {
      let new_state = SearchState(..state, query: query, loading: True)
      let effect = create_search_effect(query)
      #(new_state, [effect])
    }

    // Handle successful search results
    GotSearchResults(Ok(results)) -> {
      let truncated = truncate(results, max_results)
      let new_state = SearchState(
        ..state,
        results: truncated,
        loading: False,
        error: option.None,
        selected_index: 0,
      )
      #(new_state, no_effects())
    }

    // Handle search error
    GotSearchResults(Error(err)) -> {
      let new_state = SearchState(
        ..state,
        loading: False,
        error: option.Some(err),
      )
      #(new_state, no_effects())
    }

    // Select by number (1-based input, convert to 0-based index)
    SelectByNumber(number) -> {
      let index = int.clamp(number - 1, 0, list.length(state.results) - 1)
      let new_state = SearchState(..state, selected_index: index)
      #(new_state, no_effects())
    }

    // Arrow navigation with wrap-around
    SelectByArrow(direction) -> {
      let results_count = list.length(state.results)
      let delta = case direction {
        Up -> -1
        Down -> 1
      }
      let new_index = wrap_index(state.selected_index, delta, results_count)
      let new_state = SearchState(..state, selected_index: new_index)
      #(new_state, no_effects())
    }

    // Confirm selection
    SearchConfirm -> {
      case get_result_at(state.results, state.selected_index) {
        option.Some(types.FoodSearchResult(food_id, food_name, _, _, _, _)) -> {
          let effect = fn() {
            FoodSelected(
              food_id: types.food_id_to_string(food_id),
              food_name: food_name,
            )
          }
          #(SearchState(..state, active: False), [effect])
        }
        option.None -> {
          // No results or invalid index - don't close
          #(state, no_effects())
        }
      }
    }

    // Cancel and reset to initial state
    SearchCancel -> #(init(), no_effects())

    // Clear error message
    ClearError -> {
      let new_state = SearchState(..state, error: option.None)
      #(new_state, no_effects())
    }

    // FoodSelected is produced by effects, not handled directly
    FoodSelected(_, _) -> #(state, no_effects())
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Check if popup is active
pub fn is_active(state: SearchState) -> Bool {
  state.active
}

/// Get current query
pub fn get_query(state: SearchState) -> String {
  state.query
}

/// Get current results
pub fn get_results(state: SearchState) -> List(types.FoodSearchResult) {
  state.results
}

/// Get selected index
pub fn get_selected_index(state: SearchState) -> Int {
  state.selected_index
}

/// Get selected result if any
pub fn get_selected_result(state: SearchState) -> Option(types.FoodSearchResult) {
  get_result_at(state.results, state.selected_index)
}

/// Check if loading
pub fn is_loading(state: SearchState) -> Bool {
  state.loading
}

/// Get error if any
pub fn get_error(state: SearchState) -> Option(String) {
  state.error
}

/// Get results count
pub fn get_results_count(state: SearchState) -> Int {
  list.length(state.results)
}
