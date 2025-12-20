/// Tandoor Recipe Manager web handlers
///
/// This module provides endpoints for Tandoor Recipe Manager integration,
/// including:
/// - Status checking
/// - Units listing
/// - Keywords listing
/// - Recipes CRUD operations
/// - Supermarkets CRUD operations
/// - Supermarket Categories CRUD operations
import gleam/json
import meal_planner/tandoor/handlers/helpers
import meal_planner/web/handlers/tandoor/export_logs
import meal_planner/web/handlers/tandoor/import_logs
import meal_planner/web/handlers/tandoor/ingredients
import meal_planner/web/handlers/tandoor/keywords
import meal_planner/web/handlers/tandoor/meal_plans
import meal_planner/web/handlers/tandoor/steps
import meal_planner/web/handlers/tandoor/supermarket_categories
import meal_planner/web/handlers/tandoor/supermarkets
import meal_planner/web/handlers/tandoor/recipes
import meal_planner/web/handlers/tandoor/units
import meal_planner/web/handlers/tandoor/preferences
import meal_planner/web/handlers/tandoor_cuisines

import wisp

/// Main router for Tandoor API requests
pub fn handle_tandoor_routes(req: wisp.Request) -> wisp.Response {
  let path = wisp.path_segments(req)

  case path {
    // Status endpoint
    ["tandoor", "status"] -> {
      case helpers.get_authenticated_client() {
        Ok(_) -> {
          json.object([
            #("status", json.string("connected")),
            #("service", json.string("tandoor")),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(resp) -> resp
      }
    }

    // Units (GET only)
    ["api", "tandoor", "units"] -> units.handle_units(req)

    // Keywords (GET only)
    ["api", "tandoor", "keywords"] -> keywords.handle_keywords(req)

    // Cuisines (GET list, POST create)
    ["api", "tandoor", "cuisines"] ->
      tandoor_cuisines.handle_cuisines_collection(req)

    // Cuisine by ID (GET, PUT, DELETE)
    ["api", "tandoor", "cuisines", cuisine_id] ->
      tandoor_cuisines.handle_cuisine_by_id(req, cuisine_id)

    // Recipes (GET list, POST create)
    ["api", "tandoor", "recipes"] ->
      recipes.handle_recipes_collection(req)

    // Recipe by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "recipes", recipe_id] ->
      recipes.handle_recipe_by_id(req, recipe_id)

    // Meal Plans (GET list, POST create)
    ["api", "tandoor", "meal-plans"] ->
      meal_plans.handle_meal_plans_collection(req)

    // Meal Plan by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "meal-plans", meal_plan_id] ->
      meal_plans.handle_meal_plan_by_id(req, meal_plan_id)

    // Steps (GET list, POST create)
    ["api", "tandoor", "steps"] -> steps.handle_steps_collection(req)

    // Step by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "steps", step_id] ->
      steps.handle_step_by_id(req, step_id)

    // Ingredients (GET list only)
    ["api", "tandoor", "ingredients"] ->
      ingredients.handle_ingredients_collection(req)

    // Import Logs
    ["api", "tandoor", "import-logs"] ->
      import_logs.handle_import_logs_collection(req)
    ["api", "tandoor", "import-logs", log_id] ->
      import_logs.handle_import_log_by_id(req, log_id)

    // Export Logs
    ["api", "tandoor", "export-logs"] ->
      export_logs.handle_export_logs_collection(req)
    ["api", "tandoor", "export-logs", log_id] ->
      export_logs.handle_export_log_by_id(req, log_id)

    // Supermarkets (GET list, POST create)
    ["api", "tandoor", "supermarkets"] ->
      supermarkets.handle_supermarkets_collection(req)

    // Supermarket by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarkets", supermarket_id] ->
      supermarkets.handle_supermarket_by_id(req, supermarket_id)

    // Supermarket Categories (GET list, POST create)
    ["api", "tandoor", "supermarket-categories"] ->
      supermarket_categories.handle_categories_collection(req)

    // Supermarket Category by ID (GET, PATCH, DELETE)
    ["api", "tandoor", "supermarket-categories", category_id] ->
      supermarket_categories.handle_category_by_id(req, category_id)

    // User Preferences (GET, PUT)
    ["api", "tandoor", "preferences"] -> preferences.handle_preferences(req)

    _ -> wisp.not_found()
  }
}
