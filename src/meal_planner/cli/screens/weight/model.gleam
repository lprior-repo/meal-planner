/// Weight Screen Model - MVC Architecture
///
/// This module contains all data types and state for the weight tracking screen.
/// Following the Model-View-Controller pattern, this is the Model layer.
import gleam/option.{type Option, None}
import meal_planner/fatsecret/weight/types as weight_types

// ============================================================================
// Model Types
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
