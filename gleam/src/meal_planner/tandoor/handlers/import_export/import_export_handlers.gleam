/// Import/Export HTTP handlers for Tandoor API
///
/// This module provides HTTP request handlers for import/export log endpoints.
/// These handlers integrate with the router and provide proper error handling.
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import meal_planner/tandoor/api/import_export/import_export_api
import meal_planner/tandoor/client
import meal_planner/tandoor/encoders/import_export/export_log_encoder
import meal_planner/tandoor/encoders/import_export/import_log_encoder
import pog
import wisp

/// Handle import log list and create endpoints
///
/// GET /api/tandoor/import-logs - List import logs with pagination
/// POST /api/tandoor/import-logs - Create new import log
pub fn handle_import_logs(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_import_logs(req, db)
    http.Post -> handle_create_import_log(req, db)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle single import log operations
///
/// GET /api/tandoor/import-logs/:id - Get import log by ID
/// PATCH /api/tandoor/import-logs/:id - Update import log
/// DELETE /api/tandoor/import-logs/:id - Delete import log
pub fn handle_import_log(
  req: wisp.Request,
  db: pog.Connection,
  log_id: String,
) -> wisp.Response {
  case int.parse(log_id) {
    Error(_) -> wisp.bad_request()
    Ok(id) ->
      case req.method {
        http.Get -> handle_get_import_log(req, db, id)
        http.Patch -> handle_update_import_log(req, db, id)
        http.Delete -> handle_delete_import_log(req, db, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
  }
}

/// Handle export log list and create endpoints
///
/// GET /api/tandoor/export-logs - List export logs with pagination
/// POST /api/tandoor/export-logs - Create new export log
pub fn handle_export_logs(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_export_logs(req, db)
    http.Post -> handle_create_export_log(req, db)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle single export log operations
///
/// GET /api/tandoor/export-logs/:id - Get export log by ID
/// PATCH /api/tandoor/export-logs/:id - Update export log
/// DELETE /api/tandoor/export-logs/:id - Delete export log
pub fn handle_export_log(
  req: wisp.Request,
  db: pog.Connection,
  log_id: String,
) -> wisp.Response {
  case int.parse(log_id) {
    Error(_) -> wisp.bad_request()
    Ok(id) ->
      case req.method {
        http.Get -> handle_get_export_log(req, db, id)
        http.Patch -> handle_update_export_log(req, db, id)
        http.Delete -> handle_delete_export_log(req, db, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
  }
}

// Internal handler implementations

fn handle_list_import_logs(
  _req: wisp.Request,
  db: pog.Connection,
) -> wisp.Response {
  // Get Tandoor config from database
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      // TODO: Parse query parameters for limit/offset
      case
        import_export_api.list_import_logs(
          config,
          limit: option.Some(20),
          offset: option.Some(0),
        )
      {
        Ok(log_list) -> {
          let response_json =
            json.object([
              #("count", json.int(log_list.count)),
              #(
                "next",
                case log_list.next {
                  option.Some(url) -> json.string(url)
                  option.None -> json.null()
                },
              ),
              #(
                "previous",
                case log_list.previous {
                  option.Some(url) -> json.string(url)
                  option.None -> json.null()
                },
              ),
              #("results", json.array(log_list.results, fn(_) { json.null() })),
            ])

          wisp.json_response(json.to_string(response_json), 200)
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

fn handle_get_import_log(
  _req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case import_export_api.get_import_log(config, log_id: log_id) {
        Ok(_import_log) -> {
          // TODO: Encode import_log to JSON
          wisp.json_response("{}", 200)
        }
        Error(client.NotFoundError(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

fn handle_create_import_log(
  req: wisp.Request,
  db: pog.Connection,
) -> wisp.Response {
  use body <- wisp.require_string_body(req)

  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      // Parse request body
      case json.parse(body, using: decode.dynamic) {
        Error(_) -> wisp.bad_request()
        Ok(json_data) -> {
          // TODO: Decode JSON to ImportLogCreateRequest
          let request =
            import_log_encoder.ImportLogCreateRequest(
              import_type: "nextcloud",
              msg: option.None,
              keyword: option.None,
            )

          case import_export_api.create_import_log(config, request) {
            Ok(_import_log) -> {
              // TODO: Encode import_log to JSON
              wisp.json_response("{}", 201)
            }
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
  }
}

fn handle_update_import_log(
  req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  use body <- wisp.require_string_body(req)

  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case json.parse(body, using: decode.dynamic) {
        Error(_) -> wisp.bad_request()
        Ok(_json_data) -> {
          // TODO: Decode JSON to ImportLogUpdateRequest
          let request =
            import_log_encoder.ImportLogUpdateRequest(
              import_type: option.None,
              msg: option.None,
              running: option.None,
              keyword: option.None,
            )

          case
            import_export_api.update_import_log(
              config,
              log_id: log_id,
              request,
            )
          {
            Ok(_import_log) -> {
              // TODO: Encode import_log to JSON
              wisp.json_response("{}", 200)
            }
            Error(client.NotFoundError(_)) -> wisp.not_found()
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
  }
}

fn handle_delete_import_log(
  _req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case import_export_api.delete_import_log(config, log_id: log_id) {
        Ok(_) -> wisp.no_content()
        Error(client.NotFoundError(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

fn handle_list_export_logs(
  _req: wisp.Request,
  db: pog.Connection,
) -> wisp.Response {
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case
        import_export_api.list_export_logs(
          config,
          limit: option.Some(20),
          offset: option.Some(0),
        )
      {
        Ok(log_list) -> {
          let response_json =
            json.object([
              #("count", json.int(log_list.count)),
              #(
                "next",
                case log_list.next {
                  option.Some(url) -> json.string(url)
                  option.None -> json.null()
                },
              ),
              #(
                "previous",
                case log_list.previous {
                  option.Some(url) -> json.string(url)
                  option.None -> json.null()
                },
              ),
              #("results", json.array(log_list.results, fn(_) { json.null() })),
            ])

          wisp.json_response(json.to_string(response_json), 200)
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

fn handle_get_export_log(
  _req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case import_export_api.get_export_log(config, log_id: log_id) {
        Ok(_export_log) -> {
          // TODO: Encode export_log to JSON
          wisp.json_response("{}", 200)
        }
        Error(client.NotFoundError(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

fn handle_create_export_log(
  req: wisp.Request,
  db: pog.Connection,
) -> wisp.Response {
  use body <- wisp.require_string_body(req)

  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case json.parse(body, using: decode.dynamic) {
        Error(_) -> wisp.bad_request()
        Ok(_json_data) -> {
          // TODO: Decode JSON to ExportLogCreateRequest
          let request =
            export_log_encoder.ExportLogCreateRequest(
              export_type: "zip",
              msg: option.None,
              cache_duration: option.None,
            )

          case import_export_api.create_export_log(config, request) {
            Ok(_export_log) -> {
              // TODO: Encode export_log to JSON
              wisp.json_response("{}", 201)
            }
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
  }
}

fn handle_update_export_log(
  req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  use body <- wisp.require_string_body(req)

  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case json.parse(body, using: decode.dynamic) {
        Error(_) -> wisp.bad_request()
        Ok(_json_data) -> {
          // TODO: Decode JSON to ExportLogUpdateRequest
          let request =
            export_log_encoder.ExportLogUpdateRequest(
              export_type: option.None,
              msg: option.None,
              running: option.None,
              cache_duration: option.None,
            )

          case
            import_export_api.update_export_log(
              config,
              log_id: log_id,
              request,
            )
          {
            Ok(_export_log) -> {
              // TODO: Encode export_log to JSON
              wisp.json_response("{}", 200)
            }
            Error(client.NotFoundError(_)) -> wisp.not_found()
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
  }
}

fn handle_delete_export_log(
  _req: wisp.Request,
  db: pog.Connection,
  log_id: Int,
) -> wisp.Response {
  case client.get_tandoor_config(db) {
    Error(_) -> wisp.internal_server_error()
    Ok(config) -> {
      case import_export_api.delete_export_log(config, log_id: log_id) {
        Ok(_) -> wisp.no_content()
        Error(client.NotFoundError(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}
