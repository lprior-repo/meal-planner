/// Keyword API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing keywords/tags via Tandoor API.
/// Keywords are used to categorize recipes and form a hierarchical tree structure.
///
/// Refactored to use CRUD helpers - achieved 60%+ line reduction.
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
// CRUD Operations
// ============================================================================

/// Get all keywords from Tandoor API
pub fn list_keywords(
  config: ClientConfig,
) -> Result(List(Keyword), TandoorError) {
  list_keywords_by_parent(config, None)
}

/// Get keywords filtered by parent ID (None for root keywords)
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

/// Get a single keyword by ID
pub fn get_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, keyword_decoder.keyword_decoder())
}

/// Create a new keyword in Tandoor
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

/// Update an existing keyword (supports partial updates)
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

/// Delete a keyword from Tandoor
pub fn delete_keyword(
  config: ClientConfig,
  keyword_id keyword_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
