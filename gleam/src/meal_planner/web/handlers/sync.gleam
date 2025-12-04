//// Todoist synchronization handlers for API endpoints

import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/uri
import meal_planner/actors/todoist_actor
import wisp

/// Web context holding database connection
pub type Context {
  Context
}

/// POST /api/sync/todoist - Initiate Todoist synchronization
///
/// Sends a sync request to the TodoistActor for asynchronous processing.
/// Returns 202 Accepted to indicate the request has been queued.
///
/// Query parameters:
/// - user_id: The user's ID to sync (required)
///
/// Returns:
/// - 202 Accepted: Sync request queued successfully
/// - 400 Bad Request: Missing or invalid user_id
pub fn api_sync_todoist(
  req: wisp.Request,
  todoist_actor: Subject(todoist_actor.Message),
) -> wisp.Response {
  case req.method {
    http.Post -> handle_sync_request(req, todoist_actor)
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// Handle POST request to sync with Todoist
fn handle_sync_request(
  req: wisp.Request,
  todoist_actor: Subject(todoist_actor.Message),
) -> wisp.Response {
  // Extract user_id from request body or query parameters
  case extract_user_id(req) {
    Ok(user_id) -> {
      // Send sync message to TodoistActor (async processing)
      todoist_actor.sync(todoist_actor, user_id)

      // Return 202 Accepted - async processing has been initiated
      let response_body =
        json.object([
          #("status", json.string("accepted")),
          #("message", json.string("Sync request queued for processing")),
          #("user_id", json.string(user_id)),
        ])

      wisp.json_response(json.to_string(response_body), 202)
    }
    Error(error_msg) -> {
      let error_response =
        json.object([
          #("error", json.string(error_msg)),
          #("status", json.string("failed")),
        ])

      wisp.json_response(json.to_string(error_response), 400)
    }
  }
}

/// Extract user_id from request body or query parameters
fn extract_user_id(req: wisp.Request) -> Result(String, String) {
  // Parse query parameters from the request
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  case parsed_query {
    Ok(params) -> {
      case list.find(params, fn(param) { param.0 == "user_id" }) {
        Ok(#(_, user_id)) if user_id != "" -> Ok(user_id)
        _ -> Error("Missing required parameter: user_id")
      }
    }
    Error(_) -> Error("Invalid query parameters")
  }
}
