/// Nutrition Dashboard Page Component
///
/// This page component displays a comprehensive nutrition dashboard showing:
/// - Daily calorie intake vs target
/// - Macro progress (protein, fat, carbs)
/// - Daily meal log timeline
/// - Date navigation
/// - Quick stats and actions
///
/// Responsive layout:
/// - Mobile (320px): Single column, stacked
/// - Tablet (768px): Two-column with flexible layout
/// - Desktop (1024px): Three-column with full features
///
/// See: docs/UI_REQUIREMENTS_ANALYSIS.md (Bead 3)
/// See: docs/component_signatures.md (Dashboard Page)
import meal_planner/ui/components/card
import meal_planner/ui/components/daily_log
import meal_planner/ui/components/layout
import meal_planner/ui/components/progress
import meal_planner/ui/types/ui_types

/// Dashboard data structure
///
/// Contains all data needed to render the dashboard:
/// - User profile and targets
/// - Daily log with meals and macros
/// - Selected date for viewing
pub type DashboardData {
  DashboardData(
    profile_id: String,
    daily_calories_current: Float,
    daily_calories_target: Float,
    protein_current: Float,
    protein_target: Float,
    fat_current: Float,
    fat_target: Float,
    carbs_current: Float,
    carbs_target: Float,
    date: String,
    meal_entries: List(ui_types.MealEntryData),
  )
}

/// Render the complete nutrition dashboard
///
/// Returns HTML for the full dashboard including:
/// - Page header with date navigation
/// - Calorie summary card with animated numbers
/// - Macro progress bars
/// - Daily log entries list
/// - Quick action buttons
pub fn render_dashboard(data: DashboardData) -> String {
  // Calorie summary card
  let calorie_card =
    card.calorie_summary_card(
      data.daily_calories_current,
      data.daily_calories_target,
      data.date,
    )

  // Macro progress bars
  let protein_bar =
    progress.macro_bar("Protein", data.protein_current, data.protein_target, "macro-protein")
  let fat_bar =
    progress.macro_bar("Fat", data.fat_current, data.fat_target, "macro-fat")
  let carbs_bar =
    progress.macro_bar("Carbs", data.carbs_current, data.carbs_target, "macro-carbs")

  // Daily log timeline
  let timeline = daily_log.daily_log_timeline(data.meal_entries)

  // Build layout
  layout.container(1200, [
    layout.section([
      card.card_with_header("Daily Summary", [calorie_card]),
    ]),
    layout.section([
      card.card_with_header("Macros", [protein_bar, fat_bar, carbs_bar]),
    ]),
    layout.section([
      card.card_with_header("Daily Log", [timeline]),
    ]),
  ])
}
