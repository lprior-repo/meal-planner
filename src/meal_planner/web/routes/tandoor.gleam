//// Tandoor Recipe Manager routing module
////
//// Routes:
//// - /tandoor/status
//// - /api/tandoor/recipes/*
//// - /api/tandoor/units
//// - /api/tandoor/keywords
//// - /api/tandoor/meal-plans/*
//// - /api/tandoor/shopping-list-entries/*
//// - /api/tandoor/shopping-list-recipe
//// - /api/tandoor/supermarkets/*
//// - /api/tandoor/supermarket-categories/*
//// - /api/tandoor/import-logs/*
//// - /api/tandoor/export-logs/*

import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers
import meal_planner/web/routes/types
import wisp

/// Route Tandoor integration requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  _ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    // Tandoor status
    ["tandoor", "status"] -> Some(handlers.handle_tandoor_routes(req))

    // Recipes
    ["api", "tandoor", "recipes"] -> Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "recipes", _recipe_id] ->
      Some(handlers.handle_tandoor_routes(req))

    // Units
    ["api", "tandoor", "units"] -> Some(handlers.handle_tandoor_routes(req))

    // Keywords
    ["api", "tandoor", "keywords"] -> Some(handlers.handle_tandoor_routes(req))

    // Meal Plans
    ["api", "tandoor", "meal-plans"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "meal-plans", _entry_id] ->
      Some(handlers.handle_tandoor_routes(req))

    // Shopping Lists
    ["api", "tandoor", "shopping-list-entries"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "shopping-list-entries", _entry_id] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "shopping-list-recipe"] ->
      Some(handlers.handle_tandoor_routes(req))

    // Supermarkets
    ["api", "tandoor", "supermarkets"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "supermarkets", _supermarket_id] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "supermarket-categories"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "supermarket-categories", _category_id] ->
      Some(handlers.handle_tandoor_routes(req))

    // Import/Export Logs
    ["api", "tandoor", "import-logs"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "import-logs", _log_id] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "export-logs"] ->
      Some(handlers.handle_tandoor_routes(req))
    ["api", "tandoor", "export-logs", _log_id] ->
      Some(handlers.handle_tandoor_routes(req))

    _ -> None
  }
}
