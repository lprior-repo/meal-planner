/// Automation API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing automations via Tandoor API.
/// Automations allow automatic processing of recipes during import and editing.
///
/// Operations:
/// - list_automations: Get all automations
/// - get_automation: Get a single automation by ID
/// - create_automation: Create a new automation
/// - update_automation: Update an existing automation
/// - delete_automation: Delete an automation
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/automation/automation_decoder
import meal_planner/tandoor/encoders/automation/automation_encoder.{
  type AutomationCreateRequest, type AutomationUpdateRequest,
}
import meal_planner/tandoor/types/automation/automation.{type Automation}

// ============================================================================
// List Automations
// ============================================================================

/// Get all automations from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration
///
/// # Returns
/// Result with list of automations or error
pub fn list_automations(
  config: ClientConfig,
) -> Result(List(Automation), TandoorError) {
  use req <- result.try(client.build_get_request(config, "/api/automation/", []))
  logger.debug("Tandoor GET /api/automation/")

  use resp <- result.try(execute_and_parse(config, req))

  // Parse as list of automations
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(
          json_data,
          decode.list(automation_decoder.automation_decoder()),
        )
      {
        Ok(automations) -> Ok(automations)
        Error(errors) -> {
          let error_msg =
            "Failed to decode automation list: "
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
// Get Automation
// ============================================================================

/// Get a single automation by ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `automation_id` - Automation ID
///
/// # Returns
/// Result with automation or error
pub fn get_automation(
  config: ClientConfig,
  automation_id: Int,
) -> Result(Automation, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"

  use req <- result.try(client.build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, automation_decoder.automation_decoder()) {
        Ok(automation) -> Ok(automation)
        Error(errors) -> {
          let error_msg =
            "Failed to decode automation: "
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
// Create Automation
// ============================================================================

/// Create a new automation in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `create_data` - Automation creation data
///
/// # Returns
/// Result with created automation or error
pub fn create_automation(
  config: ClientConfig,
  create_data: AutomationCreateRequest,
) -> Result(Automation, TandoorError) {
  let body =
    automation_encoder.encode_automation_create_request(create_data)
    |> json.to_string

  use req <- result.try(client.build_post_request(
    config,
    "/api/automation/",
    body,
  ))
  logger.debug("Tandoor POST /api/automation/")

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, automation_decoder.automation_decoder()) {
        Ok(automation) -> Ok(automation)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created automation: "
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
// Update Automation
// ============================================================================

/// Update an existing automation in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `automation_id` - Automation ID to update
/// * `update_data` - Automation update data (partial update supported)
///
/// # Returns
/// Result with updated automation or error
pub fn update_automation(
  config: ClientConfig,
  automation_id: Int,
  update_data: AutomationUpdateRequest,
) -> Result(Automation, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"
  let body =
    automation_encoder.encode_automation_update_request(update_data)
    |> json.to_string

  use req <- result.try(client.build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(execute_and_parse(config, req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, automation_decoder.automation_decoder()) {
        Ok(automation) -> Ok(automation)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated automation: "
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
// Delete Automation
// ============================================================================

/// Delete an automation from Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `automation_id` - Automation ID to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_automation(
  config: ClientConfig,
  automation_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"

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
