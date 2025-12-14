/// Property encoder for Tandoor SDK
///
/// This module provides JSON encoders for Property types.
/// Handles encoding for create and update requests.
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/types/property/property.{
  type PropertyType, FoodProperty, RecipeProperty,
}

/// Request type for creating a property
pub type PropertyCreateRequest {
  PropertyCreateRequest(
    name: String,
    description: String,
    property_type: PropertyType,
    unit: Option(String),
    order: Int,
  )
}

/// Request type for updating a property (all fields optional)
pub type PropertyUpdateRequest {
  PropertyUpdateRequest(
    name: Option(String),
    description: Option(String),
    property_type: Option(PropertyType),
    unit: Option(String),
    order: Option(Int),
  )
}

/// Convert PropertyType to JSON string
fn property_type_to_string(property_type: PropertyType) -> String {
  case property_type {
    RecipeProperty -> "RECIPE"
    FoodProperty -> "FOOD"
  }
}

/// Encode PropertyCreateRequest to JSON
///
/// # Arguments
/// * `req` - Property create request
///
/// # Returns
/// JSON representation
pub fn encode_property_create_request(req: PropertyCreateRequest) -> Json {
  json.object([
    #("name", json.string(req.name)),
    #("description", json.string(req.description)),
    #("property_type", json.string(property_type_to_string(req.property_type))),
    #("unit", case req.unit {
      Some(unit) -> json.string(unit)
      None -> json.null()
    }),
    #("order", json.int(req.order)),
  ])
}

/// Encode PropertyUpdateRequest to JSON
///
/// Only includes fields that are Some(_), allowing partial updates
///
/// # Arguments
/// * `req` - Property update request
///
/// # Returns
/// JSON representation
pub fn encode_property_update_request(req: PropertyUpdateRequest) -> Json {
  let fields = []

  let fields = case req.name {
    Some(name) -> [#("name", json.string(name)), ..fields]
    None -> fields
  }

  let fields = case req.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    None -> fields
  }

  let fields = case req.property_type {
    Some(ptype) -> [
      #("property_type", json.string(property_type_to_string(ptype))),
      ..fields
    ]
    None -> fields
  }

  let fields = case req.unit {
    Some(unit) -> [#("unit", json.string(unit)), ..fields]
    None -> fields
  }

  let fields = case req.order {
    Some(ord) -> [#("order", json.int(ord)), ..fields]
    None -> fields
  }

  json.object(fields)
}
