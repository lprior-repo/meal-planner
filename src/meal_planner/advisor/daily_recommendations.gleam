/// Daily nutrition advisor email generation
///
/// This module generates daily nutrition recommendations based on FatSecret diary
/// analysis. It compares actual consumption vs target macros and generates
/// actionable insights for the user.
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/fatsecret/diary/types.{type DaySummary, type FoodEntry}
import meal_planner/fatsecret/profile/service as profile_service
import meal_planner/fatsecret/profile/types as profile_types
import pog

// ============================================================================
// Types
// ============================================================================

/// Complete advisor email content
pub type AdvisorEmail {
  AdvisorEmail(
    date: String,
    actual_macros: Macros,
    target_macros: Macros,
    insights: List(String),
    seven_day_trend: Option(MacroTrend),
  )
}

/// Macro nutrition values
pub type Macros {
  Macros(calories: Float, protein: Float, fat: Float, carbs: Float)
}

/// 7-day rolling average trend
pub type MacroTrend {
  MacroTrend(
    avg_calories: Float,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
  )
}

/// Status of actual vs target macros
pub type MacroStatus {
  Under(deficit: Float)
  OnTrack
  Over(excess: Float)
}

// ============================================================================
// Main Function
// ============================================================================

/// Generate daily advisor email with FatSecret diary analysis
///
/// Parameters:
/// - conn: Database connection
/// - date_int: Date as days since Unix epoch
///
/// Returns:
/// - Ok(AdvisorEmail) with recommendations
/// - Error(String) on failure
pub fn generate_daily_advisor_email(
  conn: pog.Connection,
  date_int: Int,
) -> Result(AdvisorEmail, String) {
  // Fetch today's diary entries
  use entries <- result.try(
    diary_service.get_day_entries(conn, date_int)
    |> result.map_error(fn(e) {
      "Failed to fetch diary entries: " <> diary_service.error_to_message(e)
    }),
  )

  // Fetch user's profile goals
  use profile <- result.try(
    profile_service.get_profile(conn)
    |> result.map_error(fn(e) {
      "Failed to fetch profile: " <> profile_service.error_to_message(e)
    }),
  )

  // Calculate actual macros from entries
  let actual_macros = calculate_total_macros(entries)

  // Extract target macros from profile
  let target_macros = extract_target_macros(profile)

  // Generate insights based on status
  let insights = generate_insight_messages(actual_macros, target_macros)

  // Calculate 7-day trend (optional - fetch last 7 days)
  let seven_day_trend = calculate_seven_day_trend(conn, date_int)

  // Convert date_int to readable date string
  let date = diary_types.int_to_date(date_int)

  Ok(AdvisorEmail(
    date: date,
    actual_macros: actual_macros,
    target_macros: target_macros,
    insights: insights,
    seven_day_trend: seven_day_trend,
  ))
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate total macros from list of food entries
fn calculate_total_macros(entries: List(FoodEntry)) -> Macros {
  list.fold(
    entries,
    Macros(calories: 0.0, protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, entry) {
      Macros(
        calories: acc.calories +. entry.calories,
        protein: acc.protein +. entry.protein,
        fat: acc.fat +. entry.fat,
        carbs: acc.carbs +. entry.carbohydrate,
      )
    },
  )
}

/// Extract target macros from FatSecret profile
///
/// FatSecret profile only has calorie_goal, so we estimate macros using
/// standard ratios: 30% protein, 25% fat, 45% carbs
fn extract_target_macros(profile: profile_types.Profile) -> Macros {
  case profile.calorie_goal {
    Some(cal_goal) -> {
      let calories = int.to_float(cal_goal)
      // Calculate macros from calorie goal using standard ratios
      // Protein: 30% of calories / 4 cal per gram = grams
      // Fat: 25% of calories / 9 cal per gram = grams
      // Carbs: 45% of calories / 4 cal per gram = grams
      let protein = calories *. 0.3 /. 4.0
      let fat = calories *. 0.25 /. 9.0
      let carbs = calories *. 0.45 /. 4.0
      Macros(calories: calories, protein: protein, fat: fat, carbs: carbs)
    }
    None ->
      // Default to 2000 calories if no goal set
      Macros(calories: 2000.0, protein: 150.0, fat: 55.6, carbs: 225.0)
  }
}

/// Calculate macro status (under/on-track/over)
fn calculate_macro_status(actual: Float, target: Float) -> MacroStatus {
  let diff = actual -. target
  let percent_diff = diff /. target *. 100.0

  case percent_diff {
    p if p <. -10.0 -> Under(deficit: float.absolute_value(diff))
    p if p >. 10.0 -> Over(excess: diff)
    _ -> OnTrack
  }
}

/// Generate insight messages based on macro status
fn generate_insight_messages(actual: Macros, target: Macros) -> List(String) {
  let calorie_status = calculate_macro_status(actual.calories, target.calories)
  let protein_status = calculate_macro_status(actual.protein, target.protein)
  let fat_status = calculate_macro_status(actual.fat, target.fat)
  let carbs_status = calculate_macro_status(actual.carbs, target.carbs)

  []
  |> add_insight_if_needed(
    calorie_status,
    "calories",
    "cal",
    "consider a snack",
    "you're over budget",
  )
  |> add_insight_if_needed(
    protein_status,
    "protein",
    "g",
    "add more protein",
    "protein is high",
  )
  |> add_insight_if_needed(
    fat_status,
    "fat",
    "g",
    "add healthy fats",
    "reduce fat intake",
  )
  |> add_insight_if_needed(
    carbs_status,
    "carbs",
    "g",
    "add complex carbs",
    "reduce carbs",
  )
  |> check_if_on_track(calorie_status, protein_status, fat_status, carbs_status)
}

/// Add insight message if macro is not on track
fn add_insight_if_needed(
  insights: List(String),
  status: MacroStatus,
  macro_name: String,
  unit: String,
  under_advice: String,
  over_advice: String,
) -> List(String) {
  case status {
    Under(deficit) -> {
      let msg =
        macro_name
        <> " is "
        <> float_to_string(deficit, 0)
        <> unit
        <> " under target - "
        <> under_advice
      [msg, ..insights]
    }
    Over(excess) -> {
      let msg =
        macro_name
        <> " is "
        <> float_to_string(excess, 0)
        <> unit
        <> " over target - "
        <> over_advice
      [msg, ..insights]
    }
    OnTrack -> insights
  }
}

/// Add "on track" message if all macros are within range
fn check_if_on_track(
  insights: List(String),
  cal_status: MacroStatus,
  prot_status: MacroStatus,
  fat_status: MacroStatus,
  carb_status: MacroStatus,
) -> List(String) {
  case insights {
    [] ->
      // All macros on track
      case cal_status, prot_status, fat_status, carb_status {
        OnTrack, OnTrack, OnTrack, OnTrack -> [
          "Great job! All macros are on track.",
        ]
        _, _, _, _ -> insights
      }
    _ -> insights
  }
}

/// Calculate 7-day rolling average trend
///
/// Fetches diary entries for the past 7 days and calculates average macros.
/// Returns None if unable to fetch data for all 7 days.
fn calculate_seven_day_trend(
  conn: pog.Connection,
  current_date_int: Int,
) -> Option(MacroTrend) {
  // Fetch entries for past 7 days (including today)
  let dates = list.range(current_date_int - 6, current_date_int)

  // Attempt to fetch all days
  let all_entries =
    list.try_map(dates, fn(date_int) {
      diary_service.get_day_entries(conn, date_int)
    })

  case all_entries {
    Ok(entries_by_day) -> {
      // Flatten all entries
      let all_entries = list.flatten(entries_by_day)

      // Calculate total macros
      let total = calculate_total_macros(all_entries)

      // Average over 7 days
      Some(MacroTrend(
        avg_calories: total.calories /. 7.0,
        avg_protein: total.protein /. 7.0,
        avg_fat: total.fat /. 7.0,
        avg_carbs: total.carbs /. 7.0,
      ))
    }
    Error(_) -> None
  }
}

/// Format float to string with specified decimals
fn float_to_string(value: Float, decimals: Int) -> String {
  case decimals {
    0 -> {
      let rounded = float.round(value)
      int.to_string(rounded)
    }
    1 -> {
      let multiplied = value *. 10.0
      let rounded_int = float.round(multiplied)
      let int_val = float.truncate(int.to_float(rounded_int))
      let whole = int_val / 10
      let decimal = int_val % 10
      int.to_string(whole) <> "." <> int.to_string(decimal)
    }
    _ -> float.to_string(value)
  }
}
