/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks (with Mealie connectivity validation)
/// - Recipe scoring
/// - AI meal planning
/// - Macro calculations
/// - Vertical diet compliance
///
/// Error Handling:
/// - Maps Mealie API errors to appropriate HTTP status codes
/// - Implements retry logic for transient failures
/// - Provides detailed error responses
///
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import meal_planner/auto_planner
import meal_planner/config
import meal_planner/meal_plan
import meal_planner/mealie/client
import meal_planner/mealie/retry
import meal_planner/mealie/types
import mist
import wisp
import wisp/wisp_mist

/// Database configuration
pub type DatabaseConfig {
  DatabaseConfig(
    host: String,
    port: Int,
    name: String,
    user: String,
    password: String,
  )
}

/// Mealie API configuration
pub type MealieConfig {
  MealieConfig(url: String, token: String)
}

/// Server configuration
pub type ServerConfig {
  ServerConfig(port: Int, database: DatabaseConfig, mealie: MealieConfig)
}

/// Application context passed to handlers
pub type Context {
  Context(config: ServerConfig)
}

/// Start the HTTP server
pub fn start(config: ServerConfig) -> Nil {
  let ctx = Context(config: config)

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
    |> mist.port(config.port)
    |> mist.start

  io.println(
    "🚀 Meal Planner API server started on http://localhost:"
    <> int.to_string(config.port),
  )

  // Keep the server running
  process.sleep_forever()
}

/// Main request router
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  // Parse the request path
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> health_handler(req)
    ["health"] -> health_handler(req)

    // API endpoints (to be implemented)
    ["api", "meal-plan"] -> meal_plan_handler(req, ctx)
    ["api", "macros", "calculate"] -> macro_calc_handler(req)
    ["api", "vertical-diet", "check"] -> vertical_diet_handler(req, ctx)
    ["api", "recipes", "search"] -> recipe_search_handler(req, ctx)
    ["api", "recipes"] -> recipes_handler(req, ctx)
    ["api", "recipes", slug] -> recipe_slug_handler(req, ctx, slug)

    // Mealie integration endpoints
    ["api", "mealie", "recipes"] -> mealie_recipes_handler(req, ctx)
    ["api", "mealie", "recipes", id] ->
      mealie_recipe_detail_handler(req, ctx, id)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Error Handling Helpers
// ============================================================================

/// Map Mealie ClientError to appropriate HTTP status code
fn client_error_to_status(error: client.ClientError) -> Int {
  case error {
    // 400 Bad Request - Client configuration issues
    client.ConfigError(_) -> 400
    client.DecodeError(_) -> 400

    // 404 Not Found
    client.RecipeNotFound(_) -> 404

    // 408 Request Timeout
    client.NetworkTimeout(_, _) -> 408

    // 500 Internal Server Error - Default for server issues
    client.HttpError(_) -> 500
    client.ApiError(_) -> 500

    // 502 Bad Gateway - Upstream service issues
    client.ConnectionRefused(_) -> 502
    client.DnsResolutionFailed(_) -> 502

    // 503 Service Unavailable
    client.MealieUnavailable(_) -> 503
  }
}

/// Create error response from ClientError
fn error_response(error: client.ClientError) -> wisp.Response {
  let status = client_error_to_status(error)
  let error_msg = client.error_to_string(error)
  let user_msg = client.error_to_user_message(error)

  let body =
    json.object([
      #("error", json.string(error_msg)),
      #("message", json.string(user_msg)),
      #("status_code", json.int(status)),
      #("retryable", json.bool(retry.is_retryable(error))),
    ])
    |> json.to_string

  wisp.json_response(body, status)
}

/// Execute operation with retry logic and return appropriate response
fn with_retry_response(
  operation: fn() -> Result(a, client.ClientError),
  success_handler: fn(a) -> wisp.Response,
) -> wisp.Response {
  case retry.with_backoff(operation) {
    Ok(result) -> success_handler(result)
    Error(error) -> error_response(error)
  }
}

// ============================================================================
// Health Check
// ============================================================================

/// Health check endpoint with Mealie connectivity validation
/// Returns 200 OK with service status and Mealie connection status
/// GET /health or /
fn health_handler(_req: wisp.Request) -> wisp.Response {
  // Load config to check Mealie
  let app_config = config.load()

  // Check if Mealie is configured
  let mealie_configured = config.has_mealie_integration(app_config)

  // Attempt to connect to Mealie if configured
  let mealie_status = case mealie_configured {
    True -> {
      // Try to list recipes with a quick timeout to test connectivity
      case retry.with_backoff(fn() { client.list_recipes(app_config) }) {
        Ok(response) -> #(
          "healthy",
          Some(
            "Connected successfully, found "
            <> int.to_string(response.total)
            <> " recipes",
          ),
        )
        Error(client.ConfigError(msg)) -> #("not_configured", Some(msg))
        Error(client.ConnectionRefused(_)) -> #(
          "unreachable",
          Some("Cannot connect to Mealie server"),
        )
        Error(client.NetworkTimeout(_, _)) -> #(
          "timeout",
          Some("Mealie server not responding in time"),
        )
        Error(client.DnsResolutionFailed(_)) -> #(
          "dns_failed",
          Some("Cannot resolve Mealie hostname"),
        )
        Error(error) -> #("error", Some(client.error_to_user_message(error)))
      }
    }
    False -> #("not_configured", Some("MEALIE_API_TOKEN not set"))
  }

  let #(mealie_health, mealie_message) = mealie_status

  // Overall health is healthy if service is running
  // Mealie status is separate
  let body =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
      #(
        "mealie",
        json.object([
          #("status", json.string(mealie_health)),
          #("message", case mealie_message {
            Some(msg) -> json.string(msg)
            None -> json.null()
          }),
          #("configured", json.bool(mealie_configured)),
        ]),
      ),
    ])
    |> json.to_string

  // Return 200 even if Mealie is down - the service itself is healthy
  wisp.json_response(body, 200)
}

/// AI meal planning endpoint
/// POST /api/meal-plan
/// Generates optimized meal plans using Mealie recipes
///
/// Request body (JSON):
/// {
///   "days": 7,
///   "meals_per_day": 3,
///   "preferences": {
///     "dietary_restrictions": ["vegetarian"],
///     "preferred_cuisines": ["italian", "asian"]
///   }
/// }
fn meal_plan_handler(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Load application config
  let app_config = config.load()

  // For now, generate a simple meal plan using available recipes from Mealie
  with_retry_response(
    fn() { client.list_recipes(app_config) },
    fn(recipes_response) {
      // Get first 7 recipes to create a 7-day meal plan with one meal per day
      let available_recipes = recipes_response.items
      let selected_recipes = list.take(available_recipes, 7)

      case list.length(selected_recipes) {
        0 -> {
          // No recipes available
          let body =
            json.object([
              #("error", json.string("No recipes available in Mealie")),
              #("message", json.string("Cannot generate meal plan without recipes")),
            ])
            |> json.to_string

          wisp.json_response(body, 400)
        }
        _ -> {
          // Build daily meal plans from selected recipes
          let daily_meals =
            list.index_map(selected_recipes, fn(recipe, day_index) {
              let day_names = [
                "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
                "Sunday",
              ]
              let day_name = case day_index {
                0 -> "Monday"
                1 -> "Tuesday"
                2 -> "Wednesday"
                3 -> "Thursday"
                4 -> "Friday"
                5 -> "Saturday"
                6 -> "Sunday"
                _ -> "Day " <> int.to_string(day_index + 1)
              }

              json.object([
                #("day", json.string(day_name)),
                #("day_index", json.int(day_index + 1)),
                #(
                  "meals",
                  json.array([recipe], fn(r) {
                    json.object([
                      #("type", json.string("dinner")),
                      #("recipe_id", json.string(r.id)),
                      #("recipe_name", json.string(r.name)),
                      #("recipe_slug", json.string(r.slug)),
                      #(
                        "image",
                        case r.image {
                          Some(img) -> json.string(img)
                          None -> json.null()
                        },
                      ),
                      #(
                        "yield",
                        case r.recipe_yield {
                          Some(y) -> json.string(y)
                          None -> json.null()
                        },
                      ),
                    ])
                  }),
                ),
              ])
            })

          // Build the response
          let body =
            json.object([
              #("status", json.string("success")),
              #("type", json.string("meal_plan")),
              #("total_days", json.int(list.length(daily_meals))),
              #("meals_per_day", json.int(1)),
              #("days", json.array(daily_meals, fn(x) { x })),
              #(
                "metadata",
                json.object([
                  #("generated_from", json.string("mealie_api")),
                  #("total_recipes_available", json.int(recipes_response.total)),
                  #("recipes_used", json.int(list.length(selected_recipes))),
                ]),
              ),
            ])
            |> json.to_string

          wisp.json_response(body, 200)
        }
      }
    },
  )
}

/// Macro calculation endpoint
/// POST /api/macros/calculate
/// Calculates macros for recipes and meals
fn macro_calc_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement macro calculation logic
  let body =
    json.object([
      #("message", json.string("Macro calculation endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Vertical diet compliance endpoint
/// POST /api/vertical-diet/check
/// Checks if Mealie recipes comply with vertical diet guidelines
fn vertical_diet_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement vertical diet compliance logic using Mealie recipe data
  let body =
    json.object([
      #(
        "message",
        json.string("Vertical diet compliance endpoint - coming soon"),
      ),
      #("status", json.string("not_implemented")),
      #("note", json.string("Uses Mealie API for recipe data")),
      #("mealie_url", json.string(ctx.config.mealie.url)),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Recipe search endpoint
/// GET /api/recipes/search?q={query}
/// Searches recipes from Mealie API by query string
fn recipe_search_handler(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Extract the 'q' query parameter
  let query = case request.get_query(req) {
    Ok(params) -> {
      // Find the 'q' parameter in the list
      list.find_map(params, fn(param) {
        case param {
          #(key, value) if key == "q" -> Ok(value)
          _ -> Error(Nil)
        }
      })
    }
    Error(_) -> Error(Nil)
  }

  // Load full config for Mealie client
  let app_config = config.load()

  case query {
    Ok(search_query) if search_query != "" -> {
      // Execute with retry logic for transient failures
      with_retry_response(
        fn() { client.search_recipes(app_config, search_query) },
        fn(recipes_response) {
          let body =
            json.object([
              #("query", json.string(search_query)),
              #("total", json.int(recipes_response.total)),
              #("page", json.int(recipes_response.page)),
              #("per_page", json.int(recipes_response.per_page)),
              #("total_pages", json.int(recipes_response.total_pages)),
              #(
                "items",
                json.array(recipes_response.items, fn(recipe) {
                  json.object([
                    #("id", json.string(recipe.id)),
                    #("name", json.string(recipe.name)),
                    #("slug", json.string(recipe.slug)),
                    #("image", case recipe.image {
                      Some(img) -> json.string(img)
                      None -> json.null()
                    }),
                  ])
                }),
              ),
            ])
            |> json.to_string

          wisp.json_response(body, 200)
        },
      )
    }
    _ -> {
      // Empty query parameter - return 400 Bad Request
      let body =
        json.object([
          #("error", json.string("Missing or empty search query")),
          #("message", json.string("The 'q' query parameter is required")),
          #("status_code", json.int(400)),
        ])
        |> json.to_string

      wisp.json_response(body, 400)
    }
  }
}

/// Recipe listing endpoint
/// GET /api/recipes
/// Proxies to Mealie's list_recipes endpoint with automatic retry on transient failures
fn recipes_handler(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Load full config for Mealie client
  let app_config = config.load()

  // Execute with retry logic for transient failures
  with_retry_response(
    fn() { client.list_recipes(app_config) },
    fn(recipes_response) {
      let body =
        json.object([
          #("page", json.int(recipes_response.page)),
          #("perPage", json.int(recipes_response.per_page)),
          #("total", json.int(recipes_response.total)),
          #("totalPages", json.int(recipes_response.total_pages)),
          #(
            "items",
            json.array(recipes_response.items, fn(recipe) {
              json.object([
                #("id", json.string(recipe.id)),
                #("name", json.string(recipe.name)),
                #("slug", json.string(recipe.slug)),
                #("description", case recipe.description {
                  Some(desc) -> json.string(desc)
                  None -> json.null()
                }),
                #("image", case recipe.image {
                  Some(img) -> json.string(img)
                  None -> json.null()
                }),
                #("rating", case recipe.rating {
                  Some(r) -> json.int(r)
                  None -> json.null()
                }),
                #("recipeYield", case recipe.recipe_yield {
                  Some(y) -> json.string(y)
                  None -> json.null()
                }),
                #("totalTime", case recipe.total_time {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
                #("prepTime", case recipe.prep_time {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
                #("cookTime", case recipe.cook_time {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
              ])
            }),
          ),
          #("next", case recipes_response.next {
            Some(url) -> json.string(url)
            None -> json.null()
          }),
          #("previous", case recipes_response.previous {
            Some(url) -> json.string(url)
            None -> json.null()
          }),
        ])
        |> json.to_string

      wisp.json_response(body, 200)
    },
  )
}

/// Mealie recipes list endpoint
/// GET /api/mealie/recipes
/// Fetches recipes from Mealie API
fn mealie_recipes_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // TODO: Implement Mealie API client integration
  let body =
    json.object([
      #("message", json.string("Mealie recipes endpoint - coming soon")),
      #("status", json.string("not_implemented")),
      #("mealie_url", json.string(ctx.config.mealie.url)),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Mealie recipe detail endpoint
/// GET /api/mealie/recipes/:id
/// Fetches a specific recipe from Mealie API
fn mealie_recipe_detail_handler(
  req: wisp.Request,
  ctx: Context,
  id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // TODO: Implement Mealie API client integration
  let body =
    json.object([
      #("message", json.string("Mealie recipe detail endpoint - coming soon")),
      #("status", json.string("not_implemented")),
      #("recipe_id", json.string(id)),
      #("mealie_url", json.string(ctx.config.mealie.url)),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}
