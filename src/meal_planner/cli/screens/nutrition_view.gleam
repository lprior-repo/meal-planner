/// Nutrition Analysis View Screen - Complete TUI Implementation
///
/// This module implements the nutrition tracking and analysis screen
/// following Shore Framework (Elm Architecture).
///
/// SCREEN FEATURES:
/// - View daily nutrition summary
/// - Track macro goals (protein, carbs, fat, calories)
/// - View weekly/monthly trends
/// - Analyze meal composition
/// - Set and manage nutrition goals
/// - View nutrient breakdown charts
/// - Compare actual vs target intake
///
/// ARCHITECTURE:
/// - Model: NutritionModel (state container)
/// - Msg: NutritionMsg (all possible events)
/// - Update: nutrition_update (state transitions)
/// - View: nutrition_view (rendering)
import birl
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Root state for the Nutrition TUI screen
pub type NutritionModel {
  NutritionModel(
    /// Current view state
    view_state: NutritionViewState,
    /// Current date for daily view
    current_date: Int,
    /// Daily nutrition data
    daily_data: DailyNutrition,
    /// Weekly data for trends
    weekly_data: List(DailyNutrition),
    /// Nutrition goals
    goals: NutritionGoals,
    /// Goal editing state
    goal_edit_state: Option(GoalEditState),
    /// Loading state
    is_loading: Bool,
    /// Error message
    error_message: Option(String),
    /// Chart settings
    chart_settings: ChartSettings,
    /// History of daily summaries for analysis
    history: List(DailyNutrition),
    /// Meal breakdown for current day
    meal_breakdown: List(MealNutrition),
  )
}

/// View state machine
pub type NutritionViewState {
  /// Main dashboard with daily summary
  DashboardView
  /// Weekly trends view
  WeeklyTrendsView
  /// Monthly trends view
  MonthlyTrendsView
  /// Goal settings view
  GoalsView
  /// Goal edit popup
  GoalEditView
  /// Meal breakdown view
  MealBreakdownView
  /// Nutrient details view
  NutrientDetailsView(nutrient: NutrientType)
  /// Comparison view (actual vs target)
  ComparisonView
  /// Date picker
  DatePicker(date_input: String)
}

/// Daily nutrition data
pub type DailyNutrition {
  DailyNutrition(
    date_int: Int,
    date_string: String,
    /// Core macros
    calories: Float,
    protein: Float,
    carbohydrate: Float,
    fat: Float,
    /// Extended nutrients
    fiber: Float,
    sugar: Float,
    saturated_fat: Float,
    sodium: Float,
    cholesterol: Float,
    /// Calculated values
    protein_pct: Float,
    carb_pct: Float,
    fat_pct: Float,
    /// Goal compliance
    calories_status: MacroStatus,
    protein_status: MacroStatus,
    carb_status: MacroStatus,
    fat_status: MacroStatus,
  )
}

/// Nutrition goals
pub type NutritionGoals {
  NutritionGoals(
    /// Daily targets
    calories_target: Float,
    protein_target: Float,
    carb_target: Float,
    fat_target: Float,
    fiber_target: Float,
    sugar_limit: Float,
    sodium_limit: Float,
    /// Tolerance for "on target" status (percentage)
    tolerance_pct: Float,
    /// Goal type
    goal_type: GoalType,
  )
}

/// Type of nutrition goal
pub type GoalType {
  WeightLoss
  WeightMaintenance
  WeightGain
  MuscleBuilding
  Custom
}

/// Goal editing state
pub type GoalEditState {
  GoalEditState(
    editing_field: NutrientType,
    current_value: String,
    original_goals: NutritionGoals,
  )
}

/// Macro status relative to target
pub type MacroStatus {
  Under
  OnTarget
  Over
}

/// Type of nutrient
pub type NutrientType {
  Calories
  Protein
  Carbohydrate
  Fat
  Fiber
  Sugar
  SaturatedFat
  Sodium
  Cholesterol
}

/// Chart settings
pub type ChartSettings {
  ChartSettings(
    show_calories: Bool,
    show_protein: Bool,
    show_carbs: Bool,
    show_fat: Bool,
    chart_type: ChartType,
    time_range: TimeRange,
  )
}

/// Chart display type
pub type ChartType {
  LineChart
  BarChart
  AreaChart
}

/// Time range for charts
pub type TimeRange {
  Last7Days
  Last14Days
  Last30Days
  Last90Days
}

/// Nutrition breakdown by meal
pub type MealNutrition {
  MealNutrition(
    meal_name: String,
    calories: Float,
    protein: Float,
    carbohydrate: Float,
    fat: Float,
    entry_count: Int,
    percentage_of_daily: Float,
  )
}

/// Messages for the nutrition screen
pub type NutritionMsg {
  // Navigation
  ShowDashboard
  ShowWeeklyTrends
  ShowMonthlyTrends
  ShowGoals
  ShowMealBreakdown
  ShowNutrientDetails(nutrient: NutrientType)
  ShowComparison
  ShowDatePicker
  GoBack

  // Date Navigation
  DatePrevious
  DateNext
  DateToday
  DateConfirm(date_input: String)
  DateCancel

  // Goals
  EditGoalStart(field: NutrientType)
  GoalValueChanged(value: String)
  GoalConfirm
  GoalCancel
  SetGoalType(goal_type: GoalType)
  SetTolerance(pct: Float)

  // Chart Settings
  ToggleCaloriesChart
  ToggleProteinChart
  ToggleCarbsChart
  ToggleFatChart
  SetChartType(chart_type: ChartType)
  SetTimeRange(range: TimeRange)

  // Data Loading
  GotDailyData(Result(DailyNutrition, String))
  GotWeeklyData(Result(List(DailyNutrition), String))
  GotGoals(Result(NutritionGoals, String))
  GotMealBreakdown(Result(List(MealNutrition), String))
  SaveGoals(goals: NutritionGoals)
  GoalsSaved(Result(Nil, String))

  // UI
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

/// Effects for the nutrition screen
pub type NutritionEffect {
  NoEffect
  FetchDailyData(date_int: Int)
  FetchWeeklyData(end_date_int: Int)
  FetchMonthlyData(end_date_int: Int)
  FetchGoals
  FetchMealBreakdown(date_int: Int)
  PersistGoals(goals: NutritionGoals)
  BatchEffects(effects: List(NutritionEffect))
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial NutritionModel
pub fn init(today_date_int: Int) -> NutritionModel {
  NutritionModel(
    view_state: DashboardView,
    current_date: today_date_int,
    daily_data: empty_daily_nutrition(today_date_int),
    weekly_data: [],
    goals: default_goals(),
    goal_edit_state: None,
    is_loading: False,
    error_message: None,
    chart_settings: default_chart_settings(),
    history: [],
    meal_breakdown: [],
  )
}

/// Create empty daily nutrition
fn empty_daily_nutrition(date_int: Int) -> DailyNutrition {
  DailyNutrition(
    date_int: date_int,
    date_string: date_int_to_string(date_int),
    calories: 0.0,
    protein: 0.0,
    carbohydrate: 0.0,
    fat: 0.0,
    fiber: 0.0,
    sugar: 0.0,
    saturated_fat: 0.0,
    sodium: 0.0,
    cholesterol: 0.0,
    protein_pct: 0.0,
    carb_pct: 0.0,
    fat_pct: 0.0,
    calories_status: Under,
    protein_status: Under,
    carb_status: Under,
    fat_status: Under,
  )
}

/// Default nutrition goals (based on 2000 cal diet)
pub fn default_goals() -> NutritionGoals {
  NutritionGoals(
    calories_target: 2000.0,
    protein_target: 150.0,
    carb_target: 225.0,
    fat_target: 65.0,
    fiber_target: 25.0,
    sugar_limit: 50.0,
    sodium_limit: 2300.0,
    tolerance_pct: 10.0,
    goal_type: WeightMaintenance,
  )
}

/// Default chart settings
fn default_chart_settings() -> ChartSettings {
  ChartSettings(
    show_calories: True,
    show_protein: True,
    show_carbs: True,
    show_fat: True,
    chart_type: BarChart,
    time_range: Last7Days,
  )
}

// ============================================================================
// Update Function
// ============================================================================

/// Main update function for nutrition view
pub fn nutrition_update(
  model: NutritionModel,
  msg: NutritionMsg,
) -> #(NutritionModel, NutritionEffect) {
  case msg {
    // === Navigation ===
    ShowDashboard -> {
      let updated = NutritionModel(..model, view_state: DashboardView)
      #(updated, FetchDailyData(model.current_date))
    }

    ShowWeeklyTrends -> {
      let updated =
        NutritionModel(..model, view_state: WeeklyTrendsView, is_loading: True)
      #(updated, FetchWeeklyData(model.current_date))
    }

    ShowMonthlyTrends -> {
      let updated =
        NutritionModel(..model, view_state: MonthlyTrendsView, is_loading: True)
      #(updated, FetchMonthlyData(model.current_date))
    }

    ShowGoals -> {
      let updated = NutritionModel(..model, view_state: GoalsView)
      #(updated, FetchGoals)
    }

    ShowMealBreakdown -> {
      let updated =
        NutritionModel(..model, view_state: MealBreakdownView, is_loading: True)
      #(updated, FetchMealBreakdown(model.current_date))
    }

    ShowNutrientDetails(nutrient) -> {
      let updated =
        NutritionModel(..model, view_state: NutrientDetailsView(nutrient))
      #(updated, NoEffect)
    }

    ShowComparison -> {
      let updated = NutritionModel(..model, view_state: ComparisonView)
      #(updated, NoEffect)
    }

    ShowDatePicker -> {
      let date_str = date_int_to_string(model.current_date)
      let updated = NutritionModel(..model, view_state: DatePicker(date_str))
      #(updated, NoEffect)
    }

    GoBack -> {
      case model.view_state {
        DashboardView -> #(model, NoEffect)
        GoalEditView -> {
          let updated =
            NutritionModel(
              ..model,
              view_state: GoalsView,
              goal_edit_state: None,
            )
          #(updated, NoEffect)
        }
        NutrientDetailsView(_) -> {
          let updated = NutritionModel(..model, view_state: DashboardView)
          #(updated, NoEffect)
        }
        _ -> {
          let updated = NutritionModel(..model, view_state: DashboardView)
          #(updated, NoEffect)
        }
      }
    }

    // === Date Navigation ===
    DatePrevious -> {
      let new_date = model.current_date - 1
      let updated =
        NutritionModel(..model, current_date: new_date, is_loading: True)
      #(updated, FetchDailyData(new_date))
    }

    DateNext -> {
      let new_date = model.current_date + 1
      let updated =
        NutritionModel(..model, current_date: new_date, is_loading: True)
      #(updated, FetchDailyData(new_date))
    }

    DateToday -> {
      let today = get_today_date_int()
      let updated =
        NutritionModel(..model, current_date: today, is_loading: True)
      #(updated, FetchDailyData(today))
    }

    DateConfirm(date_input) -> {
      case parse_date_string(date_input) {
        Ok(date_int) -> {
          let updated =
            NutritionModel(
              ..model,
              current_date: date_int,
              view_state: DashboardView,
              is_loading: True,
            )
          #(updated, FetchDailyData(date_int))
        }
        Error(err) -> {
          let updated =
            NutritionModel(
              ..model,
              error_message: Some(err),
              view_state: DashboardView,
            )
          #(updated, NoEffect)
        }
      }
    }

    DateCancel -> {
      let updated = NutritionModel(..model, view_state: DashboardView)
      #(updated, NoEffect)
    }

    // === Goals ===
    EditGoalStart(field) -> {
      let current_value = get_goal_value(model.goals, field)
      let edit_state =
        GoalEditState(
          editing_field: field,
          current_value: float_to_string(current_value),
          original_goals: model.goals,
        )
      let updated =
        NutritionModel(
          ..model,
          view_state: GoalEditView,
          goal_edit_state: Some(edit_state),
        )
      #(updated, NoEffect)
    }

    GoalValueChanged(value) -> {
      case model.goal_edit_state {
        Some(edit) -> {
          let new_edit = GoalEditState(..edit, current_value: value)
          let updated = NutritionModel(..model, goal_edit_state: Some(new_edit))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    GoalConfirm -> {
      case model.goal_edit_state {
        Some(edit) -> {
          case float.parse(edit.current_value) {
            Ok(value) -> {
              let new_goals =
                set_goal_value(model.goals, edit.editing_field, value)
              let updated =
                NutritionModel(
                  ..model,
                  goals: new_goals,
                  view_state: GoalsView,
                  goal_edit_state: None,
                )
              #(updated, PersistGoals(new_goals))
            }
            Error(_) -> {
              let updated =
                NutritionModel(..model, error_message: Some("Invalid number"))
              #(updated, NoEffect)
            }
          }
        }
        None -> #(model, NoEffect)
      }
    }

    GoalCancel -> {
      let updated =
        NutritionModel(..model, view_state: GoalsView, goal_edit_state: None)
      #(updated, NoEffect)
    }

    SetGoalType(goal_type) -> {
      let new_goals = NutritionGoals(..model.goals, goal_type: goal_type)
      let updated = NutritionModel(..model, goals: new_goals)
      #(updated, NoEffect)
    }

    SetTolerance(pct) -> {
      let new_goals = NutritionGoals(..model.goals, tolerance_pct: pct)
      let updated = NutritionModel(..model, goals: new_goals)
      #(updated, NoEffect)
    }

    // === Chart Settings ===
    ToggleCaloriesChart -> {
      let settings =
        ChartSettings(
          ..model.chart_settings,
          show_calories: !model.chart_settings.show_calories,
        )
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    ToggleProteinChart -> {
      let settings =
        ChartSettings(
          ..model.chart_settings,
          show_protein: !model.chart_settings.show_protein,
        )
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    ToggleCarbsChart -> {
      let settings =
        ChartSettings(
          ..model.chart_settings,
          show_carbs: !model.chart_settings.show_carbs,
        )
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    ToggleFatChart -> {
      let settings =
        ChartSettings(
          ..model.chart_settings,
          show_fat: !model.chart_settings.show_fat,
        )
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    SetChartType(chart_type) -> {
      let settings =
        ChartSettings(..model.chart_settings, chart_type: chart_type)
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    SetTimeRange(range) -> {
      let settings = ChartSettings(..model.chart_settings, time_range: range)
      let updated = NutritionModel(..model, chart_settings: settings)
      #(updated, NoEffect)
    }

    // === Data Loading ===
    GotDailyData(result) -> {
      case result {
        Ok(data) -> {
          let updated =
            NutritionModel(..model, daily_data: data, is_loading: False)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            NutritionModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    GotWeeklyData(result) -> {
      case result {
        Ok(data) -> {
          let updated =
            NutritionModel(..model, weekly_data: data, is_loading: False)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            NutritionModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    GotGoals(result) -> {
      case result {
        Ok(goals) -> {
          let updated = NutritionModel(..model, goals: goals)
          #(updated, NoEffect)
        }
        Error(_) -> #(model, NoEffect)
      }
    }

    GotMealBreakdown(result) -> {
      case result {
        Ok(breakdown) -> {
          let updated =
            NutritionModel(
              ..model,
              meal_breakdown: breakdown,
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            NutritionModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    SaveGoals(goals) -> {
      let updated = NutritionModel(..model, goals: goals)
      #(updated, PersistGoals(goals))
    }

    GoalsSaved(result) -> {
      case result {
        Ok(_) -> #(model, NoEffect)
        Error(err) -> {
          let updated =
            NutritionModel(
              ..model,
              error_message: Some("Failed to save: " <> err),
            )
          #(updated, NoEffect)
        }
      }
    }

    // === UI ===
    ClearError -> {
      let updated = NutritionModel(..model, error_message: None)
      #(updated, NoEffect)
    }

    KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    Refresh -> {
      let updated = NutritionModel(..model, is_loading: True)
      #(updated, FetchDailyData(model.current_date))
    }

    NoOp -> #(model, NoEffect)
  }
}

/// Handle keyboard input
fn handle_key_press(
  model: NutritionModel,
  key_str: String,
) -> #(NutritionModel, NutritionEffect) {
  case model.view_state {
    DashboardView -> {
      case key_str {
        "[" -> nutrition_update(model, DatePrevious)
        "]" -> nutrition_update(model, DateNext)
        "t" -> nutrition_update(model, DateToday)
        "g" -> nutrition_update(model, ShowDatePicker)
        "w" -> nutrition_update(model, ShowWeeklyTrends)
        "m" -> nutrition_update(model, ShowMonthlyTrends)
        "G" -> nutrition_update(model, ShowGoals)
        "b" -> nutrition_update(model, ShowMealBreakdown)
        "c" -> nutrition_update(model, ShowComparison)
        "r" -> nutrition_update(model, Refresh)
        _ -> #(model, NoEffect)
      }
    }

    GoalsView -> {
      case key_str {
        "\u{001B}" -> nutrition_update(model, GoBack)
        "1" -> nutrition_update(model, EditGoalStart(Calories))
        "2" -> nutrition_update(model, EditGoalStart(Protein))
        "3" -> nutrition_update(model, EditGoalStart(Carbohydrate))
        "4" -> nutrition_update(model, EditGoalStart(Fat))
        _ -> #(model, NoEffect)
      }
    }

    GoalEditView -> {
      case key_str {
        "\u{001B}" -> nutrition_update(model, GoalCancel)
        "\r" -> nutrition_update(model, GoalConfirm)
        _ -> #(model, NoEffect)
      }
    }

    DatePicker(_) -> {
      case key_str {
        "\u{001B}" -> nutrition_update(model, DateCancel)
        _ -> #(model, NoEffect)
      }
    }

    _ -> {
      case key_str {
        "\u{001B}" -> nutrition_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get today's date as days since epoch
fn get_today_date_int() -> Int {
  let now = birl.now()
  let seconds = birl.to_unix(now)
  seconds / 86_400
}

/// Convert date_int to display string
fn date_int_to_string(date_int: Int) -> String {
  let seconds = date_int * 86_400
  let date = birl.from_unix(seconds)
  birl.to_iso8601(date)
  |> string.slice(0, 10)
}

/// Parse date string to date_int
fn parse_date_string(date_str: String) -> Result(Int, String) {
  case string.split(date_str, "-") {
    [year_str, month_str, day_str] -> {
      case int.parse(year_str), int.parse(month_str), int.parse(day_str) {
        Ok(_), Ok(_), Ok(_) -> {
          case birl.from_naive(date_str <> "T00:00:00") {
            Ok(dt) -> {
              let seconds = birl.to_unix(dt)
              Ok(seconds / 86_400)
            }
            Error(_) -> Error("Invalid date format")
          }
        }
        _, _, _ -> Error("Invalid date components")
      }
    }
    _ -> Error("Expected YYYY-MM-DD format")
  }
}

/// Format float to string with 1 decimal
fn float_to_string(value: Float) -> String {
  let rounded = float.truncate(value *. 10.0) |> int.to_float
  float.to_string(rounded /. 10.0)
}

/// Get goal value for a nutrient type
fn get_goal_value(goals: NutritionGoals, nutrient: NutrientType) -> Float {
  case nutrient {
    Calories -> goals.calories_target
    Protein -> goals.protein_target
    Carbohydrate -> goals.carb_target
    Fat -> goals.fat_target
    Fiber -> goals.fiber_target
    Sugar -> goals.sugar_limit
    Sodium -> goals.sodium_limit
    SaturatedFat -> goals.fat_target *. 0.3
    Cholesterol -> 300.0
  }
}

/// Set goal value for a nutrient type
fn set_goal_value(
  goals: NutritionGoals,
  nutrient: NutrientType,
  value: Float,
) -> NutritionGoals {
  case nutrient {
    Calories -> NutritionGoals(..goals, calories_target: value)
    Protein -> NutritionGoals(..goals, protein_target: value)
    Carbohydrate -> NutritionGoals(..goals, carb_target: value)
    Fat -> NutritionGoals(..goals, fat_target: value)
    Fiber -> NutritionGoals(..goals, fiber_target: value)
    Sugar -> NutritionGoals(..goals, sugar_limit: value)
    Sodium -> NutritionGoals(..goals, sodium_limit: value)
    _ -> goals
  }
}

/// Format macro status
fn format_status(status: MacroStatus) -> String {
  case status {
    Under -> "⬇ Under"
    OnTarget -> "✓ On Target"
    Over -> "⬆ Over"
  }
}

/// Get status color
fn status_color(status: MacroStatus) -> style.Color {
  case status {
    Under -> style.Yellow
    OnTarget -> style.Green
    Over -> style.Red
  }
}

/// Calculate percentage
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> current /. target *. 100.0
    False -> 0.0
  }
}

/// Render progress bar
fn render_progress_bar(percentage: Float, width: Int) -> String {
  let filled = float.truncate(percentage /. 100.0 *. int.to_float(width))
  let filled_clamped = case filled > width {
    True -> width
    False ->
      case filled < 0 {
        True -> 0
        False -> filled
      }
  }
  let empty = width - filled_clamped

  "[" <> string.repeat("█", filled_clamped) <> string.repeat("░", empty) <> "]"
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the nutrition view screen
pub fn nutrition_view(model: NutritionModel) -> shore.Node(NutritionMsg) {
  case model.view_state {
    DashboardView -> view_dashboard(model)
    WeeklyTrendsView -> view_weekly_trends(model)
    MonthlyTrendsView -> view_monthly_trends(model)
    GoalsView -> view_goals(model)
    GoalEditView -> view_goal_edit(model)
    MealBreakdownView -> view_meal_breakdown(model)
    NutrientDetailsView(nutrient) -> view_nutrient_details(model, nutrient)
    ComparisonView -> view_comparison(model)
    DatePicker(date_input) -> view_date_picker(model, date_input)
  }
}

/// Render main dashboard
fn view_dashboard(model: NutritionModel) -> shore.Node(NutritionMsg) {
  let data = model.daily_data
  let goals = model.goals

  let cal_pct = calculate_percentage(data.calories, goals.calories_target)
  let prot_pct = calculate_percentage(data.protein, goals.protein_target)
  let carb_pct = calculate_percentage(data.carbohydrate, goals.carb_target)
  let fat_pct = calculate_percentage(data.fat, goals.fat_target)

  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled(
        "📊 Nutrition Dashboard - " <> data.date_string,
        Some(style.Green),
        None,
      ),
    ),
    ui.hr_styled(style.Green),
  ]

  let error_section = case model.error_message {
    Some(err) -> [ui.br(), ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let nav_section = [
    ui.br(),
    ui.text_styled(
      "[<-] Prev  [->] Next  [t] Today  [g] Go to  [G] Goals  [w] Weekly  [b] Breakdown",
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
  ]

  let loading_section = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let macros_section = [
    ui.br(),
    ui.text_styled("Calories", Some(style.Yellow), None),
    ui.text(
      "  "
      <> render_progress_bar(cal_pct, 30)
      <> " "
      <> float_to_string(data.calories)
      <> " / "
      <> float_to_string(goals.calories_target)
      <> " ("
      <> float_to_string(cal_pct)
      <> "%)",
    ),
    ui.br(),
    ui.text_styled("Protein", Some(style.Cyan), None),
    ui.text(
      "  "
      <> render_progress_bar(prot_pct, 30)
      <> " "
      <> float_to_string(data.protein)
      <> "g / "
      <> float_to_string(goals.protein_target)
      <> "g ("
      <> float_to_string(prot_pct)
      <> "%)",
    ),
    ui.br(),
    ui.text_styled("Carbohydrates", Some(style.Magenta), None),
    ui.text(
      "  "
      <> render_progress_bar(carb_pct, 30)
      <> " "
      <> float_to_string(data.carbohydrate)
      <> "g / "
      <> float_to_string(goals.carb_target)
      <> "g ("
      <> float_to_string(carb_pct)
      <> "%)",
    ),
    ui.br(),
    ui.text_styled("Fat", Some(style.Yellow), None),
    ui.text(
      "  "
      <> render_progress_bar(fat_pct, 30)
      <> " "
      <> float_to_string(data.fat)
      <> "g / "
      <> float_to_string(goals.fat_target)
      <> "g ("
      <> float_to_string(fat_pct)
      <> "%)",
    ),
    ui.br(),
  ]

  let distribution_section = [
    ui.hr(),
    ui.text_styled("Macro Distribution:", Some(style.Yellow), None),
    ui.text(
      "  Protein: "
      <> float_to_string(data.protein_pct)
      <> "% | "
      <> "Carbs: "
      <> float_to_string(data.carb_pct)
      <> "% | "
      <> "Fat: "
      <> float_to_string(data.fat_pct)
      <> "%",
    ),
    ui.br(),
  ]

  let status_section = [
    ui.text_styled("Status:", Some(style.Cyan), None),
    ui.text_styled(
      "  Calories: " <> format_status(data.calories_status),
      Some(status_color(data.calories_status)),
      None,
    ),
    ui.text_styled(
      "  Protein: " <> format_status(data.protein_status),
      Some(status_color(data.protein_status)),
      None,
    ),
    ui.text_styled(
      "  Carbs: " <> format_status(data.carb_status),
      Some(status_color(data.carb_status)),
      None,
    ),
    ui.text_styled(
      "  Fat: " <> format_status(data.fat_status),
      Some(status_color(data.fat_status)),
      None,
    ),
  ]

  ui.col(
    list.flatten([
      header_section,
      error_section,
      nav_section,
      loading_section,
      macros_section,
      distribution_section,
      status_section,
    ]),
  )
}

/// Render weekly trends
fn view_weekly_trends(model: NutritionModel) -> shore.Node(NutritionMsg) {
  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📈 Weekly Trends", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Last 7 days nutrition data:"),
    ui.br(),
  ]

  let data_section = case model.weekly_data {
    [] -> [ui.text("No data available for this period.")]
    data -> {
      list.map(data, fn(day) {
        ui.text(
          "  "
          <> day.date_string
          <> ": "
          <> float_to_string(day.calories)
          <> " cal | "
          <> "P:"
          <> float_to_string(day.protein)
          <> "g | "
          <> "C:"
          <> float_to_string(day.carbohydrate)
          <> "g | "
          <> "F:"
          <> float_to_string(day.fat)
          <> "g",
        )
      })
    }
  }

  let footer_section = [
    ui.br(),
    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ]

  ui.col(list.flatten([header_section, data_section, footer_section]))
}

/// Render monthly trends
fn view_monthly_trends(model: NutritionModel) -> shore.Node(NutritionMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📊 Monthly Trends", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Last 30 days summary:"),
    ui.br(),

    // Show averages
    case list.length(model.weekly_data) {
      0 -> ui.text("No data available.")
      _ -> {
        let avg_cal =
          list.fold(model.weekly_data, 0.0, fn(acc, d) { acc +. d.calories })
          /. int.to_float(list.length(model.weekly_data))
        ui.text("Average daily calories: " <> float_to_string(avg_cal))
      }
    },
    ui.br(),
    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Render goals view
fn view_goals(model: NutritionModel) -> shore.Node(NutritionMsg) {
  let g = model.goals

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🎯 Nutrition Goals", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Goal Type: " <> goal_type_to_string(g.goal_type)),
    ui.text("Tolerance: ±" <> float_to_string(g.tolerance_pct) <> "%"),
    ui.br(),

    ui.text_styled("Daily Targets:", Some(style.Yellow), None),
    ui.text("  1. Calories:     " <> float_to_string(g.calories_target)),
    ui.text("  2. Protein:      " <> float_to_string(g.protein_target) <> "g"),
    ui.text("  3. Carbohydrates:" <> float_to_string(g.carb_target) <> "g"),
    ui.text("  4. Fat:          " <> float_to_string(g.fat_target) <> "g"),
    ui.br(),

    ui.text_styled("Limits:", Some(style.Yellow), None),
    ui.text("  5. Fiber (min):  " <> float_to_string(g.fiber_target) <> "g"),
    ui.text("  6. Sugar (max):  " <> float_to_string(g.sugar_limit) <> "g"),
    ui.text("  7. Sodium (max): " <> float_to_string(g.sodium_limit) <> "mg"),
    ui.br(),

    ui.hr(),
    ui.text_styled("[1-7] Edit goal  [Esc] Back", Some(style.Cyan), None),
  ])
}

/// Convert goal type to string
fn goal_type_to_string(goal_type: GoalType) -> String {
  case goal_type {
    WeightLoss -> "Weight Loss"
    WeightMaintenance -> "Weight Maintenance"
    WeightGain -> "Weight Gain"
    MuscleBuilding -> "Muscle Building"
    Custom -> "Custom"
  }
}

/// Render goal edit view
fn view_goal_edit(model: NutritionModel) -> shore.Node(NutritionMsg) {
  case model.goal_edit_state {
    None -> ui.col([ui.text("No goal being edited")])
    Some(edit) -> {
      let field_name = nutrient_type_to_string(edit.editing_field)

      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("✏ Edit " <> field_name, Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        ui.text(
          "Current value: "
          <> float_to_string(get_goal_value(
            edit.original_goals,
            edit.editing_field,
          )),
        ),
        ui.br(),

        ui.input("New value:", edit.current_value, style.Pct(40), fn(v) {
          GoalValueChanged(v)
        }),
        ui.br(),

        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ])
    }
  }
}

/// Convert nutrient type to string
fn nutrient_type_to_string(nutrient: NutrientType) -> String {
  case nutrient {
    Calories -> "Calories"
    Protein -> "Protein"
    Carbohydrate -> "Carbohydrates"
    Fat -> "Fat"
    Fiber -> "Fiber"
    Sugar -> "Sugar"
    SaturatedFat -> "Saturated Fat"
    Sodium -> "Sodium"
    Cholesterol -> "Cholesterol"
  }
}

/// Render meal breakdown view
fn view_meal_breakdown(model: NutritionModel) -> shore.Node(NutritionMsg) {
  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled(
        "🍽 Meal Breakdown - " <> model.daily_data.date_string,
        Some(style.Green),
        None,
      ),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
  ]

  let meals_section = case model.meal_breakdown {
    [] -> [ui.text("No meals logged for this day.")]
    meals -> {
      list.map(meals, fn(meal) {
        ui.text(
          "  "
          <> meal.meal_name
          <> " ("
          <> int.to_string(meal.entry_count)
          <> " items): "
          <> float_to_string(meal.calories)
          <> " cal ("
          <> float_to_string(meal.percentage_of_daily)
          <> "% of daily)",
        )
      })
    }
  }

  let footer_section = [
    ui.br(),
    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ]

  ui.col(list.flatten([header_section, meals_section, footer_section]))
}

/// Render nutrient details view
fn view_nutrient_details(
  model: NutritionModel,
  nutrient: NutrientType,
) -> shore.Node(NutritionMsg) {
  let name = nutrient_type_to_string(nutrient)

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📋 " <> name <> " Details", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Detailed information about " <> name <> " intake."),
    ui.br(),
    ui.text("(Details view coming soon)"),
    ui.br(),

    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Render comparison view
fn view_comparison(model: NutritionModel) -> shore.Node(NutritionMsg) {
  let data = model.daily_data
  let goals = model.goals

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚖ Actual vs Target", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Date: " <> data.date_string),
    ui.br(),

    ui.text_styled("Comparison:", Some(style.Yellow), None),
    ui.text(
      "  Calories:  "
      <> float_to_string(data.calories)
      <> " / "
      <> float_to_string(goals.calories_target)
      <> " ("
      <> format_difference(data.calories, goals.calories_target)
      <> ")",
    ),
    ui.text(
      "  Protein:   "
      <> float_to_string(data.protein)
      <> "g / "
      <> float_to_string(goals.protein_target)
      <> "g ("
      <> format_difference(data.protein, goals.protein_target)
      <> ")",
    ),
    ui.text(
      "  Carbs:     "
      <> float_to_string(data.carbohydrate)
      <> "g / "
      <> float_to_string(goals.carb_target)
      <> "g ("
      <> format_difference(data.carbohydrate, goals.carb_target)
      <> ")",
    ),
    ui.text(
      "  Fat:       "
      <> float_to_string(data.fat)
      <> "g / "
      <> float_to_string(goals.fat_target)
      <> "g ("
      <> format_difference(data.fat, goals.fat_target)
      <> ")",
    ),
    ui.br(),

    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Format difference between actual and target
fn format_difference(actual: Float, target: Float) -> String {
  let diff = actual -. target
  case diff >=. 0.0 {
    True -> "+" <> float_to_string(diff)
    False -> float_to_string(diff)
  }
}

/// Render date picker
fn view_date_picker(
  model: NutritionModel,
  date_input: String,
) -> shore.Node(NutritionMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📅 Go to Date", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Enter date (YYYY-MM-DD):"),
    ui.br(),
    ui.input("Date:", date_input, style.Pct(50), fn(d) { DateConfirm(d) }),
    ui.br(),

    ui.text_styled(
      "Current: " <> date_int_to_string(model.current_date),
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
    ui.text_styled("[Enter] Confirm  [Esc] Cancel", Some(style.Cyan), None),
  ])
}
