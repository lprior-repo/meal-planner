/// Meal Plan Display Component Module
///
/// This module provides components for displaying generated weekly meal plans:
/// - Weekly meal plan grid with day-by-day breakdown
/// - Daily meal cards for breakfast, lunch, dinner
/// - Nutritional summaries per day
/// - HTMX-powered interactive features
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: Bead meal-planner-3b0
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h2, h3, h4, section, span}
import meal_planner/meal_plan.{
  type DailyPlan, type Meal, type WeeklyMealPlan, daily_plan_macros,
}
import meal_planner/types.{macros_calories}
import meal_planner/ui/components/meal_card

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Meal type identifier for categorizing meals
pub type MealCategory {
  BreakfastMeal
  LunchMeal
  DinnerMeal
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Convert MealCategory to string for display
fn meal_category_to_string(category: MealCategory) -> String {
  case category {
    BreakfastMeal -> "Breakfast"
    LunchMeal -> "Lunch"
    DinnerMeal -> "Dinner"
  }
}

/// Convert MealCategory to lowercase ID
fn meal_category_to_id(category: MealCategory) -> String {
  case category {
    BreakfastMeal -> "breakfast"
    LunchMeal -> "lunch"
    DinnerMeal -> "dinner"
  }
}

/// Get meal from daily plan by index (0=breakfast, 1=lunch, 2=dinner)
fn get_meal_by_index(plan: DailyPlan, index: Int) -> Result(Meal, Nil) {
  case list.drop(plan.meals, index) {
    [meal, ..] -> Ok(meal)
    [] -> Error(Nil)
  }
}

/// Format float to 1 decimal place
fn format_float(value: Float) -> String {
  let truncated = float.truncate(value)
  let decimal = { value -. int.to_float(truncated) } *. 10.0
  let decimal_int = float.truncate(decimal)
  int.to_string(truncated) <> "." <> int.to_string(decimal_int)
}

// ===================================================================
// COMPONENT: MEAL CARD WRAPPER
// ===================================================================

/// Render a single meal card with category context
///
/// Wraps the existing meal_card component and adds:
/// - Meal category label (Breakfast, Lunch, Dinner)
/// - Day context for HTMX swap targets
///
/// HTMX Target Format: #day-{day_index}-{meal_type}-card
fn render_categorized_meal_card(
  meal: Meal,
  category: MealCategory,
  day_index: Int,
) -> Element(msg) {
  let category_str = meal_category_to_string(category)
  let category_id = meal_category_to_id(category)
  let card_id = "day-" <> int.to_string(day_index) <> "-" <> category_id

  div([class("meal-card-wrapper")], [
    h4([class("meal-category-label")], [text(category_str)]),
    meal_card.render_meal_card(meal, card_id),
  ])
}

// ===================================================================
// COMPONENT: DAILY NUTRITIONAL SUMMARY
// ===================================================================

/// Render compact nutritional summary for a single day
///
/// Displays:
/// - Total calories
/// - Protein (g)
/// - Carbs (g)
/// - Fat (g)
fn daily_nutrition_summary(plan: DailyPlan) -> Element(msg) {
  let macros = daily_plan_macros(plan)
  let calories = macros_calories(macros)

  let calories_str = int.to_string(float.truncate(calories))
  let protein_str = format_float(macros.protein)
  let carbs_str = format_float(macros.carbs)
  let fat_str = format_float(macros.fat)

  div([class("daily-nutrition-summary")], [
    h4([class("summary-title")], [text("Daily Totals")]),
    div([class("summary-grid")], [
      nutrition_item("Calories", calories_str, "kcal", "calories"),
      nutrition_item("Protein", protein_str, "g", "protein"),
      nutrition_item("Carbs", carbs_str, "g", "carbs"),
      nutrition_item("Fat", fat_str, "g", "fat"),
    ]),
  ])
}

/// Helper to render a single nutrition item
fn nutrition_item(
  label: String,
  value: String,
  unit: String,
  class_suffix: String,
) -> Element(msg) {
  div([class("nutrition-item nutrition-" <> class_suffix)], [
    span([class("nutrition-label")], [text(label)]),
    span([class("nutrition-value")], [text(value <> " " <> unit)]),
  ])
}

// ===================================================================
// COMPONENT: DAILY MEAL PLAN CARD
// ===================================================================

/// Render complete daily meal plan with all meals and summary
///
/// Displays:
/// - Day name header (e.g., "Monday", "Tuesday")
/// - Breakfast, Lunch, Dinner meal cards
/// - Daily nutritional summary
/// - Expandable/collapsible section via HTMX
///
/// HTMX Features:
/// - Click day header to expand/collapse
/// - Swap individual meals
pub fn daily_meal_plan_card(plan: DailyPlan, day_index: Int) -> Element(msg) {
  // Get meals by index (assuming 3 meals per day: breakfast, lunch, dinner)
  let breakfast_result = get_meal_by_index(plan, 0)
  let lunch_result = get_meal_by_index(plan, 1)
  let dinner_result = get_meal_by_index(plan, 2)

  // Build meal cards list
  let meal_cards = case breakfast_result, lunch_result, dinner_result {
    Ok(breakfast), Ok(lunch), Ok(dinner) -> [
      render_categorized_meal_card(breakfast, BreakfastMeal, day_index),
      render_categorized_meal_card(lunch, LunchMeal, day_index),
      render_categorized_meal_card(dinner, DinnerMeal, day_index),
    ]
    _, _, _ -> []
  }

  let day_id = "day-plan-" <> int.to_string(day_index)

  div(
    [
      class("daily-meal-plan-card"),
      attribute("data-day-index", int.to_string(day_index)),
    ],
    [
      div([class("day-header")], [
        h3([class("day-name")], [text(plan.day_name)]),
        button(
          [
            class("collapse-toggle"),
            attribute(
              "hx-get",
              "/api/meal-plan/day/" <> int.to_string(day_index) <> "/toggle",
            ),
            attribute("hx-target", "#" <> day_id <> "-body"),
            attribute("hx-swap", "outerHTML"),
          ],
          [text("▼")],
        ),
      ]),
      div([class("day-body"), attribute("id", day_id <> "-body")], [
        div([class("meals-grid")], meal_cards),
        daily_nutrition_summary(plan),
      ]),
    ],
  )
}

// ===================================================================
// COMPONENT: WEEKLY MEAL PLAN DISPLAY
// ===================================================================

/// Render complete weekly meal plan with all days
///
/// Displays:
/// - Week header with date range
/// - Daily meal plan cards for each day
/// - Weekly summary statistics
/// - Shopping list button (HTMX)
///
/// HTMX Features:
/// - Generate shopping list endpoint
/// - Regenerate meal plan endpoint
/// - Individual meal swaps within each day
pub fn weekly_meal_plan_display(plan: WeeklyMealPlan) -> Element(msg) {
  let day_cards =
    plan.days
    |> list.index_map(fn(day, index) { daily_meal_plan_card(day, index) })

  div([class("weekly-meal-plan-display")], [
    week_header(),
    div([class("weekly-actions")], [
      button(
        [
          class("btn btn-primary"),
          attribute("hx-get", "/api/meal-plan/shopping-list"),
          attribute("hx-target", "#shopping-list-modal"),
          attribute("hx-swap", "innerHTML"),
        ],
        [text("📋 View Shopping List")],
      ),
      button(
        [
          class("btn btn-secondary"),
          attribute("hx-post", "/api/meal-plan/regenerate"),
          attribute("hx-target", "#meal-plan-container"),
          attribute("hx-swap", "outerHTML"),
          attribute("hx-confirm", "Regenerate entire meal plan?"),
        ],
        [text("🔄 Regenerate Plan")],
      ),
    ]),
    div([class("days-container")], day_cards),
    weekly_summary(plan),
  ])
}

/// Render week header with current week info
fn week_header() -> Element(msg) {
  section([class("week-header")], [
    h2([class("week-title")], [text("Your Weekly Meal Plan")]),
    span([class("week-subtitle")], [text("7-day personalized nutrition plan")]),
  ])
}

/// Render weekly summary statistics
///
/// Displays:
/// - Average daily calories
/// - Average daily macros
/// - Total unique recipes
fn weekly_summary(plan: WeeklyMealPlan) -> Element(msg) {
  let avg_macros = meal_plan.weekly_plan_avg_daily_macros(plan)
  let avg_calories = macros_calories(avg_macros)

  let calories_str = int.to_string(float.truncate(avg_calories))
  let protein_str = format_float(avg_macros.protein)
  let carbs_str = format_float(avg_macros.carbs)
  let fat_str = format_float(avg_macros.fat)

  let total_days = list.length(plan.days)

  section([class("weekly-summary")], [
    h3([class("summary-title")], [text("Weekly Overview")]),
    div([class("summary-stats")], [
      stat_item("Total Days", int.to_string(total_days), "days"),
      stat_item("Avg Calories/Day", calories_str, "kcal"),
      stat_item("Avg Protein/Day", protein_str, "g"),
      stat_item("Avg Carbs/Day", carbs_str, "g"),
      stat_item("Avg Fat/Day", fat_str, "g"),
    ]),
  ])
}

/// Helper to render a single stat item
fn stat_item(label: String, value: String, unit: String) -> Element(msg) {
  div([class("stat-item")], [
    span([class("stat-label")], [text(label)]),
    span([class("stat-value")], [text(value <> " " <> unit)]),
  ])
}

// ===================================================================
// COMPONENT: EMPTY STATE
// ===================================================================

/// Render empty state when no meal plan exists
///
/// Displays:
/// - Call-to-action message
/// - Generate meal plan button (HTMX)
pub fn empty_meal_plan_state() -> Element(msg) {
  div([class("empty-meal-plan-state")], [
    h2([class("empty-title")], [text("No Meal Plan Yet")]),
    div([class("empty-message")], [
      text(
        "Generate your personalized weekly meal plan based on your nutrition goals.",
      ),
    ]),
    button(
      [
        class("btn btn-primary btn-large"),
        attribute("hx-post", "/api/meal-plan/generate"),
        attribute("hx-target", "#meal-plan-container"),
        attribute("hx-swap", "outerHTML"),
      ],
      [text("🎯 Generate Meal Plan")],
    ),
  ])
}

// ===================================================================
// COMPONENT: LOADING STATE
// ===================================================================

/// Render loading state during meal plan generation
///
/// Displays:
/// - Loading spinner
/// - Status message
pub fn loading_meal_plan_state() -> Element(msg) {
  div([class("loading-meal-plan-state")], [
    div([class("loading-spinner")], []),
    div([class("loading-message")], [
      text("Generating your personalized meal plan..."),
    ]),
  ])
}
