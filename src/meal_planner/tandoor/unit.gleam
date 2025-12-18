/// Tandoor Unit Module
///
/// Provides the Unit type (measurement units like gram, liter, piece),
/// along with JSON encoding/decoding and CRUD API operations.
///
/// This module consolidates types, decoders, encoders, and API functions
/// following CUPID principles (domain-centric organization).
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}

// ============================================================================
// Type
// ============================================================================

/// Tandoor Unit type
/// Represents a unit of measurement (gram, liter, piece, etc.)
pub type Unit {
  Unit(
    /// Tandoor unit ID
    id: Int,
    /// Unit name (required)
    name: String,
    /// Optional plural form of the unit name
    plural_name: Option(String),
    /// Optional description of the unit
    description: Option(String),
    /// Optional base unit for conversion
    base_unit: Option(String),
    /// Optional Open Food Facts data slug
    open_data_slug: Option(String),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode a Unit from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "gram",
///   "plural_name": "grams",
///   "description": "Metric unit of mass",
///   "base_unit": "kilogram",
///   "open_data_slug": "g"
/// }
/// ```
///
/// Required fields:
/// - id: Int
/// - name: String
///
/// Optional fields (nullable):
/// - plural_name: String
/// - description: String
/// - base_unit: String
/// - open_data_slug: String
pub fn decode_unit() -> decode.Decoder(Unit) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use base_unit <- decode.field("base_unit", decode.optional(decode.string))
  use open_data_slug <- decode.field(
    "open_data_slug",
    decode.optional(decode.string),
  )

  decode.success(Unit(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    base_unit: base_unit,
    open_data_slug: open_data_slug,
  ))
}

// ============================================================================
// Encoder
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
pub fn encode_unit_create(name: String) -> Json {
  json.object([#("name", json.string(name))])
}

/// Helper to encode optional string fields
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    option.Some(str) -> json.string(str)
    option.None -> json.null()
  }
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// Get a single unit by ID
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to retrieve
///
/// # Returns
/// Result with the unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_unit(config, unit_id: 1)
/// ```
pub fn get_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  crud_helpers.parse_json_single(resp, decode_unit())
}

/// Create a new unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `name` - The unit name (required)
///
/// # Returns
/// Result with the created unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = create_unit(config, name: "tablespoon")
/// ```
pub fn create_unit(
  config: ClientConfig,
  name name: String,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/"

  let request_body =
    encode_unit_create(name)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(config, path, request_body))

  crud_helpers.parse_json_single(resp, decode_unit())
}

/// Update an existing unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to update
/// * `unit` - The updated unit data
///
/// # Returns
/// Result with the updated unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let unit = Unit(id: 1, name: "gram", ...)
/// let result = update_unit(config, unit_id: 1, unit: unit)
/// ```
pub fn update_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
  unit unit: Unit,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  let request_body =
    encode_unit(unit)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, request_body))

  crud_helpers.parse_json_single(resp, decode_unit())
}

/// Delete a unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_unit(config, unit_id: 1)
/// ```
pub fn delete_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  Ok(Nil)
}

// ============================================================================
// API - List Operations
// ============================================================================

/// List units from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated unit list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_units(config, limit: Some(25), page: Some(1))
/// ```
pub fn list_units(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Unit), TandoorError) {
  let query_params = build_query_params(limit, page)

  generic_crud.list_paginated(config, "/api/unit/", query_params, decode_unit())
}

/// Build query parameters from limit and page options
fn build_query_params(
  limit: Option(Int),
  page: Option(Int),
) -> List(#(String, String)) {
  let limit_params = case limit {
    option.Some(l) -> [#("page_size", int.to_string(l))]
    option.None -> []
  }

  let page_params = case page {
    option.Some(p) -> [#("page", int.to_string(p))]
    option.None -> []
  }

  list.append(limit_params, page_params)
}
