/// HTTP handler for FatSecret Food Diary copy operations
///
/// Routes:
///   POST /api/fatsecret/diary/copy-entries - Copy all entries between dates
///   POST /api/fatsecret/diary/copy-meal - Copy entries between meal types
///   POST /api/fatsecret/diary/commit-day - Commit day entries
///   POST /api/fatsecret/diary/save-template - Save day as template
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/json
import meal_planner/fatsecret/diary/handlers/helpers
import meal_planner/fatsecret/diary/service
import meal_planner/fatsecret/diary/types
import pog
import wisp.{type Request, type Response}

// ============================================================================
// POST /api/fatsecret/diary/copy-meal - Copy entries between meal types
// ============================================================================

/// POST /api/fatsecret/diary/copy-meal - Copy entries from one meal to another
///
/// Request body (JSON):
/// ```json
/// {
///   "from_date_int": 19723,
///   "from_meal": "lunch",
///   "to_date_int": 19724,
///   "to_meal": "dinner"
/// }
/// ```
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn copy_meal(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use from_date_int <- decode.field("from_date_int", decode.int)
    use from_meal_str <- decode.field("from_meal", decode.string)
    use to_date_int <- decode.field("to_date_int", decode.int)
    use to_meal_str <- decode.field("to_meal", decode.string)
    decode.success(#(from_date_int, from_meal_str, to_date_int, to_meal_str))
  }

  case decode.run(body, decoder) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #(
              "message",
              json.string(
                "Missing required fields: from_date_int, from_meal, to_date_int, to_meal",
              ),
            ),
          ]),
        ),
        400,
      )

    Ok(#(from_date_int, from_meal_str, to_date_int, to_meal_str)) -> {
      // Parse meal types
      case
        types.meal_type_from_string(from_meal_str),
        types.meal_type_from_string(to_meal_str)
      {
        Error(_), _ | _, Error(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("error", json.string("invalid_request")),
                #(
                  "message",
                  json.string(
                    "Invalid meal type. Use: breakfast, lunch, dinner, or other",
                  ),
                ),
              ]),
            ),
            400,
          )

        Ok(from_meal), Ok(to_meal) -> {
          case
            service.copy_meal(
              conn,
              from_date_int,
              from_meal,
              to_date_int,
              to_meal,
            )
          {
            Ok(_) ->
              wisp.json_response(
                json.to_string(
                  json.object([
                    #("success", json.bool(True)),
                    #("message", json.string("Meal copied successfully")),
                  ]),
                ),
                200,
              )

            Error(e) -> helpers.error_response(e)
          }
        }
      }
    }
  }
}

// ============================================================================
// POST /api/fatsecret/diary/copy-entries - Copy all entries between dates
// ============================================================================

/// POST /api/fatsecret/diary/copy-entries - Copy all entries from one date to another
///
/// Request body (JSON):
/// ```json
/// {
///   "from_date_int": 19723,
///   "to_date_int": 19724
/// }
/// ```
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn copy_entries(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use from_date_int <- decode.field("from_date_int", decode.int)
    use to_date_int <- decode.field("to_date_int", decode.int)
    decode.success(#(from_date_int, to_date_int))
  }

  case decode.run(body, decoder) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #(
              "message",
              json.string("Missing from_date_int or to_date_int fields"),
            ),
          ]),
        ),
        400,
      )

    Ok(#(from_date_int, to_date_int)) -> {
      case service.copy_entries(conn, from_date_int, to_date_int) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Entries copied successfully")),
              ]),
            ),
            200,
          )

        Error(e) -> helpers.error_response(e)
      }
    }
  }
}

// ============================================================================
// POST /api/fatsecret/diary/commit-day - Commit day entries
// ============================================================================

pub fn commit_day(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use date_int <- decode.field("date_int", decode.int)
    decode.success(date_int)
  }

  case decode.run(body, decoder) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #("message", json.string("Missing date_int field")),
          ]),
        ),
        400,
      )

    Ok(date_int) -> {
      case service.commit_day(conn, date_int) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Day committed successfully")),
              ]),
            ),
            200,
          )

        Error(e) -> helpers.error_response(e)
      }
    }
  }
}

// ============================================================================
// POST /api/fatsecret/diary/save-template - Save day as template
// ============================================================================

/// POST /api/fatsecret/diary/save-template - Save a day's entries as a template
///
/// Request body (JSON):
/// ```json
/// {
///   "date_int": 19723,
///   "template_name": "My Favorite Day"
/// }
/// ```
///
/// Returns:
/// - 200: Success
/// - 400: Invalid request
/// - 401: Not connected or auth revoked
/// - 500: Server error
pub fn save_template(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use date_int <- decode.field("date_int", decode.int)
    use template_name <- decode.field("template_name", decode.string)
    decode.success(#(date_int, template_name))
  }

  case decode.run(body, decoder) {
    Error(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_request")),
            #(
              "message",
              json.string("Missing date_int or template_name fields"),
            ),
          ]),
        ),
        400,
      )

    Ok(#(date_int, template_name)) -> {
      case service.save_template(conn, date_int, template_name) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Template saved successfully")),
              ]),
            ),
            200,
          )

        Error(e) -> helpers.error_response(e)
      }
    }
  }
}
