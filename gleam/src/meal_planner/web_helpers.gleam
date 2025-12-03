/// Web helper functions
/// Temporary placeholder to unblock compilation

import gleam/json.{type Json}
import wisp.{type Response}

/// JSON response helper
pub fn json_response(data: Json, status: Int) -> Response {
  wisp.response(status)
  |> wisp.set_header("content-type", "application/json")
  |> wisp.json_body(json.to_string(data))
}

/// Error response helper
pub fn error_response(message: String, status: Int) -> Response {
  let json_body =
    json.object([#("error", json.object([#("message", json.string(message))]))])
  json_response(json_body, status)
}
