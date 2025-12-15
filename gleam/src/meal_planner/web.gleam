/// Web server module for the Meal Planner API
///
/// This module centralizes all HTTP routing and server startup, delegating to
/// handler modules in web/handlers/ and fatsecret/*/handlers.gleam
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/option
import meal_planner/config
import meal_planner/fatsecret/diary/handlers as diary_handlers

import meal_planner/fatsecret/favorites/handlers as favorites_handlers
import meal_planner/fatsecret/saved_meals/handlers as saved_meals_handlers

import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/postgres
import meal_planner/web/handlers
import mist
import pog
import wisp
import wisp/wisp_mist

/// Application context passed to handlers
pub type Context {
  Context(config: config.Config, db: pog.Connection)
}

/// Start the HTTP server
pub fn start(app_config: config.Config) -> Nil {
  // Connect to database
  let db_config =
    postgres.Config(
      host: app_config.database.host,
      port: app_config.database.port,
      database: app_config.database.name,
      user: app_config.database.user,
      password: option.Some(app_config.database.password),
      pool_size: 10,
    )

  let assert Ok(db) = postgres.connect(db_config)
  io.println("✓ Database connection established")

  // Validate FatSecret connection at startup
  let fatsecret_status = fatsecret_service.startup_check(db)
  io.println(fatsecret_status)

  let ctx = Context(config: app_config, db: db)

  // Configure logging
  wisp.configure_logger()

  // Create the handler function
  let handler = fn(req: wisp.Request) -> wisp.Response {
    handle_request(req, ctx)
  }

  // Create a secret key base for session handling
  let secret_key_base = wisp.random_string(64)

  // Start the Mist server with Wisp handler
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(app_config.server.port)
    |> mist.start

  io.println(
    "🚀 Meal Planner API server started on http://localhost:"
    <> int.to_string(app_config.server.port),
  )

  // Keep the server running
  process.sleep_forever()
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
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
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
    // IMPORTANT: Specific routes MUST come before catch-all patterns!
    ["api", "fatsecret", "foods", "autocomplete"] ->
      handlers.handle_fatsecret_autocomplete_foods(req)
    ["api", "fatsecret", "foods", "search"] ->
      handlers.handle_fatsecret_search_foods(req)
    ["api", "fatsecret", "foods", food_id] ->
      handlers.handle_fatsecret_get_food(req, food_id)

    // =========================================================================
    // FatSecret Recipes API (2-legged OAuth, no user auth required)
    // =========================================================================
    ["api", "fatsecret", "recipes", "autocomplete"] ->
      handlers.handle_fatsecret_autocomplete_recipes(req)
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
    // IMPORTANT: Specific routes must come BEFORE catch-all patterns
    // Note: Handlers check methods internally - no need for double-checking
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
    ["api", "fatsecret", "favorites", "foods"] ->
      favorites_handlers.get_favorite_foods(req, ctx.db)

    // Favorite Recipes
    // Note: Handlers check methods internally - no need for double-checking
    ["api", "fatsecret", "favorites", "recipes"] ->
      favorites_handlers.get_favorite_recipes(req, ctx.db)
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
        http.Delete -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }
    ["api", "fatsecret", "saved-meals", _meal_id, "items"] ->
      case req.method {
        http.Get -> wisp.not_found()
        http.Post -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "saved-meals", _meal_id, "items", _item_id] ->
      case req.method {
        http.Put -> wisp.not_found()
        http.Delete -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    // =========================================================================
    // FatSecret Diary API (3-legged OAuth, requires user auth)
    // =========================================================================
    // Delegated routing to diary handlers module (production-ready, 824 lines)
    // Handles:
    //   POST /api/fatsecret/diary/entries - Create food entry
    //   GET /api/fatsecret/diary/entries/:entry_id - Get single entry
    //   PATCH /api/fatsecret/diary/entries/:entry_id - Edit entry
    //   DELETE /api/fatsecret/diary/entries/:entry_id - Delete entry
    //   GET /api/fatsecret/diary/day/:date_int - Get all entries for date
    //   GET /api/fatsecret/diary/month/:date_int - Get month summary
    ["api", "fatsecret", "diary", ..] ->
      diary_handlers.handle_diary_routes(req, ctx.db)
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
        http.Get -> wisp.not_found()
        http.Post -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "exercise-entries", _entry_id] ->
      case req.method {
        http.Put -> wisp.not_found()
        http.Delete -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    // =========================================================================
    // FatSecret Weight API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "weight"] ->
      case req.method {
        http.Get -> wisp.not_found()
        http.Post -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "weight", "month", _year, _month] ->
      case req.method {
        http.Get -> wisp.not_found()
        _ -> wisp.method_not_allowed([http.Get])
      }

    // =========================================================================
    // FatSecret Profile API (3-legged OAuth, requires user auth)
    // =========================================================================
    ["api", "fatsecret", "profile"] ->
      case req.method {
        http.Get -> handlers.handle_fatsecret_profile(req, ctx.db)
        http.Post -> handlers.handle_fatsecret_create_profile(req, ctx.db)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }
    ["api", "fatsecret", "profile", "auth"] ->
      handlers.handle_fatsecret_get_profile_auth(req, ctx.db)

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
    ["tandoor", "status"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "recipes"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "recipes", _recipe_id] ->
      handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "units"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "keywords"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "meal-plans"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "meal-plans", _entry_id] ->
      handlers.handle_tandoor_routes(req)

    // =========================================================================
    // Tandoor Supermarkets API
    // =========================================================================
    ["api", "tandoor", "supermarkets"] -> handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "supermarkets", _supermarket_id] ->
      handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "supermarket-categories"] ->
      handlers.handle_tandoor_routes(req)
    ["api", "tandoor", "supermarket-categories", _category_id] ->
      handlers.handle_tandoor_routes(req)

    // =========================================================================
    // Tandoor Import/Export API
    // =========================================================================
    ["api", "tandoor", "import-logs"] -> wisp.not_found()
    ["api", "tandoor", "import-logs", _log_id] -> wisp.not_found()
    ["api", "tandoor", "export-logs"] -> wisp.not_found()
    ["api", "tandoor", "export-logs", _log_id] -> wisp.not_found()

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
  io.println("Tandoor Import/Export:")
  io.println("  GET    /api/tandoor/import-logs           - List import logs")
  io.println("  POST   /api/tandoor/import-logs           - Create import log")
  io.println("  GET    /api/tandoor/import-logs/:id       - Get import log")
  io.println("  PATCH  /api/tandoor/import-logs/:id       - Update import log")
  io.println("  DELETE /api/tandoor/import-logs/:id       - Delete import log")
  io.println("  GET    /api/tandoor/export-logs           - List export logs")
  io.println("  POST   /api/tandoor/export-logs           - Create export log")
  io.println("  GET    /api/tandoor/export-logs/:id       - Get export log")
  io.println("  PATCH  /api/tandoor/export-logs/:id       - Update export log")
  io.println("  DELETE /api/tandoor/export-logs/:id       - Delete export log")
  io.println("")
  io.println("Diary, Exercise, Weight APIs coming soon...")
  io.println("")
}
