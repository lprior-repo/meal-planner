/// Web server routing for the Meal Planner API
///
/// This module centralizes all HTTP route handling, delegating to
/// handler modules in web/handlers/ and fatsecret/*/handlers.gleam
import gleam/http
import gleam/int
import gleam/io
import meal_planner/config
import meal_planner/fatsecret/favorites/handlers as favorites_handlers
import meal_planner/fatsecret/foods/handlers as foods_handlers
import meal_planner/fatsecret/profile/oauth as profile_oauth
import meal_planner/fatsecret/recipes/handlers as recipes_handlers
import meal_planner/fatsecret/saved_meals/handlers as saved_meals_handlers
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/web/handlers
import pog
import wisp

/// Application context passed to handlers
pub type Context {
  Context(config: config.Config, db: pog.Connection)
}

/// Main request router
///
/// Routes are organized by domain:
/// - Health & Status: /health, /
/// - Dashboard UI: /dashboard, /log/food/:id
/// - FatSecret OAuth: /fatsecret/connect, /callback, /status, /disconnect
/// - FatSecret Foods API: /api/fatsecret/foods/*
/// - FatSecret Recipes API: /api/fatsecret/recipes/*
/// - FatSecret Favorites API: /api/fatsecret/favorites/*
/// - FatSecret Saved Meals API: /api/fatsecret/saved-meals/*
/// - FatSecret Diary API: /api/fatsecret/diary/*
/// - FatSecret Exercise API: /api/fatsecret/exercises/*
/// - FatSecret Weight API: /api/fatsecret/weight/*
/// - FatSecret Profile API: /api/fatsecret/profile
/// - Other APIs: /api/dashboard/data, /api/ai/score-recipe, etc.
/// - Tandoor: /tandoor/*, /api/tandoor/*
pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  let base_url = "http://localhost:" <> int.to_string(ctx.config.server.port)

  // Parse the request path and route to appropriate handler
  case wisp.path_segments(req) {
    // =========================================================================
    // Health & Status
    // =========================================================================
    [] -> handlers.handle_health(req)
    ["health"] -> handlers.handle_health(req)

    // =========================================================================
    // Dashboard UI (legacy, being phased out)
    // =========================================================================
    ["dashboard"] -> handlers.handle_dashboard(req, ctx.db)
    ["log", "food", fdc_id] ->
      handlers.handle_log_food_form(req, ctx.db, fdc_id)

    // =========================================================================
    // FatSecret OAuth 3-Legged Flow (User Authentication)
    // =========================================================================
    ["fatsecret", "connect"] ->
      handlers.handle_fatsecret_connect(req, ctx.db, base_url)
    ["fatsecret", "callback"] -> handlers.handle_fatsecret_callback(req, ctx.db)
    ["fatsecret", "status"] -> handlers.handle_fatsecret_status(req, ctx.db)
    ["fatsecret", "disconnect"] ->
      handlers.handle_fatsecret_disconnect(req, ctx.db)

    // =========================================================================
    // FatSecret Foods API (2-legged OAuth, no user auth required)
    // =========================================================================
    ["api", "fatsecret", "foods", food_id] ->
      foods_handlers.handle_get_food(req, food_id)
    ["api", "fatsecret", "foods", "search"] ->
      foods_handlers.handle_search_foods(req)

    // =========================================================================
    // FatSecret Recipes API (2-legged OAuth, no user auth required)
    // =========================================================================
    ["api", "fatsecret", "recipes", "types"] ->
      handlers.handle_fatsecret_recipe_types(req)
    ["api", "fatsecret", "recipes", "search"] ->
      handlers.handle_fatsecret_search_recipes(req)
    ["api", "fatsecret", "recipes", "search", "type", type_id] ->
      handlers.handle_fatsecret_search_recipes_by_type(req, type_id)
    ["api", "fatsecret", "recipes", recipe_id] ->
      handlers.handle_fatsecret_get_recipe(req, recipe_id)

    // =========================================================================
    // FatSecret Favorites API (3-legged OAuth, requires user auth)
    // =========================================================================
    // Favorite Foods
    ["api", "fatsecret", "favorites", "foods"] ->
      case req.method {
        http.Get -> favorites_handlers.get_favorite_foods(req, ctx.db)
        _ -> wisp.method_not_allowed([http.Get])
      }
    ["api", "fatsecret", "favorites", "foods", "most-eaten"] ->
      favorites_handlers.get_most_eaten(req, ctx.db)
    ["api", "fatsecret", "favorites", "foods", "recently-eaten"] ->
      favorites_handlers.get_recently_eaten(req, ctx.db)
    ["api", "fatsecret", "favorites", "foods", food_id] ->
      case req.method {
        http.Post -> favorites_handlers.add_favorite_food(req, ctx.db, food_id)
        http.Delete ->
          favorites_handlers.delete_favorite_food(req, ctx.db, food_id)
        _ -> wisp.method_not_allowed([http.Post, http.Delete])
      }

    // Favorite Recipes
    ["api", "fatsecret", "favorites", "recipes"] ->
      case req.method {
        http.Get -> favorites_handlers.get_favorite_recipes(req, ctx.db)
        _ -> wisp.method_not_allowed([http.Get])
      }
    ["api", "fatsecret", "favorites", "recipes", recipe_id] ->
      case req.method {
        http.Post ->
          favorites_handlers.add_favorite_recipe(req, ctx.db, recipe_id)
        http.Delete ->
          favorites_handlers.delete_favorite_recipe(req, ctx.db, recipe_id)
        _ -> wisp.method_not_allowed([http.Post, http.Delete])
      }

    // =========================================================================
    // FatSecret Saved Meals API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "saved-meals"] ->
      case req.method {
        http.Get -> saved_meals_handlers.handle_get_saved_meals(req, ctx.db)
        http.Post -> saved_meals_handlers.handle_create_saved_meal(req, ctx.db)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "saved-meals", meal_id] ->
      case req.method {
        http.Put ->
          saved_meals_handlers.handle_edit_saved_meal(req, ctx.db, meal_id)
        http.Delete ->
          saved_meals_handlers.handle_delete_saved_meal(req, ctx.db, meal_id)
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }
    ["api", "fatsecret", "saved-meals", meal_id, "items"] ->
      case req.method {
        http.Get ->
          saved_meals_handlers.handle_get_saved_meal_items(req, ctx.db, meal_id)
        http.Post ->
          saved_meals_handlers.handle_add_saved_meal_item(req, ctx.db, meal_id)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "saved-meals", meal_id, "items", item_id] ->
      case req.method {
        http.Put ->
          saved_meals_handlers.handle_edit_saved_meal_item(
            req,
            ctx.db,
            meal_id,
            item_id,
          )
        http.Delete ->
          saved_meals_handlers.handle_delete_saved_meal_item(
            req,
            ctx.db,
            meal_id,
            item_id,
          )
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    // =========================================================================
    // FatSecret Diary API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "diary"] ->
      case req.method {
        http.Get ->
          // GET /api/fatsecret/diary?date=YYYY-MM-DD - Get day's entries
          handlers.handle_fatsecret_entries(req, ctx.db)
        http.Post ->
          // POST /api/fatsecret/diary - Create new entry
          wisp.not_found()
        // TODO: implement diary handlers
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "diary", entry_id] ->
      case req.method {
        http.Put ->
          // PUT /api/fatsecret/diary/:entry_id - Update entry
          wisp.not_found()
        // TODO: implement diary handlers
        http.Delete ->
          // DELETE /api/fatsecret/diary/:entry_id - Delete entry
          wisp.not_found()
        // TODO: implement diary handlers
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }
    ["api", "fatsecret", "diary", "month"] ->
      // GET /api/fatsecret/diary/month?year=2024&month=12 - Month summary
      wisp.not_found()

    // TODO: implement diary handlers
    // =========================================================================
    // FatSecret Exercise API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "exercises"] ->
      case req.method {
        http.Get ->
          // GET /api/fatsecret/exercises?q=running - Search exercises
          wisp.not_found()
        // TODO: implement exercise handlers
        _ -> wisp.method_not_allowed([http.Get])
      }
    ["api", "fatsecret", "exercise-entries"] ->
      case req.method {
        http.Get ->
          // GET /api/fatsecret/exercise-entries?date=YYYY-MM-DD - Get day's entries
          wisp.not_found()
        // TODO: implement exercise handlers
        http.Post ->
          // POST /api/fatsecret/exercise-entries - Create new entry
          wisp.not_found()
        // TODO: implement exercise handlers
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "exercise-entries", entry_id] ->
      case req.method {
        http.Put ->
          // PUT /api/fatsecret/exercise-entries/:entry_id - Update entry
          wisp.not_found()
        // TODO: implement exercise handlers
        http.Delete ->
          // DELETE /api/fatsecret/exercise-entries/:entry_id - Delete entry
          wisp.not_found()
        // TODO: implement exercise handlers
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    // =========================================================================
    // FatSecret Weight API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "weight"] ->
      case req.method {
        http.Get ->
          // GET /api/fatsecret/weight?date=YYYY-MM-DD - Get weight for date
          wisp.not_found()
        // TODO: implement weight handlers
        http.Post ->
          // POST /api/fatsecret/weight - Update weight for date
          wisp.not_found()
        // TODO: implement weight handlers
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "weight", "month"] ->
      case req.method {
        http.Get ->
          // GET /api/fatsecret/weight/month?year=2024&month=12 - Month summary
          wisp.not_found()
        // TODO: implement weight handlers
        _ -> wisp.method_not_allowed([http.Get])
      }

    // =========================================================================
    // FatSecret Profile API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "profile"] ->
      handlers.handle_fatsecret_profile(req, ctx.db)

    // =========================================================================
    // Legacy API Endpoints (being refactored to use new SDK)
    // =========================================================================
    ["api", "dashboard", "data"] -> handlers.handle_dashboard_data(req, ctx.db)
    ["api", "ai", "score-recipe"] -> handlers.handle_score_recipe(req)
    ["api", "diet", "vertical", "compliance", recipe_id] ->
      handlers.handle_diet_compliance(req, recipe_id)
    ["api", "macros", "calculate"] -> handlers.handle_macros_calculate(req)
    ["api", "logs", "food"] -> handlers.handle_log_food(req, ctx.db)

    // =========================================================================
    // Tandoor Recipe Manager Integration
    // =========================================================================
    ["tandoor", "status"] -> handlers.handle_tandoor_status(req)
    ["api", "tandoor", "recipes"] -> handlers.handle_tandoor_list_recipes(req)
    ["api", "tandoor", "recipes", recipe_id] ->
      handlers.handle_tandoor_get_recipe(req, recipe_id)
    ["api", "tandoor", "meal-plan"] ->
      case req.method {
        http.Get -> handlers.handle_tandoor_get_meal_plan(req)
        http.Post -> handlers.handle_tandoor_create_meal_plan(req)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "tandoor", "meal-plan", entry_id] ->
      handlers.handle_tandoor_delete_meal_plan(req, entry_id)

    // =========================================================================
    // 404 Not Found
    // =========================================================================
    _ -> wisp.not_found()
  }
}

/// Print startup information about available routes
pub fn print_routes() -> Nil {
  io.println("\n=== FatSecret SDK Routes ===")
  io.println("OAuth:")
  io.println("  GET  /fatsecret/connect       - Start OAuth flow")
  io.println("  GET  /fatsecret/callback      - OAuth callback")
  io.println("  GET  /fatsecret/status        - Check auth status")
  io.println("  POST /fatsecret/disconnect    - Disconnect account")
  io.println("")
  io.println("Foods (2-legged):")
  io.println("  GET  /api/fatsecret/foods/:id         - Get food details")
  io.println("  GET  /api/fatsecret/foods/search      - Search foods")
  io.println("")
  io.println("Recipes (2-legged):")
  io.println("  GET  /api/fatsecret/recipes/types     - List recipe types")
  io.println("  GET  /api/fatsecret/recipes/search    - Search recipes")
  io.println("  GET  /api/fatsecret/recipes/:id       - Get recipe details")
  io.println("")
  io.println("Favorites (3-legged):")
  io.println(
    "  GET    /api/fatsecret/favorites/foods              - List favorites",
  )
  io.println(
    "  POST   /api/fatsecret/favorites/foods/:id          - Add favorite",
  )
  io.println(
    "  DELETE /api/fatsecret/favorites/foods/:id          - Remove favorite",
  )
  io.println(
    "  GET    /api/fatsecret/favorites/foods/most-eaten   - Most eaten",
  )
  io.println(
    "  GET    /api/fatsecret/favorites/foods/recently-eaten - Recently eaten",
  )
  io.println("")
  io.println("Saved Meals (3-legged):")
  io.println("  GET    /api/fatsecret/saved-meals              - List meals")
  io.println("  POST   /api/fatsecret/saved-meals              - Create meal")
  io.println("  PUT    /api/fatsecret/saved-meals/:id          - Edit meal")
  io.println("  DELETE /api/fatsecret/saved-meals/:id          - Delete meal")
  io.println("  GET    /api/fatsecret/saved-meals/:id/items    - Get items")
  io.println("  POST   /api/fatsecret/saved-meals/:id/items    - Add item")
  io.println("")
  io.println("Profile (3-legged):")
  io.println("  GET  /api/fatsecret/profile               - Get user profile")
  io.println("")
  io.println("Diary, Exercise, Weight APIs coming soon...")
  io.println("")
}
