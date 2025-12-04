/// Card Components Module
///
/// This module provides card components for displaying content:
/// - Basic cards
/// - Cards with headers
/// - Cards with headers and actions
/// - Stat cards (value-focused)
/// - Recipe cards (for grid display)
/// - Food cards (search results)
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Cards)
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/nutrition_constants
import meal_planner/ui/types/ui_types

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Basic card container
///
/// Renders: <div class="card">content</div>
pub fn card(content: List(element.Element(msg))) -> element.Element(msg) {
  html.div([attribute.class("card")], content)
}

/// Card with header
///
/// Renders:
/// <div class="card">
///   <div class="card-header">Header</div>
///   <div class="card-body">content</div>
/// </div>
pub fn card_with_header(
  header: String,
  content: List(element.Element(msg)),
) -> element.Element(msg) {
  html.div([attribute.class("card")], [
    html.div([attribute.class("card-header")], [element.text(header)]),
    html.div([attribute.class("card-body")], content),
  ])
}

/// Card with header and actions
///
/// Renders:
/// <div class="card">
///   <div class="card-header">
///     Header
///     <div class="card-actions">actions...</div>
///   </div>
///   <div class="card-body">content</div>
/// </div>
pub fn card_with_actions(
  header: String,
  content: List(element.Element(msg)),
  actions: List(element.Element(msg)),
) -> element.Element(msg) {
  html.div([attribute.class("card")], [
    html.div([attribute.class("card-header")], [
      element.text(header),
      html.div([attribute.class("card-actions")], actions),
    ]),
    html.div([attribute.class("card-body")], content),
  ])
}

/// Statistic card (value-focused)
///
/// Renders:
/// <div class="stat-card">
///   <div class="stat-value">2100</div>
///   <div class="stat-unit">kcal</div>
///   <div class="stat-label">Calories</div>
/// </div>
pub fn stat_card(stat: ui_types.StatCard) -> element.Element(msg) {
  let ui_types.StatCard(
    label: label,
    value: value,
    unit: unit,
    trend: _,
    color: color,
  ) = stat
  html.div(
    [
      attribute.class("stat-card"),
      attribute.style([#("--color", color)]),
    ],
    [
      html.div([attribute.class("stat-value")], [element.text(value)]),
      html.div([attribute.class("stat-unit")], [element.text(unit)]),
      html.div([attribute.class("stat-label")], [element.text(label)]),
    ],
  )
}

/// Recipe card for display in grid
///
/// Renders:
/// <div class="recipe-card">
///   <img src="image_url" />
///   <div class="recipe-info">
///     <h3>Recipe Name</h3>
///     <span class="category">Category</span>
///     <div class="calories">Calories: 500</div>
///   </div>
/// </div>
pub fn recipe_card(data: ui_types.RecipeCardData) -> element.Element(msg) {
  let ui_types.RecipeCardData(
    id: _,
    name: name,
    category: category,
    calories: calories,
    image_url: image_url,
  ) = data
  let calories_str = calories |> float.truncate |> int.to_string

  let image_element = case image_url {
    option.Some(url) -> [html.img([attribute.src(url)])]
    option.None -> []
  }

  let children =
    list.append(image_element, [
      html.div([attribute.class("recipe-info")], [
        html.h3([], [element.text(name)]),
        html.span([attribute.class("category")], [element.text(category)]),
        html.div([attribute.class("calories")], [element.text(calories_str)]),
      ]),
    ])

  html.div([attribute.class("recipe-card")], children)
}

/// Food search result card
///
/// Renders:
/// <div class="food-card">
///   <div class="food-description">Chicken, raw</div>
///   <div class="food-category">SR Legacy Foods</div>
///   <div class="food-type">Survey (FNDDS)</div>
/// </div>
pub fn food_card(data: ui_types.FoodCardData) -> element.Element(msg) {
  let ui_types.FoodCardData(
    fdc_id: _,
    description: description,
    data_type: data_type,
    category: category,
  ) = data
  html.div([attribute.class("food-card")], [
    html.div([attribute.class("food-description")], [element.text(description)]),
    html.div([attribute.class("food-category")], [element.text(category)]),
    html.div([attribute.class("food-type")], [element.text(data_type)]),
  ])
}

// ===================================================================
// CALORIE SUMMARY CARD (Bead meal-planner-uzr.1)
// ===================================================================

/// Calorie summary card component
///
/// Features:
/// - Displays current and target calories
/// - Percentage indicator with color coding (green/yellow/red)
/// - Animated counter transition (data attribute for JS)
/// - Date navigation buttons (prev/next day)
///
/// Color coding:
/// - Green: < 90% of target
/// - Yellow: 90-100% of target
/// - Red: > 100% of target
///
/// Renders:
/// <div class="calorie-summary-card">
///   <div class="date-nav">...</div>
///   <div class="calorie-display">
///     <div class="current animated-counter">1850</div>
///     <div class="target">/ 2000</div>
///   </div>
///   <div class="percentage percentage-green">92%</div>
/// </div>
pub fn calorie_summary_card(
  current_calories: Float,
  target_calories: Float,
  date: String,
) -> element.Element(msg) {
  let current_int = float.truncate(current_calories)
  let target_int = float.truncate(target_calories)
  let percentage = { current_calories /. target_calories } *. 100.0
  let percentage_int = float.truncate(percentage)

  let percentage_class = case percentage {
    p if p <. nutrition_constants.calorie_deficit_threshold ->
      "percentage percentage-green"
    p if p <=. nutrition_constants.calorie_match_threshold ->
      "percentage percentage-yellow"
    _ -> "percentage percentage-red"
  }

  html.div([attribute.class("calorie-summary-card")], [
    html.div([attribute.class("date-nav")], [
      html.button([attribute.class("btn-prev-day")], [element.text("<")]),
      html.span([attribute.class("current-date")], [element.text(date)]),
      html.button([attribute.class("btn-next-day")], [element.text(">")]),
    ]),
    html.div([attribute.class("calorie-display")], [
      html.div(
        [
          attribute.class("current animated-counter"),
          attribute.attribute(
            "data-animate-duration",
            int.to_string(nutrition_constants.calorie_animation_duration),
          ),
        ],
        [element.text(int.to_string(current_int))],
      ),
      html.div([attribute.class("separator")], [element.text("/")]),
      html.div([attribute.class("target")], [
        element.text(int.to_string(target_int)),
      ]),
    ]),
    html.div([attribute.class(percentage_class)], [
      element.text(int.to_string(percentage_int) <> "%"),
    ]),
  ])
}
