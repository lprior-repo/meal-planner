/// Unit encoder for Tandoor SDK
///
/// This module provides JSON encoders for Unit types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (id, name)
/// - Optional fields (plural_name, description, base_unit, open_data_slug)
/// - Clean, minimal JSON output matching Tandoor API expectations
///
/// TDD Implementation: GREEN phase - making tests pass
import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/tandoor/types/unit/unit.{type Unit}

// ============================================================================
// Unit Encoder
// ============================================================================

/// Encode a Unit to JSON
///
/// This encoder creates complete JSON for Unit objects, including all fields.
/// Optional fields are encoded as null when None.
///
/// # Example
/// ```gleam
/// let unit = Unit(
///   id: 1,
///   name: "gram",
///   plural_name: Some("grams"),
///   description: Some("Metric unit of mass"),
///   base_unit: Some("kilogram"),
///   open_data_slug: Some("g")
/// )
/// let encoded = encode_unit(unit)
/// ```
///
/// # Arguments
/// * `unit` - The unit to encode
///
/// # Returns
/// JSON representation of the unit
pub fn encode_unit(unit: Unit) -> Json {
  json.object([
    #("id", json.int(unit.id)),
    #("name", json.string(unit.name)),
    #("plural_name", encode_optional_string(unit.plural_name)),
    #("description", encode_optional_string(unit.description)),
    #("base_unit", encode_optional_string(unit.base_unit)),
    #("open_data_slug", encode_optional_string(unit.open_data_slug)),
  ])
}

// ============================================================================
// Unit Create Encoder
// ============================================================================

/// Encode a unit name for creation request
///
/// This encoder creates minimal JSON for unit creation requests.
/// It only includes the required 'name' field.
///
/// # Example
/// ```gleam
/// let encoded = encode_unit_create("tablespoon")
/// json.to_string(encoded) // "{\"name\":\"tablespoon\"}"
/// ```
///
/// # Arguments
/// * `name` - The unit name
///
/// # Returns
/// JSON representation of the unit create request
pub fn encode_unit_create(name: String) -> Json {
  json.object([#("name", json.string(name))])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Helper to encode optional string fields
/// Returns json.null() for None, json.string(value) for Some(value)
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    option.Some(str) -> json.string(str)
    option.None -> json.null()
  }
}
