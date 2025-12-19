/// Meal Rotation Tracker
///
/// Manages 30-day meal rotation eligibility to prevent recipe fatigue.
/// Part of meal-planner-918 (Weekly Generation Engine).
import birl
import gleam/list
import gleam/result

// ============================================================================
// Types
// ============================================================================

/// History record for meal rotation tracking
pub type MealRotationHistory {
  MealRotationHistory(
    /// Recipe/meal identifier
    meal_id: String,
    /// Last date this meal was served (YYYY-MM-DD format)
    last_served: String,
    /// Number of days since last served
    days_since: Int,
  )
}

// ============================================================================
// Eligibility Check
// ============================================================================

/// Check if a meal is eligible for selection based on rotation rules
///
/// A meal is eligible if:
/// - It's new (not in history), OR
/// - It was last served >= min_days ago (default 30)
///
/// ## Parameters
/// - meal_id: Recipe identifier
/// - history: List of previous meal selections with dates
/// - min_days: Minimum days between selections (default 30)
///
/// ## Returns
/// True if eligible, False if too recent
pub fn is_eligible_for_selection(
  meal_id: String,
  history: List(MealRotationHistory),
  min_days: Int,
) -> Bool {
  // Find this meal in history
  case list.find(history, fn(entry) { entry.meal_id == meal_id }) {
    // Not found -> new meal, always eligible
    Error(_) -> True
    // Found -> check if enough days have passed
    Ok(entry) -> entry.days_since >= min_days
  }
}

// ============================================================================
// Date Calculations
// ============================================================================

/// Calculate days between two dates
///
/// Both dates must be in YYYY-MM-DD format.
///
/// ## Examples
/// ```gleam
/// days_between_dates("2024-01-01", "2024-01-31")
/// // -> Ok(30)
///
/// days_between_dates("2024-01-01", "2024-01-01")
/// // -> Ok(0)
/// ```
///
/// ## Returns
/// Ok(days) on success, Error(Nil) if date parsing fails
pub fn days_between_dates(from: String, to: String) -> Result(Int, Nil) {
  // Parse from date
  use from_time <- result.try(birl.from_naive(from <> "T00:00:00"))

  // Parse to date
  use to_time <- result.try(birl.from_naive(to <> "T00:00:00"))

  // Calculate difference in seconds
  let from_seconds = birl.to_unix(from_time)
  let to_seconds = birl.to_unix(to_time)

  // Convert to days
  let days = { to_seconds - from_seconds } / 86_400

  Ok(days)
}

// ============================================================================
// History Management
// ============================================================================

/// Update rotation history with a new meal selection
///
/// If the meal already exists in history, updates its last_served date.
/// If it's new, adds it to the history.
///
/// Note: days_since is set to 0 for the newly selected meal (just served today).
///
/// ## Parameters
/// - history: Current rotation history
/// - meal_id: Recipe that was just selected
/// - date: Date of selection (YYYY-MM-DD)
///
/// ## Returns
/// Updated history with the meal's last_served date set
pub fn update_rotation_history(
  history: List(MealRotationHistory),
  meal_id: String,
  date: String,
) -> List(MealRotationHistory) {
  // Create new entry for this meal
  let new_entry =
    MealRotationHistory(meal_id: meal_id, last_served: date, days_since: 0)

  // Check if meal already exists in history
  case list.find(history, fn(entry) { entry.meal_id == meal_id }) {
    // Meal exists -> replace it
    Ok(_) ->
      list.map(history, fn(entry) {
        case entry.meal_id == meal_id {
          True -> new_entry
          False -> entry
        }
      })
    // Meal doesn't exist -> add it
    Error(_) -> [new_entry, ..history]
  }
}
