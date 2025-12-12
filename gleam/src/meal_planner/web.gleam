/// Web server module for the Meal Planner API
///
/// This module provides HTTP endpoints for:
/// - Health checks
/// - Macro calculations
/// - Meal planning (stub)
///
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import meal_planner/config
import meal_planner/pagination
import meal_planner/types
import mist
import wisp
import wisp/wisp_mist

/// Application context passed to handlers
pub type Context {
  Context(config: config.Config)
}

/// Start the HTTP server
pub fn start(app_config: config.Config) -> Nil {
  let ctx = Context(config: app_config)

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
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.log_request(req)

  // Parse the request path
  case wisp.path_segments(req) {
    // Health check endpoint
    [] -> health_handler(req)
    ["health"] -> health_handler(req)

    // API endpoints (stubs - to be implemented)
    ["api", "meal-plan"] -> meal_plan_handler(req, ctx)
    ["api", "macros", "calculate"] -> macro_calc_handler(req)

    // Recipe migration progress endpoint
    ["api", "migrations", "progress", migration_id] ->
      migration_progress_handler(req, ctx, migration_id)

    // Paginated food search endpoint
    ["api", "foods", "search"] -> food_search_handler(req)

    // 404 for unknown routes
    _ -> wisp.not_found()
  }
}

// ============================================================================
// Health Check
// ============================================================================

/// Health check endpoint
/// Returns 200 OK with service status
/// GET /health or /
fn health_handler(_req: wisp.Request) -> wisp.Response {
  let body =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}

/// AI meal planning endpoint (stub)
/// POST /api/meal-plan
fn meal_plan_handler(req: wisp.Request, _ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("message", json.string("Meal planning endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Macro calculation endpoint (stub)
/// POST /api/macros/calculate
fn macro_calc_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("message", json.string("Macro calculation endpoint - coming soon")),
      #("status", json.string("not_implemented")),
    ])
    |> json.to_string

  wisp.json_response(body, 501)
}

/// Recipe migration progress handler (stub)
fn migration_progress_handler(
  req: wisp.Request,
  _ctx: Context,
  migration_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let body =
    json.object([
      #("migration_id", json.string(migration_id)),
      #("total_recipes", json.int(100)),
      #("migrated_count", json.int(45)),
      #("failed_count", json.int(2)),
      #("status", json.string("in_progress")),
      #("progress_message", json.string("45 of 100 recipes migrated")),
      #("progress_percentage", json.float(45.0)),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}

/// Paginated food search endpoint
/// GET /api/foods/search?q=<query>&limit=<limit>&cursor=<cursor>
///
/// Query parameters:
///   - q (required): Search query string
///   - limit (optional): Number of results (1-100, default 20)
///   - cursor (optional): Pagination cursor for continuing results
///
/// Returns paginated response with items and pagination metadata
fn food_search_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Get query string from request
  let query_string = wisp.get_query(req)

  // Extract parameters from query string
  let query_param = case query_string {
    Ok(qs) ->
      qs
      |> list.find_map(fn(param) {
        let #(key, value) = param
        case key == "q" {
          True -> Ok(Some(value))
          False -> Nil
        }
      })
      |> ok_or_error(None)
    Error(_) -> Error(None)
  }

  let limit_param = case query_string {
    Ok(qs) ->
      qs
      |> list.find_map(fn(param) {
        let #(key, value) = param
        case key == "limit" {
          True -> Ok(Some(value))
          False -> Nil
        }
      })
      |> ok_or_error(None)
    Error(_) -> Error(None)
  }

  let cursor_param = case query_string {
    Ok(qs) ->
      qs
      |> list.find_map(fn(param) {
        let #(key, value) = param
        case key == "cursor" {
          True -> Ok(Some(value))
          False -> Nil
        }
      })
      |> ok_or_error(None)
    Error(_) -> Error(None)
  }

  // Handle missing query parameter
  case query_param {
    Error(_) -> {
      let error_body =
        json.object([#("error", json.string("Missing required parameter: q"))])
        |> json.to_string
      wisp.json_response(error_body, 400)
    }
    Ok(query) -> {
      // Parse pagination parameters
      case pagination.parse_query_params(limit_param, cursor_param) {
        Error(e) -> {
          let error_body =
            json.object([
              #("error", json.string("Pagination error: " <> e)),
            ])
            |> json.to_string
          wisp.json_response(error_body, 400)
        }
        Ok(_params) -> {
          // For now, return a placeholder response
          // In a real implementation, this would query the database
          let items = []
          let page_info = types.PageInfo(
            has_next: False,
            has_previous: False,
            next_cursor: None,
            previous_cursor: None,
            total_items: 0,
          )

          let response =
            json.object([
              #("items", json.array(items, fn(_) { json.null() })),
              #("pagination", pagination.page_info_to_json(page_info)),
            ])
            |> json.to_string

          wisp.json_response(response, 200)
        }
      }
    }
  }
}

// Helper function to convert Option to Result
fn ok_or_error(opt: Option(a)) -> Result(a, Nil) {
  case opt {
    Some(v) -> Ok(v)
    None -> Error(Nil)
  }
}
