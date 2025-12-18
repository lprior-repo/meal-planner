/// Web server module for the Meal Planner API
///
/// This module centralizes all HTTP routing and server startup, delegating to
/// handler modules in web/handlers/ and fatsecret/*/handlers.gleam
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option
import meal_planner/config
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/postgres
import meal_planner/web/routes
import meal_planner/web/routes/types
import mist
import wisp
import wisp/wisp_mist

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

  // Configure logging
  wisp.configure_logger()

  // Create the handler function
  let handler = fn(req: wisp.Request) -> wisp.Response {
    let router_ctx = types.Context(config: app_config, db: db)
    wisp.log_request(req, fn() { routes.route(req, router_ctx) })
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
  io.println("Diary (3-legged):")
  io.println(
    "  POST   /api/fatsecret/diary/entries                 - Create entry",
  )
  io.println(
    "  GET    /api/fatsecret/diary/entries/:entry_id       - Get entry",
  )
  io.println(
    "  PATCH  /api/fatsecret/diary/entries/:entry_id       - Update entry",
  )
  io.println(
    "  DELETE /api/fatsecret/diary/entries/:entry_id       - Delete entry",
  )
  io.println(
    "  GET    /api/fatsecret/diary/day/:date_int           - Get day entries",
  )
  io.println(
    "  GET    /api/fatsecret/diary/month/:date_int         - Get month summary",
  )
  io.println("")
  io.println("Exercise, Weight APIs coming soon...")
  io.println("")
}
