/// Vertical diet compliance handler for the Meal Planner API
///
/// This module provides the diet compliance check endpoint that evaluates
/// recipes against vertical diet principles.
///
/// NOTE: This is currently a stub implementation - recipe storage is not yet implemented
import gleam/http
import gleam/json
import wisp

/// Vertical diet compliance check endpoint
/// GET /api/diet/vertical/compliance/{recipe_id}
///
/// Returns vertical diet compliance score and recommendations for a recipe.
/// Currently returns a stub response as recipe storage is not implemented.
pub fn handle_compliance(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  // TODO: Implement recipe storage and vertical diet compliance checking
  // For now, return a stub response indicating the feature is not yet implemented
  let response =
    json.object([
      #("status", json.string("error")),
      #(
        "error",
        json.string("Recipe compliance checking not yet implemented"),
      ),
      #("recipe_id", json.string(recipe_id)),
      #(
        "message",
        json.string(
          "Recipe storage layer needs to be implemented before diet compliance checks can work",
        ),
      ),
    ])
    |> json.to_string

  wisp.json_response(response, 501)
}
