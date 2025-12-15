/// Vertical diet compliance handler for the Meal Planner API
///
/// This module provides the diet compliance check endpoint that evaluates
/// recipes against vertical diet principles.
import gleam/http
import gleam/json
import wisp

/// Vertical diet compliance check endpoint
/// GET /api/diet/vertical/compliance/{recipe_id}
///
/// Returns vertical diet compliance score and recommendations for a recipe.
/// NOTE: This is a stub implementation pending recipe storage layer.
pub fn handle_compliance(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  case validate_recipe_id(recipe_id) {
    Error(msg) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string("Invalid recipe ID")),
          #("message", json.string(msg)),
          #("recipe_id", json.string(recipe_id)),
        ])
        |> json.to_string
      wisp.json_response(response, 400)
    }
    Ok(_valid_id) -> {
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
  }
}

// ============================================================================
// Validation Helpers
// ============================================================================

fn validate_recipe_id(recipe_id: String) -> Result(String, String) {
  // Basic validation: recipe_id should be a non-empty string
  case recipe_id {
    "" -> Error("Recipe ID cannot be empty")
    id -> Ok(id)
  }
}
