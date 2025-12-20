/// Food Search Popup - Reusable TUI Component
///
/// This module provides a reusable popup component for searching foods
/// in the meal planner TUI. It encapsulates:
/// - Search state management (query, results, selection)
/// - Keyboard handling (navigation, selection, cancel)
/// - Rendering logic (popup display, results list)
///
/// The component follows the Elm Architecture pattern used by the Shore framework.
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/fatsecret/foods/types as foods_types
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// State for the food search popup component
pub type PopupState {
  PopupState(
    /// Whether the popup is currently visible
    is_visible: Bool,
    /// Current search query text
    search_query: String,
    /// Search results from FatSecret API
    results: List(foods_types.FoodSearchResult),
    /// Currently selected result index (0-based)
    selected_index: Int,
    /// Whether search is in progress
    is_loading: Bool,
    /// Error message if search failed
    error_message: Option(String),
  )
}

/// Messages for popup interactions
pub type PopupMsg {
  /// Open the popup
  Open
  /// Close the popup
  Close
  /// Update search query
  UpdateQuery(String)
  /// Trigger search
  Search
  /// Navigate up in results list
  SelectPrevious
  /// Navigate down in results list
  SelectNext
  /// Confirm selection (Enter key)
  ConfirmSelection
  /// Set search results
  SetResults(List(foods_types.FoodSearchResult))
  /// Set error message
  SetError(String)
  /// Set loading state
  SetLoading(Bool)
}

/// Result of a popup action (for parent component)
pub type PopupResult {
  /// No action taken
  NoAction
  /// Popup was closed without selection
  Cancelled
  /// Food was selected
  FoodSelected(foods_types.FoodSearchResult)
}

// ============================================================================
// State Management
// ============================================================================

/// Create initial popup state (hidden)
pub fn init() -> PopupState {
  PopupState(
    is_visible: False,
    search_query: "",
    results: [],
    selected_index: 0,
    is_loading: False,
    error_message: None,
  )
}

/// Open the popup with optional initial query
pub fn open(state: PopupState, initial_query: Option(String)) -> PopupState {
  let query = case initial_query {
    Some(q) -> q
    None -> ""
  }
  PopupState(
    ..state,
    is_visible: True,
    search_query: query,
    selected_index: 0,
    error_message: None,
  )
}

/// Close the popup and reset state
pub fn close(state: PopupState) -> PopupState {
  PopupState(
    ..state,
    is_visible: False,
    search_query: "",
    results: [],
    selected_index: 0,
    error_message: None,
  )
}

/// Update search query
pub fn update_query(state: PopupState, query: String) -> PopupState {
  PopupState(..state, search_query: query, error_message: None)
}

/// Set search results
pub fn set_results(
  state: PopupState,
  results: List(foods_types.FoodSearchResult),
) -> PopupState {
  PopupState(
    ..state,
    results: results,
    is_loading: False,
    selected_index: 0,
    error_message: None,
  )
}

/// Set error message
pub fn set_error(state: PopupState, message: String) -> PopupState {
  PopupState(
    ..state,
    error_message: Some(message),
    is_loading: False,
    results: [],
  )
}

/// Set loading state
pub fn set_loading(state: PopupState, loading: Bool) -> PopupState {
  PopupState(..state, is_loading: loading, error_message: None)
}

/// Move selection up (with wrapping)
pub fn select_previous(state: PopupState) -> PopupState {
  let results_count = list.length(state.results)
  case results_count {
    0 -> state
    _ -> {
      let new_index = case state.selected_index {
        0 -> results_count - 1
        n -> n - 1
      }
      PopupState(..state, selected_index: new_index)
    }
  }
}

/// Move selection down (with wrapping)
pub fn select_next(state: PopupState) -> PopupState {
  let results_count = list.length(state.results)
  case results_count {
    0 -> state
    _ -> {
      let new_index = case state.selected_index {
        n if n >= results_count - 1 -> 0
        n -> n + 1
      }
      PopupState(..state, selected_index: new_index)
    }
  }
}

/// Get currently selected food (if any)
pub fn get_selected_food(
  state: PopupState,
) -> Option(foods_types.FoodSearchResult) {
  state.results
  |> list.drop(state.selected_index)
  |> list.first
  |> option.from_result
}

// ============================================================================
// Update Logic
// ============================================================================

/// Process popup messages and return updated state with result
pub fn update(state: PopupState, msg: PopupMsg) -> #(PopupState, PopupResult) {
  case msg {
    Open -> #(PopupState(..state, is_visible: True), NoAction)

    Close -> #(close(state), Cancelled)

    UpdateQuery(query) -> #(update_query(state, query), NoAction)

    Search -> #(set_loading(state, True), NoAction)

    SelectPrevious -> #(select_previous(state), NoAction)

    SelectNext -> #(select_next(state), NoAction)

    ConfirmSelection -> {
      case get_selected_food(state) {
        Some(food) -> #(close(state), FoodSelected(food))
        None -> #(state, NoAction)
      }
    }

    SetResults(results) -> #(set_results(state, results), NoAction)

    SetError(message) -> #(set_error(state, message), NoAction)

    SetLoading(loading) -> #(set_loading(state, loading), NoAction)
  }
}

// ============================================================================
// Keyboard Handling
// ============================================================================

/// Handle keyboard input for the popup
pub fn handle_key(state: PopupState, key_input: String) -> PopupMsg {
  case key_input {
    // Escape key - close popup
    "\u{001B}" -> Close

    // Enter key - confirm selection or search
    "\n" | "\r" -> {
      case list.is_empty(state.results) {
        True -> Search
        False -> ConfirmSelection
      }
    }

    // Up arrow - navigate up
    "\u{001B}[A" -> SelectPrevious

    // Down arrow - navigate down
    "\u{001B}[D" -> SelectNext

    // Default - no action
    _ -> UpdateQuery(state.search_query)
  }
}

// ============================================================================
// Rendering
// ============================================================================

/// Render the popup as a Shore UI node
pub fn view(state: PopupState) -> shore.Node(PopupMsg) {
  case state.is_visible {
    False -> ui.text("")
    True -> render_popup(state)
  }
}

/// Render the popup content
fn render_popup(state: PopupState) -> shore.Node(PopupMsg) {
  ui.col([
    ui.br(),
    ui.hr_styled(style.Cyan),
    ui.text_styled("Food Search", Some(style.Cyan), None),
    ui.hr_styled(style.Cyan),
    ui.br(),
    ui.input("Search:", state.search_query, style.Pct(60), UpdateQuery),
    ui.br(),
    render_status(state),
    ui.br(),
    render_results(state),
    ui.br(),
    ui.hr_styled(style.Cyan),
    render_help_text(),
  ])
}

/// Render status message (loading/error)
fn render_status(state: PopupState) -> shore.Node(PopupMsg) {
  case state.is_loading, state.error_message {
    True, _ -> ui.text_styled("Searching...", Some(style.Yellow), None)
    False, Some(error) -> ui.text_styled(error, Some(style.Red), None)
    False, None -> ui.text("")
  }
}

/// Render search results list
fn render_results(state: PopupState) -> shore.Node(PopupMsg) {
  case list.is_empty(state.results) {
    True -> ui.text("")
    False -> {
      let result_nodes =
        state.results
        |> list.index_map(fn(food, idx) {
          render_result_item(food, idx, idx == state.selected_index)
        })
      ui.col(result_nodes)
    }
  }
}

/// Render a single result item
fn render_result_item(
  food: foods_types.FoodSearchResult,
  index: Int,
  is_selected: Bool,
) -> shore.Node(PopupMsg) {
  let prefix = case is_selected {
    True -> "> "
    False -> "  "
  }

  let food_name =
    foods_types.food_id_to_string(food.food_id)
    |> string.slice(0, 50)

  let display_text =
    prefix
    <> int.to_string(index + 1)
    <> ". "
    <> food.food_name
    <> " - "
    <> food_name

  case is_selected {
    True -> ui.text_styled(display_text, Some(style.Green), None)
    False -> ui.text(display_text)
  }
}

/// Render help text
fn render_help_text() -> shore.Node(PopupMsg) {
  ui.text_styled(
    "↑/↓: Navigate | Enter: Select | Esc: Cancel",
    Some(style.Cyan),
    None,
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Check if popup is visible
pub fn is_visible(state: PopupState) -> Bool {
  state.is_visible
}

/// Get current search query
pub fn get_query(state: PopupState) -> String {
  state.search_query
}

/// Get number of results
pub fn get_results_count(state: PopupState) -> Int {
  list.length(state.results)
}

/// Check if loading
pub fn is_loading(state: PopupState) -> Bool {
  state.is_loading
}

/// Get error message if present
pub fn get_error(state: PopupState) -> Option(String) {
  state.error_message
}

/// Get selected index
pub fn get_selected_index(state: PopupState) -> Int {
  state.selected_index
}
