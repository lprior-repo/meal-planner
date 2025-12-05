/// Food Log Page Component
///
/// This page component displays a daily food log with:
/// - Date navigation (previous/next day)
/// - List of food log entries for the selected date
/// - Add entry button (opens modal/form via HTMX)
/// - Real-time updates via HTMX polling
/// - Edit/delete actions on individual entries
///
/// Responsive layout:
/// - Mobile (320px): Single column, stacked cards
/// - Tablet (768px): Two-column with flexible layout
/// - Desktop (1024px): Three-column grid
///
/// HTMX Integration:
/// - Date navigation: hx-get="/logs?date={date}" hx-push-url="true"
/// - Add entry: hx-get="/logs/new" hx-target="#modal-container"
/// - Auto-refresh: hx-get="/logs/entries?date={date}" hx-trigger="every 30s"
/// - Edit/delete: Handled by individual card components
///
/// See: Bead meal-planner-51y
/// See: food_log_entry_card.gleam for card components
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{attribute, class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h1, h2, main, section}
import meal_planner/ui/components/food_log_entry_card
import meal_planner/ui/components/layout
import meal_planner/ui/types/ui_types

// ===================================================================
// PAGE DATA TYPES
// ===================================================================

/// Food log page data structure
///
/// Contains all data needed to render the food log page:
/// - Selected date for viewing
/// - List of log entries for that date
/// - Total calories and macros for the day
pub type FoodLogPageData {
  FoodLogPageData(
    date: String,
    entries: List(ui_types.LogEntryCard),
    total_calories: Float,
    total_protein: Float,
    total_fat: Float,
    total_carbs: Float,
  )
}

// ===================================================================
// MAIN PAGE RENDERER
// ===================================================================

/// Render the complete food log page
///
/// Returns HTML for the full page including:
/// - Page header with date and totals (h1)
/// - Date navigation buttons (previous/next)
/// - Add entry button (opens modal via HTMX)
/// - List of food log entries (auto-refreshing)
/// - Empty state when no entries exist
///
/// HTMX handles all interactivity:
/// - Date navigation updates URL and content
/// - Add button opens modal form
/// - Entry list auto-refreshes every 30s
/// - Individual cards handle edit/delete
///
/// Accessibility features:
/// - Proper heading hierarchy (h1 -> h2)
/// - Semantic HTML5 elements (main, section, nav)
/// - ARIA landmarks and labels
/// - Keyboard navigation support
pub fn render_food_log_page(data: FoodLogPageData) -> Element(msg) {
  // Page title
  let page_title = h1([class("page-title")], [text("Food Log - " <> data.date)])

  // Date navigation
  let date_nav = render_date_navigation(data.date)

  // Daily totals summary
  let totals_summary =
    render_daily_totals(
      data.total_calories,
      data.total_protein,
      data.total_fat,
      data.total_carbs,
    )

  // Add entry button
  let add_button = render_add_entry_button()

  // Food log entries list
  let entries_section = render_entries_section(data.date, data.entries)

  // Modal container for add/edit forms
  let modal_container = div([id("modal-container"), class("modal-root")], [])

  // Build layout with proper ARIA landmarks
  main([attribute("role", "main"), attribute("aria-label", "Food Log")], [
    layout.container(1200, [
      page_title,
      date_nav,
      totals_summary,
      add_button,
      entries_section,
      modal_container,
    ]),
  ])
}

// ===================================================================
// DATE NAVIGATION COMPONENT
// ===================================================================

/// Render date navigation controls
///
/// Provides previous/next day navigation using HTMX:
/// - Previous button: hx-get="/logs?date={prev_date}"
/// - Next button: hx-get="/logs?date={next_date}"
/// - Updates URL with hx-push-url="true"
/// - Replaces entire main content area
///
/// Note: Date math is handled server-side
fn render_date_navigation(current_date: String) -> Element(msg) {
  div(
    [
      class("date-navigation"),
      attribute("role", "navigation"),
      attribute("aria-label", "Date navigation"),
    ],
    [
      button(
        [
          class("btn btn-secondary nav-prev"),
          attribute("hx-get", "/logs?date=prev&current=" <> current_date),
          attribute("hx-target", "main"),
          attribute("hx-swap", "innerHTML"),
          attribute("hx-push-url", "true"),
          attribute("aria-label", "Previous day"),
        ],
        [text("← Previous Day")],
      ),
      div([class("current-date")], [text(current_date)]),
      button(
        [
          class("btn btn-secondary nav-next"),
          attribute("hx-get", "/logs?date=next&current=" <> current_date),
          attribute("hx-target", "main"),
          attribute("hx-swap", "innerHTML"),
          attribute("hx-push-url", "true"),
          attribute("aria-label", "Next day"),
        ],
        [text("Next Day →")],
      ),
    ],
  )
}

// ===================================================================
// DAILY TOTALS SUMMARY
// ===================================================================

/// Render daily totals summary card
///
/// Displays aggregated nutrition totals for the day:
/// - Total calories
/// - Total protein, fat, carbs
///
/// Updates automatically when entries change
fn render_daily_totals(
  calories: Float,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Element(msg) {
  let calories_str = int.to_string(float.truncate(calories))
  let protein_str = int.to_string(float.truncate(protein))
  let fat_str = int.to_string(float.truncate(fat))
  let carbs_str = int.to_string(float.truncate(carbs))

  section(
    [
      class("daily-totals-summary"),
      attribute("aria-labelledby", "totals-heading"),
    ],
    [
      h2([id("totals-heading"), class("section-header")], [
        text("Daily Totals"),
      ]),
      div([class("totals-grid")], [
        div([class("total-item total-calories")], [
          div([class("total-label")], [text("Calories")]),
          div([class("total-value")], [text(calories_str <> " kcal")]),
        ]),
        div([class("total-item total-protein")], [
          div([class("total-label")], [text("Protein")]),
          div([class("total-value")], [text(protein_str <> "g")]),
        ]),
        div([class("total-item total-fat")], [
          div([class("total-label")], [text("Fat")]),
          div([class("total-value")], [text(fat_str <> "g")]),
        ]),
        div([class("total-item total-carbs")], [
          div([class("total-label")], [text("Carbs")]),
          div([class("total-value")], [text(carbs_str <> "g")]),
        ]),
      ]),
    ],
  )
}

// ===================================================================
// ADD ENTRY BUTTON
// ===================================================================

/// Render add entry button
///
/// Opens a modal form for adding new food log entries:
/// - HTMX loads form: hx-get="/logs/new"
/// - Form appears in #modal-container
/// - Form submission handled by form's own HTMX attributes
fn render_add_entry_button() -> Element(msg) {
  div([class("add-entry-section")], [
    button(
      [
        class("btn btn-primary btn-add-entry"),
        attribute("hx-get", "/logs/new"),
        attribute("hx-target", "#modal-container"),
        attribute("hx-swap", "innerHTML"),
        attribute("aria-label", "Add new food log entry"),
      ],
      [text("+ Add Entry")],
    ),
  ])
}

// ===================================================================
// ENTRIES LIST SECTION
// ===================================================================

/// Render food log entries section
///
/// Displays a scrollable list of food log entries:
/// - Auto-refreshes every 30 seconds via HTMX polling
/// - Shows empty state when no entries
/// - Each entry card handles its own edit/delete
///
/// HTMX polling keeps entries fresh without page reload
fn render_entries_section(
  date: String,
  entries: List(ui_types.LogEntryCard),
) -> Element(msg) {
  section(
    [
      class("food-log-entries-section"),
      attribute("aria-labelledby", "entries-heading"),
    ],
    [
      h2([id("entries-heading"), class("section-header")], [
        text("Food Entries"),
      ]),
      render_entries_list(date, entries),
    ],
  )
}

/// Render scrollable list of food log entries
///
/// Container with HTMX polling for real-time updates:
/// - Polls /logs/entries?date={date} every 30s
/// - Replaces innerHTML with updated entries
/// - Shows empty state when list is empty
fn render_entries_list(
  date: String,
  entries: List(ui_types.LogEntryCard),
) -> Element(msg) {
  let poll_url = "/logs/entries?date=" <> date

  case entries {
    [] ->
      div(
        [
          id("entries-list"),
          class("entries-list empty"),
          attribute("hx-get", poll_url),
          attribute("hx-trigger", "every 30s"),
          attribute("hx-swap", "innerHTML"),
        ],
        [render_empty_state()],
      )

    _ ->
      div(
        [
          id("entries-list"),
          class("entries-list"),
          attribute("hx-get", poll_url),
          attribute("hx-trigger", "every 30s"),
          attribute("hx-swap", "innerHTML"),
        ],
        entries |> list.map(food_log_entry_card.render_log_entry_card),
      )
  }
}

/// Render empty state when no entries exist
///
/// Shows a friendly message encouraging user to add entries
fn render_empty_state() -> Element(msg) {
  div([class("empty-state")], [
    div([class("empty-icon")], [text("🍽️")]),
    div([class("empty-message")], [text("No food entries yet")]),
    div([class("empty-hint")], [
      text("Click 'Add Entry' to log your first meal"),
    ]),
  ])
}

// ===================================================================
// COMPACT MOBILE VIEW (Optional)
// ===================================================================

/// Render compact food log page for mobile
///
/// Similar to full page but with:
/// - Compact entry cards
/// - Simplified totals display
/// - Optimized for small screens
pub fn render_food_log_page_compact(data: FoodLogPageData) -> Element(msg) {
  // Page title
  let page_title = h1([class("page-title compact")], [text(data.date)])

  // Date navigation (icons only)
  let date_nav = render_date_navigation_compact(data.date)

  // Simplified totals (just calories)
  let totals_summary = render_daily_totals_compact(data.total_calories)

  // Add entry button (icon)
  let add_button = render_add_entry_button_compact()

  // Food log entries (compact cards)
  let entries_section = render_entries_section_compact(data.date, data.entries)

  // Modal container
  let modal_container = div([id("modal-container"), class("modal-root")], [])

  // Build compact layout
  main([attribute("role", "main"), attribute("aria-label", "Food Log")], [
    layout.container(600, [
      page_title,
      date_nav,
      totals_summary,
      add_button,
      entries_section,
      modal_container,
    ]),
  ])
}

/// Compact date navigation (icons only)
fn render_date_navigation_compact(current_date: String) -> Element(msg) {
  div([class("date-navigation compact")], [
    button(
      [
        class("btn-icon nav-prev"),
        attribute("hx-get", "/logs?date=prev&current=" <> current_date),
        attribute("hx-target", "main"),
        attribute("hx-swap", "innerHTML"),
        attribute("hx-push-url", "true"),
        attribute("aria-label", "Previous day"),
      ],
      [text("←")],
    ),
    div([class("current-date")], [text(current_date)]),
    button(
      [
        class("btn-icon nav-next"),
        attribute("hx-get", "/logs?date=next&current=" <> current_date),
        attribute("hx-target", "main"),
        attribute("hx-swap", "innerHTML"),
        attribute("hx-push-url", "true"),
        attribute("aria-label", "Next day"),
      ],
      [text("→")],
    ),
  ])
}

/// Compact daily totals (calories only)
fn render_daily_totals_compact(calories: Float) -> Element(msg) {
  let calories_str = int.to_string(float.truncate(calories))

  div([class("daily-totals-compact")], [
    text(calories_str <> " kcal"),
  ])
}

/// Compact add entry button (floating action button)
fn render_add_entry_button_compact() -> Element(msg) {
  button(
    [
      class("btn-fab btn-add-entry"),
      attribute("hx-get", "/logs/new"),
      attribute("hx-target", "#modal-container"),
      attribute("hx-swap", "innerHTML"),
      attribute("aria-label", "Add new food log entry"),
    ],
    [text("+")],
  )
}

/// Compact entries section (uses compact cards)
fn render_entries_section_compact(
  date: String,
  entries: List(ui_types.LogEntryCard),
) -> Element(msg) {
  let poll_url = "/logs/entries?date=" <> date

  case entries {
    [] ->
      div(
        [
          id("entries-list"),
          class("entries-list compact empty"),
          attribute("hx-get", poll_url),
          attribute("hx-trigger", "every 30s"),
          attribute("hx-swap", "innerHTML"),
        ],
        [render_empty_state()],
      )

    _ ->
      div(
        [
          id("entries-list"),
          class("entries-list compact"),
          attribute("hx-get", poll_url),
          attribute("hx-trigger", "every 30s"),
          attribute("hx-swap", "innerHTML"),
        ],
        entries |> list.map(food_log_entry_card.render_log_entry_card_compact),
      )
  }
}
