/// Unit CRUD API
///
/// This module provides create, read, update, delete operations for units.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/encoders/unit/unit_encoder
import meal_planner/tandoor/types/unit/unit.{type Unit}

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

  // Build and execute GET request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, unit_decoder.decode_unit()) {
        Ok(unit) -> Ok(unit)
        Error(errors) -> {
          let error_msg =
            "Failed to decode unit: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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

  // Encode unit name to JSON using the encoder
  let request_body =
    unit_encoder.encode_unit_create(name)
    |> json.to_string

  // Build and execute POST request
  use req <- result.try(client.build_post_request(config, path, request_body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, unit_decoder.decode_unit()) {
        Ok(unit) -> Ok(unit)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created unit: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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

  // Encode unit data to JSON
  let request_body =
    unit_encoder.encode_unit(unit)
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, unit_decoder.decode_unit()) {
        Ok(updated_unit) -> Ok(updated_unit)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated unit: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
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

  // Build and execute DELETE request
  use req <- result.try(client.build_delete_request(config, path))

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
