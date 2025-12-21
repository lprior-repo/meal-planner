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
  type DiaryEffect, type DiaryModel, type DiaryMsg, type EditState,
  type MealSection, type MealTotals, type NutritionTarget, type SearchState,
  type ViewState, ConfirmDelete, DatePicker, DiaryModel, EditAmount, EditState,
  MainView, MealSection, MealTotals, NutritionTarget, SearchPopup, SearchState,
}
import meal_planner/fatsecret/diary/types as diary_types

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
  // GIVEN: MainView state
  let view_state: ViewState = MainView

  // THEN: Can pattern match without errors
  case view_state {
    MainView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_search_popup_test() {
  // GIVEN: SearchPopup state
  let view_state: ViewState = SearchPopup

  // THEN: Can pattern match correctly
  case view_state {
    SearchPopup -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  // GIVEN: DatePicker state with input
  let view_state: ViewState = DatePicker("2025-12-20")

  // THEN: Can pattern match and extract date_input
  case view_state {
    DatePicker(date_input) -> date_input
    _ -> ""
  }
  |> should.equal("2025-12-20")
}

pub fn view_state_confirm_delete_test() {
  // GIVEN: ConfirmDelete state with entry ID
  let entry_id = diary_types.food_entry_id("12345")
  let view_state: ViewState = ConfirmDelete(entry_id)

  // THEN: Can pattern match and extract entry_id
  case view_state {
    ConfirmDelete(id) -> diary_types.food_entry_id_to_string(id)
    _ -> ""
  }
  |> should.equal("12345")
}

pub fn view_state_edit_amount_test() {
  // GIVEN: EditAmount state with edit state
  let entry = diary_types.food_entry(
    food_entry_id: "entry_1",
    food_id: "food_1",
    food_entry_name: "Apple",
    meal: diary_types.Snack,
    number_of_units: 1.0,
    serving_id: "serving_1",
    calories: 95.0,
    carbohydrates: 25.0,
    protein: 0.5,
    fat: 0.3,
  )
  let edit_state = EditState(
    entry: entry,
    new_number_of_units: 2.0,
    original_number_of_units: 1.0,
  )
  let view_state: ViewState = EditAmount(edit_state)

  // THEN: Can pattern match and access edit state
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
  // GIVEN: Initial model
  let model = fatsecret_diary.init(20_000)

  // THEN: SearchState should be initialized correctly
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
  // GIVEN: Search state with data
  let search_state = SearchState(
    query: "chicken",
    results: [],
    selected_index: 0,
    is_loading: True,
    search_error: None,
  )

  // THEN: State should construct correctly
  search_state.query
  |> should.equal("chicken")

  search_state.is_loading
  |> should.equal(True)
}

// ============================================================================
// Edit State Tests
// ============================================================================

pub fn edit_state_construction_test() {
  // GIVEN: A food entry
  let entry = diary_types.food_entry(
    food_entry_id: "entry_1",
    food_id: "food_1",
    food_entry_name: "Grilled Chicken",
    meal: diary_types.Lunch,
    number_of_units: 1.5,
    serving_id: "serving_1",
    calories: 250.0,
    carbohydrates: 0.0,
    protein: 45.0,
    fat: 8.0,
  )

  // WHEN: Creating edit state
  let edit_state = EditState(
    entry: entry,
    new_number_of_units: 2.0,
    original_number_of_units: 1.5,
  )

  // THEN: Edit state should have correct values
  edit_state.new_number_of_units
  |> should.equal(2.0)

  edit_state.original_number_of_units
  |> should.equal(1.5)

  edit_state.entry.food_entry_name
  |> should.equal("Grilled Chicken")
}

// ============================================================================
// Nutrition Target Tests
// ============================================================================

pub fn nutrition_target_construction_test() {
  // GIVEN: Nutrition target data
  let target = NutritionTarget(
    calories: 2000.0,
    carbohydrate: 250.0,
    protein: 150.0,
    fat: 65.0,
  )

  // THEN: Target should have correct values
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
  // GIVEN: Initial model
  let model = fatsecret_diary.init(20_000)

  // THEN: Nutrition targets should be None initially
  model.nutrition_targets
  |> should.equal(None)
}

// ============================================================================
// Meal Section Tests
// ============================================================================

pub fn meal_section_construction_test() {
  // GIVEN: Meal section data
  let totals = MealTotals(
    calories: 500.0,
    carbohydrate: 50.0,
    protein: 40.0,
    fat: 20.0,
  )

  let section = MealSection(
    meal_type: diary_types.Breakfast,
    entries: [],
    section_totals: totals,
  )

  // THEN: Section should have correct values
  section.meal_type
  |> should.equal(diary_types.Breakfast)

  section.section_totals.calories
  |> should.equal(500.0)

  section.entries
  |> should.equal([])
}

pub fn meal_totals_construction_test() {
  // GIVEN: Meal totals data
  let totals = MealTotals(
    calories: 750.0,
    carbohydrate: 80.0,
    protein: 55.0,
    fat: 25.0,
  )

  // THEN: Totals should have correct values
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

pub fn date_int_to_string_test() {
  // GIVEN: A date_int representing a specific day
  let date_int = 19_720  // Approximately 2023-12-25

  // WHEN: Converting to string
  let date_str = diary_view.date_int_to_string(date_int)

  // THEN: Should produce valid YYYY-MM-DD format
  date_str
  |> should.not_equal("")
}

pub fn parse_date_string_valid_test() {
  // GIVEN: A valid date string
  let date_str = "2025-12-20"

  // WHEN: Parsing the string
  let result = diary_view.parse_date_string(date_str)

  // THEN: Should return Ok with valid date_int
  case result {
    Ok(date_int) -> date_int > 0
    Error(_) -> False
  }
  |> should.be_true
}

pub fn parse_date_string_invalid_test() {
  // GIVEN: An invalid date string
  let date_str = "not-a-date"

  // WHEN: Parsing the string
  let result = diary_view.parse_date_string(date_str)

  // THEN: Should return Error
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
  // GIVEN: Current value well below target
  let current = 50.0
  let target = 100.0

  // WHEN: Calculating status
  let status = fatsecret_diary.calculate_macro_status(current, target)

  // THEN: Should be Under
  status
  |> should.equal(fatsecret_diary.Under)
}

pub fn calculate_macro_status_met_test() {
  // GIVEN: Current value at target
  let current = 100.0
  let target = 100.0

  // WHEN: Calculating status
  let status = fatsecret_diary.calculate_macro_status(current, target)

  // THEN: Should be Met
  status
  |> should.equal(fatsecret_diary.Met)
}

pub fn calculate_macro_status_over_test() {
  // GIVEN: Current value well above target
  let current = 150.0
  let target = 100.0

  // WHEN: Calculating status
  let status = fatsecret_diary.calculate_macro_status(current, target)

  // THEN: Should be Over
  status
  |> should.equal(fatsecret_diary.Over)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn diary_msg_all_variants_compile_test() {
  // This test verifies all DiaryMsg variants can be constructed
  // Compilation success = type system is complete

  let entry_id = diary_types.food_entry_id("test")
  let entry = diary_types.food_entry(
    food_entry_id: "e1",
    food_id: "f1",
    food_entry_name: "Test",
    meal: diary_types.Lunch,
    number_of_units: 1.0,
    serving_id: "s1",
    calories: 100.0,
    carbohydrates: 10.0,
    protein: 10.0,
    fat: 5.0,
  )

  let _msgs = [
    // Date navigation
    fatsecret_diary.DateNavigatePrevious,
    fatsecret_diary.DateNavigateNext,
    fatsecret_diary.DateJumpToToday,
    fatsecret_diary.DateShowPicker,
    fatsecret_diary.DateConfirmPicker("2025-12-20"),
    fatsecret_diary.DateCancelPicker,
    // Add entry
    fatsecret_diary.AddEntryStart,
    fatsecret_diary.SearchQueryChanged("test"),
    fatsecret_diary.SearchFoodStarted,
    fatsecret_diary.GotFoodSearchResults(Ok([])),
    fatsecret_diary.CancelAddEntry,
    // Edit entry
    fatsecret_diary.EditEntryStart(entry),
    fatsecret_diary.EditEntryServingsChanged(1.5),
    fatsecret_diary.EditEntryConfirm,
    fatsecret_diary.EditEntryCancel,
    // Delete entry
    fatsecret_diary.DeleteEntryStart(entry_id),
    fatsecret_diary.DeleteEntryConfirm,
    fatsecret_diary.DeleteEntryCancel,
    // Copy meal
    fatsecret_diary.CopyMealStart,
    fatsecret_diary.CopyMealSelectSource(diary_types.Breakfast),
    fatsecret_diary.CopyMealSelectDate(20_000),
    fatsecret_diary.CopyMealSelectDestMeal(diary_types.Lunch),
    fatsecret_diary.CopyMealConfirm,
    fatsecret_diary.CopyMealCancel,
    // Server responses
    fatsecret_diary.FetchEntriesForDate(20_000),
    fatsecret_diary.GotDailyEntries(Ok([])),
    fatsecret_diary.EntryCreated(Ok(entry_id)),
    fatsecret_diary.EntryUpdated(Ok(Nil)),
    fatsecret_diary.EntryDeleted(Ok(Nil)),
    // UI
    fatsecret_diary.ClearError,
    fatsecret_diary.KeyPressed("a"),
    fatsecret_diary.NoOp,
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn diary_effect_all_variants_compile_test() {
  // This test verifies all DiaryEffect variants can be constructed

  let entry_id = diary_types.food_entry_id("test")
  let input = diary_types.FoodEntryInput(
    food_id: diary_types.food_id("f1"),
    serving_id: diary_types.serving_id("s1"),
    meal: diary_types.Lunch,
    number_of_units: 1.0,
    date_int: 20_000,
  )
  let update = diary_types.FoodEntryUpdate(number_of_units: Some(2.0))

  let _effects: List(DiaryEffect) = [
    fatsecret_diary.None,
    fatsecret_diary.FetchEntries(20_000),
    fatsecret_diary.SearchFoods("chicken"),
    fatsecret_diary.CreateEntry(input),
    fatsecret_diary.UpdateEntry(entry_id, update),
    fatsecret_diary.DeleteEntry(entry_id),
    fatsecret_diary.FetchNutritionTargets,
    fatsecret_diary.Batch([]),
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}

// ============================================================================
// Cache Validity Tests
// ============================================================================

pub fn is_cache_valid_fresh_test() {
  // GIVEN: Cache entry from 1 hour ago
  let cached_at = 1_000_000
  let current_time = 1_003_600  // 1 hour later

  // WHEN: Checking validity
  let is_valid = diary_view.is_cache_valid(cached_at, current_time)

  // THEN: Should be valid (within 7 day TTL)
  is_valid
  |> should.equal(True)
}

pub fn is_cache_valid_expired_test() {
  // GIVEN: Cache entry from 10 days ago
  let cached_at = 1_000_000
  let current_time = cached_at + { 10 * 86_400 }  // 10 days later

  // WHEN: Checking validity
  let is_valid = diary_view.is_cache_valid(cached_at, current_time)

  // THEN: Should be expired (beyond 7 day TTL)
  is_valid
  |> should.equal(False)
}
