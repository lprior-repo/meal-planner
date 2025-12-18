/// ImportLog encoder for Tandoor SDK
///
/// This module provides JSON encoders for ImportLog types to send to Tandoor API.
/// It includes encoders for create requests and update requests.
///
/// The encoders handle:
/// - Create requests (writable fields only)
/// - Update requests (partial updates with optional fields)
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

/// Request to create a new import log in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, created_at, etc.)
pub type ImportLogCreateRequest {
  ImportLogCreateRequest(
    import_type: String,
    msg: Option(String),
    keyword: Option(Int),
  )
}

/// Request to update an existing import log in Tandoor
///
/// All fields are optional to support partial updates
pub type ImportLogUpdateRequest {
  ImportLogUpdateRequest(
    import_type: Option(String),
    msg: Option(String),
    running: Option(Bool),
    keyword: Option(Option(Int)),
  )
}

/// Encode an ImportLogCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_import_log_create_request(request: ImportLogCreateRequest) -> Json {
  let base_fields = [#("import_type", json.string(request.import_type))]

  let msg_field = case request.msg {
    Some(msg) -> [#("msg", json.string(msg))]
    None -> []
  }

  let keyword_field = case request.keyword {
    Some(keyword_id) -> [#("keyword", json.int(keyword_id))]
    None -> []
  }

  json.object(list.flatten([base_fields, msg_field, keyword_field]))
}

/// Encode an ImportLogUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_import_log_update_request(request: ImportLogUpdateRequest) -> Json {
  let import_type_field = case request.import_type {
    Some(import_type) -> [#("import_type", json.string(import_type))]
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

  let keyword_field = case request.keyword {
    Some(Some(keyword_id)) -> [#("keyword", json.int(keyword_id))]
    Some(None) -> [#("keyword", json.null())]
    None -> []
  }

  json.object(
    list.flatten([import_type_field, msg_field, running_field, keyword_field]),
  )
}
