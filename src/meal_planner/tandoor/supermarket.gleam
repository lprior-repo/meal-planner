/// Tandoor Supermarket Module
///
/// Provides types for supermarket and category management, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Supermarkets represent physical or online grocery stores with category
/// mappings that organize foods by store aisles/sections.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_empty_response,
  parse_json_paginated, parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}

// ============================================================================
// Types
// ============================================================================

/// Supermarket/store definition
///
/// Represents a physical or online grocery store with category mappings
/// that organize foods by store aisles/sections.
///
/// Fields:
/// - id: Tandoor supermarket ID
/// - name: Supermarket name (e.g., "Whole Foods", "Trader Joe's")
/// - description: Optional description
/// - category_to_supermarket: Category mappings for this supermarket
/// - open_data_slug: Optional slug for external data integration
pub type Supermarket {
  Supermarket(
    id: Int,
    name: String,
    description: Option(String),
    category_to_supermarket: List(SupermarketCategoryRelation),
    open_data_slug: Option(String),
  )
}

/// Relation between a supermarket and a category
///
/// Defines the ordering and association of categories within a specific store.
///
/// Fields:
/// - id: Relation ID
/// - category_id: The category being mapped
/// - supermarket_id: The supermarket this category belongs to
/// - order: Display order for this category in the supermarket
pub type SupermarketCategoryRelation {
  SupermarketCategoryRelation(
    id: Int,
    category_id: Int,
    supermarket_id: Int,
    order: Int,
  )
}

/// Supermarket category for organizing foods by store aisles/sections
///
/// Maps food categories to supermarket departments (e.g., "Produce", "Dairy").
///
/// Fields:
/// - id: Tandoor supermarket category ID
/// - name: Category name (e.g., "Produce", "Dairy", "Frozen Foods")
/// - description: Optional description of this category
/// - open_data_slug: Optional slug for external data integration
pub type SupermarketCategory {
  SupermarketCategory(
    id: Int,
    name: String,
    description: Option(String),
    open_data_slug: Option(String),
  )
}

/// Request to create a new supermarket in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id).
pub type SupermarketCreateRequest {
  SupermarketCreateRequest(name: String, description: Option(String))
}

/// Request to create a new supermarket category in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id).
pub type SupermarketCategoryCreateRequest {
  SupermarketCategoryCreateRequest(name: String, description: Option(String))
}

// ============================================================================
// Decoders
// ============================================================================

/// Decode a SupermarketCategoryRelation from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "category": 10,
///   "supermarket": 2,
///   "order": 0
/// }
/// ```
fn category_relation_decoder() -> decode.Decoder(SupermarketCategoryRelation) {
  use id <- decode.field("id", decode.int)
  use category_id <- decode.field("category", decode.int)
  use supermarket_id <- decode.field("supermarket", decode.int)
  use order <- decode.field("order", decode.int)

  decode.success(SupermarketCategoryRelation(
    id: id,
    category_id: category_id,
    supermarket_id: supermarket_id,
    order: order,
  ))
}

/// Decode a Supermarket from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Whole Foods",
///   "description": "Natural and organic grocery store",
///   "category_to_supermarket": [...],
///   "open_data_slug": "whole-foods"
/// }
/// ```
pub fn supermarket_decoder() -> decode.Decoder(Supermarket) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use category_to_supermarket <- decode.field(
    "category_to_supermarket",
    decode.list(category_relation_decoder()),
  )
  use open_data_slug <- decode.optional_field(
    "open_data_slug",
    None,
    decode.optional(decode.string),
  )

  decode.success(Supermarket(
    id: id,
    name: name,
    description: description,
    category_to_supermarket: category_to_supermarket,
    open_data_slug: open_data_slug,
  ))
}

/// Decode a SupermarketCategory from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Produce",
///   "description": "Fresh fruits and vegetables",
///   "open_data_slug": "produce"
/// }
/// ```
pub fn supermarket_category_decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use open_data_slug <- decode.optional_field(
    "open_data_slug",
    None,
    decode.optional(decode.string),
  )

  decode.success(SupermarketCategory(
    id: id,
    name: name,
    description: description,
    open_data_slug: open_data_slug,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a SupermarketCreateRequest to JSON
///
/// Only includes writable fields for POST/PATCH requests.
pub fn encode_supermarket_create_request(
  request: SupermarketCreateRequest,
) -> Json {
  let base_fields = [#("name", json.string(request.name))]

  let description_field = case request.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  json.object(list.flatten([base_fields, description_field]))
}

/// Encode a SupermarketCategoryCreateRequest to JSON
///
/// Only includes writable fields for POST/PATCH requests.
pub fn encode_supermarket_category_create_request(
  request: SupermarketCategoryCreateRequest,
) -> Json {
  let base_fields = [#("name", json.string(request.name))]

  let description_field = case request.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  json.object(list.flatten([base_fields, description_field]))
}

// ============================================================================
// API - CRUD Operations - Supermarkets
// ============================================================================

/// List supermarkets from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated supermarket list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_supermarkets(config, limit: Some(20), page: Some(1))
/// ```
pub fn list_supermarkets(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Supermarket), TandoorError) {
  let query_params = case limit, page {
    Some(l), Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    Some(l), None -> [#("page_size", int.to_string(l))]
    None, Some(p) -> [#("page", int.to_string(p))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/supermarket/", query_params))
  parse_json_paginated(resp, supermarket_decoder())
}

/// Get a single supermarket by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Supermarket ID
///
/// # Returns
/// Result with supermarket details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_supermarket(config, id: 1)
/// ```
pub fn get_supermarket(
  config: ClientConfig,
  id id: Int,
) -> Result(Supermarket, TandoorError) {
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, supermarket_decoder())
}

/// Create a new supermarket in Tandoor
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Supermarket creation request data
///
/// # Returns
/// Result with created supermarket or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = SupermarketCreateRequest(
///   name: "Whole Foods",
///   description: Some("Natural grocery store")
/// )
/// let result = create_supermarket(config, request)
/// ```
pub fn create_supermarket(
  config: ClientConfig,
  request: SupermarketCreateRequest,
) -> Result(Supermarket, TandoorError) {
  let body =
    encode_supermarket_create_request(request)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/supermarket/", body))
  parse_json_single(resp, supermarket_decoder())
}

/// Update an existing supermarket in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Supermarket ID to update
/// * `data` - Updated supermarket data (name, description)
///
/// # Returns
/// Result with updated supermarket or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let supermarket_data = SupermarketCreateRequest(
///   name: "Whole Foods Market",
///   description: Some("Updated description")
/// )
/// let result = update_supermarket(config, id: 1, data: supermarket_data)
/// ```
pub fn update_supermarket(
  config: ClientConfig,
  id id: Int,
  data data: SupermarketCreateRequest,
) -> Result(Supermarket, TandoorError) {
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"
  let body =
    encode_supermarket_create_request(data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, supermarket_decoder())
}

/// Delete a supermarket from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - The ID of the supermarket to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_supermarket(config, id: 1)
/// ```
pub fn delete_supermarket(
  config: ClientConfig,
  id id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"
  use resp <- result.try(execute_delete(config, path))
  parse_empty_response(resp)
}

// ============================================================================
// API - CRUD Operations - Supermarket Categories
// ============================================================================

/// List supermarket categories from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated supermarket category list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_categories(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_categories(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(SupermarketCategory), TandoorError) {
  let query_params = case limit, offset {
    Some(l), Some(o) -> [
      #("page_size", int.to_string(l)),
      #("offset", int.to_string(o)),
    ]
    Some(l), None -> [#("page_size", int.to_string(l))]
    None, Some(o) -> [#("offset", int.to_string(o))]
    None, None -> []
  }

  use resp <- result.try(execute_get(
    config,
    "/api/supermarket-category/",
    query_params,
  ))
  parse_json_paginated(resp, supermarket_category_decoder())
}

/// Get a single supermarket category by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to fetch
///
/// # Returns
/// Result with category details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_category(config, category_id: 1)
/// ```
pub fn get_category(
  config: ClientConfig,
  category_id category_id: Int,
) -> Result(SupermarketCategory, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, supermarket_category_decoder())
}

/// Create a new supermarket category in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_data` - Category data to create (name, description)
///
/// # Returns
/// Result with created category or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let category_data = SupermarketCategoryCreateRequest(
///   name: "Produce",
///   description: Some("Fresh fruits and vegetables")
/// )
/// let result = create_category(config, category_data)
/// ```
pub fn create_category(
  config: ClientConfig,
  category_data: SupermarketCategoryCreateRequest,
) -> Result(SupermarketCategory, TandoorError) {
  let body =
    encode_supermarket_category_create_request(category_data)
    |> json.to_string
  use resp <- result.try(execute_post(
    config,
    "/api/supermarket-category/",
    body,
  ))
  parse_json_single(resp, supermarket_category_decoder())
}

/// Update an existing supermarket category in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to update
/// * `category_data` - Updated category data (name, description)
///
/// # Returns
/// Result with updated category or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let category_data = SupermarketCategoryCreateRequest(
///   name: "Fresh Produce",
///   description: Some("Organic fruits and vegetables")
/// )
/// let result = update_category(config, category_id: 1, category_data: category_data)
/// ```
pub fn update_category(
  config: ClientConfig,
  category_id category_id: Int,
  category_data category_data: SupermarketCategoryCreateRequest,
) -> Result(SupermarketCategory, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"
  let body =
    encode_supermarket_category_create_request(category_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, supermarket_category_decoder())
}

/// Delete a supermarket category from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `category_id` - The ID of the category to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_category(config, category_id: 1)
/// ```
pub fn delete_category(
  config: ClientConfig,
  category_id category_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/supermarket-category/" <> int.to_string(category_id) <> "/"
  use resp <- result.try(execute_delete(config, path))
  parse_empty_response(resp)
}
