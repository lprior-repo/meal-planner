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
import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import meal_planner/config
import meal_planner/mealie/client
import meal_planner/mealie/fallback
import meal_planner/mealie/retry
import meal_planner/vertical_diet_compliance
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

    // API endpoints
    ["api", "meal-plan"] -> meal_plan_handler(req, ctx)
    ["api", "macros", "calculate"] -> macro_calc_handler(req)
    ["api", "vertical-diet", "check"] -> vertical_diet_handler(req, ctx)
    ["api", "recipes", "search"] -> recipe_search_handler(req, ctx)
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

/// Execute operation with retry logic and fallback on error
/// Used for endpoints that should gracefully degrade when Mealie fetch fails
/// by showing a fallback response (e.g., "Unknown Recipe (slug)")
fn with_retry_and_fallback_response(
  operation: fn() -> Result(a, client.ClientError),
  fallback_provider: fn(client.ClientError) -> a,
  success_handler: fn(a) -> wisp.Response,
) -> wisp.Response {
  case retry.with_backoff(operation) {
    Ok(result) -> success_handler(result)
    Error(error) -> {
      // Use fallback on error instead of returning error response
      let fallback_result = fallback_provider(error)
      success_handler(fallback_result)
    }
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
/// Checks if Mealie recipes comply with vertical diet guidelines using recipe slugs
fn vertical_diet_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  case extract_recipe_slug(body) {
    Ok(slug) -> {
      case retry.with_backoff(fn() { client.get_recipe(ctx.config, slug) }) {
        Ok(recipe) -> {
          let compliance = vertical_diet_compliance.check_compliance(recipe)

          let response_body =
            json.object([
              #("recipe_slug", json.string(recipe.slug)),
              #("recipe_name", json.string(recipe.name)),
              #("compliant", json.bool(compliance.compliant)),
              #("score", json.int(compliance.score)),
              #("reasons", json.array(compliance.reasons, fn(r) { json.string(r) })),
              #("recommendations", json.array(compliance.recommendations, fn(r) { json.string(r) })),
              #("mealie_url", json.string(ctx.config.mealie.url)),
            ])
            |> json.to_string

          wisp.json_response(response_body, 200)
        }
        Error(error) -> error_response(error)
      }
    }
    Error(err_msg) -> {
      let error_body =
        json.object([
          #("error", json.string("Invalid request format")),
          #("message", json.string(err_msg)),
          #("details", json.string("Expected JSON body with 'recipe_slug' field")),
        ])
        |> json.to_string

      wisp.json_response(error_body, 400)
    }
  }
}

/// Extract recipe slug from JSON request body
fn extract_recipe_slug(body: dynamic.Dynamic) -> Result(String, String) {
  let decoder = {
    use slug <- decode.field("recipe_slug", decode.string)
    decode.success(slug)
  }

  case decode.run(body, decoder) {
    Ok(slug) -> Ok(slug)
    Error(_) -> Error("Missing required field: 'recipe_slug' (must be a string)")
  }
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

/// Recipe by slug endpoint
/// GET /api/recipes/:slug
/// Fetches a recipe from Mealie by its slug
/// On failure, returns a fallback recipe with the display name "Unknown Recipe (slug)"
fn recipe_slug_handler(
  req: wisp.Request,
  ctx: Context,
  slug: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  let _ = ctx
  let app_config = config.load()

  with_retry_and_fallback_response(
    fn() { client.get_recipe(app_config, slug) },
    fn(_error) { fallback.create_fallback_recipe(slug) },
    fn(recipe) {
      let recipe_json =
        json.object([
          #("id", json.string(recipe.id)),
          #("slug", json.string(recipe.slug)),
          #("name", json.string(recipe.name)),
          #("description", case recipe.description {
            Some(desc) -> json.string(desc)
            None -> json.null()
          }),
          #("image", case recipe.image {
            Some(img) -> json.string(img)
            None -> json.null()
          }),
          #("recipe_yield", case recipe.recipe_yield {
            Some(y) -> json.string(y)
            None -> json.null()
          }),
          #("total_time", case recipe.total_time {
            Some(t) -> json.string(t)
            None -> json.null()
          }),
          #("prep_time", case recipe.prep_time {
            Some(t) -> json.string(t)
            None -> json.null()
          }),
          #("cook_time", case recipe.cook_time {
            Some(t) -> json.string(t)
            None -> json.null()
          }),
          #("rating", case recipe.rating {
            Some(r) -> json.int(r)
            None -> json.null()
          }),
          #("org_url", case recipe.org_url {
            Some(u) -> json.string(u)
            None -> json.null()
          }),
          #("recipe_ingredient", json.array(
            recipe.recipe_ingredient,
            fn(ing) {
              json.object([
                #("reference_id", json.string(ing.reference_id)),
                #("quantity", case ing.quantity {
                  Some(q) -> json.float(q)
                  None -> json.null()
                }),
                #("unit", case ing.unit {
                  Some(u) ->
                    json.object([
                      #("id", json.string(u.id)),
                      #("name", json.string(u.name)),
                      #("abbreviation", json.string(u.abbreviation)),
                    ])
                  None -> json.null()
                }),
                #("food", case ing.food {
                  Some(f) ->
                    json.object([
                      #("id", json.string(f.id)),
                      #("name", json.string(f.name)),
                    ])
                  None -> json.null()
                }),
                #("note", case ing.note {
                  Some(n) -> json.string(n)
                  None -> json.null()
                }),
                #("is_food", json.bool(ing.is_food)),
                #("disable_amount", json.bool(ing.disable_amount)),
                #("display", json.string(ing.display)),
              ])
            },
          )),
          #("recipe_instructions", json.array(
            recipe.recipe_instructions,
            fn(instr) {
              json.object([
                #("id", json.string(instr.id)),
                #("title", case instr.title {
                  Some(t) -> json.string(t)
                  None -> json.null()
                }),
                #("text", json.string(instr.text)),
              ])
            },
          )),
          #("recipe_category", json.array(
            recipe.recipe_category,
            fn(cat) {
              json.object([
                #("id", json.string(cat.id)),
                #("name", json.string(cat.name)),
                #("slug", json.string(cat.slug)),
              ])
            },
          )),
          #("tags", json.array(recipe.tags, fn(tag) {
            json.object([
              #("id", json.string(tag.id)),
              #("name", json.string(tag.name)),
              #("slug", json.string(tag.slug)),
            ])
          })),
          #("nutrition", case recipe.nutrition {
            Some(n) ->
              json.object([
                #("calories", case n.calories {
                  Some(c) -> json.string(c)
                  None -> json.null()
                }),
                #("fat_content", case n.fat_content {
                  Some(f) -> json.string(f)
                  None -> json.null()
                }),
                #("protein_content", case n.protein_content {
                  Some(p) -> json.string(p)
                  None -> json.null()
                }),
                #("carbohydrate_content", case n.carbohydrate_content {
                  Some(c) -> json.string(c)
                  None -> json.null()
                }),
                #("fiber_content", case n.fiber_content {
                  Some(f) -> json.string(f)
                  None -> json.null()
                }),
                #("sodium_content", case n.sodium_content {
                  Some(s) -> json.string(s)
                  None -> json.null()
                }),
                #("sugar_content", case n.sugar_content {
                  Some(s) -> json.string(s)
                  None -> json.null()
                }),
              ])
            None -> json.null()
          }),
          #("date_added", case recipe.date_added {
            Some(d) -> json.string(d)
            None -> json.null()
          }),
          #("date_updated", case recipe.date_updated {
            Some(d) -> json.string(d)
            None -> json.null()
          }),
        ])

      wisp.json_response(recipe_json |> json.to_string, 200)
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
