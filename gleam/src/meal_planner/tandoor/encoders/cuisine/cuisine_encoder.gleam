/// Cuisine encoder for Tandoor SDK
///
/// This module provides JSON encoders for Cuisine types to send to Tandoor API.
/// It includes encoders for create requests and update requests.
///
/// The encoders handle:
/// - Create requests (writable fields only)
/// - Update requests (partial updates with optional fields)
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
import meal_planner/tandoor/types/cuisine/cuisine.{
  type Cuisine, type CuisineCreateRequest, type CuisineUpdateRequest,
}

/// Encode a complete Cuisine to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_cuisine(cuisine: Cuisine) -> Json {
  json.object([
    #("id", json.int(cuisine.id)),
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
      Some(parent_id) -> json.int(parent_id)
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
