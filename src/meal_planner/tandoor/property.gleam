/// Tandoor Property Module
///
/// Provides the Property type for custom metadata on recipes and foods, along
/// with JSON encoding/decoding and CRUD API operations.
///
/// Properties allow users to add custom metadata fields beyond standard attributes
/// such as allergen information, dietary restrictions, meal prep time categories,
/// custom nutrition facts, or source/origin tracking.
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
import meal_planner/tandoor/core/ids.{type PropertyId}

// ============================================================================
// Types
// ============================================================================

/// Property type (recipe or food)
pub type PropertyType {
  RecipeProperty
  FoodProperty
}

/// Custom property for recipes or foods
///
/// Properties extend Tandoor's data model with user-defined fields.
/// They can be used for filtering, searching, and custom workflows.
///
/// Fields:
/// - id: Unique identifier
/// - name: Property name (required)
/// - description: Optional detailed description
/// - property_type: Whether this applies to recipes or foods
/// - unit: Optional unit of measurement
/// - order: Display order (lower numbers first)
/// - created_at: Creation timestamp (readonly)
/// - updated_at: Last update timestamp (readonly)
pub type Property {
  Property(
    id: PropertyId,
    name: String,
    description: String,
    property_type: PropertyType,
    unit: Option(String),
    order: Int,
    created_at: String,
    updated_at: String,
  )
}

/// Request to create a new property in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, timestamps)
pub type PropertyCreateRequest {
  PropertyCreateRequest(
    name: String,
    description: String,
    property_type: PropertyType,
    unit: Option(String),
    order: Int,
  )
}

/// Request to update an existing property in Tandoor
///
/// All fields are optional to support partial updates
pub type PropertyUpdateRequest {
  PropertyUpdateRequest(
    name: Option(String),
    description: Option(String),
    property_type: Option(PropertyType),
    unit: Option(String),
    order: Option(Int),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode PropertyType from JSON string
fn property_type_decoder() -> decode.Decoder(PropertyType) {
  use type_string <- decode.then(decode.string)
  case type_string {
    "RECIPE" -> decode.success(RecipeProperty)
    "FOOD" -> decode.success(FoodProperty)
    _ ->
      decode.failure(RecipeProperty, "Unknown property type: " <> type_string)
  }
}

/// Decode Property from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "allergens",
///   "description": "Food allergen information",
///   "property_type": "FOOD",
///   "unit": null,
///   "order": 0,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn property_decoder() -> decode.Decoder(Property) {
  use id <- decode.field("id", ids.property_id_decoder())
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use property_type <- decode.field("property_type", property_type_decoder())
  use unit <- decode.field("unit", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Property(
    id: id,
    name: name,
    description: description,
    property_type: property_type,
    unit: unit,
    order: order,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Convert PropertyType to JSON string
fn property_type_to_string(property_type: PropertyType) -> String {
  case property_type {
    RecipeProperty -> "RECIPE"
    FoodProperty -> "FOOD"
  }
}

/// Encode a complete Property to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_property(property: Property) -> Json {
  json.object([
    #("id", json.int(ids.property_id_to_int(property.id))),
    #("name", json.string(property.name)),
    #("description", json.string(property.description)),
    #(
      "property_type",
      json.string(property_type_to_string(property.property_type)),
    ),
    #("unit", case property.unit {
      Some(unit) -> json.string(unit)
      None -> json.null()
    }),
    #("order", json.int(property.order)),
    #("created_at", json.string(property.created_at)),
    #("updated_at", json.string(property.updated_at)),
  ])
}

/// Encode a PropertyCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
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

/// Encode a PropertyUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_property_update_request(req: PropertyUpdateRequest) -> Json {
  let name_field = case req.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let description_field = case req.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  let property_type_field = case req.property_type {
    Some(ptype) -> [
      #("property_type", json.string(property_type_to_string(ptype))),
    ]
    None -> []
  }

  let unit_field = case req.unit {
    Some(unit) -> [#("unit", json.string(unit))]
    None -> []
  }

  let order_field = case req.order {
    Some(ord) -> [#("order", json.int(ord))]
    None -> []
  }

  json.object(
    [
      name_field,
      description_field,
      property_type_field,
      unit_field,
      order_field,
    ]
    |> list.flatten,
  )
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// Get all properties from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration
///
/// # Returns
/// Result with list of properties or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_properties(config)
/// ```
pub fn list_properties(
  config: ClientConfig,
) -> Result(List(Property), TandoorError) {
  let path = "/api/property/"

  use resp <- result.try(execute_get(config, path, []))

  parse_json_list(resp, property_decoder())
}

/// Get a single property by ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID
///
/// # Returns
/// Result with property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_property(config, property_id: 1)
/// ```
pub fn get_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
) -> Result(Property, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  use resp <- result.try(execute_get(config, path, []))

  parse_json_single(resp, property_decoder())
}

/// Create a new property in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `create_data` - Property creation data
///
/// # Returns
/// Result with created property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = PropertyCreateRequest(name: "rating", property_type: RecipeProperty, ...)
/// let result = create_property(config, request)
/// ```
pub fn create_property(
  config: ClientConfig,
  create_data: PropertyCreateRequest,
) -> Result(Property, TandoorError) {
  let path = "/api/property/"

  let request_body =
    encode_property_create_request(create_data)
    |> json.to_string

  use resp <- result.try(execute_post(config, path, request_body))

  parse_json_single(resp, property_decoder())
}

/// Update an existing property in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID to update
/// * `update_data` - Property update data (partial update supported)
///
/// # Returns
/// Result with updated property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = PropertyUpdateRequest(name: option.Some("new_name"), ...)
/// let result = update_property(config, property_id: 1, update_data: request)
/// ```
pub fn update_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
  update_data update_data: PropertyUpdateRequest,
) -> Result(Property, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  let request_body =
    encode_property_update_request(update_data)
    |> json.to_string

  use resp <- result.try(execute_patch(config, path, request_body))

  parse_json_single(resp, property_decoder())
}

/// Delete a property from Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_property(config, property_id: 1)
/// ```
pub fn delete_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
) -> Result(Nil, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  use _resp <- result.try(execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
