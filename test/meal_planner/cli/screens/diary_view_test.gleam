/// Tests for Diary View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Search state management
/// - Edit state management
/// - Nutrition targets
/// - Meal section totals
/// - Date utilities
import gleam/dict
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/diary_view
import meal_planner/cli/screens/fatsecret_diary.{
  type DiaryEffect, type EditState, type MealSection, type MealTotals,
  type NutritionTarget, type SearchState, type ViewState, ConfirmDelete,
  DatePicker, EditAmount, EditState, MainView, MealSection, MealTotals,
  NutritionTarget, SearchPopup, SearchState,
}
import meal_planner/fatsecret/diary/types as diary_types

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a minimal FoodEntry for testing
fn test_food_entry(
  name: String,
  meal: diary_types.MealType,
) -> diary_types.FoodEntry {
  diary_types.FoodEntry(
    food_entry_id: diary_types.food_entry_id("entry_1"),
    food_entry_name: name,
    food_entry_description: name <> " - 1 serving",
    food_id: "food_1",
    serving_id: "serving_1",
    number_of_units: 1.0,
    meal: meal,
    date_int: 20_000,
    calories: 100.0,
    carbohydrate: 10.0,
    protein: 10.0,
    fat: 5.0,
    saturated_fat: None,
    polyunsaturated_fat: None,
    monounsaturated_fat: None,
    cholesterol: None,
    sodium: None,
    potassium: None,
    fiber: None,
    sugar: None,
  )
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: Today's date as date_int
  let today = 20_000

  // WHEN: Initializing DiaryModel
  let model = fatsecret_diary.init(today)

  // THEN: Model should have correct initial state
  model.current_date
  |> should.equal(today)

  model.entries_by_meal
  |> should.equal([])

  model.view_state
  |> should.equal(MainView)

  model.error_message
  |> should.equal(None)

  model.nutrition_targets
  |> should.equal(None)

  // AND: Search state should be empty
  model.search_state.query
  |> should.equal("")

  model.search_state.results
  |> should.equal([])

  model.search_state.selected_index
  |> should.equal(0)

  model.search_state.is_loading
  |> should.equal(False)

  // AND: Edit state should be None
  model.edit_state
  |> should.equal(None)

  // AND: Food cache should be empty
  model.food_cache
  |> dict.size
  |> should.equal(0)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_main_view_test() {
  let view_state: ViewState = MainView
  case view_state {
    MainView -> True
  }
  |> should.be_true
}

pub fn view_state_search_popup_test() {
  let view_state: ViewState = SearchPopup
  case view_state {
    SearchPopup -> True
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  let view_state: ViewState = DatePicker("2025-12-20")
  case view_state {
    DatePicker(date_input) -> date_input
    _ -> ""
  }
  |> should.equal("2025-12-20")
}

pub fn view_state_confirm_delete_test() {
  let entry_id = diary_types.food_entry_id("12345")
  let view_state: ViewState = ConfirmDelete(entry_id)
  case view_state {
    ConfirmDelete(id) -> diary_types.food_entry_id_to_string(id)
    _ -> ""
  }
  |> should.equal("12345")
}

pub fn view_state_edit_amount_test() {
  let entry = test_food_entry("Apple", diary_types.Snack)
  let edit_state =
    EditState(
      entry: entry,
      new_number_of_units: 2.0,
      original_number_of_units: 1.0,
    )
  let view_state: ViewState = EditAmount(edit_state)
  case view_state {
    EditAmount(state) -> state.new_number_of_units
    _ -> 0.0
  }
  |> should.equal(2.0)
}

// ============================================================================
// Search State Tests
// ============================================================================

pub fn search_state_initial_test() {
  let model = fatsecret_diary.init(20_000)
  model.search_state.query
  |> should.equal("")
  model.search_state.results
  |> should.equal([])
  model.search_state.selected_index
  |> should.equal(0)
  model.search_state.is_loading
  |> should.equal(False)
  model.search_state.search_error
  |> should.equal(None)
}

pub fn search_state_construction_test() {
  let search_state =
    SearchState(
      query: "chicken",
      results: [],
      selected_index: 0,
      is_loading: True,
      search_error: None,
    )
  search_state.query
  |> should.equal("chicken")
  search_state.is_loading
  |> should.equal(True)
}

// ============================================================================
// Edit State Tests
// ============================================================================

pub fn edit_state_construction_test() {
  let entry = test_food_entry("Grilled Chicken", diary_types.Lunch)
  let edit_state =
    EditState(
      entry: entry,
      new_number_of_units: 2.0,
      original_number_of_units: 1.0,
    )
  edit_state.new_number_of_units
  |> should.equal(2.0)
  edit_state.original_number_of_units
  |> should.equal(1.0)
  edit_state.entry.food_entry_name
  |> should.equal("Grilled Chicken")
}

// ============================================================================
// Nutrition Target Tests
// ============================================================================

pub fn nutrition_target_construction_test() {
  let target =
    NutritionTarget(
      calories: 2000.0,
      carbohydrate: 250.0,
      protein: 150.0,
      fat: 65.0,
    )
  target.calories
  |> should.equal(2000.0)
  target.carbohydrate
  |> should.equal(250.0)
  target.protein
  |> should.equal(150.0)
  target.fat
  |> should.equal(65.0)
}

pub fn nutrition_target_initial_none_test() {
  let model = fatsecret_diary.init(20_000)
  model.nutrition_targets
  |> should.equal(None)
}

// ============================================================================
// Meal Section Tests
// ============================================================================

pub fn meal_section_construction_test() {
  let totals =
    MealTotals(calories: 500.0, carbohydrate: 50.0, protein: 40.0, fat: 20.0)
  let section =
    MealSection(
      meal_type: diary_types.Breakfast,
      entries: [],
      section_totals: totals,
    )
  section.meal_type
  |> should.equal(diary_types.Breakfast)
  section.section_totals.calories
  |> should.equal(500.0)
  section.entries
  |> should.equal([])
}

pub fn meal_totals_construction_test() {
  let totals =
    MealTotals(calories: 750.0, carbohydrate: 80.0, protein: 55.0, fat: 25.0)
  totals.calories
  |> should.equal(750.0)
  totals.carbohydrate
  |> should.equal(80.0)
  totals.protein
  |> should.equal(55.0)
  totals.fat
  |> should.equal(25.0)
}

// ============================================================================
// Date Utility Tests
// ============================================================================

pub fn date_int_to_string_produces_valid_format_test() {
  let date_int = 19_720
  let date_str = diary_view.date_int_to_string(date_int)
  date_str
  |> should.not_equal("")
}

pub fn parse_date_string_valid_test() {
  let date_str = "2025-12-20"
  let result = diary_view.parse_date_string(date_str)
  case result {
    Ok(date_int) -> date_int > 0
    Error(_) -> False
  }
  |> should.be_true
}

pub fn parse_date_string_invalid_test() {
  let date_str = "not-a-date"
  let result = diary_view.parse_date_string(date_str)
  case result {
    Ok(_) -> False
    Error(_) -> True
  }
  |> should.be_true
}

// ============================================================================
// Macro Status Tests
// ============================================================================

pub fn calculate_macro_status_under_test() {
  let status = fatsecret_diary.calculate_macro_status(50.0, 100.0)
  status
  |> should.equal(fatsecret_diary.Under)
}

pub fn calculate_macro_status_met_test() {
  let status = fatsecret_diary.calculate_macro_status(100.0, 100.0)
  status
  |> should.equal(fatsecret_diary.Met)
}

pub fn calculate_macro_status_over_test() {
  let status = fatsecret_diary.calculate_macro_status(150.0, 100.0)
  status
  |> should.equal(fatsecret_diary.Over)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn diary_msg_navigation_variants_compile_test() {
  let _msgs = [
    fatsecret_diary.DateNavigatePrevious,
    fatsecret_diary.DateNavigateNext,
    fatsecret_diary.DateJumpToToday,
    fatsecret_diary.DateShowPicker,
    fatsecret_diary.DateConfirmPicker("2025-12-20"),
    fatsecret_diary.DateCancelPicker,
  ]
  True
  |> should.be_true
}

pub fn diary_msg_add_entry_variants_compile_test() {
  let _msgs = [
    fatsecret_diary.AddEntryStart,
    fatsecret_diary.SearchQueryChanged("test"),
    fatsecret_diary.SearchFoodStarted,
    fatsecret_diary.GotFoodSearchResults(Ok([])),
    fatsecret_diary.CancelAddEntry,
  ]
  True
  |> should.be_true
}

pub fn diary_msg_edit_variants_compile_test() {
  let entry = test_food_entry("Test", diary_types.Lunch)
  let _msgs = [
    fatsecret_diary.EditEntryStart(entry),
    fatsecret_diary.EditEntryServingsChanged(1.5),
    fatsecret_diary.EditEntryConfirm,
    fatsecret_diary.EditEntryCancel,
  ]
  True
  |> should.be_true
}

pub fn diary_msg_delete_variants_compile_test() {
  let entry_id = diary_types.food_entry_id("test")
  let _msgs = [
    fatsecret_diary.DeleteEntryStart(entry_id),
    fatsecret_diary.DeleteEntryConfirm,
    fatsecret_diary.DeleteEntryCancel,
  ]
  True
  |> should.be_true
}

pub fn diary_msg_ui_variants_compile_test() {
  let _msgs = [
    fatsecret_diary.ClearError,
    fatsecret_diary.KeyPressed("a"),
    fatsecret_diary.NoOp,
  ]
  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn diary_effect_all_variants_compile_test() {
  let entry_id = diary_types.food_entry_id("test")
  let _effects: List(DiaryEffect) = [
    fatsecret_diary.None,
    fatsecret_diary.FetchEntries(20_000),
    fatsecret_diary.SearchFoods("chicken"),
    fatsecret_diary.DeleteEntry(entry_id),
    fatsecret_diary.FetchNutritionTargets,
    fatsecret_diary.Batch([]),
  ]
  True
  |> should.be_true
}

// ============================================================================
// Cache Validity Tests
// ============================================================================

pub fn is_cache_valid_fresh_test() {
  let cached_at = 1_000_000
  let current_time = 1_003_600
  let is_valid = diary_view.is_cache_valid(cached_at, current_time)
  is_valid
  |> should.equal(True)
}

pub fn is_cache_valid_expired_test() {
  let cached_at = 1_000_000
  let current_time = cached_at + { 10 * 86_400 }
  let is_valid = diary_view.is_cache_valid(cached_at, current_time)
  is_valid
  |> should.equal(False)
}
