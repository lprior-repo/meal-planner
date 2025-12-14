/// Keyword API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing keywords/tags via Tandoor API.
/// Keywords are used to categorize recipes and form a hierarchical tree structure.
///
/// Operations:
/// - list_keywords: Get all keywords or filter by parent
/// - get_keyword: Get a single keyword by ID
/// - create_keyword: Create a new keyword
/// - update_keyword: Update an existing keyword
/// - delete_keyword: Delete a keyword
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
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
pub fn list_keywords_by_parent(
  config: ClientConfig,
  parent_id: Option(Int),
) -> Result(List(Keyword), TandoorError) {
  let query_params = case parent_id {
    Some(id) -> [#("parent", int.to_string(id))]
    None -> [#("parent", "null")]
  }

  use req <- result.try(client.build_get_request(
    config,
    "/api/keyword/",
    query_params,
  ))
  logger.debug("Tandoor GET /api/keyword/")

  use resp <- result.try(execute_and_parse(config, req))

  // Parse as list of keywords
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(json_data, decode.list(keyword_decoder.keyword_decoder()))
      {
        Ok(keywords) -> Ok(keywords)
        Error(errors) -> {
          let error_msg =
            "Failed to decode keyword list: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
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
pub fn get_keyword(
  config: ClientConfig,
  keyword_id: Int,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"

  use req <- result.try(client.build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, keyword_decoder.keyword_decoder()) {
        Ok(keyword) -> Ok(keyword)
        Error(errors) -> {
          let error_msg =
            "Failed to decode keyword: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
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
pub fn create_keyword(
  config: ClientConfig,
  create_data: KeywordCreateRequest,
) -> Result(Keyword, TandoorError) {
  let body =
    keyword_encoder.encode_keyword_create_request(create_data)
    |> json.to_string

  use req <- result.try(client.build_post_request(config, "/api/keyword/", body))
  logger.debug("Tandoor POST /api/keyword/")

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, keyword_decoder.keyword_decoder()) {
        Ok(keyword) -> Ok(keyword)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created keyword: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
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
pub fn update_keyword(
  config: ClientConfig,
  keyword_id: Int,
  update_data: KeywordUpdateRequest,
) -> Result(Keyword, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"
  let body =
    keyword_encoder.encode_keyword_update_request(update_data)
    |> json.to_string

  use req <- result.try(client.build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, keyword_decoder.keyword_decoder()) {
        Ok(keyword) -> Ok(keyword)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated keyword: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
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
pub fn delete_keyword(
  config: ClientConfig,
  keyword_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/keyword/" <> int.to_string(keyword_id) <> "/"

  use req <- result.try(client.build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(config, req))
  Ok(Nil)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Execute request and parse response
fn execute_and_parse(
  _config: ClientConfig,
  req: request.Request(String),
) -> Result(client.ApiResponse, TandoorError) {
  use resp <- result.try(execute_request(req))
  client.parse_response(resp)
}

/// Execute HTTP request
fn execute_request(
  req: request.Request(String),
) -> Result(response.Response(String), TandoorError) {
  case httpc.send(req) {
    Ok(resp) -> Ok(resp)
    Error(_) -> Error(NetworkError("Failed to connect to Tandoor"))
  }
}
