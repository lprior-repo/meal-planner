/// Tests for List View Component
///
/// Tests cover:
/// - Initialization and defaults
/// - Navigation (previous, next, first, last, page up/down)
/// - Selection (single and multi-select)
/// - Filter functionality
/// - State management
/// - Keyboard handling
/// - Public API functions
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/components/list_view.{
  type ListViewEffect, type ListViewModel, type ListViewMsg,
  ClearError, ClearFilter, Confirm, DeselectAll, FilterChanged,
  FilterQueryChanged, ItemSelected, ItemsSelected, NoEffect, PageDown, PageUp,
  SelectAll, SelectFirst, SelectLast, SelectNext, SelectPrevious, SetError,
  SetLoading, ToggleFilter, ToggleSelection,
}

// ============================================================================
// Test Data
// ============================================================================

fn sample_items() -> List(String) {
  ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew"]
}

fn small_items() -> List(String) {
  ["One", "Two", "Three"]
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: A list of items and visible count
  let items = sample_items()
  let visible_count = 5

  // WHEN: Initializing list view
  let model = list_view.init(items, visible_count)

  // THEN: Model should have correct initial state
  model.selected_index
  |> should.equal(0)

  model.scroll_offset
  |> should.equal(0)

  model.visible_count
  |> should.equal(5)

  model.multi_select
  |> should.equal(False)

  model.filter_query
  |> should.equal("")

  model.filter_active
  |> should.equal(False)

  model.is_loading
  |> should.equal(False)

  model.error
  |> should.equal(None)

  list.length(model.items)
  |> should.equal(8)
}

pub fn init_with_empty_list_test() {
  // GIVEN: An empty list
  let items: List(String) = []

  // WHEN: Initializing list view
  let model = list_view.init(items, 5)

  // THEN: Model should handle empty list
  list.length(model.items)
  |> should.equal(0)

  model.selected_index
  |> should.equal(0)
}

pub fn init_multi_select_enables_multi_selection_test() {
  // GIVEN: Items list
  let items = sample_items()

  // WHEN: Initializing with multi-select
  let model = list_view.init_multi_select(items, 5)

  // THEN: Multi-select should be enabled
  model.multi_select
  |> should.equal(True)

  model.selected_indices
  |> should.equal([])
}

pub fn init_with_title_sets_title_test() {
  // GIVEN: Items and a title
  let items = sample_items()
  let title = "My List"

  // WHEN: Initializing with title
  let model = list_view.init_with_title(items, 5, title)

  // THEN: Title should be set
  model.title
  |> should.equal(Some("My List"))
}

// ============================================================================
// Navigation Tests
// ============================================================================

pub fn select_next_navigates_forward_test() {
  // GIVEN: A list view at index 0
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting next
  let #(updated, effect) = list_view.update(model, SelectNext)

  // THEN: Index should increase by 1
  updated.selected_index
  |> should.equal(1)

  effect
  |> should.equal(NoEffect)
}

pub fn select_next_stops_at_end_test() {
  // GIVEN: A list view at last item
  let items = small_items()
  let model = list_view.init(items, 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Selecting next at end
  let #(updated, _effect) = list_view.update(model2, SelectNext)

  // THEN: Index should stay at end
  updated.selected_index
  |> should.equal(2)
}

pub fn select_previous_navigates_backward_test() {
  // GIVEN: A list view at index 2
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Selecting previous
  let #(updated, effect) = list_view.update(model2, SelectPrevious)

  // THEN: Index should decrease by 1
  updated.selected_index
  |> should.equal(1)

  effect
  |> should.equal(NoEffect)
}

pub fn select_previous_stops_at_beginning_test() {
  // GIVEN: A list view at index 0
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting previous at beginning
  let #(updated, _effect) = list_view.update(model, SelectPrevious)

  // THEN: Index should stay at 0
  updated.selected_index
  |> should.equal(0)
}

pub fn select_first_goes_to_beginning_test() {
  // GIVEN: A list view at index 5
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 5, scroll_offset: 2)

  // WHEN: Selecting first
  let #(updated, effect) = list_view.update(model2, SelectFirst)

  // THEN: Index and scroll should be at 0
  updated.selected_index
  |> should.equal(0)

  updated.scroll_offset
  |> should.equal(0)

  effect
  |> should.equal(NoEffect)
}

pub fn select_last_goes_to_end_test() {
  // GIVEN: A list view at index 0 with 8 items
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting last
  let #(updated, effect) = list_view.update(model, SelectLast)

  // THEN: Index should be at last item
  updated.selected_index
  |> should.equal(7)

  effect
  |> should.equal(NoEffect)
}

pub fn page_up_navigates_by_page_test() {
  // GIVEN: A list view at index 6 with visible count 5
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 6, scroll_offset: 3)

  // WHEN: Page up
  let #(updated, _effect) = list_view.update(model2, PageUp)

  // THEN: Index should decrease by visible count
  updated.selected_index
  |> should.equal(1)
}

pub fn page_up_stops_at_zero_test() {
  // GIVEN: A list view at index 2 with visible count 5
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Page up
  let #(updated, _effect) = list_view.update(model2, PageUp)

  // THEN: Index should be 0 (not negative)
  updated.selected_index
  |> should.equal(0)
}

pub fn page_down_navigates_by_page_test() {
  // GIVEN: A list view at index 0 with visible count 5
  let model = list_view.init(sample_items(), 5)

  // WHEN: Page down
  let #(updated, _effect) = list_view.update(model, PageDown)

  // THEN: Index should increase by visible count
  updated.selected_index
  |> should.equal(5)
}

pub fn page_down_stops_at_end_test() {
  // GIVEN: A list view at index 5 with 8 items
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 5)

  // WHEN: Page down
  let #(updated, _effect) = list_view.update(model2, PageDown)

  // THEN: Index should be at last item
  updated.selected_index
  |> should.equal(7)
}

// ============================================================================
// Single Selection Tests
// ============================================================================

pub fn toggle_selection_single_mode_returns_item_test() {
  // GIVEN: A list view in single-select mode
  let model = list_view.init(sample_items(), 5)

  // WHEN: Toggling selection
  let #(_updated, effect) = list_view.update(model, ToggleSelection)

  // THEN: Should return ItemSelected effect
  case effect {
    ItemSelected(item, index) -> {
      item |> should.equal("Apple")
      index |> should.equal(0)
    }
    _ -> should.fail()
  }
}

pub fn confirm_single_mode_returns_item_test() {
  // GIVEN: A list view at index 2
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Confirming
  let #(_updated, effect) = list_view.update(model2, Confirm)

  // THEN: Should return ItemSelected effect with correct item
  case effect {
    ItemSelected(item, index) -> {
      item |> should.equal("Cherry")
      index |> should.equal(2)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Multi Selection Tests
// ============================================================================

pub fn toggle_selection_multi_mode_adds_index_test() {
  // GIVEN: A list view in multi-select mode
  let model = list_view.init_multi_select(sample_items(), 5)

  // WHEN: Toggling selection
  let #(updated, effect) = list_view.update(model, ToggleSelection)

  // THEN: Index should be added to selected_indices
  list.contains(updated.selected_indices, 0)
  |> should.equal(True)

  effect
  |> should.equal(NoEffect)
}

pub fn toggle_selection_multi_mode_removes_index_test() {
  // GIVEN: A list view with index 0 already selected
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [0])

  // WHEN: Toggling selection again
  let #(updated, _effect) = list_view.update(model2, ToggleSelection)

  // THEN: Index should be removed from selected_indices
  list.contains(updated.selected_indices, 0)
  |> should.equal(False)
}

pub fn select_all_selects_all_items_test() {
  // GIVEN: A list view in multi-select mode
  let model = list_view.init_multi_select(sample_items(), 5)

  // WHEN: Selecting all
  let #(updated, effect) = list_view.update(model, SelectAll)

  // THEN: All indices should be selected
  list.length(updated.selected_indices)
  |> should.equal(8)

  effect
  |> should.equal(NoEffect)
}

pub fn select_all_single_mode_does_nothing_test() {
  // GIVEN: A list view in single-select mode
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting all
  let #(updated, _effect) = list_view.update(model, SelectAll)

  // THEN: Should not change selected_indices
  list.length(updated.selected_indices)
  |> should.equal(0)
}

pub fn deselect_all_clears_selection_test() {
  // GIVEN: A list view with some items selected
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [0, 2, 4])

  // WHEN: Deselecting all
  let #(updated, effect) = list_view.update(model2, DeselectAll)

  // THEN: All indices should be cleared
  list.length(updated.selected_indices)
  |> should.equal(0)

  effect
  |> should.equal(NoEffect)
}

pub fn confirm_multi_mode_returns_selected_items_test() {
  // GIVEN: A list view with multiple items selected
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [0, 2, 4])

  // WHEN: Confirming
  let #(_updated, effect) = list_view.update(model2, Confirm)

  // THEN: Should return ItemsSelected effect
  case effect {
    ItemsSelected(items, indices) -> {
      list.length(items) |> should.equal(3)
      list.length(indices) |> should.equal(3)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Filter Tests
// ============================================================================

pub fn filter_query_changed_updates_query_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Changing filter query
  let #(updated, effect) = list_view.update(model, FilterQueryChanged("apple"))

  // THEN: Query should be updated
  updated.filter_query
  |> should.equal("apple")

  case effect {
    FilterChanged(query) -> query |> should.equal("apple")
    _ -> should.fail()
  }
}

pub fn toggle_filter_enables_filter_mode_test() {
  // GIVEN: A list view with filter disabled
  let model = list_view.init(sample_items(), 5)

  // WHEN: Toggling filter
  let #(updated, effect) = list_view.update(model, ToggleFilter)

  // THEN: Filter should be enabled
  updated.filter_active
  |> should.equal(True)

  effect
  |> should.equal(NoEffect)
}

pub fn toggle_filter_disables_filter_mode_test() {
  // GIVEN: A list view with filter enabled
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, filter_active: True, filter_query: "test")

  // WHEN: Toggling filter
  let #(updated, _effect) = list_view.update(model2, ToggleFilter)

  // THEN: Filter should be disabled and query cleared
  updated.filter_active
  |> should.equal(False)

  updated.filter_query
  |> should.equal("")
}

pub fn clear_filter_resets_filter_state_test() {
  // GIVEN: A list view with active filter
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, filter_active: True, filter_query: "apple")

  // WHEN: Clearing filter
  let #(updated, effect) = list_view.update(model2, ClearFilter)

  // THEN: Filter should be cleared
  updated.filter_active
  |> should.equal(False)

  updated.filter_query
  |> should.equal("")

  case effect {
    FilterChanged(query) -> query |> should.equal("")
    _ -> should.fail()
  }
}

// ============================================================================
// State Management Tests
// ============================================================================

pub fn init_with_new_items_replaces_items_test() {
  // GIVEN: Need to replace items
  let new_items = ["New1", "New2"]

  // WHEN: Initializing with new items (SetItems was removed, use init instead)
  let updated = list_view.init(new_items, 5)

  // THEN: Items should be set and position should be at start
  list.length(updated.items)
  |> should.equal(2)

  updated.selected_index
  |> should.equal(0)

  updated.scroll_offset
  |> should.equal(0)
}

pub fn set_loading_updates_loading_state_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Setting loading to true
  let #(updated, effect) = list_view.update(model, SetLoading(True))

  // THEN: Loading should be true
  updated.is_loading
  |> should.equal(True)

  effect
  |> should.equal(NoEffect)

  // WHEN: Setting loading to false
  let #(updated2, _) = list_view.update(updated, SetLoading(False))

  // THEN: Loading should be false
  updated2.is_loading
  |> should.equal(False)
}

pub fn set_error_updates_error_state_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Setting error
  let #(updated, effect) = list_view.update(model, SetError(Some("Test error")))

  // THEN: Error should be set
  updated.error
  |> should.equal(Some("Test error"))

  effect
  |> should.equal(NoEffect)
}

pub fn clear_error_removes_error_test() {
  // GIVEN: A list view with error
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, error: Some("Test error"))

  // WHEN: Clearing error
  let #(updated, effect) = list_view.update(model2, ClearError)

  // THEN: Error should be cleared
  updated.error
  |> should.equal(None)

  effect
  |> should.equal(NoEffect)
}

// ============================================================================
// Keyboard Handling Tests
// ============================================================================

pub fn key_j_navigates_next_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Pressing 'j' key
  let #(updated, _effect) = list_view.handle_key(model, "j")

  // THEN: Should navigate next
  updated.selected_index
  |> should.equal(1)
}

pub fn key_k_navigates_previous_test() {
  // GIVEN: A list view at index 2
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Pressing 'k' key
  let #(updated, _effect) = list_view.handle_key(model2, "k")

  // THEN: Should navigate previous
  updated.selected_index
  |> should.equal(1)
}

pub fn key_g_goes_to_first_test() {
  // GIVEN: A list view at index 5
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 5)

  // WHEN: Pressing 'g' key
  let #(updated, _effect) = list_view.handle_key(model2, "g")

  // THEN: Should go to first
  updated.selected_index
  |> should.equal(0)
}

pub fn key_upper_g_goes_to_last_test() {
  // GIVEN: A list view at index 0
  let model = list_view.init(sample_items(), 5)

  // WHEN: Pressing 'G' key
  let #(updated, _effect) = list_view.handle_key(model, "G")

  // THEN: Should go to last
  updated.selected_index
  |> should.equal(7)
}

pub fn key_space_toggles_selection_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Pressing space key
  let #(_updated, effect) = list_view.handle_key(model, " ")

  // THEN: Should return ItemSelected effect (single mode)
  case effect {
    ItemSelected(_, _) -> True |> should.equal(True)
    _ -> should.fail()
  }
}

pub fn key_enter_confirms_selection_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Pressing Enter key
  let #(_updated, effect) = list_view.handle_key(model, "\r")

  // THEN: Should return ItemSelected effect
  case effect {
    ItemSelected(_, _) -> True |> should.equal(True)
    _ -> should.fail()
  }
}

pub fn key_slash_toggles_filter_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Pressing '/' key
  let #(updated, _effect) = list_view.handle_key(model, "/")

  // THEN: Filter should be toggled
  updated.filter_active
  |> should.equal(True)
}

pub fn key_a_selects_all_test() {
  // GIVEN: A list view in multi-select mode
  let model = list_view.init_multi_select(sample_items(), 5)

  // WHEN: Pressing 'a' key
  let #(updated, _effect) = list_view.handle_key(model, "a")

  // THEN: All should be selected
  list.length(updated.selected_indices)
  |> should.equal(8)
}

pub fn key_d_deselects_all_test() {
  // GIVEN: A list view with items selected
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [0, 1, 2])

  // WHEN: Pressing 'd' key
  let #(updated, _effect) = list_view.handle_key(model2, "d")

  // THEN: All should be deselected
  list.length(updated.selected_indices)
  |> should.equal(0)
}

pub fn escape_in_filter_mode_exits_filter_test() {
  // GIVEN: A list view with filter active
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, filter_active: True)

  // WHEN: Pressing escape key
  let #(updated, _effect) = list_view.handle_key(model2, "\u{001B}")

  // THEN: Filter should be disabled
  updated.filter_active
  |> should.equal(False)
}

// ============================================================================
// Helper Function Tests
// ============================================================================

pub fn get_visible_items_returns_correct_slice_test() {
  // GIVEN: A list view with scroll offset
  let model = list_view.init(sample_items(), 3)
  let model2 = list_view.ListViewModel(..model, scroll_offset: 2)

  // WHEN: Getting visible items
  let visible = list_view.get_visible_items(model2)

  // THEN: Should return correct items
  list.length(visible)
  |> should.equal(3)

  case list.first(visible) {
    Ok(item) -> item |> should.equal("Cherry")
    Error(_) -> should.fail()
  }
}

pub fn get_selected_item_returns_current_item_test() {
  // GIVEN: A list view at index 3
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 3)

  // WHEN: Getting selected item
  let selected = list_view.get_selected_item(model2)

  // THEN: Should return correct item
  selected
  |> should.equal(Some("Date"))
}

pub fn get_selected_item_empty_list_returns_none_test() {
  // GIVEN: An empty list view
  let model = list_view.init([], 5)

  // WHEN: Getting selected item
  let selected = list_view.get_selected_item(model)

  // THEN: Should return None
  selected
  |> should.equal(None)
}

pub fn get_selected_items_returns_multi_selection_test() {
  // GIVEN: A list view with multiple selections
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [1, 3, 5])

  // WHEN: Getting selected items
  let selected = list_view.get_selected_items(model2)

  // THEN: Should return correct items
  list.length(selected)
  |> should.equal(3)
}

pub fn is_index_selected_single_mode_test() {
  // GIVEN: A list view in single-select mode at index 2
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 2)

  // WHEN: Checking if indices are selected
  // THEN: Only index 2 should be selected
  list_view.is_index_selected(model2, 0)
  |> should.equal(False)

  list_view.is_index_selected(model2, 2)
  |> should.equal(True)

  list_view.is_index_selected(model2, 4)
  |> should.equal(False)
}

pub fn is_index_selected_multi_mode_test() {
  // GIVEN: A list view in multi-select mode with indices 1, 3 selected
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [1, 3])

  // WHEN: Checking if indices are selected
  // THEN: Only indices 1 and 3 should be selected
  list_view.is_index_selected(model2, 0)
  |> should.equal(False)

  list_view.is_index_selected(model2, 1)
  |> should.equal(True)

  list_view.is_index_selected(model2, 2)
  |> should.equal(False)

  list_view.is_index_selected(model2, 3)
  |> should.equal(True)
}

// ============================================================================
// Public API Tests
// ============================================================================

pub fn set_items_function_replaces_items_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_index: 3)

  // WHEN: Using set_items function
  let updated = list_view.set_items(model2, ["A", "B", "C"])

  // THEN: Items should be replaced
  list.length(updated.items)
  |> should.equal(3)

  updated.selected_index
  |> should.equal(0)
}

pub fn set_title_function_sets_title_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Setting title
  let updated = list_view.set_title(model, "New Title")

  // THEN: Title should be set
  updated.title
  |> should.equal(Some("New Title"))
}

pub fn set_empty_message_function_sets_message_test() {
  // GIVEN: A list view
  let model = list_view.init([], 5)

  // WHEN: Setting empty message
  let updated = list_view.set_empty_message(model, "Nothing here")

  // THEN: Message should be set
  updated.empty_message
  |> should.equal("Nothing here")
}

pub fn enable_multi_select_function_enables_test() {
  // GIVEN: A single-select list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Enabling multi-select
  let updated = list_view.enable_multi_select(model)

  // THEN: Multi-select should be enabled
  updated.multi_select
  |> should.equal(True)
}

pub fn disable_multi_select_function_disables_test() {
  // GIVEN: A multi-select list view with selections
  let model = list_view.init_multi_select(sample_items(), 5)
  let model2 = list_view.ListViewModel(..model, selected_indices: [0, 1, 2])

  // WHEN: Disabling multi-select
  let updated = list_view.disable_multi_select(model2)

  // THEN: Multi-select should be disabled and selections cleared
  updated.multi_select
  |> should.equal(False)

  list.length(updated.selected_indices)
  |> should.equal(0)
}

pub fn set_visible_count_function_updates_count_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Setting visible count
  let updated = list_view.set_visible_count(model, 10)

  // THEN: Visible count should be updated
  updated.visible_count
  |> should.equal(10)
}

pub fn select_index_function_selects_valid_index_test() {
  // GIVEN: A list view
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting index 4
  let updated = list_view.select_index(model, 4)

  // THEN: Index should be updated
  updated.selected_index
  |> should.equal(4)
}

pub fn select_index_function_clamps_to_valid_range_test() {
  // GIVEN: A list view with 8 items
  let model = list_view.init(sample_items(), 5)

  // WHEN: Selecting index beyond range
  let updated = list_view.select_index(model, 100)

  // THEN: Index should be clamped to last item
  updated.selected_index
  |> should.equal(7)

  // WHEN: Selecting negative index
  let updated2 = list_view.select_index(model, -5)

  // THEN: Index should be clamped to 0
  updated2.selected_index
  |> should.equal(0)
}

// ============================================================================
// Scroll Offset Tests
// ============================================================================

pub fn navigation_adjusts_scroll_offset_down_test() {
  // GIVEN: A list view with 8 items, visible count 3, at bottom of visible area
  let model = list_view.init(sample_items(), 3)
  let model2 = list_view.ListViewModel(..model, selected_index: 2, scroll_offset: 0)

  // WHEN: Navigating next
  let #(updated, _) = list_view.update(model2, SelectNext)

  // THEN: Scroll offset should adjust to keep item visible
  updated.selected_index
  |> should.equal(3)

  updated.scroll_offset
  |> should.equal(1)
}

pub fn navigation_adjusts_scroll_offset_up_test() {
  // GIVEN: A list view with scroll offset
  let model = list_view.init(sample_items(), 3)
  let model2 = list_view.ListViewModel(..model, selected_index: 3, scroll_offset: 3)

  // WHEN: Navigating previous
  let #(updated, _) = list_view.update(model2, SelectPrevious)

  // THEN: Scroll offset should adjust
  updated.selected_index
  |> should.equal(2)

  // Scroll should adjust when selected goes above visible area
  { updated.scroll_offset <= 2 }
  |> should.equal(True)
}

// ============================================================================
// Item Renderer Tests
// ============================================================================

pub fn default_item_renderer_formats_correctly_test() {
  // GIVEN: An item with various states
  let item = "Test Item"

  // WHEN: Using default renderer with cursor
  let with_cursor = list_view.default_item_renderer(item, 0, True, False)

  // THEN: Should have cursor indicator
  { with_cursor != "" }
  |> should.equal(True)

  // WHEN: Using with selection
  let with_selection = list_view.default_item_renderer(item, 0, False, True)

  // THEN: Should have selection indicator
  { with_selection != "" }
  |> should.equal(True)
}

pub fn simple_item_renderer_formats_correctly_test() {
  // GIVEN: An item
  let item = "Simple Item"

  // WHEN: Using simple renderer
  let rendered = list_view.simple_item_renderer(item, 2, True, False)

  // THEN: Should format with cursor and index
  { rendered != "" }
  |> should.equal(True)
}
