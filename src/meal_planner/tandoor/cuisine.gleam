/// Tandoor Cuisine Module
///
/// Provides the Cuisine type for recipe categorization by cultural/regional origin,
/// along with JSON encoding/decoding and CRUD API operations.
///
/// Cuisines categorize recipes by their cultural or regional origin (e.g., Italian,
/// Mexican, Thai). They can be hierarchical (e.g., Asian > Chinese > Szechuan).
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
import meal_planner/tandoor/core/ids.{
  type CuisineId, cuisine_id_from_int, cuisine_id_to_int,
}

// ============================================================================
// Types
// ============================================================================

/// Cuisine data structure from Tandoor API
///
/// Cuisines categorize recipes by their cultural or regional origin.
/// They can be hierarchical (e.g., Asian > Chinese > Szechuan).
///
/// Fields:
/// - id: Unique identifier (readonly)
/// - name: Display name (e.g., "Italian", "Mexican") (max 128 chars)
/// - description: Optional detailed description
/// - icon: Optional emoji or icon identifier
/// - parent: Optional parent cuisine ID for hierarchy
/// - num_recipes: Number of recipes tagged with this cuisine (readonly)
/// - created_at: Timestamp when created (readonly)
/// - updated_at: Timestamp when last modified (readonly)
pub type Cuisine {
  Cuisine(
    id: CuisineId,
    name: String,
    description: Option(String),
    icon: Option(String),
    parent: Option(CuisineId),
    num_recipes: Int,
    created_at: String,
    updated_at: String,
  )
}

/// Request data for creating a new cuisine
///
/// Only required field is `name`. All other fields are optional.
pub type CuisineCreateRequest {
  CuisineCreateRequest(
    name: String,
    description: Option(String),
    icon: Option(String),
    parent: Option(Int),
  )
}

/// Request data for updating an existing cuisine
///
/// All fields are optional - only provided fields will be updated (PATCH semantics).
/// For nullable fields (description, icon, parent):
/// - None: Don't update this field
/// - Some(None): Set to null
/// - Some(Some(value)): Set to value
pub type CuisineUpdateRequest {
  CuisineUpdateRequest(
    name: Option(String),
    description: Option(Option(String)),
    icon: Option(Option(String)),
    parent: Option(Option(Int)),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode a Cuisine from JSON
///
/// This decoder handles all fields of a cuisine including optional description, icon, and parent.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Italian",
///   "description": "Traditional Italian cuisine",
///   "icon": "🇮🇹",
///   "parent": null,
///   "num_recipes": 42,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn cuisine_decoder() -> decode.Decoder(Cuisine) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.field("parent", decode.optional(decode.int))
  use num_recipes <- decode.field("num_recipes", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Cuisine(
    id: cuisine_id_from_int(id),
    name: name,
    description: description,
    icon: icon,
    parent: option.map(parent, cuisine_id_from_int),
    num_recipes: num_recipes,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a complete Cuisine to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_cuisine(cuisine: Cuisine) -> Json {
  json.object([
    #("id", json.int(cuisine_id_to_int(cuisine.id))),
    #("name", json.string(cuisine.name)),
    #("description", case cuisine.description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    }),
    #("icon", case cuisine.icon {
      Some(icon) -> json.string(icon)
      None -> json.null()
    }),
    #("parent", case cuisine.parent {
      Some(parent_id) -> json.int(cuisine_id_to_int(parent_id))
      None -> json.null()
    }),
    #("num_recipes", json.int(cuisine.num_recipes)),
    #("created_at", json.string(cuisine.created_at)),
    #("updated_at", json.string(cuisine.updated_at)),
  ])
}

/// Encode a CuisineCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_cuisine_create_request(request: CuisineCreateRequest) -> Json {
  let base_fields = [#("name", json.string(request.name))]

  let description_field = case request.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  let icon_field = case request.icon {
    Some(icon) -> [#("icon", json.string(icon))]
    None -> []
  }

  let parent_field = case request.parent {
    Some(parent_id) -> [#("parent", json.int(parent_id))]
    None -> []
  }

  json.object(
    list.flatten([base_fields, description_field, icon_field, parent_field]),
  )
}

/// Encode a CuisineUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_cuisine_update_request(request: CuisineUpdateRequest) -> Json {
  let name_field = case request.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let description_field = case request.description {
    Some(Some(desc)) -> [#("description", json.string(desc))]
    Some(None) -> [#("description", json.null())]
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

/// Get all cuisines from Tandoor API
pub fn list_cuisines(
  config: ClientConfig,
) -> Result(List(Cuisine), TandoorError) {
  list_cuisines_by_parent(config, None)
}

/// Get cuisines filtered by parent ID (None for root cuisines)
pub fn list_cuisines_by_parent(
  config: ClientConfig,
  parent_id: Option(CuisineId),
) -> Result(List(Cuisine), TandoorError) {
  let query_params = case parent_id {
    Some(id) -> [#("parent", int.to_string(cuisine_id_to_int(id)))]
    None -> [#("parent", "null")]
  }
  use resp <- result.try(execute_get(config, "/api/cuisine/", query_params))
  parse_json_list(resp, cuisine_decoder())
}

/// Get a single cuisine by ID
pub fn get_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
) -> Result(Cuisine, TandoorError) {
  let path =
    "/api/cuisine/" <> int.to_string(cuisine_id_to_int(cuisine_id)) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, cuisine_decoder())
}

/// Create a new cuisine in Tandoor
pub fn create_cuisine(
  config: ClientConfig,
  cuisine_data: CuisineCreateRequest,
) -> Result(Cuisine, TandoorError) {
  let body =
    encode_cuisine_create_request(cuisine_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/cuisine/", body))
  parse_json_single(resp, cuisine_decoder())
}

/// Update an existing cuisine (supports partial updates)
pub fn update_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
  data update_data: CuisineUpdateRequest,
) -> Result(Cuisine, TandoorError) {
  let path =
    "/api/cuisine/" <> int.to_string(cuisine_id_to_int(cuisine_id)) <> "/"
  let body =
    encode_cuisine_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, cuisine_decoder())
}

/// Delete a cuisine from Tandoor
pub fn delete_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
) -> Result(Nil, TandoorError) {
  let path =
    "/api/cuisine/" <> int.to_string(cuisine_id_to_int(cuisine_id)) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
