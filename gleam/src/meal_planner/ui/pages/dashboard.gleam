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
import lustre/attribute.{attribute, class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h1, h2, main, section}
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
/// - Page header with date navigation (h1)
/// - Calorie summary card with animated numbers (section)
/// - Macro progress bars (section with h2)
/// - Daily log entries list (section with h2)
/// - Quick action buttons
/// - Filter controls for meal types
/// - HTMX handles all interactivity
///
/// Accessibility features:
/// - Proper heading hierarchy (h1 -> h2)
/// - Semantic HTML5 elements (main, section, article)
/// - ARIA landmarks and labels
/// - Live region for filter announcements
pub fn render_dashboard(data: DashboardData) -> Element(msg) {
  // Page title for screen readers
  let page_title =
    h1([class("sr-only")], [
      text("Nutrition Dashboard for " <> data.date),
    ])

  // Calorie summary card
  let calorie_card =
    card.calorie_summary_card(
      data.daily_calories_current,
      data.daily_calories_target,
      data.date,
    )

  // Macro progress bars
  let protein_bar =
    progress.macro_bar(
      "Protein",
      data.protein_current,
      data.protein_target,
      "macro-protein",
    )
  let fat_bar =
    progress.macro_bar("Fat", data.fat_current, data.fat_target, "macro-fat")
  let carbs_bar =
    progress.macro_bar(
      "Carbs",
      data.carbs_current,
      data.carbs_target,
      "macro-carbs",
    )

  // Filter controls for meal log
  let filter_controls = render_filter_controls()

  // Daily log timeline
  let timeline = daily_log.daily_log_timeline(data.meal_entries)

  // Build layout with proper ARIA landmarks
  main(
    [attribute("role", "main"), attribute("aria-label", "Nutrition Dashboard")],
    [
      page_title,
      layout.container(1200, [
        section([attribute("aria-labelledby", "daily-summary-heading")], [
          h2([id("daily-summary-heading"), class("section-header")], [
            text("Daily Summary"),
          ]),
          calorie_card,
        ]),
        section([attribute("aria-labelledby", "macros-heading")], [
          h2([id("macros-heading"), class("section-header")], [
            text("Macronutrients"),
          ]),
          protein_bar,
          fat_bar,
          carbs_bar,
        ]),
        section([attribute("aria-labelledby", "daily-log-heading")], [
          h2([id("daily-log-heading"), class("section-header")], [
            text("Daily Log"),
          ]),
          filter_controls,
          timeline,
        ]),
      ]),
    ],
  )
}

/// Render filter controls for meal log
///
/// Provides client-side filtering by meal type using HTMX:
/// - All meals (default)
/// - Breakfast only
/// - Lunch only
/// - Dinner only
/// - Snacks only
fn render_filter_controls() -> Element(msg) {
  div(
    [
      class("meal-filters"),
      attribute("role", "group"),
      attribute("aria-label", "Filter meals by type"),
    ],
    [
      div([class("filter-buttons")], [
        button(
          [
            class("filter-btn active"),
            attribute("data-filter-meal-type", "all"),
            attribute("aria-pressed", "true"),
          ],
          [text("All")],
        ),
        button(
          [
            class("filter-btn"),
            attribute("data-filter-meal-type", "breakfast"),
            attribute("aria-pressed", "false"),
          ],
          [text("Breakfast")],
        ),
        button(
          [
            class("filter-btn"),
            attribute("data-filter-meal-type", "lunch"),
            attribute("aria-pressed", "false"),
          ],
          [text("Lunch")],
        ),
        button(
          [
            class("filter-btn"),
            attribute("data-filter-meal-type", "dinner"),
            attribute("aria-pressed", "false"),
          ],
          [text("Dinner")],
        ),
        button(
          [
            class("filter-btn"),
            attribute("data-filter-meal-type", "snack"),
            attribute("aria-pressed", "false"),
          ],
          [text("Snack")],
        ),
      ]),
      div(
        [
          id("filter-results-summary"),
          class("filter-summary"),
          attribute("aria-live", "polite"),
        ],
        [],
      ),
      div(
        [
          id("filter-announcement"),
          class("sr-only"),
          attribute("role", "status"),
          attribute("aria-live", "assertive"),
          attribute("aria-atomic", "true"),
        ],
        [],
      ),
    ],
  )
}
