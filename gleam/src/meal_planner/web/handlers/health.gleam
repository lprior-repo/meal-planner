/// Health check handler for the Meal Planner API
///
/// This module provides the health check endpoint that returns the service status.

import gleam/http
import gleam/json
import wisp

/// Health check endpoint
/// Returns 200 OK with service status
/// GET /health or /
pub fn handle(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let body =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
      #("version", json.string("1.0.0")),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}
