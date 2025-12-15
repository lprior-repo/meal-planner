/// ExportLog encoder for Tandoor SDK
///
/// This module provides JSON encoders for ExportLog types to send to Tandoor API.
/// It includes encoders for create requests and update requests.
///
/// The encoders handle:
/// - Create requests (writable fields only)
/// - Update requests (partial updates with optional fields)
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

/// Request to create a new export log in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, created_at, etc.)
pub type ExportLogCreateRequest {
  ExportLogCreateRequest(
    export_type: String,
    msg: Option(String),
    cache_duration: Option(Int),
  )
}

/// Request to update an existing export log in Tandoor
///
/// All fields are optional to support partial updates
pub type ExportLogUpdateRequest {
  ExportLogUpdateRequest(
    export_type: Option(String),
    msg: Option(String),
    running: Option(Bool),
    cache_duration: Option(Int),
  )
}

/// Encode an ExportLogCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_export_log_create_request(request: ExportLogCreateRequest) -> Json {
  let base_fields = [#("export_type", json.string(request.export_type))]

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let cache_duration_field = case request.cache_duration {
    Some(duration) -> [#("cache_duration", json.int(duration))]
    None -> []
  }

  json.object(list.flatten([base_fields, msg_field, cache_duration_field]))
}

/// Encode an ExportLogUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_export_log_update_request(request: ExportLogUpdateRequest) -> Json {
  let export_type_field = case request.export_type {
    Some(export_type) -> [#("export_type", json.string(export_type))]
    None -> []
  }

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let running_field = case request.running {
    Some(running) -> [#("running", json.bool(running))]
    None -> []
  }

  let cache_duration_field = case request.cache_duration {
    Some(duration) -> [#("cache_duration", json.int(duration))]
    None -> []
  }

  json.object(
    list.flatten([
      export_type_field,
      msg_field,
      running_field,
      cache_duration_field,
    ]),
  )
}
