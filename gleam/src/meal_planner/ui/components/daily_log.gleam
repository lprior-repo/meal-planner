/// Daily Log Components Module
///
/// This module provides components for displaying daily meal logs:
/// - Meal entry items with time, food, portion, macros, calories
/// - Edit/delete action buttons
/// - Meal sections grouped by meal type (breakfast, lunch, dinner, snack)
/// - Collapsible sections
/// - Complete daily log timeline
///
/// All components render as HTML strings suitable for SSR.
///
/// See: Bead meal-planner-uzr.3
import gleam/float
import gleam/int
import gleam/list
import gleam/string
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
///
/// Renders:
/// <div class="meal-entry-item">
///   <div class="entry-time">08:30 AM</div>
///   <div class="entry-details">
///     <div class="food-name">Scrambled Eggs</div>
///     <div class="portion">2 servings</div>
///   </div>
///   <div class="entry-macros">
///     <span class="macro">P: 24g</span>
///     <span class="macro">F: 18g</span>
///     <span class="macro">C: 4g</span>
///   </div>
///   <div class="entry-calories">320 kcal</div>
///   <div class="entry-actions">
///     <button class="btn-edit">Edit</button>
///     <button class="btn-delete">Delete</button>
///   </div>
/// </div>
pub fn meal_entry_item(entry: ui_types.MealEntryData) -> String {
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

  "<div class=\"meal-entry-item\" data-entry-id=\""
  <> id
  <> "\">"
  <> "<div class=\"entry-time\">"
  <> time
  <> "</div>"
  <> "<div class=\"entry-details\">"
  <> "<div class=\"food-name\">"
  <> food_name
  <> "</div>"
  <> "<div class=\"portion\">"
  <> portion
  <> "</div>"
  <> "</div>"
  <> "<div class=\"entry-macros\">"
  <> "<span class=\"macro macro-protein\">P: "
  <> protein_str
  <> "g</span>"
  <> "<span class=\"macro macro-fat\">F: "
  <> fat_str
  <> "g</span>"
  <> "<span class=\"macro macro-carbs\">C: "
  <> carbs_str
  <> "g</span>"
  <> "</div>"
  <> "<div class=\"entry-calories\">"
  <> calories_str
  <> " kcal</div>"
  <> "<div class=\"entry-actions\">"
  <> "<button class=\"btn-icon btn-edit\" data-entry-id=\""
  <> id
  <> "\">✏️</button>"
  <> "<button class=\"btn-icon btn-delete\" data-entry-id=\""
  <> id
  <> "\">🗑️</button>"
  <> "</div>"
  <> "</div>"
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
///
/// Renders:
/// <div class="meal-section" data-meal-type="breakfast">
///   <div class="meal-section-header">
///     <h3>Breakfast <span class="entry-count">(3)</span></h3>
///     <span class="section-calories">650 kcal</span>
///     <button class="collapse-toggle">▼</button>
///   </div>
///   <div class="meal-section-body">
///     <!-- meal entries -->
///   </div>
/// </div>
pub fn meal_section(
  meal_type: String,
  entries: List(ui_types.MealEntryData),
) -> String {
  let entry_count = list.fold(entries, 0, fn(acc, _) { acc + 1 })
  let total_calories =
    entries
    |> list.fold(0.0, fn(sum, entry) { sum +. entry.calories })
  let total_calories_str = float.truncate(total_calories) |> int.to_string

  let entries_html =
    entries
    |> list.map(meal_entry_item)
    |> string.concat

  let meal_type_lower = string.lowercase(meal_type)

  "<div class=\"meal-section\" data-meal-type=\""
  <> meal_type_lower
  <> "\">"
  <> "<div class=\"meal-section-header\">"
  <> "<h3>"
  <> meal_type
  <> " <span class=\"entry-count\">("
  <> int.to_string(entry_count)
  <> ")</span></h3>"
  <> "<span class=\"section-calories\">"
  <> total_calories_str
  <> " kcal</span>"
  <> "<button class=\"collapse-toggle\">▼</button>"
  <> "</div>"
  <> "<div class=\"meal-section-body\">"
  <> entries_html
  <> "</div>"
  <> "</div>"
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
///
/// Renders:
/// <div class="daily-log-timeline">
///   <!-- meal sections -->
/// </div>
pub fn daily_log_timeline(entries: List(ui_types.MealEntryData)) -> String {
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

  // Build sections HTML
  let sections = [
    case list.is_empty(breakfast_entries) {
      True -> ""
      False -> meal_section("Breakfast", breakfast_entries)
    },
    case list.is_empty(lunch_entries) {
      True -> ""
      False -> meal_section("Lunch", lunch_entries)
    },
    case list.is_empty(dinner_entries) {
      True -> ""
      False -> meal_section("Dinner", dinner_entries)
    },
    case list.is_empty(snack_entries) {
      True -> ""
      False -> meal_section("Snack", snack_entries)
    },
  ]

  let sections_html = sections |> string.concat

  "<div class=\"daily-log-timeline\">" <> sections_html <> "</div>"
}
