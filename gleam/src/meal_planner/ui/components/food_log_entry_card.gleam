/// Food Log Entry Card Components Module
///
/// This module provides beautiful food log entry cards with edit/delete controls.
/// Implements meal-planner-51y: Build Food Log Entry UI Cards
///
/// Features:
/// - Food name, portion size, macros, timestamp, meal type display
/// - Edit button with HTMX integration (hx-get to edit form)
/// - Delete button with HTMX confirmation (hx-delete with confirmation)
/// - Macro breakdown visualization (protein/fat/carbs)
/// - Responsive design (mobile-friendly)
/// - Smooth HTMX animations (hx-swap with transitions)
///
/// All components render as Lustre HTML elements suitable for SSR.
/// NO JavaScript files - HTMX only.
///
/// See: Bead meal-planner-51y
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, span}
import meal_planner/ui/types/ui_types

// ===================================================================
// MACRO BREAKDOWN VISUALIZATION
// ===================================================================

/// Render macro breakdown bar with color-coded segments
///
/// Displays a horizontal bar with three segments:
/// - Protein (blue)
/// - Fat (yellow)
/// - Carbs (green)
///
/// Each segment's width is proportional to its calorie contribution
fn macro_breakdown_bar(protein: Float, fat: Float, carbs: Float) -> Element(msg) {
  // Calculate calorie contributions
  let protein_cals = protein *. 4.0
  let fat_cals = fat *. 9.0
  let carbs_cals = carbs *. 4.0
  let total_cals = protein_cals +. fat_cals +. carbs_cals

  // Calculate percentages
  let protein_pct = case total_cals >. 0.0 {
    True -> { protein_cals /. total_cals } *. 100.0
    False -> 0.0
  }
  let fat_pct = case total_cals >. 0.0 {
    True -> { fat_cals /. total_cals } *. 100.0
    False -> 0.0
  }
  let carbs_pct = case total_cals >. 0.0 {
    True -> { carbs_cals /. total_cals } *. 100.0
    False -> 0.0
  }

  div([class("macro-breakdown-bar")], [
    div(
      [
        class("macro-segment macro-protein"),
        attribute("style", "width: " <> float.to_string(protein_pct) <> "%"),
        attribute(
          "title",
          "Protein: " <> int.to_string(float.truncate(protein)) <> "g",
        ),
      ],
      [],
    ),
    div(
      [
        class("macro-segment macro-fat"),
        attribute("style", "width: " <> float.to_string(fat_pct) <> "%"),
        attribute("title", "Fat: " <> int.to_string(float.truncate(fat)) <> "g"),
      ],
      [],
    ),
    div(
      [
        class("macro-segment macro-carbs"),
        attribute("style", "width: " <> float.to_string(carbs_pct) <> "%"),
        attribute(
          "title",
          "Carbs: " <> int.to_string(float.truncate(carbs)) <> "g",
        ),
      ],
      [],
    ),
  ])
}

/// Render macro stats with labels
///
/// Displays:
/// - P: 25g
/// - F: 15g
/// - C: 40g
fn macro_stats(protein: Float, fat: Float, carbs: Float) -> Element(msg) {
  let protein_str = int.to_string(float.truncate(protein))
  let fat_str = int.to_string(float.truncate(fat))
  let carbs_str = int.to_string(float.truncate(carbs))

  div([class("macro-stats")], [
    span([class("macro-stat macro-protein")], [
      text("P: " <> protein_str <> "g"),
    ]),
    span([class("macro-stat macro-fat")], [text("F: " <> fat_str <> "g")]),
    span([class("macro-stat macro-carbs")], [text("C: " <> carbs_str <> "g")]),
  ])
}

// ===================================================================
// FOOD LOG ENTRY CARD COMPONENT
// ===================================================================

/// Render a beautiful food log entry card
///
/// Displays:
/// - Food name and portion size
/// - Meal type badge
/// - Timestamp
/// - Total calories
/// - Macro breakdown visualization (bar + stats)
/// - Edit button (HTMX: hx-get to edit form)
/// - Delete button (HTMX: hx-delete with confirmation)
///
/// HTMX Integration:
/// - Edit: hx-get="/logs/{id}/edit" hx-target="#log-{id}" hx-swap="outerHTML"
/// - Delete: hx-delete="/logs/{id}" hx-target="#log-{id}" hx-swap="outerHTML swap:1s" hx-confirm="Delete?"
///
/// Example:
/// ```gleam
/// let card = LogEntryCard(
///   entry_id: "log-123",
///   food_name: "Grilled Chicken Breast",
///   portion: 6.0,
///   unit: "oz",
///   protein: 52.0,
///   fat: 6.0,
///   carbs: 0.0,
///   calories: 276.0,
///   meal_type: "lunch",
///   logged_at: "2025-12-04 12:30",
/// )
/// render_log_entry_card(card)
/// ```
pub fn render_log_entry_card(card: ui_types.LogEntryCard) -> Element(msg) {
  let ui_types.LogEntryCard(
    entry_id: entry_id,
    food_name: food_name,
    portion: portion,
    unit: unit,
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
    meal_type: meal_type,
    logged_at: logged_at,
  ) = card

  // Format values
  let portion_str = float.to_string(portion)
  let calories_str = int.to_string(float.truncate(calories))
  let meal_type_display = string.capitalise(meal_type)

  // Build HTMX attributes for edit button
  let edit_path = "/logs/" <> entry_id <> "/edit"
  let target_id = "#log-" <> entry_id

  // Build HTMX attributes for delete button
  let delete_path = "/logs/" <> entry_id

  div(
    [
      class("food-log-entry-card"),
      attribute("id", "log-" <> entry_id),
      attribute("data-entry-id", entry_id),
    ],
    [
      // Header: Food name and meal type badge
      div([class("card-header")], [
        div([class("food-info")], [
          div([class("food-name")], [text(food_name)]),
          span([class("meal-type-badge meal-type-" <> meal_type)], [
            text(meal_type_display),
          ]),
        ]),
        div([class("logged-time")], [text(logged_at)]),
      ]),
      // Body: Portion, calories, macros
      div([class("card-body")], [
        div([class("portion-info")], [
          span([class("portion-size")], [text(portion_str <> " " <> unit)]),
          span([class("calorie-count")], [text(calories_str <> " kcal")]),
        ]),
        // Macro breakdown visualization
        div([class("macro-breakdown")], [
          macro_breakdown_bar(protein, fat, carbs),
          macro_stats(protein, fat, carbs),
        ]),
      ]),
      // Footer: Edit and delete buttons with HTMX
      div([class("card-actions")], [
        button(
          [
            class("btn btn-edit"),
            attribute("hx-get", edit_path),
            attribute("hx-target", target_id),
            attribute("hx-swap", "outerHTML"),
            attribute("aria-label", "Edit entry"),
          ],
          [text("Edit")],
        ),
        button(
          [
            class("btn btn-delete btn-danger"),
            attribute("hx-delete", delete_path),
            attribute("hx-target", target_id),
            attribute("hx-swap", "outerHTML swap:1s"),
            attribute("hx-confirm", "Delete this entry?"),
            attribute("aria-label", "Delete entry"),
          ],
          [text("Delete")],
        ),
      ]),
    ],
  )
}

// ===================================================================
// COMPACT VARIANT (Optional)
// ===================================================================

/// Render a compact version of the food log entry card
///
/// Similar to the full card but with reduced spacing and no macro bar.
/// Useful for mobile views or dense layouts.
///
/// Displays:
/// - Food name
/// - Portion and calories inline
/// - Macro stats (no bar)
/// - Edit/delete buttons (icons only)
pub fn render_log_entry_card_compact(
  card: ui_types.LogEntryCard,
) -> Element(msg) {
  let ui_types.LogEntryCard(
    entry_id: entry_id,
    food_name: food_name,
    portion: portion,
    unit: unit,
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
    meal_type: meal_type,
    logged_at: logged_at,
  ) = card

  // Format values
  let portion_str = float.to_string(portion)
  let calories_str = int.to_string(float.truncate(calories))
  let meal_type_display = string.capitalise(meal_type)

  // Build HTMX attributes
  let edit_path = "/logs/" <> entry_id <> "/edit"
  let delete_path = "/logs/" <> entry_id
  let target_id = "#log-" <> entry_id

  div(
    [
      class("food-log-entry-card compact"),
      attribute("id", "log-" <> entry_id),
      attribute("data-entry-id", entry_id),
    ],
    [
      div([class("compact-header")], [
        div([class("food-name")], [text(food_name)]),
        div([class("card-actions-inline")], [
          button(
            [
              class("btn-icon btn-edit"),
              attribute("hx-get", edit_path),
              attribute("hx-target", target_id),
              attribute("hx-swap", "outerHTML"),
              attribute("aria-label", "Edit entry"),
            ],
            [text("✏️")],
          ),
          button(
            [
              class("btn-icon btn-delete"),
              attribute("hx-delete", delete_path),
              attribute("hx-target", target_id),
              attribute("hx-swap", "outerHTML swap:1s"),
              attribute("hx-confirm", "Delete this entry?"),
              attribute("aria-label", "Delete entry"),
            ],
            [text("🗑️")],
          ),
        ]),
      ]),
      div([class("compact-details")], [
        span([class("meal-type-badge meal-type-" <> meal_type)], [
          text(meal_type_display),
        ]),
        span([class("portion")], [text(portion_str <> " " <> unit)]),
        span([class("calories")], [text(calories_str <> " kcal")]),
        span([class("time")], [text(logged_at)]),
      ]),
      macro_stats(protein, fat, carbs),
    ],
  )
}

// ===================================================================
// LIST WRAPPER (Optional Helper)
// ===================================================================

/// Render a list of food log entry cards
///
/// Wraps cards in a container with proper spacing and layout.
/// Useful for rendering multiple entries on a page.
pub fn render_log_entry_list(cards: List(ui_types.LogEntryCard)) -> Element(msg) {
  div([class("food-log-entry-list")], cards |> list.map(render_log_entry_card))
}
