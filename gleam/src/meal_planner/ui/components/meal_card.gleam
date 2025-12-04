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
/// All components render as HTML strings suitable for SSR.
import gleam/float
import gleam/int
import meal_planner/meal_plan.{type Meal, meal_macros}
import meal_planner/types.{type Macros, macros_calories}

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
pub fn render_meal_card(meal: Meal, meal_type: String) -> String {
  let macros = meal_macros(meal)
  let calories = macros_calories(macros)
  let calories_int = float.truncate(calories)
  let protein_str = float.to_string(macros.protein)
  let carbs_str = float.to_string(macros.carbs)
  let fat_str = float.to_string(macros.fat)

  "<div id=\""
  <> meal_type
  <> "-card\" class=\"meal-card\">"
  <> "<div class=\"meal-name\">"
  <> meal.recipe.name
  <> "</div>"
  <> "<div class=\"meal-macros\">"
  <> "<div class=\"macro-item\">"
  <> "<span class=\"macro-label\">Calories</span>"
  <> "<span class=\"macro-value\">"
  <> int.to_string(calories_int)
  <> "</span>"
  <> "</div>"
  <> "<div class=\"macro-item\">"
  <> "<span class=\"macro-label\">Protein</span>"
  <> "<span class=\"macro-value\">"
  <> protein_str
  <> "g</span>"
  <> "</div>"
  <> "<div class=\"macro-item\">"
  <> "<span class=\"macro-label\">Carbs</span>"
  <> "<span class=\"macro-value\">"
  <> carbs_str
  <> "g</span>"
  <> "</div>"
  <> "<div class=\"macro-item\">"
  <> "<span class=\"macro-label\">Fat</span>"
  <> "<span class=\"macro-value\">"
  <> fat_str
  <> "g</span>"
  <> "</div>"
  <> "</div>"
  <> "<button hx-post=\"/api/swap/"
  <> meal_type
  <> "\" hx-target=\"#"
  <> meal_type
  <> "-card\" hx-swap=\"outerHTML\" class=\"btn btn-primary\">Swap Meal</button>"
  <> "</div>"
}
