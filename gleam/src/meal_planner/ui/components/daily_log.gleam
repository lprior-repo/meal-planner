/// Daily Log Components Module
///
/// This module provides components for displaying daily meal logs:
/// - Meal entry items with time, food, portion, macros, calories
/// - Edit/delete action buttons
/// - Meal sections grouped by meal type (breakfast, lunch, dinner, snack)
/// - Collapsible sections
/// - Complete daily log timeline
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: Bead meal-planner-uzr.3
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h3, span}
import meal_planner/ui/types/ui_types

// ===================================================================
// MEAL ENTRY ITEM COMPONENT
// ===================================================================

/// Render a single meal entry item
///
/// Displays:
/// - Time of meal
/// - Food name
/// - Portion size
/// - Macros (P/F/C)
/// - Calories
/// - Edit and delete action buttons
pub fn meal_entry_item(entry: ui_types.MealEntryData) -> Element(msg) {
  let ui_types.MealEntryData(
    id: id,
    time: time,
    food_name: food_name,
    portion: portion,
    protein: protein,
    fat: fat,
    carbs: carbs,
    calories: calories,
    meal_type: _,
  ) = entry

  let protein_str = float.truncate(protein) |> int.to_string
  let fat_str = float.truncate(fat) |> int.to_string
  let carbs_str = float.truncate(carbs) |> int.to_string
  let calories_str = float.truncate(calories) |> int.to_string

  div([class("meal-entry-item"), attribute("data-entry-id", id)], [
    div([class("entry-time")], [text(time)]),
    div([class("entry-details")], [
      div([class("food-name")], [text(food_name)]),
      div([class("portion")], [text(portion)]),
    ]),
    div([class("entry-macros")], [
      span([class("macro macro-protein")], [text("P: " <> protein_str <> "g")]),
      span([class("macro macro-fat")], [text("F: " <> fat_str <> "g")]),
      span([class("macro macro-carbs")], [text("C: " <> carbs_str <> "g")]),
    ]),
    div([class("entry-calories")], [text(calories_str <> " kcal")]),
    div([class("entry-actions")], [
      button(
        [
          class("btn-icon btn-edit"),
          attribute("data-entry-id", id),
          attribute("hx-get", "/log/" <> id <> "/edit"),
          attribute("hx-target", "#modal-container"),
          attribute("hx-swap", "innerHTML"),
        ],
        [text("✏️")],
      ),
      button(
        [
          class("btn-icon btn-delete"),
          attribute("data-entry-id", id),
          attribute(
            "hx-delete",
            "/api/logs/entry/" <> id <> "?action=delete",
          ),
          attribute("hx-target", "closest .meal-entry-item"),
          attribute("hx-swap", "outerHTML swap:1s"),
          attribute("hx-confirm", "Delete this entry?"),
        ],
        [text("🗑️")],
      ),
    ]),
  ])
}

// ===================================================================
// MEAL SECTION COMPONENT
// ===================================================================

/// Render a collapsible meal section (e.g., Breakfast, Lunch)
///
/// Displays:
/// - Meal type header with entry count
/// - Total calories for this meal type
/// - Collapsible toggle
/// - List of meal entries
pub fn meal_section(
  meal_type: String,
  entries: List(ui_types.MealEntryData),
) -> Element(msg) {
  let entry_count = list.length(entries)
  let total_calories =
    entries
    |> list.fold(0.0, fn(sum, entry) { sum +. entry.calories })
  let total_calories_str = float.truncate(total_calories) |> int.to_string

  let meal_type_lower = string.lowercase(meal_type)

  div([class("meal-section"), attribute("data-meal-type", meal_type_lower)], [
    div([class("meal-section-header")], [
      h3([], [
        text(meal_type <> " "),
        span([class("entry-count")], [
          text("(" <> int.to_string(entry_count) <> ")"),
        ]),
      ]),
      span([class("section-calories")], [
        text(total_calories_str <> " kcal"),
      ]),
      button([class("collapse-toggle")], [text("▼")]),
    ]),
    div([class("meal-section-body")], list.map(entries, meal_entry_item)),
  ])
}

// ===================================================================
// DAILY LOG TIMELINE COMPONENT
// ===================================================================

/// Render complete daily log timeline
///
/// Groups entries by meal type and renders sections:
/// - Breakfast
/// - Lunch
/// - Dinner
/// - Snack
///
/// Each section is collapsible and shows total calories
pub fn daily_log_timeline(entries: List(ui_types.MealEntryData)) -> Element(msg) {
  // Group entries by meal type
  let breakfast_entries =
    entries
    |> list.filter(fn(e) { e.meal_type == "breakfast" })

  let lunch_entries =
    entries
    |> list.filter(fn(e) { e.meal_type == "lunch" })

  let dinner_entries =
    entries
    |> list.filter(fn(e) { e.meal_type == "dinner" })

  let snack_entries =
    entries
    |> list.filter(fn(e) { e.meal_type == "snack" })

  // Build sections list
  let sections =
    [
      #("Breakfast", breakfast_entries),
      #("Lunch", lunch_entries),
      #("Dinner", dinner_entries),
      #("Snack", snack_entries),
    ]
    |> list.filter(fn(section) {
      let #(_, section_entries) = section
      !list.is_empty(section_entries)
    })
    |> list.map(fn(section) {
      let #(name, section_entries) = section
      meal_section(name, section_entries)
    })

  div([class("daily-log-timeline")], sections)
}
