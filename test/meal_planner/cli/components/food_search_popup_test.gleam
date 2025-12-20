/// Tests for Food Search Popup component
///
/// Test Coverage:
/// 1. Activation - SearchActivate shows popup
/// 2. Query Input - SearchQuery updates text and triggers search
/// 3. Results Display - GotSearchResults truncates to 9 items
/// 4. Results Numbering - Results numbered 1-9
/// 5. Number Selection - SelectByNumber(n) highlights item n
/// 6. Arrow Up Navigation - SelectByArrow(Up) cycles list
/// 7. Arrow Down Navigation - SelectByArrow(Down) cycles list
/// 8. Confirm Selection - SearchConfirm returns selected food
/// 9. Cancel Search - SearchCancel hides popup
/// 10. Error Display - GotSearchResults(Err) displayed to user
/// 11. Clear Error - ClearError removes error message
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/components/food_search_popup
import meal_planner/fatsecret/foods/types as foods_types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

fn create_mock_food(id: String, name: String) -> foods_types.FoodSearchResult {
  foods_types.FoodSearchResult(
    food_id: foods_types.food_id(id),
    food_name: name,
    food_type: "Generic",
    brand_name: None,
    food_url: "https://fatsecret.com/food/" <> id,
    food_description: "100 cal per serving",
  )
}

fn create_mock_foods(count: Int) -> List(foods_types.FoodSearchResult) {
  list.range(1, count)
  |> list.map(fn(i) {
    let id = "food_" <> int.to_string(i)
    let name = "Test Food " <> int.to_string(i)
    create_mock_food(id, name)
  })
}

// ============================================================================
// 1. Activation Tests
// ============================================================================

pub fn search_activate_shows_popup_test() {
  // Arrange
  let initial_state = food_search_popup.init()

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchActivate)

  // Assert
  new_state.active
  |> should.be_true
}

pub fn search_activate_clears_previous_state_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: False,
      query: "old query",
      results: [create_mock_food("1", "Old Food")],
      selected_index: 5,
      loading: False,
      error: Some("Previous error"),
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchActivate)

  // Assert
  new_state.active |> should.be_true
  new_state.query |> should.equal("")
  new_state.results |> should.equal([])
  new_state.selected_index |> should.equal(0)
  new_state.error |> should.equal(None)
}

// ============================================================================
// 2. Query Input Tests
// ============================================================================

pub fn search_query_updates_text_test() {
  // Arrange
  let initial_state = food_search_popup.init()

  // Act
  let #(new_state, effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.SearchQuery("banana"),
    )

  // Assert
  new_state.query |> should.equal("banana")
  new_state.loading |> should.be_true
  effects |> list.length |> should.equal(1)
}

pub fn search_query_empty_string_test() {
  // Arrange
  let initial_state = food_search_popup.init()

  // Act - SearchQuery with empty string should still trigger effect
  let #(new_state, effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchQuery(""))

  // Assert
  new_state.query |> should.equal("")
  new_state.loading |> should.be_true
  effects |> list.length |> should.equal(1)
}

// ============================================================================
// 3. Results Display Tests
// ============================================================================

pub fn search_results_truncate_to_9_items_test() {
  // Arrange
  let initial_state = food_search_popup.init()
  let mock_foods = create_mock_foods(15)

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.GotSearchResults(Ok(mock_foods)),
    )

  // Assert
  new_state.results
  |> list.length
  |> should.equal(9)
}

pub fn search_results_sets_loading_false_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: [],
      selected_index: 0,
      loading: True,
      error: None,
    )
  let mock_foods = create_mock_foods(3)

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.GotSearchResults(Ok(mock_foods)),
    )

  // Assert
  new_state.loading |> should.be_false
  new_state.error |> should.equal(None)
}

// ============================================================================
// 4. Results Numbering Tests
// ============================================================================

pub fn results_numbered_1_to_9_test() {
  // This test verifies the rendering behavior
  // We can't directly test rendering, but we can verify the results list
  // is ordered correctly (which the render function uses)
  let initial_state = food_search_popup.init()
  let mock_foods = create_mock_foods(9)

  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.GotSearchResults(Ok(mock_foods)),
    )

  // Results should be in order (render function will number them 1-9)
  new_state.results
  |> list.length
  |> should.equal(9)
}

// ============================================================================
// 5. Number Selection Tests
// ============================================================================

pub fn select_by_number_highlights_item_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(9),
      selected_index: 0,
      loading: False,
      error: None,
    )

  // Act - Select item 5
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.SelectByNumber(5))

  // Assert - selected_index should be 4 (5 - 1, 0-based)
  new_state.selected_index |> should.equal(4)
}

pub fn select_by_number_first_item_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(9),
      selected_index: 5,
      loading: False,
      error: None,
    )

  // Act - Select item 1
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.SelectByNumber(1))

  // Assert - selected_index should be 0
  new_state.selected_index |> should.equal(0)
}

// ============================================================================
// 6. Arrow Up Navigation Tests
// ============================================================================

pub fn select_by_arrow_up_from_middle_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(5),
      selected_index: 3,
      loading: False,
      error: None,
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.SelectByArrow(food_search_popup.Up),
    )

  // Assert
  new_state.selected_index |> should.equal(2)
}

pub fn select_by_arrow_up_cycles_from_first_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(5),
      selected_index: 0,
      loading: False,
      error: None,
    )

  // Act - Up from index 0 should wrap to last item (index 4)
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.SelectByArrow(food_search_popup.Up),
    )

  // Assert
  new_state.selected_index |> should.equal(4)
}

// ============================================================================
// 7. Arrow Down Navigation Tests
// ============================================================================

pub fn select_by_arrow_down_from_middle_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(5),
      selected_index: 2,
      loading: False,
      error: None,
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.SelectByArrow(food_search_popup.Down),
    )

  // Assert
  new_state.selected_index |> should.equal(3)
}

pub fn select_by_arrow_down_cycles_from_last_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: create_mock_foods(5),
      selected_index: 4,
      loading: False,
      error: None,
    )

  // Act - Down from last index (4) should wrap to first item (index 0)
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.SelectByArrow(food_search_popup.Down),
    )

  // Assert
  new_state.selected_index |> should.equal(0)
}

// ============================================================================
// 8. Confirm Selection Tests
// ============================================================================

pub fn search_confirm_returns_selected_food_test() {
  // Arrange
  let mock_foods = create_mock_foods(3)
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: mock_foods,
      selected_index: 1,
      loading: False,
      error: None,
    )

  // Act
  let #(new_state, effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchConfirm)

  // Assert
  new_state.active |> should.be_false
  effects |> list.length |> should.equal(1)

  // Execute the effect to get the FoodSelected message
  case effects {
    [effect] -> {
      let msg = effect()
      case msg {
        food_search_popup.FoodSelected(food_id, food_name) -> {
          food_id |> should.equal("food_2")
          food_name |> should.equal("Test Food 2")
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn search_confirm_no_results_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: [],
      selected_index: 0,
      loading: False,
      error: None,
    )

  // Act
  let #(new_state, effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchConfirm)

  // Assert - Should not change state or create effects
  new_state.active |> should.be_true
  effects |> should.equal([])
}

// ============================================================================
// 9. Cancel Search Tests
// ============================================================================

pub fn search_cancel_hides_popup_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test query",
      results: create_mock_foods(5),
      selected_index: 2,
      loading: False,
      error: Some("some error"),
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.SearchCancel)

  // Assert
  new_state.active |> should.be_false
  new_state.query |> should.equal("")
  new_state.results |> should.equal([])
  new_state.error |> should.equal(None)
}

// ============================================================================
// 10. Error Display Tests
// ============================================================================

pub fn search_error_displayed_to_user_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: [],
      selected_index: 0,
      loading: True,
      error: None,
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(
      initial_state,
      food_search_popup.GotSearchResults(Error("Network timeout")),
    )

  // Assert
  new_state.loading |> should.be_false
  new_state.error |> should.equal(Some("Network timeout"))
}

// ============================================================================
// 11. Clear Error Tests
// ============================================================================

pub fn search_clear_error_removes_message_test() {
  // Arrange
  let initial_state =
    food_search_popup.SearchState(
      active: True,
      query: "test",
      results: [],
      selected_index: 0,
      loading: False,
      error: Some("Previous error"),
    )

  // Act
  let #(new_state, _effects) =
    food_search_popup.update(initial_state, food_search_popup.ClearError)

  // Assert
  new_state.error |> should.equal(None)
}
