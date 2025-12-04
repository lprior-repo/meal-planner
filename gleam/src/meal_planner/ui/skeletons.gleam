// Skeleton Loading States Module
// Beautiful skeleton loaders with shimmer animations for all major components
//
// Usage:
//   case loading_state {
//     Loading -> skeletons.food_card_skeleton()
//     Loaded(data) -> food_card(data)
//     Error(e) -> error_display(e)
//   }

import gleam/string
import gleam/int
import gleam/list

/// Food card skeleton - placeholder for food search results
/// Shows skeleton for food name, type, and macro badges
pub fn food_card_skeleton() -> String {
  "
<div class=\"food-item skeleton-list-item\" role=\"status\" aria-label=\"Loading food item\">
  <div class=\"food-info\">
    <div class=\"skeleton skeleton-text skeleton-text-3/4\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-1/2\"></div>
  </div>
  <div class=\"skeleton-badges\">
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
  </div>
</div>
"
}

/// Recipe card skeleton - placeholder for recipe cards
/// Shows skeleton for recipe title, category, time, and nutrition info
pub fn recipe_card_skeleton() -> String {
  "
<div class=\"recipe-card skeleton-card\" role=\"status\" aria-label=\"Loading recipe\">
  <div class=\"skeleton-content\">
    <div class=\"skeleton skeleton-text skeleton-text-full\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-1/2\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-1/4\" style=\"margin-top: var(--space-3);\"></div>
  </div>
  <div class=\"skeleton-badges\">
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
  </div>
</div>
"
}

/// Meal log entry skeleton - placeholder for daily meal log entries
/// Shows skeleton for time, food name, portion, macros, and calories
pub fn meal_log_skeleton() -> String {
  "
<div class=\"meal-entry-item\" role=\"status\" aria-label=\"Loading meal entry\">
  <div class=\"entry-time\">
    <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 50px;\"></div>
  </div>
  <div class=\"entry-details\">
    <div class=\"skeleton skeleton-text skeleton-text-3/4\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-1/2\" style=\"margin-top: var(--space-1);\"></div>
  </div>
  <div class=\"entry-macros\">
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
  </div>
  <div class=\"entry-calories\">
    <div class=\"skeleton skeleton-text\" style=\"height: 16px; width: 60px;\"></div>
  </div>
  <div class=\"entry-actions\" style=\"opacity: 0;\">
    <div class=\"skeleton\" style=\"width: 32px; height: 32px; border-radius: var(--radius-md);\"></div>
    <div class=\"skeleton\" style=\"width: 32px; height: 32px; border-radius: var(--radius-md);\"></div>
  </div>
</div>
"
}

/// Macro progress bar skeleton - placeholder for macro tracking charts
/// Shows skeleton for protein, fat, and carbs progress bars
pub fn macro_chart_skeleton() -> String {
  "
<div class=\"macro-bars\" role=\"status\" aria-label=\"Loading macro progress\">
  <div class=\"macro-bar skeleton-progress-bar\">
    <div class=\"macro-bar-header\">
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 80px;\"></div>
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 60px;\"></div>
    </div>
    <div class=\"progress-bar\">
      <div class=\"skeleton-bar\"></div>
    </div>
  </div>
  <div class=\"macro-bar skeleton-progress-bar\">
    <div class=\"macro-bar-header\">
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 80px;\"></div>
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 60px;\"></div>
    </div>
    <div class=\"progress-bar\">
      <div class=\"skeleton-bar\"></div>
    </div>
  </div>
  <div class=\"macro-bar skeleton-progress-bar\">
    <div class=\"macro-bar-header\">
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 80px;\"></div>
      <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 60px;\"></div>
    </div>
    <div class=\"progress-bar\">
      <div class=\"skeleton-bar\"></div>
    </div>
  </div>
</div>
"
}

/// Micronutrient panel skeleton - placeholder for micronutrient visualization
/// Shows skeleton for vitamin and mineral progress bars
pub fn micronutrient_skeleton() -> String {
  "
<div class=\"micronutrient-panel\" role=\"status\" aria-label=\"Loading micronutrients\">
  <div class=\"micro-section\">
    <div class=\"skeleton skeleton-text skeleton-text-1/4\" style=\"height: 20px; margin-bottom: var(--space-3);\"></div>
    <div class=\"micro-list\">
      " <> micronutrient_bar_skeleton() <> "
      " <> micronutrient_bar_skeleton() <> "
      " <> micronutrient_bar_skeleton() <> "
    </div>
  </div>
  <div class=\"micro-section\">
    <div class=\"skeleton skeleton-text skeleton-text-1/4\" style=\"height: 20px; margin-bottom: var(--space-3);\"></div>
    <div class=\"micro-list\">
      " <> micronutrient_bar_skeleton() <> "
      " <> micronutrient_bar_skeleton() <> "
      " <> micronutrient_bar_skeleton() <> "
    </div>
  </div>
</div>
"
}

/// Helper: Single micronutrient bar skeleton
fn micronutrient_bar_skeleton() -> String {
  "
<div class=\"micronutrient-bar\">
  <div class=\"micro-header\">
    <div class=\"skeleton skeleton-text\" style=\"height: 14px; width: 100px;\"></div>
    <div class=\"skeleton skeleton-text\" style=\"height: 12px; width: 60px;\"></div>
  </div>
  <div class=\"micro-progress\">
    <div class=\"skeleton-bar\"></div>
  </div>
  <div class=\"skeleton skeleton-text\" style=\"height: 12px; width: 40px; margin-top: var(--space-1);\"></div>
</div>
"
}

/// Table row skeleton - placeholder for data table rows
/// Accepts count parameter for number of rows to display
pub fn table_row_skeleton(count: Int) -> String {
  let rows = list.range(1, count)
    |> list.map(fn(_) { single_table_row_skeleton() })
    |> string.join("")

  rows
}

/// Helper: Single table row skeleton
fn single_table_row_skeleton() -> String {
  "
<tr class=\"skeleton-table-row\" role=\"status\" aria-label=\"Loading table row\">
  <td><div class=\"skeleton skeleton-text skeleton-text-3/4\"></div></td>
  <td><div class=\"skeleton skeleton-text skeleton-text-1/2\"></div></td>
  <td><div class=\"skeleton skeleton-text skeleton-text-1/4\"></div></td>
  <td><div class=\"skeleton skeleton-text skeleton-text-1/2\"></div></td>
</tr>
"
}

/// Form skeleton - placeholder for form loading states
/// Shows skeleton for form fields and submit button
pub fn form_skeleton() -> String {
  "
<div class=\"card skeleton-card\" role=\"status\" aria-label=\"Loading form\">
  <div class=\"card-header\">
    <div class=\"skeleton skeleton-text skeleton-text-1/2\" style=\"height: 32px;\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-full\" style=\"height: 16px; margin-top: var(--space-2);\"></div>
  </div>
  <div class=\"card-body\">
    " <> form_field_skeleton() <> "
    " <> form_field_skeleton() <> "
    <div class=\"grid grid-cols-2 gap-4\">
      " <> form_field_skeleton() <> "
      " <> form_field_skeleton() <> "
    </div>
    " <> form_field_skeleton() <> "
  </div>
  <div class=\"card-footer\">
    <div class=\"skeleton\" style=\"width: 140px; height: 42px; border-radius: var(--radius-md);\"></div>
    <div class=\"skeleton\" style=\"width: 100px; height: 42px; border-radius: var(--radius-md);\"></div>
  </div>
</div>
"
}

/// Helper: Single form field skeleton
fn form_field_skeleton() -> String {
  "
<div class=\"form-group\">
  <div class=\"skeleton skeleton-text\" style=\"height: 16px; width: 120px; margin-bottom: var(--space-2);\"></div>
  <div class=\"skeleton\" style=\"height: 42px; width: 100%; border-radius: var(--radius-md);\"></div>
</div>
"
}

/// Search box skeleton - placeholder for search input
pub fn search_box_skeleton() -> String {
  "
<div class=\"search-box\" role=\"status\" aria-label=\"Loading search\">
  <div class=\"skeleton\" style=\"flex: 1; height: 42px; border-radius: var(--radius-md);\"></div>
  <div class=\"skeleton\" style=\"width: 100px; height: 42px; border-radius: var(--radius-md);\"></div>
</div>
"
}

/// Card stat skeleton - placeholder for statistics cards
pub fn card_stat_skeleton() -> String {
  "
<div class=\"card card-stat skeleton-card\" role=\"status\" aria-label=\"Loading statistic\">
  <div class=\"skeleton\" style=\"width: 100px; height: 64px; margin-bottom: var(--space-2);\"></div>
  <div class=\"skeleton skeleton-text\" style=\"height: 12px; width: 60px; margin-top: var(--space-1);\"></div>
  <div class=\"skeleton skeleton-text\" style=\"height: 16px; width: 80px; margin-top: var(--space-2);\"></div>
</div>
"
}

/// List skeleton - placeholder for generic lists
/// Accepts count parameter for number of list items
pub fn list_skeleton(count: Int) -> String {
  let items = list.range(1, count)
    |> list.map(fn(_) {
      "
<div class=\"skeleton-list-item\">
  <div class=\"skeleton skeleton-text skeleton-text-full\"></div>
  <div class=\"skeleton skeleton-text skeleton-text-3/4\"></div>
  <div class=\"skeleton-badges\">
    <div class=\"skeleton-badge\"></div>
    <div class=\"skeleton-badge\"></div>
  </div>
</div>
"
    })
    |> string.join("")

  "<div class=\"food-list\" role=\"status\" aria-label=\"Loading list\">"
    <> items
    <> "</div>"
}

/// Page skeleton - full page loading state
/// Shows skeleton for header, content area, and optional sidebar
pub fn page_skeleton() -> String {
  "
<div class=\"loading-page\" role=\"status\" aria-label=\"Loading page\">
  <div class=\"loading-page-content\">
    <div class=\"spinner-large\"></div>
    <div class=\"loading-title\">Loading...</div>
    <div class=\"loading-subtitle\">Please wait while we prepare your content</div>
  </div>
</div>
"
}

/// Loading overlay skeleton - for in-place content loading
pub fn loading_overlay(message: String) -> String {
  "
<div class=\"loading-overlay\" role=\"status\" aria-label=\"Loading\">
  <div class=\"loading-overlay-content\">
    <div class=\"spinner-standard\"></div>
    <p class=\"loading-message\">" <> message <> "</p>
  </div>
</div>
"
}

/// Inline spinner - for buttons and inline content
pub fn inline_spinner() -> String {
  "
<span class=\"spinner-inline\" role=\"status\" aria-label=\"Loading\">
  <span class=\"spinner-dot\"></span>
  <span class=\"spinner-dot\"></span>
  <span class=\"spinner-dot\"></span>
</span>
"
}

/// Meal section skeleton - collapsible meal section with entries
pub fn meal_section_skeleton() -> String {
  "
<div class=\"meal-section\" role=\"status\" aria-label=\"Loading meal section\">
  <div class=\"meal-section-header\">
    <div class=\"skeleton skeleton-text\" style=\"height: 24px; width: 120px;\"></div>
    <div class=\"skeleton skeleton-text\" style=\"height: 16px; width: 60px;\"></div>
    <div class=\"skeleton skeleton-text\" style=\"height: 16px; width: 80px;\"></div>
    <div class=\"skeleton\" style=\"width: 32px; height: 32px; border-radius: var(--radius-md);\"></div>
  </div>
  <div class=\"meal-section-body\">
    " <> meal_log_skeleton() <> "
    " <> meal_log_skeleton() <> "
    " <> meal_log_skeleton() <> "
  </div>
</div>
"
}

/// Daily log timeline skeleton - full day view with multiple meal sections
pub fn daily_log_timeline_skeleton() -> String {
  "
<div class=\"daily-log-timeline\" role=\"status\" aria-label=\"Loading daily log\">
  " <> meal_section_skeleton() <> "
  " <> meal_section_skeleton() <> "
  " <> meal_section_skeleton() <> "
  " <> meal_section_skeleton() <> "
</div>
"
}

/// Recipe grid skeleton - grid of recipe cards
pub fn recipe_grid_skeleton(count: Int) -> String {
  let cards = list.range(1, count)
    |> list.map(fn(_) { recipe_card_skeleton() })
    |> string.join("")

  "
<div class=\"grid grid-cols-3 gap-4\" role=\"status\" aria-label=\"Loading recipes\">
  " <> cards <> "
</div>
"
}

/// Food search results skeleton - list of food items
pub fn food_search_results_skeleton(count: Int) -> String {
  let items = list.range(1, count)
    |> list.map(fn(_) { food_card_skeleton() })
    |> string.join("")

  "
<div class=\"food-list\" role=\"status\" aria-label=\"Loading search results\">
  " <> items <> "
</div>
"
}

/// Dashboard skeleton - full dashboard with stats and charts
pub fn dashboard_skeleton() -> String {
  "
<div class=\"container\" role=\"status\" aria-label=\"Loading dashboard\">
  <div class=\"page-header\">
    <div class=\"skeleton skeleton-text skeleton-text-1/2\" style=\"height: 40px;\"></div>
    <div class=\"skeleton skeleton-text skeleton-text-full\" style=\"height: 20px; margin-top: var(--space-2);\"></div>
  </div>

  <div class=\"grid grid-cols-4 gap-4\" style=\"margin-bottom: var(--space-6);\">
    " <> card_stat_skeleton() <> "
    " <> card_stat_skeleton() <> "
    " <> card_stat_skeleton() <> "
    " <> card_stat_skeleton() <> "
  </div>

  <div class=\"grid grid-cols-2 gap-6\">
    <div class=\"card skeleton-card\">
      <div class=\"card-header\">
        <div class=\"skeleton skeleton-text skeleton-text-1/3\" style=\"height: 24px;\"></div>
      </div>
      <div class=\"card-body\">
        " <> macro_chart_skeleton() <> "
      </div>
    </div>

    <div class=\"card skeleton-card\">
      <div class=\"card-header\">
        <div class=\"skeleton skeleton-text skeleton-text-1/3\" style=\"height: 24px;\"></div>
      </div>
      <div class=\"card-body\">
        " <> micronutrient_skeleton() <> "
      </div>
    </div>
  </div>
</div>
"
}
