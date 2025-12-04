/// Dashboard UI Components Module
///
/// This module provides the main dashboard UI components showing today's nutrition summary:
/// - Daily macro totals (protein/fat/carbs/calories)
/// - Progress bars for each macro vs goals
/// - Recent food log entries (last 5)
/// - Quick actions (Log Food, View Weekly Plan)
/// - HTMX integration for live updates
///
/// Features:
/// - Auto-refresh totals every 30s: `hx-get="/api/dashboard/totals" hx-trigger="every 30s"`
/// - Live log updates with `hx-swap-oob="true"` for new entries
/// - HTMX-powered interactions (NO JavaScript files)
/// - Server-side rendered with Gleam + Lustre
///
/// See: Task requirement for Dashboard UI Components
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h2, h3, section, span}
import meal_planner/types.{type FoodLogEntry, type Macros, type UserProfile}
import meal_planner/ui/components/button
import meal_planner/ui/components/card
import meal_planner/ui/components/food_log_entry_card
import meal_planner/ui/components/macro_summary
import meal_planner/ui/components/progress
import meal_planner/ui/types/ui_types

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Dashboard data structure containing all information needed for the dashboard
pub type DashboardData {
  DashboardData(
    date: String,
    macros: Macros,
    goals: Macros,
    recent_entries: List(FoodLogEntry),
    profile: UserProfile,
  )
}

// ===================================================================
// MAIN DASHBOARD COMPONENT
// ===================================================================

/// Render the complete dashboard component
///
/// Displays:
/// - Date header with current date
/// - Daily macro summary panel (today's totals vs goals)
/// - Progress bars for each macro (protein, fat, carbs, calories)
/// - Recent food log entries (last 5 with HTMX refresh)
/// - Quick action buttons (Log Food, View Weekly Plan)
///
/// HTMX Integration:
/// - Auto-refresh totals: `hx-get="/api/dashboard/totals" hx-trigger="every 30s"`
/// - Live log updates: New entries use `hx-swap-oob="true"` to update in place
/// - Quick actions: Navigate with `hx-get` for smooth transitions
///
/// Example:
/// ```gleam
/// let data = DashboardData(
///   date: "2025-12-04",
///   macros: Macros(protein: 120.0, fat: 65.0, carbs: 250.0),
///   goals: Macros(protein: 150.0, fat: 70.0, carbs: 300.0),
///   recent_entries: [...],
///   profile: profile,
/// )
/// render_dashboard(data)
/// ```
pub fn render_dashboard(data: DashboardData) -> Element(msg) {
  let targets =
    macro_summary.MacroTargets(
      protein: data.goals.protein,
      fat: data.goals.fat,
      carbs: data.goals.carbs,
      calories: types.macros_calories(data.goals),
    )

  let summary =
    macro_summary.DailyMacroSummary(
      date: data.date,
      totals: data.macros,
      calories: types.macros_calories(data.macros),
      targets: targets,
      protein_percentage: calculate_percentage(
        data.macros.protein,
        data.goals.protein,
      ),
      fat_percentage: calculate_percentage(data.macros.fat, data.goals.fat),
      carbs_percentage: calculate_percentage(
        data.macros.carbs,
        data.goals.carbs,
      ),
      calories_percentage: calculate_percentage(
        types.macros_calories(data.macros),
        types.macros_calories(data.goals),
      ),
    )

  div([class("dashboard-container")], [
    render_date_header(data.date),
    render_macro_summary_section(summary),
    render_recent_entries_section(data.recent_entries),
    render_quick_actions(),
  ])
}

// ===================================================================
// SECTION COMPONENTS
// ===================================================================

/// Render date header with current date
///
/// Displays:
/// - Today's Date: December 4, 2025
/// - Styled header with prominent display
fn render_date_header(date: String) -> Element(msg) {
  div([class("dashboard-header")], [
    h2([class("dashboard-date")], [text("Today: " <> date)]),
  ])
}

/// Render macro summary section with progress bars
///
/// Displays:
/// - Section title: "Daily Macros"
/// - Protein progress bar (current / target)
/// - Fat progress bar (current / target)
/// - Carbs progress bar (current / target)
/// - Calories progress bar (current / target)
///
/// HTMX: This section auto-refreshes every 30s
/// - Container has: hx-get="/api/dashboard/totals" hx-trigger="every 30s"
/// - Server returns updated macro values
fn render_macro_summary_section(
  summary: macro_summary.DailyMacroSummary,
) -> Element(msg) {
  section(
    [
      class("dashboard-section macro-summary-section"),
      attribute("id", "macro-summary"),
      attribute("hx-get", "/api/dashboard/totals"),
      attribute("hx-trigger", "every 30s"),
      attribute("hx-swap", "innerHTML"),
      attribute("hx-target", "#macro-summary-content"),
    ],
    [
      h3([class("section-title")], [text("Daily Macros")]),
      div([attribute("id", "macro-summary-content")], [
        macro_summary_content(summary),
      ]),
    ],
  )
}

/// Render the actual macro summary content (for HTMX updates)
fn macro_summary_content(
  summary: macro_summary.DailyMacroSummary,
) -> Element(msg) {
  let protein_current = float.truncate(summary.totals.protein)
  let protein_target = float.truncate(summary.targets.protein)
  let fat_current = float.truncate(summary.totals.fat)
  let fat_target = float.truncate(summary.targets.fat)
  let carbs_current = float.truncate(summary.totals.carbs)
  let carbs_target = float.truncate(summary.targets.carbs)
  let calories_current = float.truncate(summary.calories)
  let calories_target = float.truncate(summary.targets.calories)

  div([class("macro-progress-container")], [
    // Protein
    progress.macro_bar(
      "Protein",
      summary.totals.protein,
      summary.targets.protein,
      "macro-protein",
    ),
    div([class("macro-details")], [
      text(
        int.to_string(protein_current)
        <> "g / "
        <> int.to_string(protein_target)
        <> "g ("
        <> int.to_string(float.truncate(summary.protein_percentage))
        <> "%)",
      ),
    ]),
    // Fat
    progress.macro_bar(
      "Fat",
      summary.totals.fat,
      summary.targets.fat,
      "macro-fat",
    ),
    div([class("macro-details")], [
      text(
        int.to_string(fat_current)
        <> "g / "
        <> int.to_string(fat_target)
        <> "g ("
        <> int.to_string(float.truncate(summary.fat_percentage))
        <> "%)",
      ),
    ]),
    // Carbs
    progress.macro_bar(
      "Carbs",
      summary.totals.carbs,
      summary.targets.carbs,
      "macro-carbs",
    ),
    div([class("macro-details")], [
      text(
        int.to_string(carbs_current)
        <> "g / "
        <> int.to_string(carbs_target)
        <> "g ("
        <> int.to_string(float.truncate(summary.carbs_percentage))
        <> "%)",
      ),
    ]),
    // Calories
    card.calorie_summary_card(
      summary.calories,
      summary.targets.calories,
      summary.date,
    ),
    div([class("macro-details")], [
      text(
        int.to_string(calories_current)
        <> " / "
        <> int.to_string(calories_target)
        <> " kcal ("
        <> int.to_string(float.truncate(summary.calories_percentage))
        <> "%)",
      ),
    ]),
  ])
}

/// Render recent food log entries section
///
/// Displays:
/// - Section title: "Recent Entries"
/// - Last 5 food log entries with edit/delete controls
/// - Empty state if no entries
///
/// HTMX: This section updates when new entries are added
/// - New entries use hx-swap-oob="true" to prepend to list
/// - Container has id="recent-entries-list" for targeting
fn render_recent_entries_section(entries: List(FoodLogEntry)) -> Element(msg) {
  section([class("dashboard-section recent-entries-section")], [
    h3([class("section-title")], [text("Recent Entries")]),
    case entries {
      [] -> render_empty_entries()
      entries -> render_entries_list(entries)
    },
  ])
}

/// Render empty state for food log entries
fn render_empty_entries() -> Element(msg) {
  div([class("empty-state")], [
    div([class("empty-icon")], [text("📝")]),
    div([class("empty-message")], [text("No entries logged today")]),
    button.button("Log Your First Meal", "/foods/search", ui_types.Primary),
  ])
}

/// Render list of food log entry cards
///
/// Takes last 5 entries and renders them as cards with:
/// - Food name and portion
/// - Macro breakdown
/// - Edit/delete buttons with HTMX
fn render_entries_list(entries: List(FoodLogEntry)) -> Element(msg) {
  let recent_five = list.take(entries, 5)
  let cards =
    recent_five
    |> list.map(food_log_entry_to_card)
    |> list.map(food_log_entry_card.render_log_entry_card)

  div(
    [
      class("recent-entries-list"),
      attribute("id", "recent-entries-list"),
      attribute("hx-swap-oob", "true"),
    ],
    cards,
  )
}

/// Convert FoodLogEntry to LogEntryCard for rendering
fn food_log_entry_to_card(entry: FoodLogEntry) -> ui_types.LogEntryCard {
  let meal_type_str = types.meal_type_to_string(entry.meal_type)
  let calories = types.macros_calories(entry.macros)

  ui_types.LogEntryCard(
    entry_id: entry.id,
    food_name: entry.recipe_name,
    portion: entry.servings,
    unit: "serving",
    protein: entry.macros.protein,
    fat: entry.macros.fat,
    carbs: entry.macros.carbs,
    calories: calories,
    meal_type: meal_type_str,
    logged_at: entry.logged_at,
  )
}

/// Render quick action buttons
///
/// Displays:
/// - Log Food button (navigates to food search)
/// - View Weekly Plan button (navigates to weekly view)
///
/// HTMX: Uses hx-get for smooth navigation
fn render_quick_actions() -> Element(msg) {
  section([class("dashboard-section quick-actions-section")], [
    h3([class("section-title")], [text("Quick Actions")]),
    div([class("quick-actions-container")], [
      button(
        [
          class("btn btn-primary btn-lg"),
          attribute("hx-get", "/foods/search"),
          attribute("hx-push-url", "true"),
          attribute("hx-target", "#main-content"),
          attribute("hx-swap", "innerHTML"),
        ],
        [
          span([class("btn-icon")], [text("🍽️")]),
          span([class("btn-text")], [text("Log Food")]),
        ],
      ),
      button(
        [
          class("btn btn-secondary btn-lg"),
          attribute("hx-get", "/weekly-plan"),
          attribute("hx-push-url", "true"),
          attribute("hx-target", "#main-content"),
          attribute("hx-swap", "innerHTML"),
        ],
        [
          span([class("btn-icon")], [text("📅")]),
          span([class("btn-text")], [text("View Weekly Plan")]),
        ],
      ),
    ]),
  ])
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Calculate percentage of current value vs target
/// Returns 0-100, capped at 100 for display purposes
fn calculate_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> {
      let pct = current /. target *. 100.0
      case pct >. 100.0 {
        True -> 100.0
        False -> pct
      }
    }
    False -> 0.0
  }
}

// ===================================================================
// LEGACY COMPATIBILITY (for old string-based rendering)
// ===================================================================

/// Legacy progress bar function for backward compatibility
///
/// NOTE: This is deprecated. Use the new Lustre-based `render_dashboard`
/// function for modern HTMX-powered dashboards.
///
/// Returns raw HTML string for progress bar
pub fn progress_bar(current: Int, target: Int) -> String {
  let percent = int.to_string(current * 100 / target)
  "<div class=\"w-full bg-gray-200 rounded\">"
  <> "<div class=\"bg-green-500 h-2 rounded\" style=\"width: "
  <> percent
  <> "%\"></div>"
  <> "</div>"
}

// ===================================================================
// ALTERNATE LAYOUTS (Optional)
// ===================================================================

/// Render compact dashboard for mobile views
///
/// Similar to full dashboard but with:
/// - Smaller cards
/// - Stacked layout
/// - Abbreviated labels
pub fn render_dashboard_compact(data: DashboardData) -> Element(msg) {
  let targets =
    macro_summary.MacroTargets(
      protein: data.goals.protein,
      fat: data.goals.fat,
      carbs: data.goals.carbs,
      calories: types.macros_calories(data.goals),
    )

  div([class("dashboard-container dashboard-compact")], [
    div([class("compact-header")], [text(data.date)]),
    // Macro badges instead of progress bars
    macro_summary.macro_summary_badge(data.macros, targets),
    // Compact recent entries (3 max)
    render_compact_recent_entries(list.take(data.recent_entries, 3)),
    // Quick actions
    render_quick_actions(),
  ])
}

/// Render compact recent entries (for mobile)
fn render_compact_recent_entries(entries: List(FoodLogEntry)) -> Element(msg) {
  let cards =
    entries
    |> list.map(food_log_entry_to_card)
    |> list.map(food_log_entry_card.render_log_entry_card_compact)

  div([class("compact-entries-list")], cards)
}

// ===================================================================
// HTMX PARTIAL UPDATES (Server-side rendering helpers)
// ===================================================================

/// Render only macro summary content for HTMX partial updates
///
/// This function is called by the server when handling:
/// GET /api/dashboard/totals (triggered every 30s)
///
/// Returns just the macro progress bars and values without wrapping section
pub fn render_macro_summary_partial(
  macros: Macros,
  goals: Macros,
  date: String,
) -> Element(msg) {
  let targets =
    macro_summary.MacroTargets(
      protein: goals.protein,
      fat: goals.fat,
      carbs: goals.carbs,
      calories: types.macros_calories(goals),
    )

  let summary =
    macro_summary.DailyMacroSummary(
      date: date,
      totals: macros,
      calories: types.macros_calories(macros),
      targets: targets,
      protein_percentage: calculate_percentage(macros.protein, goals.protein),
      fat_percentage: calculate_percentage(macros.fat, goals.fat),
      carbs_percentage: calculate_percentage(macros.carbs, goals.carbs),
      calories_percentage: calculate_percentage(
        types.macros_calories(macros),
        types.macros_calories(goals),
      ),
    )

  macro_summary_content(summary)
}

/// Render single new log entry for HTMX out-of-band swap
///
/// This function is called when a new food entry is logged:
/// POST /api/logs (returns new entry with hx-swap-oob)
///
/// Returns entry card with hx-swap-oob="afterbegin:#recent-entries-list"
pub fn render_new_entry_oob(entry: FoodLogEntry) -> Element(msg) {
  let card = food_log_entry_to_card(entry)

  div(
    [
      attribute("hx-swap-oob", "afterbegin:#recent-entries-list"),
      attribute("id", "log-" <> entry.id),
    ],
    [food_log_entry_card.render_log_entry_card(card)],
  )
}
