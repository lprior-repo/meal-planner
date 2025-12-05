/// Meal Card Component Module
///
/// This module provides a meal card component for displaying individual meals
/// with their nutritional information and meal swap functionality.
///
/// Features:
/// - Display meal name from recipe
/// - Show nutritional macros: calories, protein, carbs, fat
/// - HTMX swap button for dynamic meal replacement
/// - Proper element IDs for HTMX targeting
///
/// All components render as Lustre HTML elements suitable for SSR.
import gleam/float
import gleam/int
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/meal_plan.{type Meal, meal_macros}
import meal_planner/types.{macros_calories}

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Render a meal card with nutritional information and swap button
///
/// Displays:
/// - Meal name
/// - Calories (calculated from macros)
/// - Protein
/// - Carbs
/// - Fat
/// - HTMX swap button for replacing the meal
///
/// HTMX Attributes:
/// - hx-post: POST to /api/swap/:meal_type endpoint
/// - hx-target: #:meal_type-card (targets the card element)
/// - hx-swap: outerHTML (replaces the entire card)
///
/// Renders:
/// <div id=":meal_type-card" class="meal-card">
///   <div class="meal-name">Recipe Name</div>
///   <div class="meal-macros">
///     <div class="macro-item">
///       <span class="macro-label">Calories</span>
///       <span class="macro-value">500</span>
///     </div>
///     ...
///   </div>
///   <button hx-post="/api/swap/:meal_type"
///           hx-target="#:meal_type-card"
///           hx-swap="outerHTML"
///           class="btn btn-primary">Swap Meal</button>
/// </div>
pub fn render_meal_card(meal: Meal, meal_type: String) -> element.Element(msg) {
  let macros = meal_macros(meal)
  let calories = macros_calories(macros)
  let calories_int = float.truncate(calories)

  html.div([attribute.id(meal_type <> "-card"), attribute.class("meal-card")], [
    html.div([attribute.class("meal-name")], [element.text(meal.recipe.name)]),
    html.div([attribute.class("meal-macros")], [
      macro_item("Calories", int.to_string(calories_int), ""),
      macro_item("Protein", float.to_string(macros.protein), "g"),
      macro_item("Carbs", float.to_string(macros.carbs), "g"),
      macro_item("Fat", float.to_string(macros.fat), "g"),
    ]),
    html.button(
      [
        attribute.attribute("hx-post", "/api/swap/" <> meal_type),
        attribute.attribute("hx-target", "#" <> meal_type <> "-card"),
        attribute.attribute("hx-swap", "outerHTML"),
        attribute.class("btn btn-primary"),
      ],
      [element.text("Swap Meal")],
    ),
  ])
}

// ===================================================================
// PRIVATE HELPER FUNCTIONS
// ===================================================================

/// Helper function to render a macro item (label and value)
fn macro_item(
  label: String,
  value: String,
  unit: String,
) -> element.Element(msg) {
  html.div([attribute.class("macro-item")], [
    html.span([attribute.class("macro-label")], [element.text(label)]),
    html.span([attribute.class("macro-value")], [
      element.text(value <> unit),
    ]),
  ])
}
