/// Keyword encoder for Tandoor SDK
///
/// This module provides JSON encoders for Keyword types to send to Tandoor API.
/// It includes encoders for full keywords, create requests, and update requests.
///
/// The encoders handle:
/// - Complete keyword objects (all fields)
/// - Create requests (writable fields only)
/// - Update requests (partial updates with optional fields)
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/types/keyword/keyword.{type Keyword}

/// Request to create a new keyword in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, label, etc.)
pub type KeywordCreateRequest {
  KeywordCreateRequest(
    name: String,
    description: String,
    icon: Option(String),
    parent: Option(Int),
  )
}

/// Request to update an existing keyword in Tandoor
///
/// All fields are optional to support partial updates
pub type KeywordUpdateRequest {
  KeywordUpdateRequest(
    name: Option(String),
    description: Option(String),
    icon: Option(Option(String)),
    parent: Option(Option(Int)),
  )
}

/// Encode a complete Keyword to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_keyword(keyword: Keyword) -> Json {
  json.object([
    #("id", json.int(keyword.id)),
    #("name", json.string(keyword.name)),
    #("label", json.string(keyword.label)),
    #("description", json.string(keyword.description)),
    #("icon", case keyword.icon {
      Some(icon) -> json.string(icon)
      None -> json.null()
    }),
    #("parent", case keyword.parent {
      Some(parent_id) -> json.int(parent_id)
      None -> json.null()
    }),
    #("numchild", json.int(keyword.numchild)),
    #("created_at", json.string(keyword.created_at)),
    #("updated_at", json.string(keyword.updated_at)),
    #("full_name", json.string(keyword.full_name)),
  ])
}

/// Encode a KeywordCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_keyword_create_request(request: KeywordCreateRequest) -> Json {
  let base_fields = [
    #("name", json.string(request.name)),
    #("description", json.string(request.description)),
  ]

  let icon_field = case request.icon {
    Some(icon) -> [#("icon", json.string(icon))]
    None -> []
  }

  let parent_field = case request.parent {
    Some(parent_id) -> [#("parent", json.int(parent_id))]
    None -> []
  }

  json.object(list.flatten([base_fields, icon_field, parent_field]))
}

/// Encode a KeywordUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_keyword_update_request(request: KeywordUpdateRequest) -> Json {
  let name_field = case request.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let description_field = case request.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  let icon_field = case request.icon {
    Some(Some(icon)) -> [#("icon", json.string(icon))]
    Some(None) -> [#("icon", json.null())]
    None -> []
  }

  let parent_field = case request.parent {
    Some(Some(parent_id)) -> [#("parent", json.int(parent_id))]
    Some(None) -> [#("parent", json.null())]
    None -> []
  }

  json.object(
    list.flatten([name_field, description_field, icon_field, parent_field]),
  )
}
