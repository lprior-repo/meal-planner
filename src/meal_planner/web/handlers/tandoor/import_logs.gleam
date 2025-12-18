/// Import Logs web handlers for Tandoor Recipe Manager
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result

import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/import_export.{
  type ImportLog, type ImportLogCreateRequest, type ImportLogUpdateRequest,
  ImportLogCreateRequest, ImportLogUpdateRequest, create_import_log,
  delete_import_log, encode_import_log, get_import_log,
  import_log_create_request_decoder, import_log_update_request_decoder,
  list_import_logs, update_import_log,
}

import wisp

/// Handle import logs collection (GET list, POST create)
pub fn handle_import_logs_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_import_logs(req)
    http.Post -> handle_create_import_log(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle import log by ID (GET, PATCH, DELETE)
pub fn handle_import_log_by_id(
  req: wisp.Request,
  log_id: String,
) -> wisp.Response {
  case int.parse(log_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_import_log(req, id)
        http.Patch -> handle_update_import_log(req, id)
        http.Delete -> handle_delete_import_log(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid log ID")
  }
}

// =============================================================================
// Private Handler Functions
// =============================================================================

fn handle_list_import_logs(req: wisp.Request) -> wisp.Response {
  let query_params = wisp.get_query(req)
  let limit =
    list.find(query_params, fn(p) { p.0 == "limit" })
    |> result.map(fn(p) { p.1 })
    |> result.try(int.parse)
    |> option.from_result
  let offset =
    list.find(query_params, fn(p) { p.0 == "offset" })
    |> result.map(fn(p) { p.1 })
    |> result.try(int.parse)
    |> option.from_result

  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case list_import_logs(config, limit: limit, offset: offset) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(log) { encode_import_log(log) })

          helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_import_log(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_import_log_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case create_import_log(config, request) {
            Ok(log) -> {
              encode_import_log(log)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create import log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_get_import_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case get_import_log(config, log_id: id) {
        Ok(log) -> {
          encode_import_log(log)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_import_log(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_import_log_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case update_import_log(config, request, log_id: id) {
            Ok(log) -> {
              encode_import_log(log)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update import log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_import_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case delete_import_log(config, log_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// JSON Encoding and Decoding
// =============================================================================

fn encode_import_log(log: ImportLog) -> json.Json {
  let keyword_json = case log.keyword {
    option.Some(keyword) ->
      json.object([
        #("id", json.int(keyword.id)),
        #("name", json.string(keyword.name)),
      ])
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(log.id)),
    #("import_type", json.string(log.import_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("keyword", keyword_json),
    #("total_recipes", json.int(log.total_recipes)),
    #("imported_recipes", json.int(log.imported_recipes)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

fn parse_import_log_create_request(
  json_data: dynamic.Dynamic,
) -> Result(ImportLogCreateRequest, String) {
  decode.run(json_data, import_log_create_request_decoder())
  |> result.map_error(fn(_) { "Invalid import log create request" })
}

fn parse_import_log_update_request(
  json_data: dynamic.Dynamic,
) -> Result(ImportLogUpdateRequest, String) {
  decode.run(json_data, import_log_update_request_decoder())
  |> result.map_error(fn(_) { "Invalid import log update request" })
}
