/// Keyword API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing keywords/tags via Tandoor API.
/// Keywords are used to categorize recipes and form a hierarchical tree structure.
///
/// Refactored to use CRUD helpers - 60%+ line reduction.
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/keyword/keyword_decoder
import meal_planner/tandoor/encoders/keyword/keyword_encoder.{
  type KeywordCreateRequest, type KeywordUpdateRequest,
}
import meal_planner/tandoor/types/keyword/keyword.{type Keyword}

// ============================================================================
// List Keywords
// ============================================================================

/// Get all keywords from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration
///
/// # Returns
/// Result with list of keywords or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_keywords(config)
/// ```
pub fn list_keywords(
  config: ClientConfig,
) -> Result(List(Keyword), TandoorError) {
  list_keywords_by_parent(config, None)
}

/// Get keywords filtered by parent ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `parent_id` - Optional parent ID (None for root keywords)
///
/// # Returns
/// Result with list of keywords or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// // Get root keywords
/// let result = list_keywords_by_parent(config, None)
/// // Get children of keyword 5
/// let result = list_keywords_by_parent(config, Some(5))
/// ```
pub fn list_keywords_by_parent(
  config: ClientConfig,
  parent_id: Option(Int),
) -> Result(List(Keyword), TandoorError) {
  let query_params = case parent_id {
    Some(id) -> [#("parent", int.to_string(id))]
    None -> [#("parent", "null")]
  }

  use resp <- result.try(execute_get(config, "/api/keyword/", query_params))
  parse_json_list(resp, keyword_decoder.keyword_decoder())
}

// ============================================================================
// Get Keyword
// ============================================================================

/// Get a single keyword by ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `keyword_id` - Keyword ID
///
/// # Returns
/// Result with keyword or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_keyword(config, keyword_id: 42)
/// ```
pub fn get_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, keyword_decoder.keyword_decoder())
}

// ============================================================================
// Create Keyword
// ============================================================================

/// Create a new keyword in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `create_data` - Keyword creation data
///
/// # Returns
/// Result with created keyword or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let data = KeywordCreateRequest(
///   name: "vegetarian",
///   description: "Vegetarian recipes",
///   icon: Some("🥗"),
///   parent: None,
/// )
/// let result = create_keyword(config, data)
/// ```
pub fn create_keyword(
  config: ClientConfig,
  create_data: KeywordCreateRequest,
) -> Result(Keyword, TandoorError) {
  let body =
    keyword_encoder.encode_keyword_create_request(create_data)
    |> json.to_string

  use resp <- result.try(execute_post(config, "/api/keyword/", body))
  parse_json_single(resp, keyword_decoder.keyword_decoder())
}

// ============================================================================
// Update Keyword
// ============================================================================

/// Update an existing keyword in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `keyword_id` - Keyword ID to update
/// * `update_data` - Keyword update data (partial update supported)
///
/// # Returns
/// Result with updated keyword or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let data = KeywordUpdateRequest(
///   name: Some("vegan"),
///   description: Some("Vegan recipes only"),
///   icon: None,
///   parent: None,
/// )
/// let result = update_keyword(config, keyword_id: 42, data)
/// ```
pub fn update_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
  data update_data: KeywordUpdateRequest,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  let body =
    keyword_encoder.encode_keyword_update_request(update_data)
    |> json.to_string

  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, keyword_decoder.keyword_decoder())
}

// ============================================================================
// Delete Keyword
// ============================================================================

/// Delete a keyword from Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `keyword_id` - Keyword ID to delete
///
/// # Returns
/// Result with unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_keyword(config, keyword_id: 42)
/// ```
pub fn delete_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
