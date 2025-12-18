/// Property encoder for Tandoor SDK
///
/// This module provides JSON encoders for Property types.
/// Encodes Property instances (values) with amounts.
import gleam/json.{type Json}
import gleam/option.{None, Some}
import meal_planner/tandoor/types/property/property.{type Property}

/// Encode Property to JSON
///
/// Encodes a Property instance (value) with an optional amount.
///
/// # Arguments
/// * `property` - Property instance to encode
///
/// # Returns
/// JSON representation
pub fn encode_property(property: Property) -> Json {
  let amount_json = case property.property_amount {
    Some(amount) -> json.float(amount)
    None -> json.null()
  }

  json.object([
    #("id", json.int(property.id)),
    #("property_amount", amount_json),
    #("property_type", json.int(property.property_type.id)),
  ])
}
