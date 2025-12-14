/// Macro calculation handler for the Meal Planner API
///
/// This module provides the macro calculation endpoint that aggregates
/// nutritional information across recipes.
import gleam/http
import gleam/json
import wisp

/// Macro calculation endpoint
/// POST /api/macros/calculate
///
/// Calculates total macros from recipe servings and individual macros.
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement JSON decoding for MacrosRequest
  // For now, return a stub response indicating the feature is not yet implemented
  let response =
    json.object([
      #("status", json.string("error")),
      #(
        "error",
        json.string("Macro calculation not yet fully implemented"),
      ),
      #(
        "message",
        json.string(
          "JSON request parsing needs to be implemented before macro calculations can work",
        ),
      ),
    ])
    |> json.to_string

  wisp.json_response(response, 501)
}
