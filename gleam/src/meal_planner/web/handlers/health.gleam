/// Health check handler for the Meal Planner API
///
/// This module provides the health check endpoint that returns the service status.
/// Uses Wisp's idiomatic patterns for all HTTP method checking and response handling.
///
/// Routes:
/// - GET /health - Health check JSON response
/// - GET / - Alias for /health
///
/// Response: 200 OK with JSON body
import gleam/http
import gleam/json
import meal_planner/web/responses
import wisp

/// Health check endpoint - GET /health or GET /
///
/// Returns a JSON response indicating service health status.
/// This endpoint uses Wisp's idiomatic patterns:
/// - wisp.require_method() to enforce GET-only access
/// - wisp.json_response() for proper Content-Type handling
pub fn handle(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let health_data =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
    ])

  responses.json_ok(health_data)
}
