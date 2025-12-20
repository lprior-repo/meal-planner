/// Tests for FatSecret Diary TUI Types
///
/// ARCHITECT PHASE - Type System Verification
///
/// This test suite validates:
/// 1. All types compile and construct correctly
/// 2. ViewState prevents impossible states
/// 3. Gleam 7 commandments are applied
/// 4. Opaque types enforce type safety
/// 5. Exhaustive pattern matching works
import gleam/dict
import gleam/option
import gleeunit/should
import meal_planner/cli/screens/fatsecret_diary as diary
import meal_planner/fatsecret/diary/types as diary_types

// ============================================================================
// Test: Model Construction & Initialization
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: Today's date as date_int
  let today = 20_000

  // WHEN: Initializing DiaryModel
  let model = diary.init(today)

  // THEN: Model should have correct initial state
  model.current_date
  |> should.equal(today)

  model.entries_by_meal
  |> should.equal([])

  model.nutrition_targets
  |> should.equal(option.None)

  model.error_message
  |> should.equal(option.None)

  // AND: ViewState should be MainView
  model.view_state
  |> should.equal(diary.MainView)

  // AND: SearchState should be empty
  model.search_state.query
  |> should.equal("")

  model.search_state.results
  |> should.equal([])

  model.search_state.selected_index
  |> should.equal(0)

  model.search_state.is_loading
  |> should.equal(False)

  // AND: EditState should be None
  model.edit_state
  |> should.equal(option.None)

  // AND: FoodCache should be empty
  model.food_cache
  |> dict.size
  |> should.equal(0)
}

// ============================================================================
// Test: ViewState Type Safety - Impossible States Prevention
// ============================================================================

pub fn view_state_main_view_test() {
  // GIVEN: MainView state
  let view_state = diary.MainView

  // THEN: Can pattern match without errors
  case view_state {
    diary.MainView -> True
  }
  |> should.be_true
}

pub fn view_state_search_popup_test() {
  // GIVEN: SearchPopup state
  let view_state = diary.SearchPopup

  // THEN: Can pattern match correctly
  case view_state {
    diary.SearchPopup -> True
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  // GIVEN: DatePicker state with input
  let view_state = diary.DatePicker("2025-12-20")

  // THEN: Can pattern match and extract date_input
  case view_state {
    diary.DatePicker(date_input) -> date_input
  }
  |> should.equal("2025-12-20")
}

pub fn view_state_confirm_delete_test() {
  // GIVEN: ConfirmDelete state with entry ID
  let entry_id = diary_types.food_entry_id("12345")
  let view_state = diary.ConfirmDelete(entry_id)

  // THEN: Can pattern match and extract entry_id
  case view_state {
    diary.ConfirmDelete(id) -> diary_types.food_entry_id_to_string(id)
  }
  |> should.equal("12345")
}

// ============================================================================
// Test: MacroComparison Status Logic
// ============================================================================

pub fn calculate_macro_status_under_test() {
  // GIVEN: Current is less than 90% of target
  let current = 80.0
  let target = 100.0

  // WHEN: Calculating status
  let status = diary.calculate_macro_status(current, target)

  // THEN: Status should be Under
  status
  |> should.equal(diary.Under)
}

pub fn calculate_macro_status_met_test() {
  // GIVEN: Current is within 90%-110% of target
  let current = 95.0
  let target = 100.0

  // WHEN: Calculating status
  let status = diary.calculate_macro_status(current, target)

  // THEN: Status should be Met
  status
  |> should.equal(diary.Met)
}

pub fn calculate_macro_status_over_test() {
  // GIVEN: Current is greater than 110% of target
  let current = 120.0
  let target = 100.0

  // WHEN: Calculating status
  let status = diary.calculate_macro_status(current, target)

  // THEN: Status should be Over
  status
  |> should.equal(diary.Over)
}

pub fn build_macro_comparison_test() {
  // GIVEN: Current 150 cal, target 200 cal
  let current = 150.0
  let target = 200.0

  // WHEN: Building comparison
  let comparison = diary.build_macro_comparison(current, target)

  // THEN: Comparison should have correct values
  comparison.current
  |> should.equal(150.0)

  comparison.target
  |> should.equal(200.0)

  comparison.percentage
  |> should.equal(75.0)

  comparison.status
  |> should.equal(diary.Under)
}

pub fn build_macro_comparison_zero_target_test() {
  // GIVEN: Zero target (edge case)
  let current = 50.0
  let target = 0.0

  // WHEN: Building comparison
  let comparison = diary.build_macro_comparison(current, target)

  // THEN: Percentage should be 0 (avoid division by zero)
  comparison.percentage
  |> should.equal(0.0)
}

// ============================================================================
// Test: SearchState Construction
// ============================================================================

pub fn search_state_initial_test() {
  // GIVEN: Initial model
  let model = diary.init(20_000)

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
  |> should.equal(option.None)
}

// ============================================================================
// Test: MealSection Construction
// ============================================================================

pub fn meal_section_construction_test() {
  // GIVEN: MealSection data
  let section =
    diary.MealSection(
      meal_type: diary_types.Breakfast,
      entries: [],
      section_totals: diary.MealTotals(
        calories: 500.0,
        carbohydrate: 60.0,
        protein: 30.0,
        fat: 15.0,
      ),
    )

  // THEN: Section should construct correctly
  section.meal_type
  |> should.equal(diary_types.Breakfast)

  section.entries
  |> should.equal([])

  section.section_totals.calories
  |> should.equal(500.0)
}

// ============================================================================
// Test: NutritionTarget Construction
// ============================================================================

pub fn nutrition_target_construction_test() {
  // GIVEN: Nutrition targets
  let target =
    diary.NutritionTarget(
      calories: 2000.0,
      carbohydrate: 250.0,
      protein: 150.0,
      fat: 67.0,
    )

  // THEN: Target should construct correctly
  target.calories
  |> should.equal(2000.0)

  target.carbohydrate
  |> should.equal(250.0)

  target.protein
  |> should.equal(150.0)

  target.fat
  |> should.equal(67.0)
}

// ============================================================================
// Test: Daily Totals Calculation
// ============================================================================

pub fn calculate_daily_totals_empty_test() {
  // GIVEN: Empty meal sections
  let sections = []

  // WHEN: Calculating daily totals
  let #(calories, carbs, protein, fat) = diary.calculate_daily_totals(sections)

  // THEN: All totals should be 0
  calories
  |> should.equal(0.0)

  carbs
  |> should.equal(0.0)

  protein
  |> should.equal(0.0)

  fat
  |> should.equal(0.0)
}

pub fn calculate_daily_totals_multiple_meals_test() {
  // GIVEN: Multiple meal sections with different totals
  let sections = [
    diary.MealSection(
      meal_type: diary_types.Breakfast,
      entries: [],
      section_totals: diary.MealTotals(
        calories: 400.0,
        carbohydrate: 50.0,
        protein: 20.0,
        fat: 15.0,
      ),
    ),
    diary.MealSection(
      meal_type: diary_types.Lunch,
      entries: [],
      section_totals: diary.MealTotals(
        calories: 600.0,
        carbohydrate: 70.0,
        protein: 40.0,
        fat: 20.0,
      ),
    ),
    diary.MealSection(
      meal_type: diary_types.Dinner,
      entries: [],
      section_totals: diary.MealTotals(
        calories: 800.0,
        carbohydrate: 90.0,
        protein: 50.0,
        fat: 30.0,
      ),
    ),
  ]

  // WHEN: Calculating daily totals
  let #(calories, carbs, protein, fat) = diary.calculate_daily_totals(sections)

  // THEN: Totals should be sum of all meals
  calories
  |> should.equal(1800.0)

  carbs
  |> should.equal(210.0)

  protein
  |> should.equal(110.0)

  fat
  |> should.equal(65.0)
}

// ============================================================================
// Test: Exhaustive Pattern Matching - DiaryMsg
// ============================================================================

pub fn diary_msg_all_variants_compile_test() {
  // This test verifies all DiaryMsg variants can be constructed
  // Compilation success = type system is complete

  let _msgs = [
    // Date navigation
    diary.DateNavigatePrevious,
    diary.DateNavigateNext,
    diary.DateJumpToToday,
    diary.DateShowPicker,
    diary.DateConfirmPicker("2025-12-20"),
    diary.DateCancelPicker,
    // Add entry
    diary.AddEntryStart,
    diary.SearchQueryChanged("chicken"),
    diary.SearchFoodStarted,
    diary.CancelAddEntry,
    // Edit entry
    diary.EditEntryServingsChanged(2.5),
    diary.EditEntryConfirm,
    diary.EditEntryCancel,
    // Delete entry
    diary.DeleteEntryConfirm,
    diary.DeleteEntryCancel,
    // Copy meal
    diary.CopyMealStart,
    diary.CopyMealSelectSource(diary_types.Breakfast),
    diary.CopyMealSelectDate(20_000),
    diary.CopyMealSelectDestMeal(diary_types.Lunch),
    diary.CopyMealConfirm,
    diary.CopyMealCancel,
    // UI
    diary.ClearError,
    diary.KeyPressed("a"),
    diary.NoOp,
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}
