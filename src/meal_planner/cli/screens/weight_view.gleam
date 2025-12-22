/// Weight Tracking View Screen - Complete TUI Implementation
///
/// This module implements the weight tracking screen following Shore Framework
/// (Elm Architecture) for logging and tracking body weight over time.
///
/// SCREEN FEATURES:
/// - Log daily weight entries
/// - View weight history with trends
/// - Set goal weight and track progress
/// - View weight change over time periods
/// - Calculate BMI and body composition metrics
/// - Graph weight trends (ASCII chart)
///
/// ARCHITECTURE:
/// - Model: WeightModel (state container)
/// - Msg: WeightMsg (all possible events)
/// - Update: weight_update (state transitions)
/// - View: weight_view (rendering)
import birl
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/weight/types as weight_types
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Root state for the Weight TUI screen
pub type WeightModel {
  WeightModel(
    /// Current view state
    view_state: WeightViewState,
    /// Current date for viewing
    current_date: Int,
    /// Weight entries (sorted by date, newest first)
    entries: List(WeightDisplayEntry),
    /// Current/latest weight
    current_weight: Option(Float),
    /// Goal settings
    goals: WeightGoals,
    /// Entry input state
    entry_input: WeightEntryInput,
    /// Edit state
    edit_state: Option(WeightEditState),
    /// Loading state
    is_loading: Bool,
    /// Error message
    error_message: Option(String),
    /// Statistics
    statistics: WeightStatistics,
    /// User profile (for BMI calculation)
    user_profile: UserProfile,
    /// Chart data
    chart_data: List(ChartPoint),
  )
}

/// View state machine
pub type WeightViewState {
  /// Main weight list view
  ListView
  /// Add new weight entry
  AddEntryView
  /// Edit existing entry
  EditEntryView
  /// Delete confirmation
  ConfirmDeleteView(entry_id: weight_types.WeightEntryId)
  /// Goal settings view
  GoalsView
  /// Statistics view
  StatsView
  /// Chart/graph view
  ChartView
  /// Profile settings (height for BMI)
  ProfileView
  /// Date picker
  DatePicker(date_input: String)
}

/// Display entry with formatting
pub type WeightDisplayEntry {
  WeightDisplayEntry(
    /// Original entry
    entry: weight_types.WeightEntry,
    /// Formatted weight display
    weight_display: String,
    /// Date display
    date_display: String,
    /// Change from previous entry
    change_display: String,
    /// BMI if height is known
    bmi_display: Option(String),
    /// Days since last entry
    days_since_previous: Option(Int),
  )
}

/// Weight goals
pub type WeightGoals {
  WeightGoals(
    /// Target weight in kg
    target_weight: Float,
    /// Starting weight for this goal
    starting_weight: Float,
    /// Start date of goal
    goal_start_date: Int,
    /// Target date to reach goal
    target_date: Option(Int),
    /// Weekly target change (positive for gain, negative for loss)
    weekly_target: Float,
    /// Goal type
    goal_type: WeightGoalType,
  )
}

/// Type of weight goal
pub type WeightGoalType {
  LoseWeight
  MaintainWeight
  GainWeight
}

/// Weight entry input
pub type WeightEntryInput {
  WeightEntryInput(
    /// Weight value as string (for input)
    weight_str: String,
    /// Date for entry
    date_int: Int,
    /// Optional comment
    comment: String,
    /// Parsed weight value
    parsed_weight: Option(Float),
  )
}

/// Weight edit state
pub type WeightEditState {
  WeightEditState(
    entry: weight_types.WeightEntry,
    new_weight_str: String,
    new_comment: String,
    original_weight: Float,
  )
}

/// Weight statistics
pub type WeightStatistics {
  WeightStatistics(
    /// Total change since first entry
    total_change: Float,
    /// Average weight
    average_weight: Float,
    /// Min weight recorded
    min_weight: Float,
    /// Max weight recorded
    max_weight: Float,
    /// 7-day change
    week_change: Float,
    /// 30-day change
    month_change: Float,
    /// Current BMI
    current_bmi: Option(Float),
    /// BMI category
    bmi_category: Option(String),
    /// Progress to goal (percentage)
    goal_progress: Float,
    /// Estimated days to goal
    days_to_goal: Option(Int),
  )
}

/// User profile for BMI
pub type UserProfile {
  UserProfile(
    /// Height in cm
    height_cm: Option(Float),
    /// Birth date for age
    birth_date: Option(Int),
    /// Gender
    gender: Option(Gender),
  )
}

/// Gender type
pub type Gender {
  Male
  Female
  Other
}

/// Chart point for graphing
pub type ChartPoint {
  ChartPoint(date_int: Int, weight: Float, label: String)
}

/// Messages for the weight screen
pub type WeightMsg {
  // Navigation
  ShowListView
  ShowAddEntry
  ShowEditEntry(entry: weight_types.WeightEntry)
  ShowDeleteConfirm(entry_id: weight_types.WeightEntryId)
  ShowGoals
  ShowStats
  ShowChart
  ShowProfile
  ShowDatePicker
  GoBack

  // Entry Input
  WeightInputChanged(weight: String)
  CommentInputChanged(comment: String)
  DateInputChanged(date: String)
  ConfirmAddEntry
  CancelAddEntry

  // Edit Entry
  EditWeightChanged(weight: String)
  EditCommentChanged(comment: String)
  ConfirmEditEntry
  CancelEditEntry

  // Delete Entry
  ConfirmDelete
  CancelDelete

  // Goals
  SetTargetWeight(weight: Float)
  SetWeeklyTarget(change: Float)
  SetGoalType(goal_type: WeightGoalType)
  SaveGoals

  // Profile
  SetHeight(height_cm: Float)
  SetGender(gender: Gender)
  SaveProfile

  // Data Loading
  GotEntries(Result(List(weight_types.WeightEntry), String))
  GotGoals(Result(WeightGoals, String))
  EntryCreated(Result(weight_types.WeightEntryId, String))
  EntryUpdated(Result(Nil, String))
  EntryDeleted(Result(Nil, String))

  // UI
  DatePrevious
  DateNext
  DateToday
  DateConfirm(date: String)
  DateCancel
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

/// Effects for the weight screen
pub type WeightEffect {
  NoEffect
  FetchEntries(limit: Int)
  FetchGoals
  CreateEntry(weight_kg: Float, date_int: Int, comment: String)
  UpdateEntry(
    entry_id: weight_types.WeightEntryId,
    weight_kg: Float,
    comment: String,
  )
  DeleteEntry(entry_id: weight_types.WeightEntryId)
  SaveGoalsEffect(goals: WeightGoals)
  SaveProfileEffect(profile: UserProfile)
  BatchEffects(effects: List(WeightEffect))
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial WeightModel
pub fn init(today_date_int: Int) -> WeightModel {
  WeightModel(
    view_state: ListView,
    current_date: today_date_int,
    entries: [],
    current_weight: None,
    goals: default_goals(),
    entry_input: empty_entry_input(today_date_int),
    edit_state: None,
    is_loading: False,
    error_message: None,
    statistics: empty_statistics(),
    user_profile: empty_profile(),
    chart_data: [],
  )
}

/// Default weight goals
fn default_goals() -> WeightGoals {
  WeightGoals(
    target_weight: 70.0,
    starting_weight: 70.0,
    goal_start_date: 0,
    target_date: None,
    weekly_target: -0.5,
    goal_type: MaintainWeight,
  )
}

/// Empty entry input
fn empty_entry_input(date_int: Int) -> WeightEntryInput {
  WeightEntryInput(
    weight_str: "",
    date_int: date_int,
    comment: "",
    parsed_weight: None,
  )
}

/// Empty statistics
fn empty_statistics() -> WeightStatistics {
  WeightStatistics(
    total_change: 0.0,
    average_weight: 0.0,
    min_weight: 0.0,
    max_weight: 0.0,
    week_change: 0.0,
    month_change: 0.0,
    current_bmi: None,
    bmi_category: None,
    goal_progress: 0.0,
    days_to_goal: None,
  )
}

/// Empty profile
fn empty_profile() -> UserProfile {
  UserProfile(height_cm: None, birth_date: None, gender: None)
}

// ============================================================================
// Update Function
// ============================================================================

/// Main update function for weight view
pub fn weight_update(
  model: WeightModel,
  msg: WeightMsg,
) -> #(WeightModel, WeightEffect) {
  case msg {
    // === Navigation ===
    ShowListView -> {
      let updated = WeightModel(..model, view_state: ListView)
      #(updated, FetchEntries(50))
    }

    ShowAddEntry -> {
      let input = empty_entry_input(model.current_date)
      let updated =
        WeightModel(..model, view_state: AddEntryView, entry_input: input)
      #(updated, NoEffect)
    }

    ShowEditEntry(entry) -> {
      let edit_state =
        WeightEditState(
          entry: entry,
          new_weight_str: float_to_string(entry.weight_kg),
          new_comment: option.unwrap(entry.weight_comment, ""),
          original_weight: entry.weight_kg,
        )
      let updated =
        WeightModel(
          ..model,
          view_state: EditEntryView,
          edit_state: Some(edit_state),
        )
      #(updated, NoEffect)
    }

    ShowDeleteConfirm(entry_id) -> {
      let updated =
        WeightModel(..model, view_state: ConfirmDeleteView(entry_id))
      #(updated, NoEffect)
    }

    ShowGoals -> {
      let updated = WeightModel(..model, view_state: GoalsView)
      #(updated, FetchGoals)
    }

    ShowStats -> {
      let updated = WeightModel(..model, view_state: StatsView)
      #(updated, NoEffect)
    }

    ShowChart -> {
      let updated = WeightModel(..model, view_state: ChartView)
      #(updated, NoEffect)
    }

    ShowProfile -> {
      let updated = WeightModel(..model, view_state: ProfileView)
      #(updated, NoEffect)
    }

    ShowDatePicker -> {
      let date_str = date_int_to_string(model.current_date)
      let updated = WeightModel(..model, view_state: DatePicker(date_str))
      #(updated, NoEffect)
    }

    GoBack -> {
      case model.view_state {
        ListView -> #(model, NoEffect)
        _ -> {
          let updated =
            WeightModel(..model, view_state: ListView, edit_state: None)
          #(updated, NoEffect)
        }
      }
    }

    // === Entry Input ===
    WeightInputChanged(weight_str) -> {
      let parsed = float.parse(weight_str)
      let input =
        WeightEntryInput(
          ..model.entry_input,
          weight_str: weight_str,
          parsed_weight: option.from_result(parsed),
        )
      let updated = WeightModel(..model, entry_input: input)
      #(updated, NoEffect)
    }

    CommentInputChanged(comment) -> {
      let input = WeightEntryInput(..model.entry_input, comment: comment)
      let updated = WeightModel(..model, entry_input: input)
      #(updated, NoEffect)
    }

    DateInputChanged(date_str) -> {
      case parse_date_string(date_str) {
        Ok(date_int) -> {
          let input = WeightEntryInput(..model.entry_input, date_int: date_int)
          let updated = WeightModel(..model, entry_input: input)
          #(updated, NoEffect)
        }
        Error(_) -> #(model, NoEffect)
      }
    }

    ConfirmAddEntry -> {
      case model.entry_input.parsed_weight {
        Some(weight) -> {
          let updated =
            WeightModel(..model, view_state: ListView, is_loading: True)
          let effect =
            CreateEntry(
              weight,
              model.entry_input.date_int,
              model.entry_input.comment,
            )
          #(updated, effect)
        }
        None -> {
          let updated =
            WeightModel(..model, error_message: Some("Invalid weight value"))
          #(updated, NoEffect)
        }
      }
    }

    CancelAddEntry -> {
      let updated = WeightModel(..model, view_state: ListView)
      #(updated, NoEffect)
    }

    // === Edit Entry ===
    EditWeightChanged(weight_str) -> {
      case model.edit_state {
        Some(edit) -> {
          let new_edit = WeightEditState(..edit, new_weight_str: weight_str)
          let updated = WeightModel(..model, edit_state: Some(new_edit))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    EditCommentChanged(comment) -> {
      case model.edit_state {
        Some(edit) -> {
          let new_edit = WeightEditState(..edit, new_comment: comment)
          let updated = WeightModel(..model, edit_state: Some(new_edit))
          #(updated, NoEffect)
        }
        None -> #(model, NoEffect)
      }
    }

    ConfirmEditEntry -> {
      case model.edit_state {
        Some(edit) -> {
          case float.parse(edit.new_weight_str) {
            Ok(weight) -> {
              let updated =
                WeightModel(
                  ..model,
                  view_state: ListView,
                  edit_state: None,
                  is_loading: True,
                )
              // Use date_int as the entry ID since that's how FatSecret identifies weight entries
              let entry_id =
                weight_types.weight_entry_id(int.to_string(edit.entry.date_int))
              let effect = UpdateEntry(entry_id, weight, edit.new_comment)
              #(updated, effect)
            }
            Error(_) -> {
              let updated =
                WeightModel(
                  ..model,
                  error_message: Some("Invalid weight value"),
                )
              #(updated, NoEffect)
            }
          }
        }
        None -> #(model, NoEffect)
      }
    }

    CancelEditEntry -> {
      let updated = WeightModel(..model, view_state: ListView, edit_state: None)
      #(updated, NoEffect)
    }

    // === Delete Entry ===
    ConfirmDelete -> {
      case model.view_state {
        ConfirmDeleteView(entry_id) -> {
          let updated =
            WeightModel(..model, view_state: ListView, is_loading: True)
          #(updated, DeleteEntry(entry_id))
        }
        _ -> #(model, NoEffect)
      }
    }

    CancelDelete -> {
      let updated = WeightModel(..model, view_state: ListView)
      #(updated, NoEffect)
    }

    // === Goals ===
    SetTargetWeight(weight) -> {
      let goals = WeightGoals(..model.goals, target_weight: weight)
      let updated = WeightModel(..model, goals: goals)
      #(updated, NoEffect)
    }

    SetWeeklyTarget(change) -> {
      let goals = WeightGoals(..model.goals, weekly_target: change)
      let updated = WeightModel(..model, goals: goals)
      #(updated, NoEffect)
    }

    SetGoalType(goal_type) -> {
      let goals = WeightGoals(..model.goals, goal_type: goal_type)
      let updated = WeightModel(..model, goals: goals)
      #(updated, NoEffect)
    }

    SaveGoals -> {
      #(model, SaveGoalsEffect(model.goals))
    }

    // === Profile ===
    SetHeight(height_cm) -> {
      let profile =
        UserProfile(..model.user_profile, height_cm: Some(height_cm))
      let updated = WeightModel(..model, user_profile: profile)
      #(updated, NoEffect)
    }

    SetGender(gender) -> {
      let profile = UserProfile(..model.user_profile, gender: Some(gender))
      let updated = WeightModel(..model, user_profile: profile)
      #(updated, NoEffect)
    }

    SaveProfile -> {
      #(model, SaveProfileEffect(model.user_profile))
    }

    // === Data Loading ===
    GotEntries(result) -> {
      case result {
        Ok(entries) -> {
          let display_entries = format_entries(entries, model.user_profile)
          let current = case entries {
            [first, ..] -> Some(first.weight_kg)
            [] -> None
          }
          let stats =
            calculate_statistics(entries, model.goals, model.user_profile)
          let chart = build_chart_data(entries)
          let updated =
            WeightModel(
              ..model,
              entries: display_entries,
              current_weight: current,
              statistics: stats,
              chart_data: chart,
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            WeightModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    GotGoals(result) -> {
      case result {
        Ok(goals) -> {
          let updated = WeightModel(..model, goals: goals)
          #(updated, NoEffect)
        }
        Error(_) -> #(model, NoEffect)
      }
    }

    EntryCreated(result) -> {
      case result {
        Ok(_id) -> #(model, FetchEntries(50))
        Error(err) -> {
          let updated =
            WeightModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    EntryUpdated(result) -> {
      case result {
        Ok(_) -> #(model, FetchEntries(50))
        Error(err) -> {
          let updated =
            WeightModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    EntryDeleted(result) -> {
      case result {
        Ok(_) -> #(model, FetchEntries(50))
        Error(err) -> {
          let updated =
            WeightModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    // === UI ===
    DatePrevious -> {
      let new_date = model.current_date - 1
      let updated = WeightModel(..model, current_date: new_date)
      #(updated, NoEffect)
    }

    DateNext -> {
      let new_date = model.current_date + 1
      let updated = WeightModel(..model, current_date: new_date)
      #(updated, NoEffect)
    }

    DateToday -> {
      let today = get_today_date_int()
      let updated = WeightModel(..model, current_date: today)
      #(updated, NoEffect)
    }

    DateConfirm(date_str) -> {
      case parse_date_string(date_str) {
        Ok(date_int) -> {
          let updated =
            WeightModel(..model, current_date: date_int, view_state: ListView)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            WeightModel(..model, error_message: Some(err), view_state: ListView)
          #(updated, NoEffect)
        }
      }
    }

    DateCancel -> {
      let updated = WeightModel(..model, view_state: ListView)
      #(updated, NoEffect)
    }

    ClearError -> {
      let updated = WeightModel(..model, error_message: None)
      #(updated, NoEffect)
    }

    KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    Refresh -> {
      let updated = WeightModel(..model, is_loading: True)
      #(updated, FetchEntries(50))
    }

    NoOp -> #(model, NoEffect)
  }
}

/// Handle keyboard input
fn handle_key_press(
  model: WeightModel,
  key_str: String,
) -> #(WeightModel, WeightEffect) {
  case model.view_state {
    ListView -> {
      case key_str {
        "a" -> weight_update(model, ShowAddEntry)
        "g" -> weight_update(model, ShowGoals)
        "s" -> weight_update(model, ShowStats)
        "c" -> weight_update(model, ShowChart)
        "p" -> weight_update(model, ShowProfile)
        "r" -> weight_update(model, Refresh)
        _ -> #(model, NoEffect)
      }
    }

    AddEntryView -> {
      case key_str {
        "\r" -> weight_update(model, ConfirmAddEntry)
        "\u{001B}" -> weight_update(model, CancelAddEntry)
        _ -> #(model, NoEffect)
      }
    }

    EditEntryView -> {
      case key_str {
        "\r" -> weight_update(model, ConfirmEditEntry)
        "\u{001B}" -> weight_update(model, CancelEditEntry)
        _ -> #(model, NoEffect)
      }
    }

    ConfirmDeleteView(_) -> {
      case key_str {
        "y" -> weight_update(model, ConfirmDelete)
        "n" -> weight_update(model, CancelDelete)
        "\u{001B}" -> weight_update(model, CancelDelete)
        _ -> #(model, NoEffect)
      }
    }

    _ -> {
      case key_str {
        "\u{001B}" -> weight_update(model, GoBack)
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
  let midnight = birl.TimeOfDay(hour: 0, minute: 0, second: 0, milli_second: 0)
  let today_midnight = birl.set_time_of_day(now, midnight)
  birl.to_unix(today_midnight) / 86_400
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
          case birl.parse(date_str <> "T00:00:00Z") {
            Ok(dt) -> {
              let days = birl.to_unix(dt) / 86_400
              Ok(days)
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

/// Format weight entries for display
fn format_entries(
  entries: List(weight_types.WeightEntry),
  profile: UserProfile,
) -> List(WeightDisplayEntry) {
  entries
  |> list.index_map(fn(entry, idx) {
    // Get the previous entry (at idx + 1) by dropping and taking first
    let prev_entry = entries |> list.drop(idx + 1) |> list.first
    let change = case prev_entry {
      Ok(prev) -> {
        let diff = entry.weight_kg -. prev.weight_kg
        case diff >=. 0.0 {
          True -> "+" <> float_to_string(diff) <> " kg"
          False -> float_to_string(diff) <> " kg"
        }
      }
      Error(_) -> "-"
    }

    let days_since = case prev_entry {
      Ok(prev) -> Some(entry.date_int - prev.date_int)
      Error(_) -> None
    }

    let bmi = case profile.height_cm {
      Some(height) -> {
        let height_m = height /. 100.0
        let bmi_val = entry.weight_kg /. { height_m *. height_m }
        Some(float_to_string(bmi_val))
      }
      None -> None
    }

    WeightDisplayEntry(
      entry: entry,
      weight_display: float_to_string(entry.weight_kg) <> " kg",
      date_display: date_int_to_string(entry.date_int),
      change_display: change,
      bmi_display: bmi,
      days_since_previous: days_since,
    )
  })
}

/// Calculate statistics from entries
fn calculate_statistics(
  entries: List(weight_types.WeightEntry),
  goals: WeightGoals,
  profile: UserProfile,
) -> WeightStatistics {
  case entries {
    [] -> empty_statistics()
    [latest, ..rest] -> {
      let all_weights = list.map(entries, fn(e) { e.weight_kg })
      let first = case list.last(entries) {
        Ok(e) -> e.weight_kg
        Error(_) -> latest.weight_kg
      }

      let total_change = latest.weight_kg -. first
      let sum = list.fold(all_weights, 0.0, fn(acc, w) { acc +. w })
      let avg = sum /. int.to_float(list.length(entries))

      let min =
        list.fold(all_weights, latest.weight_kg, fn(acc, w) {
          case w <. acc {
            True -> w
            False -> acc
          }
        })

      let max =
        list.fold(all_weights, latest.weight_kg, fn(acc, w) {
          case w >. acc {
            True -> w
            False -> acc
          }
        })

      let week_change = calculate_period_change(entries, 7)
      let month_change = calculate_period_change(entries, 30)

      let bmi = case profile.height_cm {
        Some(height) -> {
          let height_m = height /. 100.0
          Some(latest.weight_kg /. { height_m *. height_m })
        }
        None -> None
      }

      let bmi_cat = case bmi {
        Some(b) -> Some(bmi_category(b))
        None -> None
      }

      let progress = case goals.goal_type {
        MaintainWeight -> 100.0
        _ -> {
          let target_change = goals.target_weight -. goals.starting_weight
          case float.absolute_value(target_change) >. 0.1 {
            True -> {
              let actual_change = latest.weight_kg -. goals.starting_weight
              actual_change /. target_change *. 100.0
            }
            False -> 100.0
          }
        }
      }

      WeightStatistics(
        total_change: total_change,
        average_weight: avg,
        min_weight: min,
        max_weight: max,
        week_change: week_change,
        month_change: month_change,
        current_bmi: bmi,
        bmi_category: bmi_cat,
        goal_progress: progress,
        days_to_goal: None,
      )
    }
  }
}

/// Calculate weight change over a period
fn calculate_period_change(
  entries: List(weight_types.WeightEntry),
  days: Int,
) -> Float {
  case entries {
    [] -> 0.0
    [latest, ..] -> {
      let cutoff_date = latest.date_int - days
      let older = list.filter(entries, fn(e) { e.date_int <= cutoff_date })
      case older {
        [first, ..] -> latest.weight_kg -. first.weight_kg
        [] -> 0.0
      }
    }
  }
}

/// Get BMI category
fn bmi_category(bmi: Float) -> String {
  case bmi <. 18.5, bmi <. 25.0, bmi <. 30.0 {
    True, _, _ -> "Underweight"
    False, True, _ -> "Normal"
    False, False, True -> "Overweight"
    False, False, False -> "Obese"
  }
}

/// Build chart data from entries
fn build_chart_data(entries: List(weight_types.WeightEntry)) -> List(ChartPoint) {
  entries
  |> list.take(30)
  |> list.reverse
  |> list.map(fn(e) {
    ChartPoint(
      date_int: e.date_int,
      weight: e.weight_kg,
      label: date_int_to_string(e.date_int),
    )
  })
}

/// Render ASCII chart
fn render_chart(data: List(ChartPoint), width: Int, height: Int) -> List(String) {
  case data {
    [] -> ["No data to display"]
    _ -> {
      let weights = list.map(data, fn(p) { p.weight })
      let min_w = list.fold(weights, 999.0, fn(acc, w) { float.min(acc, w) })
      let max_w = list.fold(weights, 0.0, fn(acc, w) { float.max(acc, w) })
      let range = max_w -. min_w

      // Build rows
      list.range(0, height - 1)
      |> list.map(fn(row) {
        let y_val =
          max_w -. { int.to_float(row) /. int.to_float(height) *. range }
        let label = float_to_string(y_val) <> " |"
        let row_data =
          data
          |> list.map(fn(point) {
            let normalized = { point.weight -. min_w } /. range
            let point_row =
              height
              - 1
              - float.truncate(normalized *. int.to_float(height - 1))
            case point_row == row {
              True -> "●"
              False -> " "
            }
          })
          |> string.join("")
        string.pad_start(label, 10, " ") <> row_data
      })
    }
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the weight view screen
pub fn weight_view(model: WeightModel) -> shore.Node(WeightMsg) {
  case model.view_state {
    ListView -> view_list(model)
    AddEntryView -> view_add_entry(model)
    EditEntryView -> view_edit_entry(model)
    ConfirmDeleteView(entry_id) -> view_delete_confirm(model, entry_id)
    GoalsView -> view_goals(model)
    StatsView -> view_stats(model)
    ChartView -> view_chart(model)
    ProfileView -> view_profile(model)
    DatePicker(date_input) -> view_date_picker(model, date_input)
  }
}

/// Render weight list view
fn view_list(model: WeightModel) -> shore.Node(WeightMsg) {
  let current_weight_row = case model.current_weight {
    Some(w) -> [
      ui.br(),
      ui.text_styled(
        "Current Weight: " <> float_to_string(w) <> " kg",
        Some(style.Yellow),
        None,
      ),
    ]
    None -> []
  }

  let error_row = case model.error_message {
    Some(err) -> [ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let loading_row = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let entry_rows = case model.entries {
    [] -> [ui.text("No weight entries recorded.")]
    entries -> list.take(entries, 10) |> list.map(render_weight_entry)
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("⚖ Weight Tracker", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
      ],
      current_weight_row,
      error_row,
      [
        ui.br(),
        ui.text_styled(
          "[a] Add  [g] Goals  [s] Stats  [c] Chart  [p] Profile  [r] Refresh",
          Some(style.Cyan),
          None,
        ),
        ui.hr(),
        ui.br(),
      ],
      loading_row,
      [ui.text_styled("Recent Entries:", Some(style.Yellow), None)],
      entry_rows,
      [
        ui.br(),
        ui.text_styled(
          "[e] Edit  [d] Delete  [Enter] View",
          Some(style.Cyan),
          None,
        ),
      ],
    ]),
  )
}

/// Render a weight entry
fn render_weight_entry(entry: WeightDisplayEntry) -> shore.Node(WeightMsg) {
  let bmi_str = case entry.bmi_display {
    Some(b) -> " (BMI: " <> b <> ")"
    None -> ""
  }
  ui.text(
    "  "
    <> entry.date_display
    <> ": "
    <> entry.weight_display
    <> " "
    <> entry.change_display
    <> bmi_str,
  )
}

/// Render add entry view
fn view_add_entry(model: WeightModel) -> shore.Node(WeightMsg) {
  let input = model.entry_input

  let parsed_row = case input.parsed_weight {
    Some(w) -> [
      ui.text_styled(
        "Parsed: " <> float_to_string(w) <> " kg",
        Some(style.Green),
        None,
      ),
    ]
    None ->
      case input.weight_str {
        "" -> []
        _ -> [ui.text_styled("Invalid weight", Some(style.Red), None)]
      }
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("➕ Add Weight Entry", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Date: " <> date_int_to_string(input.date_int)),
        ui.br(),
        ui.input("Weight (kg):", input.weight_str, style.Pct(30), fn(w) {
          WeightInputChanged(w)
        }),
        ui.br(),
        ui.input("Comment:", input.comment, style.Pct(60), fn(c) {
          CommentInputChanged(c)
        }),
        ui.br(),
      ],
      parsed_row,
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render edit entry view
fn view_edit_entry(model: WeightModel) -> shore.Node(WeightMsg) {
  case model.edit_state {
    None -> ui.col([ui.text("No entry being edited")])
    Some(edit) -> {
      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("✏ Edit Weight Entry", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        ui.text("Date: " <> date_int_to_string(edit.entry.date_int)),
        ui.text("Original: " <> float_to_string(edit.original_weight) <> " kg"),
        ui.br(),

        ui.input("New Weight (kg):", edit.new_weight_str, style.Pct(30), fn(w) {
          EditWeightChanged(w)
        }),
        ui.br(),

        ui.input("Comment:", edit.new_comment, style.Pct(60), fn(c) {
          EditCommentChanged(c)
        }),
        ui.br(),

        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ])
    }
  }
}

/// Render delete confirmation
fn view_delete_confirm(
  _model: WeightModel,
  entry_id: weight_types.WeightEntryId,
) -> shore.Node(WeightMsg) {
  let id_str = weight_types.weight_entry_id_to_string(entry_id)

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚠ Confirm Delete", Some(style.Red), None),
    ),
    ui.hr_styled(style.Red),
    ui.br(),

    ui.text("Delete this weight entry?"),
    ui.text("Entry ID: " <> id_str),
    ui.br(),

    ui.text_styled("[y] Yes  [n] No", Some(style.Yellow), None),
  ])
}

/// Render goals view
fn view_goals(model: WeightModel) -> shore.Node(WeightMsg) {
  let g = model.goals

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🎯 Weight Goals", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Goal Type: " <> goal_type_to_string(g.goal_type)),
    ui.text("Target Weight: " <> float_to_string(g.target_weight) <> " kg"),
    ui.text("Starting Weight: " <> float_to_string(g.starting_weight) <> " kg"),
    ui.text("Weekly Target: " <> float_to_string(g.weekly_target) <> " kg/week"),
    ui.br(),

    case model.current_weight {
      Some(current) -> {
        let remaining = g.target_weight -. current
        ui.text("Remaining: " <> float_to_string(remaining) <> " kg")
      }
      None -> ui.text("")
    },
    ui.br(),

    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Convert goal type to string
fn goal_type_to_string(gt: WeightGoalType) -> String {
  case gt {
    LoseWeight -> "Lose Weight"
    MaintainWeight -> "Maintain Weight"
    GainWeight -> "Gain Weight"
  }
}

/// Render stats view
fn view_stats(model: WeightModel) -> shore.Node(WeightMsg) {
  let s = model.statistics

  let bmi_row = case s.current_bmi, s.bmi_category {
    Some(bmi), Some(cat) -> [
      ui.text("BMI: " <> float_to_string(bmi) <> " (" <> cat <> ")"),
    ]
    _, _ -> []
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📊 Statistics", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Total Change: " <> float_to_string(s.total_change) <> " kg"),
        ui.text("Average: " <> float_to_string(s.average_weight) <> " kg"),
        ui.text("Min: " <> float_to_string(s.min_weight) <> " kg"),
        ui.text("Max: " <> float_to_string(s.max_weight) <> " kg"),
        ui.br(),
        ui.text("7-Day Change: " <> float_to_string(s.week_change) <> " kg"),
        ui.text("30-Day Change: " <> float_to_string(s.month_change) <> " kg"),
        ui.br(),
      ],
      bmi_row,
      [
        ui.text("Goal Progress: " <> float_to_string(s.goal_progress) <> "%"),
        ui.br(),
        ui.hr(),
        ui.text_styled("[Esc] Back", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render chart view
fn view_chart(model: WeightModel) -> shore.Node(WeightMsg) {
  let chart_lines = render_chart(model.chart_data, 40, 10)
  let chart_rows = list.map(chart_lines, fn(line) { ui.text(line) })

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📈 Weight Chart", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Last 30 days:"),
        ui.br(),
      ],
      chart_rows,
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Esc] Back", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render profile view
fn view_profile(model: WeightModel) -> shore.Node(WeightMsg) {
  let p = model.user_profile

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("👤 Profile Settings", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text(
      "Height: "
      <> case p.height_cm {
        Some(h) -> float_to_string(h) <> " cm"
        None -> "Not set"
      },
    ),
    ui.text(
      "Gender: "
      <> case p.gender {
        Some(Male) -> "Male"
        Some(Female) -> "Female"
        Some(Other) -> "Other"
        None -> "Not set"
      },
    ),
    ui.br(),

    ui.text("(Height is used for BMI calculation)"),
    ui.br(),

    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Render date picker
fn view_date_picker(
  model: WeightModel,
  date_input: String,
) -> shore.Node(WeightMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📅 Select Date", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.input("Date (YYYY-MM-DD):", date_input, style.Pct(50), fn(d) {
      DateConfirm(d)
    }),
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
