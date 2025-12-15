/// Generic CRUD Module
///
/// Consolidates boilerplate CRUD operations across all Tandoor API endpoints.
/// Reduces code duplication from 36 individual CRUD files to a single generic module.
///
/// # Usage
///
/// Instead of writing 5 separate modules per resource (create.gleam, get.gleam, list.gleam, update.gleam, delete.gleam),
/// use this module with polymorphic functions:
///
/// ```gleam
/// // Get a single resource
/// use resp <- result.try(generic_crud.get(
///   config,
///   "/api/cuisine/",
///   5,
///   cuisine_decoder(),
/// ))
/// Ok(cuisine)
///
/// // List resources
/// use cuisines <- result.try(generic_crud.list(
///   config,
///   "/api/cuisine/",
///   [],
///   cuisine_decoder(),
/// ))
/// Ok(cuisines)
///
/// // Create resource
/// let body = cuisine_encoder.encode(data) |> json.to_string
/// use new_cuisine <- result.try(generic_crud.create(
///   config,
///   "/api/cuisine/",
///   body,
///   cuisine_decoder(),
/// ))
/// Ok(new_cuisine)
///
/// // Update resource
/// let body = cuisine_encoder.encode_update(data) |> json.to_string
/// use updated <- result.try(generic_crud.update(
///   config,
///   "/api/cuisine/",
///   5,
///   body,
///   cuisine_decoder(),
/// ))
/// Ok(updated)
///
/// // Delete resource
/// use _nil <- result.try(generic_crud.delete(config, "/api/cuisine/", 5))
/// Ok(Nil)
/// ```
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

// ============================================================================
// Path Builders
// ============================================================================

/// Build a resource path, optionally appending an ID
///
/// # Arguments
/// * `base_path` - Base path like "/api/cuisine/"
/// * `id` - Optional resource ID
///
/// # Returns
/// Complete path, e.g. "/api/cuisine/" or "/api/cuisine/5/"
///
/// # Example
/// ```gleam
/// build_path("/api/cuisine/", None)     // "/api/cuisine/"
/// build_path("/api/cuisine/", Some(5))  // "/api/cuisine/5/"
/// ```
pub fn build_path(base_path: String, id: Option(Int)) -> String {
  case id {
    None -> base_path
    Some(id_value) -> base_path <> int.to_string(id_value) <> "/"
  }
}

// ============================================================================
// Generic CRUD Operations
// ============================================================================

/// Get a single resource by ID
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `base_path` - Base API path like "/api/cuisine/"
/// * `id` - Resource ID
/// * `decoder` - Decoder for response type
///
/// # Returns
/// Result with decoded resource or error
///
/// # Example
/// ```gleam
/// use cuisine <- result.try(get(
///   config,
///   "/api/cuisine/",
///   5,
///   cuisine_decoder(),
/// ))
/// Ok(cuisine)
/// ```
pub fn get(
  config: ClientConfig,
  base_path: String,
  id: Int,
  decoder: decode.Decoder(a),
) -> Result(a, TandoorError) {
  let path = build_path(base_path, Some(id))
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, decoder)
}

/// List resources with optional query parameters
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `base_path` - Base API path like "/api/cuisine/"
/// * `query_params` - Optional query parameters as key-value pairs
/// * `decoder` - Decoder for response type
///
/// # Returns
/// Result with list of resources or error
///
/// # Example
/// ```gleam
/// use cuisines <- result.try(list(
///   config,
///   "/api/cuisine/",
///   [#("parent", "5")],
///   cuisine_decoder(),
/// ))
/// Ok(cuisines)
/// ```
pub fn list(
  config: ClientConfig,
  base_path: String,
  query_params: List(#(String, String)),
  decoder: decode.Decoder(a),
) -> Result(List(a), TandoorError) {
  let path = build_path(base_path, None)
  use resp <- result.try(crud_helpers.execute_get(config, path, query_params))
  crud_helpers.parse_json_list(resp, decoder)
}

/// Create a new resource
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `base_path` - Base API path like "/api/cuisine/"
/// * `body` - JSON string of request body
/// * `decoder` - Decoder for response type
///
/// # Returns
/// Result with created resource or error
///
/// # Example
/// ```gleam
/// let body = encoder.encode(data) |> json.to_string
/// use new_cuisine <- result.try(create(
///   config,
///   "/api/cuisine/",
///   body,
///   cuisine_decoder(),
/// ))
/// Ok(new_cuisine)
/// ```
pub fn create(
  config: ClientConfig,
  base_path: String,
  body: String,
  decoder: decode.Decoder(a),
) -> Result(a, TandoorError) {
  let path = build_path(base_path, None)
  use resp <- result.try(crud_helpers.execute_post(config, path, body))
  crud_helpers.parse_json_single(resp, decoder)
}

/// Update an existing resource
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `base_path` - Base API path like "/api/cuisine/"
/// * `id` - Resource ID to update
/// * `body` - JSON string of request body
/// * `decoder` - Decoder for response type
///
/// # Returns
/// Result with updated resource or error
///
/// # Example
/// ```gleam
/// let body = encoder.encode_update(data) |> json.to_string
/// use updated <- result.try(update(
///   config,
///   "/api/cuisine/",
///   5,
///   body,
///   cuisine_decoder(),
/// ))
/// Ok(updated)
/// ```
pub fn update(
  config: ClientConfig,
  base_path: String,
  id: Int,
  body: String,
  decoder: decode.Decoder(a),
) -> Result(a, TandoorError) {
  let path = build_path(base_path, Some(id))
  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, decoder)
}

/// Delete a resource
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `base_path` - Base API path like "/api/cuisine/"
/// * `id` - Resource ID to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// use _nil <- result.try(delete(config, "/api/cuisine/", 5))
/// Ok(Nil)
/// ```
pub fn delete(
  config: ClientConfig,
  base_path: String,
  id: Int,
) -> Result(Nil, TandoorError) {
  let path = build_path(base_path, Some(id))
  use _resp <- result.try(crud_helpers.execute_delete(config, path))
  Ok(Nil)
}
