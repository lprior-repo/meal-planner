/// Macro Summary Panel Components
///
/// This module provides components for displaying macro nutrition summaries:
/// - Daily macro totals (protein, fat, carbs, calories)
/// - Target comparison with percentages
/// - Visual progress bars
/// - Color coding (under/on-target/over)
/// - Weekly averages and trends
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: Bead meal-planner-tkm2
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h3, span}
import meal_planner/types.{type DailyLog, type Macros}

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Macro targets for daily intake goals
pub type MacroTargets {
  MacroTargets(protein: Float, fat: Float, carbs: Float, calories: Float)
}

/// Daily macro summary with totals and comparison to targets
pub type DailyMacroSummary {
  DailyMacroSummary(
    date: String,
    totals: Macros,
    calories: Float,
    targets: MacroTargets,
    protein_percentage: Float,
    fat_percentage: Float,
    carbs_percentage: Float,
    calories_percentage: Float,
  )
}

/// Weekly macro summary with daily summaries and averages
pub type WeeklyMacroSummary {
  WeeklyMacroSummary(
    daily_summaries: List(DailyMacroSummary),
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
    avg_calories: Float,
  )
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Calculate percentage of target (0-150% capped for display)
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> {
      let pct = current /. target *. 100.0
      // Cap at 150% for visual consistency
      case pct >. 150.0 {
        True -> 150.0
        False -> pct
      }
    }
    False -> 0.0
  }
}

/// Determine color class based on percentage relative to target
/// - Under (< 90%): yellow (deficiency warning)
/// - On target (90-110%): green
/// - Over (> 110%): orange/red
fn get_target_color(percentage: Float) -> String {
  case percentage {
    p if p <. 90.0 -> "status-under"
    p if p <=. 110.0 -> "status-on-target"
    p if p <=. 130.0 -> "status-over"
    _ -> "status-excess"
  }
}

/// Create daily macro summary from daily log and targets
pub fn create_daily_summary(
  log: DailyLog,
  targets: MacroTargets,
) -> DailyMacroSummary {
  let totals = log.total_macros
  let calories = types.macros_calories(totals)

  DailyMacroSummary(
    date: log.date,
    totals: totals,
    calories: calories,
    targets: targets,
    protein_percentage: calculate_percentage(totals.protein, targets.protein),
    fat_percentage: calculate_percentage(totals.fat, targets.fat),
    carbs_percentage: calculate_percentage(totals.carbs, targets.carbs),
    calories_percentage: calculate_percentage(calories, targets.calories),
  )
}

/// Create weekly summary from list of daily logs
pub fn create_weekly_summary(
  logs: List(DailyLog),
  targets: MacroTargets,
) -> WeeklyMacroSummary {
  let daily_summaries =
    logs
    |> list.map(fn(log) { create_daily_summary(log, targets) })

  let day_count = list.length(logs) |> int.to_float

  // Calculate averages
  let avg_protein = case day_count >. 0.0 {
    True -> {
      let total =
        daily_summaries
        |> list.fold(0.0, fn(sum, s) { sum +. s.totals.protein })
      total /. day_count
    }
    False -> 0.0
  }

  let avg_fat = case day_count >. 0.0 {
    True -> {
      let total =
        daily_summaries
        |> list.fold(0.0, fn(sum, s) { sum +. s.totals.fat })
      total /. day_count
    }
    False -> 0.0
  }

  let avg_carbs = case day_count >. 0.0 {
    True -> {
      let total =
        daily_summaries
        |> list.fold(0.0, fn(sum, s) { sum +. s.totals.carbs })
      total /. day_count
    }
    False -> 0.0
  }

  let avg_calories = case day_count >. 0.0 {
    True -> {
      let total =
        daily_summaries
        |> list.fold(0.0, fn(sum, s) { sum +. s.calories })
      total /. day_count
    }
    False -> 0.0
  }

  WeeklyMacroSummary(
    daily_summaries: daily_summaries,
    avg_protein: avg_protein,
    avg_fat: avg_fat,
    avg_carbs: avg_carbs,
    avg_calories: avg_calories,
  )
}

// ===================================================================
// COMPONENT RENDERING
// ===================================================================

/// Render a single macro progress bar with label and target comparison
///
/// Displays:
/// - Macro name (Protein, Fat, Carbs)
/// - Current value / Target value
/// - Visual progress bar with color coding
/// - Percentage of target
fn macro_progress_bar(
  label: String,
  current: Float,
  target: Float,
  percentage: Float,
) -> Element(msg) {
  let current_int = float.truncate(current)
  let target_int = float.truncate(target)
  let pct_int = float.truncate(percentage)

  let current_str = int.to_string(current_int)
  let target_str = int.to_string(target_int)
  let pct_str = int.to_string(pct_int)

  let color_class = get_target_color(percentage)

  // Calculate visual width (cap at 100% for display)
  let visual_percentage = case percentage >. 100.0 {
    True -> 100.0
    False -> percentage
  }
  let width_str = int.to_string(float.truncate(visual_percentage))

  div([class("macro-progress-bar " <> color_class)], [
    div([class("macro-header")], [
      span([class("macro-label")], [text(label)]),
      span([class("macro-values")], [
        text(current_str <> "g / " <> target_str <> "g"),
      ]),
    ]),
    div(
      [
        class("progress-bar"),
        attribute("role", "progressbar"),
        attribute("aria-valuenow", pct_str),
        attribute("aria-valuemin", "0"),
        attribute("aria-valuemax", "100"),
        attribute(
          "aria-label",
          label <> ": " <> current_str <> " of " <> target_str <> " grams, "
            <> pct_str
            <> " percent",
        ),
      ],
      [
        div(
          [
            class("progress-fill"),
            attribute("style", "width: " <> width_str <> "%"),
          ],
          [],
        ),
      ],
    ),
    div([class("macro-percentage")], [text(pct_str <> "%")]),
  ])
}

/// Render calories progress bar (similar to macros but shows kcal)
fn calories_progress_bar(
  current: Float,
  target: Float,
  percentage: Float,
) -> Element(msg) {
  let current_int = float.truncate(current)
  let target_int = float.truncate(target)
  let pct_int = float.truncate(percentage)

  let current_str = int.to_string(current_int)
  let target_str = int.to_string(target_int)
  let pct_str = int.to_string(pct_int)

  let color_class = get_target_color(percentage)

  let visual_percentage = case percentage >. 100.0 {
    True -> 100.0
    False -> percentage
  }
  let width_str = int.to_string(float.truncate(visual_percentage))

  div([class("macro-progress-bar calories " <> color_class)], [
    div([class("macro-header")], [
      span([class("macro-label")], [text("Calories")]),
      span([class("macro-values")], [
        text(current_str <> " / " <> target_str <> " kcal"),
      ]),
    ]),
    div(
      [
        class("progress-bar"),
        attribute("role", "progressbar"),
        attribute("aria-valuenow", pct_str),
        attribute("aria-valuemin", "0"),
        attribute("aria-valuemax", "100"),
        attribute(
          "aria-label",
          "Calories: " <> current_str <> " of " <> target_str <> " kilocalories, "
            <> pct_str
            <> " percent",
        ),
      ],
      [
        div(
          [
            class("progress-fill"),
            attribute("style", "width: " <> width_str <> "%"),
          ],
          [],
        ),
      ],
    ),
    div([class("macro-percentage")], [text(pct_str <> "%")]),
  ])
}

/// Render daily macro summary panel
///
/// Displays:
/// - Date header
/// - Progress bars for protein, fat, carbs
/// - Calories progress bar
/// - Color-coded status indicators
pub fn daily_macro_summary_panel(summary: DailyMacroSummary) -> Element(msg) {
  div([class("macro-summary-panel daily")], [
    div([class("summary-header")], [
      h3([class("summary-title")], [text("Daily Macros")]),
      span([class("summary-date")], [text(summary.date)]),
    ]),
    div([class("summary-body")], [
      macro_progress_bar(
        "Protein",
        summary.totals.protein,
        summary.targets.protein,
        summary.protein_percentage,
      ),
      macro_progress_bar(
        "Fat",
        summary.totals.fat,
        summary.targets.fat,
        summary.fat_percentage,
      ),
      macro_progress_bar(
        "Carbs",
        summary.totals.carbs,
        summary.targets.carbs,
        summary.carbs_percentage,
      ),
      calories_progress_bar(
        summary.calories,
        summary.targets.calories,
        summary.calories_percentage,
      ),
    ]),
  ])
}

/// Render weekly average macro summary
///
/// Displays:
/// - Week summary header
/// - Average values vs targets for protein, fat, carbs
/// - Average calories vs target
/// - Overall weekly performance
pub fn weekly_macro_summary_panel(summary: WeeklyMacroSummary) -> Element(msg) {
  // Calculate average percentages
  let targets = case list.first(summary.daily_summaries) {
    Ok(first) -> first.targets
    Error(_) ->
      MacroTargets(protein: 150.0, fat: 60.0, carbs: 200.0, calories: 2000.0)
  }

  let avg_protein_pct = calculate_percentage(summary.avg_protein, targets.protein)
  let avg_fat_pct = calculate_percentage(summary.avg_fat, targets.fat)
  let avg_carbs_pct = calculate_percentage(summary.avg_carbs, targets.carbs)
  let avg_calories_pct =
    calculate_percentage(summary.avg_calories, targets.calories)

  div([class("macro-summary-panel weekly")], [
    div([class("summary-header")], [
      h3([class("summary-title")], [text("Weekly Average")]),
      span([class("summary-subtitle")], [
        text(int.to_string(list.length(summary.daily_summaries)) <> " days"),
      ]),
    ]),
    div([class("summary-body")], [
      macro_progress_bar(
        "Avg Protein",
        summary.avg_protein,
        targets.protein,
        avg_protein_pct,
      ),
      macro_progress_bar(
        "Avg Fat",
        summary.avg_fat,
        targets.fat,
        avg_fat_pct,
      ),
      macro_progress_bar(
        "Avg Carbs",
        summary.avg_carbs,
        targets.carbs,
        avg_carbs_pct,
      ),
      calories_progress_bar(
        summary.avg_calories,
        targets.calories,
        avg_calories_pct,
      ),
    ]),
  ])
}

/// Compact macro summary badge (for cards)
///
/// Displays:
/// - P/F/C values in compact format
/// - Colored status indicator
pub fn macro_summary_badge(totals: Macros, targets: MacroTargets) -> Element(msg) {
  let protein_pct = calculate_percentage(totals.protein, targets.protein)
  let fat_pct = calculate_percentage(totals.fat, targets.fat)
  let carbs_pct = calculate_percentage(totals.carbs, targets.carbs)

  // Overall status based on average percentage
  let avg_pct = { protein_pct +. fat_pct +. carbs_pct } /. 3.0
  let status_class = get_target_color(avg_pct)

  let p_str = int.to_string(float.truncate(totals.protein))
  let f_str = int.to_string(float.truncate(totals.fat))
  let c_str = int.to_string(float.truncate(totals.carbs))

  div([class("macro-badge " <> status_class)], [
    span([class("macro-item protein")], [text("P:" <> p_str)]),
    span([class("macro-item fat")], [text("F:" <> f_str)]),
    span([class("macro-item carbs")], [text("C:" <> c_str)]),
  ])
}
