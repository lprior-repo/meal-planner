/// Tests for Weight View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Weight display entries
/// - Weight goals
/// - Weight entry input
/// - Edit state management
/// - Weight statistics
/// - User profile
/// - Chart data
/// - Message and effect variants
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/weight_view.{
  type ChartPoint, type Gender, type UserProfile, type WeightDisplayEntry,
  type WeightEditState, type WeightEffect, type WeightEntryInput,
  type WeightGoalType, type WeightGoals, type WeightStatistics,
  type WeightViewState, AddEntryView, ChartPoint, ChartView, ConfirmDeleteView,
  DatePicker, EditEntryView, Female, GainWeight, GoalsView, ListView, LoseWeight,
  MaintainWeight, Male, Other, ProfileView, StatsView, UserProfile,
  WeightDisplayEntry, WeightEditState, WeightEntryInput, WeightGoals,
  WeightStatistics,
}
import meal_planner/fatsecret/weight/types as weight_types

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a minimal WeightEntry for testing
fn test_weight_entry(weight: Float) -> weight_types.WeightEntry {
  weight_types.WeightEntry(
    date_int: 20_000,
    weight_kg: weight,
    weight_comment: None,
  )
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  let today = 20_000
  let model = weight_view.init(today)
  model.current_date
  |> should.equal(today)
  model.view_state
  |> should.equal(ListView)
  model.entries
  |> should.equal([])
  model.current_weight
  |> should.equal(None)
  model.edit_state
  |> should.equal(None)
  model.is_loading
  |> should.equal(False)
  model.error_message
  |> should.equal(None)
  model.chart_data
  |> should.equal([])
}

pub fn init_entry_input_empty_test() {
  let model = weight_view.init(20_000)
  model.entry_input.weight_str
  |> should.equal("")
  model.entry_input.date_int
  |> should.equal(20_000)
  model.entry_input.comment
  |> should.equal("")
  model.entry_input.parsed_weight
  |> should.equal(None)
}

pub fn init_statistics_zeroed_test() {
  let model = weight_view.init(20_000)
  model.statistics.total_change
  |> should.equal(0.0)
  model.statistics.average_weight
  |> should.equal(0.0)
  model.statistics.current_bmi
  |> should.equal(None)
}

pub fn init_profile_empty_test() {
  let model = weight_view.init(20_000)
  model.user_profile.height_cm
  |> should.equal(None)
  model.user_profile.birth_date
  |> should.equal(None)
  model.user_profile.gender
  |> should.equal(None)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_list_view_test() {
  let view_state: WeightViewState = ListView
  case view_state {
    ListView -> True
  }
  |> should.be_true
}

pub fn view_state_add_entry_view_test() {
  let view_state: WeightViewState = AddEntryView
  case view_state {
    AddEntryView -> True
  }
  |> should.be_true
}

pub fn view_state_edit_entry_view_test() {
  let view_state: WeightViewState = EditEntryView
  case view_state {
    EditEntryView -> True
  }
  |> should.be_true
}

pub fn view_state_confirm_delete_view_test() {
  let entry_id = weight_types.weight_entry_id("entry_123")
  let view_state: WeightViewState = ConfirmDeleteView(entry_id)
  case view_state {
    ConfirmDeleteView(id) ->
      weight_types.weight_entry_id_to_string(id) == "entry_123"
  }
  |> should.be_true
}

pub fn view_state_goals_view_test() {
  let view_state: WeightViewState = GoalsView
  case view_state {
    GoalsView -> True
  }
  |> should.be_true
}

pub fn view_state_stats_view_test() {
  let view_state: WeightViewState = StatsView
  case view_state {
    StatsView -> True
  }
  |> should.be_true
}

pub fn view_state_chart_view_test() {
  let view_state: WeightViewState = ChartView
  case view_state {
    ChartView -> True
  }
  |> should.be_true
}

pub fn view_state_profile_view_test() {
  let view_state: WeightViewState = ProfileView
  case view_state {
    ProfileView -> True
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  let view_state: WeightViewState = DatePicker("2025-12-20")
  case view_state {
    DatePicker(date) -> date == "2025-12-20"
  }
  |> should.be_true
}

// ============================================================================
// Weight Display Entry Tests
// ============================================================================

pub fn weight_display_entry_construction_test() {
  let entry = test_weight_entry(75.5)
  let display =
    WeightDisplayEntry(
      entry: entry,
      weight_display: "75.5 kg",
      date_display: "Dec 20, 2025",
      change_display: "-0.3 kg",
      bmi_display: Some("24.2"),
      days_since_previous: Some(1),
    )
  display.weight_display
  |> should.equal("75.5 kg")
  display.date_display
  |> should.equal("Dec 20, 2025")
  display.change_display
  |> should.equal("-0.3 kg")
  display.bmi_display
  |> should.equal(Some("24.2"))
}

// ============================================================================
// Weight Goals Tests
// ============================================================================

pub fn weight_goals_construction_test() {
  let goals =
    WeightGoals(
      target_weight: 70.0,
      starting_weight: 80.0,
      goal_start_date: 19_900,
      target_date: Some(20_200),
      weekly_target: -0.5,
      goal_type: LoseWeight,
    )
  goals.target_weight
  |> should.equal(70.0)
  goals.starting_weight
  |> should.equal(80.0)
  goals.weekly_target
  |> should.equal(-0.5)
  goals.goal_type
  |> should.equal(LoseWeight)
}

pub fn weight_goal_type_all_variants_test() {
  let _types: List(WeightGoalType) = [LoseWeight, MaintainWeight, GainWeight]
  True
  |> should.be_true
}

// ============================================================================
// Weight Entry Input Tests
// ============================================================================

pub fn weight_entry_input_construction_test() {
  let input =
    WeightEntryInput(
      weight_str: "75.5",
      date_int: 20_000,
      comment: "After breakfast",
      parsed_weight: Some(75.5),
    )
  input.weight_str
  |> should.equal("75.5")
  input.date_int
  |> should.equal(20_000)
  input.comment
  |> should.equal("After breakfast")
  input.parsed_weight
  |> should.equal(Some(75.5))
}

// ============================================================================
// Weight Edit State Tests
// ============================================================================

pub fn weight_edit_state_construction_test() {
  let entry = test_weight_entry(76.0)
  let edit_state =
    WeightEditState(
      entry: entry,
      new_weight_str: "75.8",
      new_comment: "Corrected",
      original_weight: 76.0,
    )
  edit_state.new_weight_str
  |> should.equal("75.8")
  edit_state.new_comment
  |> should.equal("Corrected")
  edit_state.original_weight
  |> should.equal(76.0)
}

// ============================================================================
// Weight Statistics Tests
// ============================================================================

pub fn weight_statistics_construction_test() {
  let stats =
    WeightStatistics(
      total_change: -5.0,
      average_weight: 77.5,
      min_weight: 75.0,
      max_weight: 82.0,
      week_change: -0.8,
      month_change: -2.5,
      current_bmi: Some(24.5),
      bmi_category: Some("Normal"),
      goal_progress: 50.0,
      days_to_goal: Some(100),
    )
  stats.total_change
  |> should.equal(-5.0)
  stats.average_weight
  |> should.equal(77.5)
  stats.min_weight
  |> should.equal(75.0)
  stats.max_weight
  |> should.equal(82.0)
  stats.current_bmi
  |> should.equal(Some(24.5))
  stats.bmi_category
  |> should.equal(Some("Normal"))
  stats.goal_progress
  |> should.equal(50.0)
}

// ============================================================================
// User Profile Tests
// ============================================================================

pub fn user_profile_construction_test() {
  let profile =
    UserProfile(
      height_cm: Some(175.0),
      birth_date: Some(8000),
      gender: Some(Male),
    )
  profile.height_cm
  |> should.equal(Some(175.0))
  profile.birth_date
  |> should.equal(Some(8000))
  profile.gender
  |> should.equal(Some(Male))
}

pub fn gender_all_variants_test() {
  let _genders: List(Gender) = [Male, Female, Other]
  True
  |> should.be_true
}

// ============================================================================
// Chart Point Tests
// ============================================================================

pub fn chart_point_construction_test() {
  let point = ChartPoint(date_int: 20_000, weight: 75.5, label: "Dec 20")
  point.date_int
  |> should.equal(20_000)
  point.weight
  |> should.equal(75.5)
  point.label
  |> should.equal("Dec 20")
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn weight_msg_navigation_variants_compile_test() {
  let entry = test_weight_entry(75.0)
  let entry_id = weight_types.weight_entry_id("e1")
  let _msgs = [
    weight_view.ShowListView,
    weight_view.ShowAddEntry,
    weight_view.ShowEditEntry(entry),
    weight_view.ShowDeleteConfirm(entry_id),
    weight_view.ShowGoals,
    weight_view.ShowStats,
    weight_view.ShowChart,
    weight_view.ShowProfile,
    weight_view.ShowDatePicker,
    weight_view.GoBack,
  ]
  True
  |> should.be_true
}

pub fn weight_msg_entry_input_variants_compile_test() {
  let _msgs = [
    weight_view.WeightInputChanged("75.5"),
    weight_view.CommentInputChanged("Morning"),
    weight_view.DateInputChanged("2025-12-20"),
    weight_view.ConfirmAddEntry,
    weight_view.CancelAddEntry,
  ]
  True
  |> should.be_true
}

pub fn weight_msg_edit_variants_compile_test() {
  let _msgs = [
    weight_view.EditWeightChanged("76.0"),
    weight_view.EditCommentChanged("Updated"),
    weight_view.ConfirmEditEntry,
    weight_view.CancelEditEntry,
  ]
  True
  |> should.be_true
}

pub fn weight_msg_delete_variants_compile_test() {
  let _msgs = [weight_view.ConfirmDelete, weight_view.CancelDelete]
  True
  |> should.be_true
}

pub fn weight_msg_goals_variants_compile_test() {
  let _msgs = [
    weight_view.SetTargetWeight(70.0),
    weight_view.SetWeeklyTarget(-0.5),
    weight_view.SetGoalType(LoseWeight),
    weight_view.SaveGoals,
  ]
  True
  |> should.be_true
}

pub fn weight_msg_profile_variants_compile_test() {
  let _msgs = [
    weight_view.SetHeight(175.0),
    weight_view.SetGender(Female),
    weight_view.SaveProfile,
  ]
  True
  |> should.be_true
}

pub fn weight_msg_ui_variants_compile_test() {
  let _msgs = [
    weight_view.DatePrevious,
    weight_view.DateNext,
    weight_view.DateToday,
    weight_view.DateConfirm("2025-12-20"),
    weight_view.DateCancel,
    weight_view.ClearError,
    weight_view.KeyPressed("a"),
    weight_view.Refresh,
    weight_view.NoOp,
  ]
  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn weight_effect_all_variants_compile_test() {
  let entry_id = weight_types.weight_entry_id("test")
  let goals =
    WeightGoals(
      target_weight: 70.0,
      starting_weight: 75.0,
      goal_start_date: 20_000,
      target_date: None,
      weekly_target: -0.5,
      goal_type: LoseWeight,
    )
  let profile =
    UserProfile(height_cm: Some(175.0), birth_date: None, gender: Some(Male))
  let _effects: List(WeightEffect) = [
    weight_view.NoEffect,
    weight_view.FetchEntries(50),
    weight_view.FetchGoals,
    weight_view.CreateEntry(75.5, 20_000, "Morning"),
    weight_view.UpdateEntry(entry_id, 75.8, "Updated"),
    weight_view.DeleteEntry(entry_id),
    weight_view.SaveGoalsEffect(goals),
    weight_view.SaveProfileEffect(profile),
    weight_view.BatchEffects([]),
  ]
  True
  |> should.be_true
}
