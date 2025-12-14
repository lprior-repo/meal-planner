/// Recipe scoring handler for the Meal Planner API
import gleam/http
import gleam/json
import wisp

/// Recipe scoring endpoint
/// POST /api/ai/score-recipe
pub fn handle_score(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  // TODO: Implement JSON decoding for scoring requests
  let response =
    json.object([
      #("status", json.string("error")),
      #("error", json.string("Recipe scoring not yet fully implemented")),
      #(
        "message",
        json.string(
          "JSON request parsing needs to be implemented before recipe scoring can work",
        ),
      ),
    ])
    |> json.to_string

  wisp.json_response(response, 501)
}
