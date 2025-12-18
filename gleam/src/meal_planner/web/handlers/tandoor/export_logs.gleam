/// Export Logs web handlers for Tandoor Recipe Manager
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result

import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/decoders/import_export/export_log_create_request_decoder
import meal_planner/tandoor/decoders/import_export/export_log_update_request_decoder
import meal_planner/tandoor/encoders/import_export/export_log_encoder.{
  type ExportLogCreateRequest, type ExportLogUpdateRequest,
  ExportLogCreateRequest, ExportLogUpdateRequest,
}
import meal_planner/tandoor/types/import_export/export_log.{type ExportLog}
import meal_planner/tandoor/handlers/helpers

import wisp

/// Handle export logs collection (GET list, POST create)
pub fn handle_export_logs_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_export_logs(req)
    http.Post -> handle_create_export_log(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle export log by ID (GET, PATCH, DELETE)
pub fn handle_export_log_by_id(
  req: wisp.Request,
  log_id: String,
) -> wisp.Response {
  case int.parse(log_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_export_log(req, id)
        http.Patch -> handle_update_export_log(req, id)
        http.Delete -> handle_delete_export_log(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid log ID")
  }
}

// =============================================================================
// Private Handler Functions
// =============================================================================

fn handle_list_export_logs(req: wisp.Request) -> wisp.Response {
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
      case
        import_export_api.list_export_logs(config, limit: limit, offset: offset)
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(log) { encode_export_log(log) })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_export_log(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_export_log_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case import_export_api.create_export_log(config, request) {
            Ok(log) -> {
              encode_export_log(log)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to create export log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_get_export_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.get_export_log(config, log_id: id) {
        Ok(log) -> {
          encode_export_log(log)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_export_log(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_export_log_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            import_export_api.update_export_log(config, request, log_id: id)
          {
            Ok(log) -> {
              encode_export_log(log)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) ->
              helpers.error_response(500, "Failed to update export log")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_export_log(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case import_export_api.delete_export_log(config, log_id: id) {
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

fn encode_export_log(log: ExportLog) -> json.Json {
  json.object([
    #("id", json.int(log.id)),
    #("export_type", json.string(log.export_type)),
    #("msg", json.string(log.msg)),
    #("running", json.bool(log.running)),
    #("total_recipes", json.int(log.total_recipes)),
    #("exported_recipes", json.int(log.exported_recipes)),
    #("cache_duration", json.int(log.cache_duration)),
    #("possibly_not_expired", json.bool(log.possibly_not_expired)),
    #("created_by", json.int(log.created_by)),
    #("created_at", json.string(log.created_at)),
  ])
}

fn parse_export_log_create_request(
  json_data: dynamic.Dynamic,
) -> Result(ExportLogCreateRequest, String) {
  decode.run(
    json_data,
    export_log_create_request_decoder.export_log_create_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(export_type, msg, cache_duration) = tuple
    ExportLogCreateRequest(
      export_type: export_type,
      msg: msg,
      cache_duration: cache_duration,
    )
  })
  |> result.map_error(fn(_) { "Invalid export log create request" })
}

fn parse_export_log_update_request(
  json_data: dynamic.Dynamic,
) -> Result(ExportLogUpdateRequest, String) {
  decode.run(
    json_data,
    export_log_update_request_decoder.export_log_update_request_decoder(),
  )
  |> result.map(fn(tuple) {
    let #(export_type, msg, running, cache_duration) = tuple
    ExportLogUpdateRequest(
      export_type: export_type,
      msg: msg,
      running: running,
      cache_duration: cache_duration,
    )
  })
  |> result.map_error(fn(_) { "Invalid export log update request" })
}
