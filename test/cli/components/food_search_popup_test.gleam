/// Tests for Food Search Popup Component
///
/// This module tests the food_search_popup component following TDD principles.
/// These tests verify:
/// - State initialization and management
/// - Keyboard navigation and handling
/// - Search result rendering and selection
/// - Error handling and loading states
///
/// Test count: 11 test cases as required

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/components/food_search_popup as popup
import meal_planner/fatsecret/foods/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test 1: Initialization
// ============================================================================

pub fn init_creates_hidden_popup_test() {
  // Given: No prior state
  // When: We initialize the popup
  let state = popup.init()

  // Then: Popup should be hidden with empty state
  state.is_visible
  |> should.be_false

  state.search_query
  |> should.equal("")

  state.results
  |> should.equal([])

  state.selected_index
  |> should.equal(0)

  state.is_loading
  |> should.be_false

  state.error_message
  |> should.equal(None)
}

// ============================================================================
// Test 2: Opening Popup
// ============================================================================

pub fn open_makes_popup_visible_test() {
  // Given: A hidden popup
  let state = popup.init()

  // When: We open the popup
  let opened = popup.open(state, None)

  // Then: Popup should be visible
  opened.is_visible
  |> should.be_true

  opened.search_query
  |> should.equal("")
}

pub fn open_with_query_sets_initial_query_test() {
  // Given: A hidden popup
  let state = popup.init()

  // When: We open with an initial query
  let opened = popup.open(state, Some("apple"))

  // Then: Query should be set
  opened.is_visible
  |> should.be_true

  opened.search_query
  |> should.equal("apple")
}

// ============================================================================
// Test 3: Closing Popup
// ============================================================================

pub fn close_hides_popup_and_resets_state_test() {
  // Given: An open popup with search state
  let state =
    popup.init()
    |> popup.open(Some("banana"))
    |> popup.set_results([create_test_food("1", "Banana")])

  // When: We close the popup
  let closed = popup.close(state)

  // Then: Popup should be hidden and reset
  closed.is_visible
  |> should.be_false

  closed.search_query
  |> should.equal("")

  closed.results
  |> should.equal([])

  closed.selected_index
  |> should.equal(0)
}

// ============================================================================
// Test 4: Query Update
// ============================================================================

pub fn update_query_changes_search_text_test() {
  // Given: An open popup
  let state = popup.init() |> popup.open(None)

  // When: We update the query
  let updated = popup.update_query(state, "orange")

  // Then: Query should be updated
  updated.search_query
  |> should.equal("orange")

  // And error should be cleared
  updated.error_message
  |> should.equal(None)
}

// ============================================================================
// Test 5: Setting Results
// ============================================================================

pub fn set_results_populates_search_results_test() {
  // Given: An open popup
  let state = popup.init() |> popup.open(None) |> popup.set_loading(True)

  // When: We set search results
  let results = [
    create_test_food("1", "Apple"),
    create_test_food("2", "Apricot"),
    create_test_food("3", "Avocado"),
  ]
  let updated = popup.set_results(state, results)

  // Then: Results should be set and loading cleared
  updated.results
  |> should.equal(results)

  updated.is_loading
  |> should.be_false

  updated.selected_index
  |> should.equal(0)

  updated.error_message
  |> should.equal(None)
}

// ============================================================================
// Test 6: Navigation - Select Previous
// ============================================================================

pub fn select_previous_moves_up_with_wrapping_test() {
  // Given: A popup with results and selection at index 1
  let results = [
    create_test_food("1", "Apple"),
    create_test_food("2", "Banana"),
    create_test_food("3", "Cherry"),
  ]
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results(results)
    |> popup.select_next

  // Verify we're at index 1
  state.selected_index
  |> should.equal(1)

  // When: We select previous
  let updated = popup.select_previous(state)

  // Then: Selection should move to index 0
  updated.selected_index
  |> should.equal(0)

  // And when we select previous again at index 0
  let wrapped = popup.select_previous(updated)

  // Then: It should wrap to last item (index 2)
  wrapped.selected_index
  |> should.equal(2)
}

// ============================================================================
// Test 7: Navigation - Select Next
// ============================================================================

pub fn select_next_moves_down_with_wrapping_test() {
  // Given: A popup with results
  let results = [
    create_test_food("1", "Apple"),
    create_test_food("2", "Banana"),
    create_test_food("3", "Cherry"),
  ]
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results(results)

  // When: We select next
  let updated = popup.select_next(state)

  // Then: Selection should move to index 1
  updated.selected_index
  |> should.equal(1)

  // When: We continue to last item
  let at_last =
    updated
    |> popup.select_next

  at_last.selected_index
  |> should.equal(2)

  // And when we select next at last item
  let wrapped = popup.select_next(at_last)

  // Then: It should wrap to first item (index 0)
  wrapped.selected_index
  |> should.equal(0)
}

// ============================================================================
// Test 8: Get Selected Food
// ============================================================================

pub fn get_selected_food_returns_current_selection_test() {
  // Given: A popup with results at index 1
  let results = [
    create_test_food("1", "Apple"),
    create_test_food("2", "Banana"),
    create_test_food("3", "Cherry"),
  ]
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results(results)
    |> popup.select_next

  // When: We get the selected food
  let selected = popup.get_selected_food(state)

  // Then: It should return the food at index 1
  case selected {
    Some(food) -> {
      food.food_name
      |> should.equal("Banana")
    }
    None -> should.fail()
  }
}

pub fn get_selected_food_returns_none_when_no_results_test() {
  // Given: A popup with no results
  let state = popup.init() |> popup.open(None)

  // When: We get the selected food
  let selected = popup.get_selected_food(state)

  // Then: It should return None
  selected
  |> should.equal(None)
}

// ============================================================================
// Test 9: Error Handling
// ============================================================================

pub fn set_error_displays_error_and_clears_results_test() {
  // Given: A popup with results and loading state
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results([create_test_food("1", "Apple")])
    |> popup.set_loading(True)

  // When: We set an error
  let updated = popup.set_error(state, "API connection failed")

  // Then: Error should be set and state cleared
  updated.error_message
  |> should.equal(Some("API connection failed"))

  updated.is_loading
  |> should.be_false

  updated.results
  |> should.equal([])
}

// ============================================================================
// Test 10: Loading State
// ============================================================================

pub fn set_loading_updates_loading_flag_test() {
  // Given: A popup with error
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_error("Previous error")

  // When: We set loading to true
  let updated = popup.set_loading(state, True)

  // Then: Loading should be true and error cleared
  updated.is_loading
  |> should.be_true

  updated.error_message
  |> should.equal(None)
}

// ============================================================================
// Test 11: Update Function - Full Flow
// ============================================================================

pub fn update_handles_confirm_selection_test() {
  // Given: A popup with results
  let results = [
    create_test_food("1", "Apple"),
    create_test_food("2", "Banana"),
  ]
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results(results)
    |> popup.select_next

  // When: We confirm selection
  let #(new_state, result) = popup.update(state, popup.ConfirmSelection)

  // Then: Popup should close and return selected food
  new_state.is_visible
  |> should.be_false

  case result {
    popup.FoodSelected(food) -> {
      food.food_name
      |> should.equal("Banana")
    }
    _ -> should.fail()
  }
}

pub fn update_handles_close_message_test() {
  // Given: An open popup
  let state = popup.init() |> popup.open(None)

  // When: We send Close message
  let #(new_state, result) = popup.update(state, popup.Close)

  // Then: Popup should close with Cancelled result
  new_state.is_visible
  |> should.be_false

  result
  |> should.equal(popup.Cancelled)
}

// ============================================================================
// Test 12: Keyboard Handling
// ============================================================================

pub fn handle_key_escape_closes_popup_test() {
  // Given: An open popup
  let state = popup.init() |> popup.open(None)

  // When: We handle Escape key
  let msg = popup.handle_key(state, "\u{001B}")

  // Then: Should return Close message
  msg
  |> should.equal(popup.Close)
}

pub fn handle_key_enter_confirms_with_results_test() {
  // Given: A popup with results
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results([create_test_food("1", "Apple")])

  // When: We handle Enter key
  let msg = popup.handle_key(state, "\n")

  // Then: Should return ConfirmSelection message
  msg
  |> should.equal(popup.ConfirmSelection)
}

pub fn handle_key_enter_searches_without_results_test() {
  // Given: A popup without results
  let state = popup.init() |> popup.open(None)

  // When: We handle Enter key
  let msg = popup.handle_key(state, "\n")

  // Then: Should return Search message
  msg
  |> should.equal(popup.Search)
}

pub fn handle_key_arrows_navigate_test() {
  // Given: A popup with results
  let state =
    popup.init()
    |> popup.open(None)
    |> popup.set_results([create_test_food("1", "Apple")])

  // When: We handle up arrow
  let up_msg = popup.handle_key(state, "\u{001B}[A")

  // Then: Should return SelectPrevious
  up_msg
  |> should.equal(popup.SelectPrevious)

  // When: We handle down arrow
  let down_msg = popup.handle_key(state, "\u{001B}[D")

  // Then: Should return SelectNext
  down_msg
  |> should.equal(popup.SelectNext)
}

// ============================================================================
// Test 13: Helper Functions
// ============================================================================

pub fn helper_functions_work_correctly_test() {
  // Given: A popup with specific state
  let state =
    popup.init()
    |> popup.open(Some("test query"))
    |> popup.set_results([
      create_test_food("1", "Apple"),
      create_test_food("2", "Banana"),
    ])
    |> popup.select_next
    |> popup.set_loading(True)

  // Then: Helper functions should return correct values
  popup.is_visible(state)
  |> should.be_true

  popup.get_query(state)
  |> should.equal("test query")

  popup.get_results_count(state)
  |> should.equal(2)

  popup.is_loading(state)
  |> should.be_true

  popup.get_error(state)
  |> should.equal(None)

  popup.get_selected_index(state)
  |> should.equal(1)
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test food search result
fn create_test_food(id: String, name: String) -> types.FoodSearchResult {
  types.FoodSearchResult(
    food_id: types.food_id(id),
    food_name: name,
    food_type: "Generic",
    food_description: name <> " - Per 100g",
    brand_name: None,
    food_url: "https://fatsecret.com/calories-nutrition/generic/" <> id,
  )
}
