/// Import/Export API
///
/// This module provides functions to interact with Tandoor's import and export
/// log endpoints. These logs track the status of recipe import/export operations.
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/import_export/export_log_decoder
import meal_planner/tandoor/decoders/import_export/export_log_list_decoder
import meal_planner/tandoor/decoders/import_export/import_log_decoder
import meal_planner/tandoor/decoders/import_export/import_log_list_decoder
import meal_planner/tandoor/encoders/import_export/export_log_encoder.{
  type ExportLogCreateRequest, type ExportLogUpdateRequest,
}
import meal_planner/tandoor/encoders/import_export/import_log_encoder.{
  type ImportLogCreateRequest, type ImportLogUpdateRequest,
}
import meal_planner/tandoor/types/import_export/export_log.{type ExportLog}
import meal_planner/tandoor/types/import_export/export_log_list.{
  type ExportLogList,
}
import meal_planner/tandoor/types/import_export/import_log.{type ImportLog}
import meal_planner/tandoor/types/import_export/import_log_list.{
  type ImportLogList,
}

/// List import logs from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated import log list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_import_logs(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_import_logs(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(ImportLogList, TandoorError) {
  // Build query parameters
  let path = case limit, offset {
    option.Some(l), option.Some(o) ->
      "/api/import-log/?limit="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(l), option.None -> "/api/import-log/?limit=" <> int.to_string(l)
    option.None, option.Some(o) ->
      "/api/import-log/?offset=" <> int.to_string(o)
    option.None, option.None -> "/api/import-log/"
  }

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(json_data, import_log_list_decoder.import_log_list_decoder())
      {
        Ok(import_log_list) -> Ok(import_log_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode import log list: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Get a single import log by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the import log to fetch
///
/// # Returns
/// Result with import log details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_import_log(config, log_id: 123)
/// ```
pub fn get_import_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(ImportLog, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, import_log_decoder.import_log_decoder()) {
        Ok(import_log) -> Ok(import_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode import log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// List export logs from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (limit parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated export log list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_export_logs(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_export_logs(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(ExportLogList, TandoorError) {
  // Build query parameters
  let path = case limit, offset {
    option.Some(l), option.Some(o) ->
      "/api/export-log/?limit="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(l), option.None -> "/api/export-log/?limit=" <> int.to_string(l)
    option.None, option.Some(o) ->
      "/api/export-log/?offset=" <> int.to_string(o)
    option.None, option.None -> "/api/export-log/"
  }

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(json_data, export_log_list_decoder.export_log_list_decoder())
      {
        Ok(export_log_list) -> Ok(export_log_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode export log list: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Get a single export log by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the export log to fetch
///
/// # Returns
/// Result with export log details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_export_log(config, log_id: 321)
/// ```
pub fn get_export_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(ExportLog, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, export_log_decoder.export_log_decoder()) {
        Ok(export_log) -> Ok(export_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode export log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Create a new import log in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Import log creation request with required fields
///
/// # Returns
/// Result with created import log or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = ImportLogCreateRequest(
///   import_type: "nextcloud",
///   msg: Some("Starting import from Nextcloud"),
///   keyword: Some(42)
/// )
/// let result = create_import_log(config, request)
/// ```
pub fn create_import_log(
  config: ClientConfig,
  request: ImportLogCreateRequest,
) -> Result(ImportLog, TandoorError) {
  let path = "/api/import-log/"
  let body = import_log_encoder.encode_import_log_create_request(request)

  // Build POST request
  use req <- result.try(client.build_post_request(
    config,
    path,
    json.to_string(body),
  ))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, import_log_decoder.import_log_decoder()) {
        Ok(import_log) -> Ok(import_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode import log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Update an existing import log in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the import log to update
/// * `request` - Import log update request with fields to modify
///
/// # Returns
/// Result with updated import log or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = ImportLogUpdateRequest(
///   msg: Some("Import completed successfully"),
///   running: Some(False),
///   import_type: None,
///   keyword: None
/// )
/// let result = update_import_log(config, log_id: 123, request)
/// ```
pub fn update_import_log(
  config: ClientConfig,
  request: ImportLogUpdateRequest,
  log_id log_id: Int,
) -> Result(ImportLog, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"
  let body = import_log_encoder.encode_import_log_update_request(request)

  // Build PATCH request
  use base_req <- result.try(client.build_get_request(config, path, []))

  let req =
    base_req
    |> request.set_method(http.Patch)
    |> request.set_body(json.to_string(body))
    |> request.set_header("content-type", "application/json")

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, import_log_decoder.import_log_decoder()) {
        Ok(import_log) -> Ok(import_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode import log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Delete an import log from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the import log to delete
///
/// # Returns
/// Result with unit on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_import_log(config, log_id: 123)
/// ```
pub fn delete_import_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/import-log/" <> int.to_string(log_id) <> "/"

  // Build DELETE request
  use base_req <- result.try(client.build_get_request(config, path, []))

  let req = base_req |> request.set_method(http.Delete)

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  Ok(Nil)
}

/// Create a new export log in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Export log creation request with required fields
///
/// # Returns
/// Result with created export log or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = ExportLogCreateRequest(
///   export_type: "zip",
///   msg: Some("Starting export to ZIP"),
///   cache_duration: Some(3600)
/// )
/// let result = create_export_log(config, request)
/// ```
pub fn create_export_log(
  config: ClientConfig,
  request: ExportLogCreateRequest,
) -> Result(ExportLog, TandoorError) {
  let path = "/api/export-log/"
  let body = export_log_encoder.encode_export_log_create_request(request)

  // Build POST request
  use req <- result.try(client.build_post_request(
    config,
    path,
    json.to_string(body),
  ))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, export_log_decoder.export_log_decoder()) {
        Ok(export_log) -> Ok(export_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode export log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Update an existing export log in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the export log to update
/// * `request` - Export log update request with fields to modify
///
/// # Returns
/// Result with updated export log or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = ExportLogUpdateRequest(
///   msg: Some("Export completed successfully"),
///   running: Some(False),
///   export_type: None,
///   cache_duration: None
/// )
/// let result = update_export_log(config, log_id: 321, request)
/// ```
pub fn update_export_log(
  config: ClientConfig,
  request: ExportLogUpdateRequest,
  log_id log_id: Int,
) -> Result(ExportLog, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"
  let body = export_log_encoder.encode_export_log_update_request(request)

  // Build PATCH request
  use base_req <- result.try(client.build_get_request(config, path, []))

  let req =
    base_req
    |> request.set_method(http.Patch)
    |> request.set_body(json.to_string(body))
    |> request.set_header("content-type", "application/json")

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, export_log_decoder.export_log_decoder()) {
        Ok(export_log) -> Ok(export_log)
        Error(errors) -> {
          let error_msg =
            "Failed to decode export log: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Delete an export log from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `log_id` - The ID of the export log to delete
///
/// # Returns
/// Result with unit on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_export_log(config, log_id: 321)
/// ```
pub fn delete_export_log(
  config: ClientConfig,
  log_id log_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/export-log/" <> int.to_string(log_id) <> "/"

  // Build DELETE request
  use base_req <- result.try(client.build_get_request(config, path, []))

  let req = base_req |> request.set_method(http.Delete)

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  Ok(Nil)
}
