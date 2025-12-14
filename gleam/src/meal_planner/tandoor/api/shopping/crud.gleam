/// Shopping List Entry CRUD API
///
/// This module provides functions to create, read, update, and delete
/// shopping list entries in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/encoders/shopping/shopping_list_encoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry, type ShoppingListEntryCreate,
  type ShoppingListEntryUpdate,
}

// ============================================================================
// Get Shopping List Entry
// ============================================================================

/// Get a single shopping list entry by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `entry_id` - The ID of the shopping list entry to fetch
///
/// # Returns
/// Result with shopping list entry details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_shopping_entry(config, entry_id: 42)
/// ```
pub fn get_shopping_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder.decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode shopping list entry: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

// ============================================================================
// Create Shopping List Entry
// ============================================================================

/// Create a new shopping list entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `entry_data` - Shopping list entry data to create
///
/// # Returns
/// Result with created shopping list entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let entry_data = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// let result = create_shopping_entry(config, entry_data)
/// ```
pub fn create_shopping_entry(
  config: ClientConfig,
  entry_data: ShoppingListEntryCreate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/"

  // Encode entry data to JSON
  let body =
    shopping_list_encoder.encode_entry_create(entry_data)
    |> json.to_string

  // Build and execute request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder.decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created shopping list entry: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

// ============================================================================
// Update Shopping List Entry
// ============================================================================

/// Update an existing shopping list entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `entry_id` - The ID of the shopping list entry to update
/// * `entry_data` - Updated shopping list entry data
///
/// # Returns
/// Result with updated shopping list entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let entry_data = ShoppingListEntryUpdate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   delay_until: None,
/// )
/// let result = update_shopping_entry(config, entry_id: 42, entry_data: entry_data)
/// ```
pub fn update_shopping_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
  entry_data entry_data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"

  // Encode entry data to JSON
  let request_body =
    shopping_list_encoder.encode_entry_update(entry_data)
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
      case decode.run(json_data, shopping_list_entry_decoder.decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated shopping list entry: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

// ============================================================================
// Delete Shopping List Entry
// ============================================================================

/// Delete a shopping list entry from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `entry_id` - The ID of the shopping list entry to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_shopping_entry(config, entry_id: 42)
/// ```
pub fn delete_shopping_entry(
  config: ClientConfig,
  entry_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"

  // Build and execute DELETE request
  use req <- result.try(client.build_delete_request(config, path))

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
