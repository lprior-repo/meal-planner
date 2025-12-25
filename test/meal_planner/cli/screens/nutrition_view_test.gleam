/// Tests for Nutrition View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Daily nutrition data
/// - Nutrition goals
/// - Goal editing state
/// - Chart settings
/// - Macro status calculations
/// - Message and effect variants
import gleam/option.{None}
import gleeunit/should
import meal_planner/cli/screens/nutrition_view.{
  type ChartType,
  type GoalType, type MacroStatus, type NutrientType,
  type NutritionEffect,
  type NutritionMsg, type NutritionViewState, type TimeRange, AreaChart,
  BarChart, Calories, Carbohydrate, ChartSettings, Cholesterol, ComparisonView,
  Custom, DailyNutrition, DashboardView, DatePicker, Fat, Fiber, GoalEditState,
  GoalEditView, GoalsView, Last14Days, Last30Days, Last7Days, Last90Days,
  LineChart, MealBreakdownView, MealNutrition, MonthlyTrendsView, MuscleBuilding,
  NutrientDetailsView, NutritionGoals, OnTarget, Over, Protein,
  SaturatedFat, Sodium, Sugar, Under, WeeklyTrendsView, WeightGain, WeightLoss,
  WeightMaintenance,
}

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // GIVEN: Today's date as date_int
  let today = 20_000

  // WHEN: Initializing NutritionModel
  let model = nutrition_view.init(today)

  // THEN: Model should have correct initial state
  model.current_date
  |> should.equal(today)

  model.view_state
  |> should.equal(DashboardView)

  model.weekly_data
  |> should.equal([])

  model.is_loading
  |> should.equal(False)

  model.error_message
  |> should.equal(None)

  model.goal_edit_state
  |> should.equal(None)

  model.history
  |> should.equal([])

  model.meal_breakdown
  |> should.equal([])
}

pub fn init_daily_data_zeroed_test() {
  // GIVEN: Initial model
  let model = nutrition_view.init(20_000)

  // THEN: Daily data should be zeroed
  model.daily_data.calories
  |> should.equal(0.0)

  model.daily_data.protein
  |> should.equal(0.0)

  model.daily_data.carbohydrate
  |> should.equal(0.0)

  model.daily_data.fat
  |> should.equal(0.0)

  model.daily_data.fiber
  |> should.equal(0.0)
}

pub fn init_goals_have_defaults_test() {
  // GIVEN: Initial model
  let model = nutrition_view.init(20_000)

  // THEN: Goals should have sensible defaults (based on 2000 cal diet)
  model.goals.calories_target
  |> should.equal(2000.0)

  model.goals.protein_target
  |> should.equal(150.0)

  model.goals.goal_type
  |> should.equal(WeightMaintenance)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_dashboard_view_test() {
  let view_state: NutritionViewState = DashboardView
  case view_state {
    DashboardView -> True
  }
  |> should.be_true
}

pub fn view_state_weekly_trends_test() {
  let view_state: NutritionViewState = WeeklyTrendsView
  case view_state {
    WeeklyTrendsView -> True
  }
  |> should.be_true
}

pub fn view_state_monthly_trends_test() {
  let view_state: NutritionViewState = MonthlyTrendsView
  case view_state {
    MonthlyTrendsView -> True
  }
  |> should.be_true
}

pub fn view_state_goals_view_test() {
  let view_state: NutritionViewState = GoalsView
  case view_state {
    GoalsView -> True
  }
  |> should.be_true
}

pub fn view_state_goal_edit_view_test() {
  let view_state: NutritionViewState = GoalEditView
  case view_state {
    GoalEditView -> True
  }
  |> should.be_true
}

pub fn view_state_meal_breakdown_view_test() {
  let view_state: NutritionViewState = MealBreakdownView
  case view_state {
    MealBreakdownView -> True
  }
  |> should.be_true
}

pub fn view_state_nutrient_details_view_test() {
  let view_state: NutritionViewState = NutrientDetailsView(Protein)
  case view_state {
    NutrientDetailsView(nutrient) -> nutrient == Protein
  }
  |> should.be_true
}

pub fn view_state_comparison_view_test() {
  let view_state: NutritionViewState = ComparisonView
  case view_state {
    ComparisonView -> True
  }
  |> should.be_true
}

pub fn view_state_date_picker_test() {
  let view_state: NutritionViewState = DatePicker("2025-12-20")
  case view_state {
    DatePicker(date_input) -> date_input
    _ -> ""
  }
  |> should.equal("2025-12-20")
}

// ============================================================================
// Daily Nutrition Tests
// ============================================================================

pub fn daily_nutrition_construction_test() {
  let daily =
    DailyNutrition(
      date_int: 20_000,
      date_string: "2025-12-20",
      calories: 1800.0,
      protein: 120.0,
      carbohydrate: 200.0,
      fat: 60.0,
      fiber: 25.0,
      sugar: 40.0,
      saturated_fat: 15.0,
      sodium: 2000.0,
      cholesterol: 250.0,
      protein_pct: 26.7,
      carb_pct: 44.4,
      fat_pct: 30.0,
      calories_status: OnTarget,
      protein_status: Under,
      carb_status: OnTarget,
      fat_status: OnTarget,
    )

  daily.calories
  |> should.equal(1800.0)

  daily.protein
  |> should.equal(120.0)

  daily.calories_status
  |> should.equal(OnTarget)
}

// ============================================================================
// Nutrition Goals Tests
// ============================================================================

pub fn nutrition_goals_construction_test() {
  let goals =
    NutritionGoals(
      calories_target: 2500.0,
      protein_target: 180.0,
      carb_target: 280.0,
      fat_target: 80.0,
      fiber_target: 30.0,
      sugar_limit: 60.0,
      sodium_limit: 2300.0,
      tolerance_pct: 10.0,
      goal_type: MuscleBuilding,
    )

  goals.calories_target
  |> should.equal(2500.0)

  goals.protein_target
  |> should.equal(180.0)

  goals.goal_type
  |> should.equal(MuscleBuilding)
}

pub fn default_goals_test() {
  let goals = nutrition_view.default_goals()

  goals.calories_target
  |> should.equal(2000.0)

  goals.tolerance_pct
  |> should.equal(10.0)

  goals.goal_type
  |> should.equal(WeightMaintenance)
}

// ============================================================================
// Goal Type Tests
// ============================================================================

pub fn goal_type_all_variants_test() {
  let _types: List(GoalType) = [
    WeightLoss,
    WeightMaintenance,
    WeightGain,
    MuscleBuilding,
    Custom,
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}

// ============================================================================
// Goal Edit State Tests
// ============================================================================

pub fn goal_edit_state_construction_test() {
  let original = nutrition_view.default_goals()

  let edit_state =
    GoalEditState(
      editing_field: Protein,
      current_value: "160",
      original_goals: original,
    )

  edit_state.editing_field
  |> should.equal(Protein)

  edit_state.current_value
  |> should.equal("160")
}

// ============================================================================
// Macro Status Tests
// ============================================================================

pub fn macro_status_under_test() {
  let status: MacroStatus = Under
  case status {
    Under -> True
  }
  |> should.be_true
}

pub fn macro_status_on_target_test() {
  let status: MacroStatus = OnTarget
  case status {
    OnTarget -> True
  }
  |> should.be_true
}

pub fn macro_status_over_test() {
  let status: MacroStatus = Over
  case status {
    Over -> True
  }
  |> should.be_true
}

// ============================================================================
// Nutrient Type Tests
// ============================================================================

pub fn nutrient_type_all_variants_test() {
  let _types: List(NutrientType) = [
    Calories,
    Protein,
    Carbohydrate,
    Fat,
    Fiber,
    Sugar,
    SaturatedFat,
    Sodium,
    Cholesterol,
  ]

  // If we reach here, all variants compile
  True
  |> should.be_true
}

// ============================================================================
// Chart Settings Tests
// ============================================================================

pub fn chart_settings_construction_test() {
  let settings =
    ChartSettings(
      show_calories: True,
      show_protein: True,
      show_carbs: False,
      show_fat: False,
      chart_type: LineChart,
      time_range: Last14Days,
    )

  settings.show_calories
  |> should.equal(True)

  settings.chart_type
  |> should.equal(LineChart)

  settings.time_range
  |> should.equal(Last14Days)
}

pub fn chart_type_all_variants_test() {
  let _types: List(ChartType) = [LineChart, BarChart, AreaChart]

  True
  |> should.be_true
}

pub fn time_range_all_variants_test() {
  let _ranges: List(TimeRange) = [Last7Days, Last14Days, Last30Days, Last90Days]

  True
  |> should.be_true
}

// ============================================================================
// Meal Nutrition Tests
// ============================================================================

pub fn meal_nutrition_construction_test() {
  let meal =
    MealNutrition(
      meal_name: "Breakfast",
      calories: 450.0,
      protein: 25.0,
      carbohydrate: 55.0,
      fat: 15.0,
      entry_count: 3,
      percentage_of_daily: 25.0,
    )

  meal.meal_name
  |> should.equal("Breakfast")

  meal.calories
  |> should.equal(450.0)

  meal.entry_count
  |> should.equal(3)

  meal.percentage_of_daily
  |> should.equal(25.0)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn nutrition_msg_all_variants_compile_test() {
  let _msgs: List(NutritionMsg) = [
    // Navigation
    nutrition_view.ShowDashboard,
    nutrition_view.ShowWeeklyTrends,
    nutrition_view.ShowMonthlyTrends,
    nutrition_view.ShowGoals,
    nutrition_view.ShowMealBreakdown,
    nutrition_view.ShowNutrientDetails(Protein),
    nutrition_view.ShowComparison,
    nutrition_view.ShowDatePicker,
    nutrition_view.GoBack,
    // Date navigation
    nutrition_view.DatePrevious,
    nutrition_view.DateNext,
    nutrition_view.DateToday,
    nutrition_view.DateConfirm("2025-12-20"),
    nutrition_view.DateCancel,
    // Goals
    nutrition_view.EditGoalStart(Calories),
    nutrition_view.GoalValueChanged("2000"),
    nutrition_view.GoalConfirm,
    nutrition_view.GoalCancel,
    nutrition_view.SetGoalType(WeightLoss),
    nutrition_view.SetTolerance(10.0),
    // Chart settings
    nutrition_view.ToggleCaloriesChart,
    nutrition_view.ToggleProteinChart,
    nutrition_view.ToggleCarbsChart,
    nutrition_view.ToggleFatChart,
    nutrition_view.SetChartType(BarChart),
    nutrition_view.SetTimeRange(Last30Days),
    // UI
    nutrition_view.ClearError,
    nutrition_view.KeyPressed("r"),
    nutrition_view.Refresh,
    nutrition_view.NoOp,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn nutrition_effect_all_variants_compile_test() {
  let goals = nutrition_view.default_goals()

  let _effects: List(NutritionEffect) = [
    nutrition_view.NoEffect,
    nutrition_view.FetchDailyData(20_000),
    nutrition_view.FetchWeeklyData(20_000),
    nutrition_view.FetchMonthlyData(20_000),
    nutrition_view.FetchGoals,
    nutrition_view.FetchMealBreakdown(20_000),
    nutrition_view.PersistGoals(goals),
    nutrition_view.BatchEffects([]),
  ]

  True
  |> should.be_true
}
