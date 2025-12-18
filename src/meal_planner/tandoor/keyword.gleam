/// Tandoor Keyword Module
///
/// Provides the Keyword type for recipe categorization, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Keywords form a hierarchical tree structure allowing nested categorization
/// (e.g., Cuisine > Italian > Sicilian).
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

// ============================================================================
// Types
// ============================================================================

/// Keyword/tag for recipe categorization
///
/// Keywords in Tandoor form a hierarchical tree structure allowing nested
/// categorization (e.g., Cuisine > Italian > Sicilian).
///
/// Fields:
/// - id: Unique identifier
/// - name: Machine-friendly name (lowercase, no spaces)
/// - label: Human-readable display name (readonly, auto-generated from name)
/// - description: Optional detailed description
/// - icon: Optional emoji or icon character
/// - parent: ID of parent keyword (None for root keywords)
/// - numchild: Number of direct children (readonly)
/// - created_at: Creation timestamp (readonly)
/// - updated_at: Last update timestamp (readonly)
/// - full_name: Full path from root (e.g., "Cuisine > Italian > Sicilian") (readonly)
pub type Keyword {
  Keyword(
    id: Int,
    name: String,
    label: String,
    description: String,
    icon: Option(String),
    parent: Option(Int),
    numchild: Int,
    created_at: String,
    updated_at: String,
    full_name: String,
  )
}

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

// ============================================================================
// Decoder
// ============================================================================

/// Decode a Keyword from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "vegetarian",
///   "label": "Vegetarian",
///   "description": "Vegetarian recipes",
///   "icon": "🥗",
///   "parent": null,
///   "numchild": 0,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z",
///   "full_name": "Vegetarian"
/// }
/// ```
pub fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use label <- decode.field("label", decode.string)
  use description <- decode.field("description", decode.string)
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.field("parent", decode.optional(decode.int))
  use numchild <- decode.field("numchild", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use full_name <- decode.field("full_name", decode.string)

  decode.success(Keyword(
    id: id,
    name: name,
    label: label,
    description: description,
    icon: icon,
    parent: parent,
    numchild: numchild,
    created_at: created_at,
    updated_at: updated_at,
    full_name: full_name,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

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

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// Get all keywords from Tandoor API
pub fn list_keywords(
  config: ClientConfig,
) -> Result(List(Keyword), TandoorError) {
  list_keywords_by_parent(config, None)
}

/// Get keywords filtered by parent ID (None for root keywords)
pub fn list_keywords_by_parent(
  config: ClientConfig,
  parent_id: Option(Int),
) -> Result(List(Keyword), TandoorError) {
  let query_params = case parent_id {
    Some(id) -> [#("parent", int.to_string(id))]
    None -> [#("parent", "null")]
  }
  use resp <- result.try(execute_get(config, "/api/keyword/", query_params))
  parse_json_list(resp, keyword_decoder())
}

/// Get a single keyword by ID
pub fn get_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, keyword_decoder())
}

/// Create a new keyword in Tandoor
pub fn create_keyword(
  config: ClientConfig,
  create_data: KeywordCreateRequest,
) -> Result(Keyword, TandoorError) {
  let body =
    encode_keyword_create_request(create_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/keyword/", body))
  parse_json_single(resp, keyword_decoder())
}

/// Update an existing keyword (supports partial updates)
pub fn update_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
  data update_data: KeywordUpdateRequest,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  let body =
    encode_keyword_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, keyword_decoder())
}

/// Delete a keyword from Tandoor
pub fn delete_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
