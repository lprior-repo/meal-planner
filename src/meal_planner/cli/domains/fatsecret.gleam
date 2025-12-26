/// FatSecret CLI domain - Re-exports for backward compatibility
///
/// This module re-exports functions from the refactored command modules
/// to maintain backward compatibility with existing code.
///
/// New organization:
/// - fatsecret/commands/detail.gleam - Food detail lookups
/// - fatsecret/commands/search.gleam - Food search
/// - fatsecret/commands/ingredients.gleam - Ingredient operations
/// - fatsecret/formatters.gleam - Display formatting
/// - fatsecret/mod.gleam - Glint command registration
import glint
import meal_planner/cli/domains/fatsecret/commands/detail
import meal_planner/cli/domains/fatsecret/commands/ingredients
import meal_planner/cli/domains/fatsecret/mod
import meal_planner/config.{type Config}

// ============================================================================
// Re-exports - Handler Functions
// ============================================================================

/// Handler for `mp fatsecret detail <FOOD_ID>` command
pub fn detail_handler(
  config: Config,
  food_id_str: String,
) -> Result(Nil, String) {
  detail.detail_handler(config, food_id_str)
}

/// Handler for `mp fatsecret ingredients <QUERY>` command
pub fn ingredients_search_handler(
  config: Config,
  query: String,
) -> Result(Nil, String) {
  ingredients.ingredients_search_handler(config, query)
}

/// Handler for listing recipe ingredients with nutrition info
pub fn list_recipe_ingredients(
  config: Config,
  recipe_id recipe_id: Int,
) -> Result(Nil, String) {
  ingredients.list_recipe_ingredients(config, recipe_id)
}

// ============================================================================
// Re-exports - Glint Command Handler
// ============================================================================

/// FatSecret domain command for Glint CLI
pub fn cmd(app_config: Config) -> glint.Command(Result(Nil, Nil)) {
  mod.cmd(app_config)
}
