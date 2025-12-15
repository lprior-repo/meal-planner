/// Tandoor Recipe Manager web handlers
///
/// Comprehensive Tandoor API endpoints structured like FatSecret handlers
///
/// Routes:
///
/// Status:
/// - GET /tandoor/status - Check Tandoor connection status
///
/// Recipes:
/// - GET /api/tandoor/recipes - List recipes (paginated)
/// - GET /api/tandoor/recipes/:id - Get recipe details
/// - POST /api/tandoor/recipes - Create recipe
/// - PATCH /api/tandoor/recipes/:id - Update recipe
/// - DELETE /api/tandoor/recipes/:id - Delete recipe
///
/// Ingredients:
/// - GET /api/tandoor/ingredients - List ingredients (paginated)
/// - GET /api/tandoor/ingredients/:id - Get ingredient details
/// - POST /api/tandoor/ingredients - Create ingredient
/// - PATCH /api/tandoor/ingredients/:id - Update ingredient
/// - DELETE /api/tandoor/ingredients/:id - Delete ingredient
///
/// Meal Plans:
/// - GET /api/tandoor/meal-plans - List meal plans (paginated, date-filtered)
/// - GET /api/tandoor/meal-plans/:id - Get meal plan details
/// - POST /api/tandoor/meal-plans - Create meal plan entry
/// - PATCH /api/tandoor/meal-plans/:id - Update meal plan entry
/// - DELETE /api/tandoor/meal-plans/:id - Delete meal plan entry
///
/// Keywords:
/// - GET /api/tandoor/keywords - List keywords
/// - GET /api/tandoor/keywords/:id - Get keyword details
///
/// Units:
/// - GET /api/tandoor/units - List measurement units

import gleam/http
import gleam/option

import meal_planner/env
import meal_planner/tandoor/client

import wisp

/// Main router for all Tandoor API requests
pub fn handle_tandoor_routes(_req: wisp.Request) -> wisp.Response {
  // All Tandoor handlers are disabled until they're properly implemented
  // Return not found for all Tandoor API routes
  wisp.not_found()
}

