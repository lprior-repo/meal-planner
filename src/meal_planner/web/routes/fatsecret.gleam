//// FatSecret API routing module
////
//// Routes (organized by resource type):
//// - Brands: /api/fatsecret/brands
//// - Foods: /api/fatsecret/foods/*
//// - Recipes: /api/fatsecret/recipes/*
//// - Favorites: /api/fatsecret/favorites/*
//// - Saved Meals: /api/fatsecret/saved-meals/*
//// - Profile: /api/fatsecret/profile
//// - Diary: /api/fatsecret/diary/*
//// - Exercise: /api/fatsecret/exercises/*
//// - Weight: /api/fatsecret/weight/*

import gleam/http
import gleam/option.{type Option, None, Some}
import meal_planner/fatsecret/diary/handlers as diary_handlers
import meal_planner/fatsecret/exercise/handlers as exercise_handlers
import meal_planner/fatsecret/favorites/handlers as favorites_handlers
import meal_planner/fatsecret/saved_meals/handlers as saved_meals_handlers
import meal_planner/fatsecret/weight/handlers as weight_handlers
import meal_planner/web/handlers
import meal_planner/web/handlers/fatsecret/brands as brands_handler
import meal_planner/web/routes/types
import pog
import wisp

/// Route FatSecret API requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    // Brands API (2-legged OAuth)
    ["api", "fatsecret", "brands"] -> Some(brands_handler.handle_brands(req))

    // Foods API (2-legged OAuth)
    ["api", "fatsecret", "foods", ..food_segments] ->
      Some(route_foods(req, food_segments))

    // Recipes API (2-legged OAuth)
    ["api", "fatsecret", "recipes", ..recipe_segments] ->
      Some(route_recipes(req, recipe_segments))

    // Favorites API (3-legged OAuth)
    ["api", "fatsecret", "favorites", ..fav_segments] ->
      Some(route_favorites(req, fav_segments, ctx.db))

    // Saved Meals API (3-legged OAuth)
    ["api", "fatsecret", "saved-meals", ..meal_segments] ->
      Some(route_saved_meals(req, meal_segments, ctx.db))

    // Diary API (3-legged OAuth)
    ["api", "fatsecret", "diary", ..] ->
      Some(diary_handlers.handle_diary_routes(req, ctx.db))

    // Exercise API (3-legged OAuth)
    ["api", "fatsecret", "exercises", ..] ->
      Some(exercise_handlers.handle_exercise_routes(req, ctx.db))

    // Weight API (3-legged OAuth)
    ["api", "fatsecret", "weight", ..weight_segments] ->
      Some(route_weight(req, weight_segments, ctx.db))

    // Profile API (3-legged OAuth)
    ["api", "fatsecret", "profile", ..profile_segments] ->
      Some(route_profile(req, profile_segments, ctx.db))

    _ -> None
  }
}

// ============================================================================
// Foods API Routing
// ============================================================================

fn route_foods(req: wisp.Request, segments: List(String)) -> wisp.Response {
  case segments {
    ["autocomplete"] -> handlers.handle_fatsecret_autocomplete_foods(req)
    ["search"] -> handlers.handle_fatsecret_search_foods(req)
    [food_id] -> handlers.handle_fatsecret_get_food(req, food_id)
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Recipes API Routing
// ============================================================================

fn route_recipes(req: wisp.Request, segments: List(String)) -> wisp.Response {
  case segments {
    ["autocomplete"] -> handlers.handle_fatsecret_autocomplete_recipes(req)
    ["types"] -> handlers.handle_fatsecret_recipe_types(req)
    ["search"] -> handlers.handle_fatsecret_search_recipes(req)
    ["search", "type", type_id] ->
      handlers.handle_fatsecret_search_recipes_by_type(req, type_id)
    [recipe_id] -> handlers.handle_fatsecret_get_recipe(req, recipe_id)
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Favorites API Routing
// ============================================================================

fn route_favorites(
  req: wisp.Request,
  segments: List(String),
  db: pog.Connection,
) -> wisp.Response {
  case segments {
    ["foods", "most-eaten"] -> favorites_handlers.get_most_eaten(req, db)

    ["foods", "recently-eaten"] ->
      favorites_handlers.get_recently_eaten(req, db)

    ["foods", food_id] ->
      case req.method {
        http.Post -> favorites_handlers.add_favorite_food(req, db, food_id)
        http.Delete -> favorites_handlers.delete_favorite_food(req, db, food_id)
        _ -> wisp.method_not_allowed([http.Post, http.Delete])
      }

    ["foods"] -> favorites_handlers.get_favorite_foods(req, db)

    ["recipes"] -> favorites_handlers.get_favorite_recipes(req, db)

    ["recipes", recipe_id] ->
      case req.method {
        http.Post -> favorites_handlers.add_favorite_recipe(req, db, recipe_id)
        http.Delete ->
          favorites_handlers.delete_favorite_recipe(req, db, recipe_id)
        _ -> wisp.method_not_allowed([http.Post, http.Delete])
      }

    _ -> wisp.not_found()
  }
}

// ============================================================================
// Saved Meals API Routing
// ============================================================================

fn route_saved_meals(
  req: wisp.Request,
  segments: List(String),
  db: pog.Connection,
) -> wisp.Response {
  saved_meals_handlers.route(req, segments, db)
}

// ============================================================================
// Weight API Routing
// ============================================================================

fn route_weight(
  req: wisp.Request,
  segments: List(String),
  db: pog.Connection,
) -> wisp.Response {
  case segments {
    [] ->
      case req.method {
        http.Get -> weight_handlers.get_weight_by_date(req, db)
        http.Post -> weight_handlers.update_weight(req, db)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }

    ["month", year, month] ->
      case req.method {
        http.Get -> weight_handlers.get_weight_month(req, db, year, month)
        _ -> wisp.method_not_allowed([http.Get])
      }

    _ -> wisp.not_found()
  }
}

// ============================================================================
// Profile API Routing
// ============================================================================

fn route_profile(
  req: wisp.Request,
  segments: List(String),
  db: pog.Connection,
) -> wisp.Response {
  case segments {
    [] ->
      case req.method {
        http.Get -> handlers.handle_fatsecret_profile(req, db)
        http.Post -> handlers.handle_fatsecret_create_profile(req, db)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }

    ["auth", user_id] ->
      handlers.handle_fatsecret_get_profile_auth(req, db, user_id)

    _ -> wisp.not_found()
  }
}
