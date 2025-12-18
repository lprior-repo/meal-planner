/// Keywords handler for Tandoor API
///
/// Handles GET requests for the /api/tandoor/keywords endpoint.
/// Extracted from the main tandoor.gleam handler following TDD/TCR workflow.
import gleam/json
import meal_planner/tandoor/api/keyword/keyword_api
import meal_planner/tandoor/handlers/helpers
import wisp

/// Handle keywords endpoint requests
///
/// Supports GET method only to list all keywords from Tandoor.
/// Returns array of keyword objects with id and name.
pub fn handle_keywords(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case keyword_api.list_keywords(config) {
        Ok(keywords) -> {
          json.array(keywords, fn(keyword) {
            json.object([
              #("id", json.int(keyword.id)),
              #("name", json.string(keyword.name)),
            ])
          })
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}
