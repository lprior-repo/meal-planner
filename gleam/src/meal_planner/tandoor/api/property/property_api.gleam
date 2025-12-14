/// Property API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing custom properties via Tandoor API.
/// Properties allow extending recipes and foods with custom metadata fields.
///
/// Operations:
/// - list_properties: Get all properties
/// - get_property: Get a single property by ID
/// - create_property: Create a new property
/// - update_property: Update an existing property
/// - delete_property: Delete a property
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/property/property_decoder
import meal_planner/tandoor/types/property/property.{type Property}

// ============================================================================
// List Properties
// ============================================================================

/// Get all properties from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration
///
/// # Returns
/// Result with list of properties or error
pub fn list_properties(
  config: ClientConfig,
) -> Result(List(Property), TandoorError) {
  use req <- result.try(client.build_get_request(config, "/api/property/", []))
  logger.debug("Tandoor GET /api/property/")

  use resp <- result.try(execute_and_parse(config, req))

  // Parse as list of properties
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(json_data, decode.list(property_decoder.property_decoder()))
      {
        Ok(properties) -> Ok(properties)
        Error(errors) -> {
          let error_msg =
            "Failed to decode property list: "
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
// Get Property
// ============================================================================

/// Get a single property by ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID
///
/// # Returns
/// Result with property or error
pub fn get_property(
  config: ClientConfig,
  property_id: Int,
) -> Result(Property, TandoorError) {
  let path = "/api/property/" <> int.to_string(property_id) <> "/"

  use req <- result.try(client.build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, property_decoder.property_decoder()) {
        Ok(property) -> Ok(property)
        Error(errors) -> {
          let error_msg =
            "Failed to decode property: "
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
// Delete Property
// ============================================================================

/// Delete a property from Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_property(
  config: ClientConfig,
  property_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/property/" <> int.to_string(property_id) <> "/"

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
