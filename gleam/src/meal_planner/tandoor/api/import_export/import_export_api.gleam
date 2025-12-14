/// Import/Export API
///
/// This module provides functions to interact with Tandoor's import and export
/// log endpoints. These logs track the status of recipe import/export operations.
import gleam/dynamic/decode
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
