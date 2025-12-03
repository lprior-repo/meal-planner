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

import gleam/option
import meal_planner/ui/types/ui_types

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Basic card container
///
/// Renders: <div class="card">content</div>
pub fn card(
  content: List(String),
) -> String {
  // CONTRACT: Returns HTML string for basic card container
  // BODY: TODO - Implement as div with card class containing content list
  todo
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
  content: List(String),
) -> String {
  // CONTRACT: Returns HTML string for card with header
  // BODY: TODO - Implement with card-header and card-body sections
  todo
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
  content: List(String),
  actions: List(String),
) -> String {
  // CONTRACT: Returns HTML string for card with header and actions
  // BODY: TODO - Implement with card-header containing actions, and card-body
  todo
}

/// Statistic card (value-focused)
///
/// Renders:
/// <div class="stat-card">
///   <div class="stat-value">2100</div>
///   <div class="stat-unit">kcal</div>
///   <div class="stat-label">Calories</div>
/// </div>
pub fn stat_card(stat: ui_types.StatCard) -> String {
  // CONTRACT: Returns HTML string for stat card
  // BODY: TODO - Implement with stat-value, stat-unit, stat-label
  // Note: trend field should optionally render as indicator
  todo
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
pub fn recipe_card(data: ui_types.RecipeCardData) -> String {
  // CONTRACT: Returns HTML string for recipe card
  // BODY: TODO - Implement with image (if available), name, category, calories
  todo
}

/// Food search result card
///
/// Renders:
/// <div class="food-card">
///   <div class="food-description">Chicken, raw</div>
///   <div class="food-category">SR Legacy Foods</div>
///   <div class="food-type">Survey (FNDDS)</div>
/// </div>
pub fn food_card(data: ui_types.FoodCardData) -> String {
  // CONTRACT: Returns HTML string for food result card
  // BODY: TODO - Implement with food-description, food-category, food-type
  todo
}
