/// User Preferences API for Tandoor SDK
///
/// This module provides functions to get and update user preferences.
///
/// API Endpoints:
/// - GET /api/user-preference/ - List all preferences (returns current user's)
/// - GET /api/user-preference/{user_id}/ - Get specific user's preferences
/// - PATCH /api/user-preference/{user_id}/ - Update preferences
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/core/error.{type TandoorError, NetworkError, ParseError}
import meal_planner/tandoor/core/http as tandoor_http
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/user/user_preference_decoder
import meal_planner/tandoor/encoders/user/user_preference_encoder.{
  type UserPreferenceUpdateRequest,
}
import meal_planner/tandoor/types/user/user_preference.{type UserPreference}

/// Configuration for Tandoor API client
pub type ClientConfig {
  ClientConfig(base_url: String, api_token: String)
}

/// Get current user's preferences
///
/// Calls GET /api/user-preference/ which returns the authenticated user's preferences.
///
/// # Arguments
/// * `config` - Client configuration with authentication
///
/// # Returns
/// Result with user preferences or error
pub fn get_current_user_preferences(
  config: ClientConfig,
) -> Result(UserPreference, TandoorError) {
  let url = config.base_url <> "/api/user-preference/"

  let req =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_host(config.base_url)
    |> request.set_path("/api/user-preference/")
    |> request.set_header("Authorization", "Token " <> config.api_token)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      NetworkError("Failed to fetch user preferences: " <> string_from_error(err))
    }),
  )

  case resp.status {
    200 -> {
      use json_data <- result.try(
        json.decode(resp.body, dynamic.dynamic)
        |> result.map_error(fn(_) {
          ParseError("Failed to parse JSON response")
        }),
      )

      // API returns array with single element for current user
      use prefs_list <- result.try(
        decode.run(json_data, decode.list(user_preference_decoder.decode))
        |> result.map_error(fn(errs) {
          ParseError(
            "Failed to decode preferences: " <> decode.errors_to_string(errs),
          )
        }),
      )

      case prefs_list {
        [first, ..] -> Ok(first)
        [] -> Error(ParseError("No preferences returned for current user"))
      }
    }
    _ ->
      Error(NetworkError(
        "HTTP " <> int.to_string(resp.status) <> ": " <> resp.body,
      ))
  }
}

/// Get user preferences by user ID
///
/// Calls GET /api/user-preference/{user_id}/
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `user_id` - The ID of the user whose preferences to fetch
///
/// # Returns
/// Result with user preferences or error
pub fn get_user_preferences(
  config: ClientConfig,
  user_id user_id: ids.UserId,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = ids.user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  let req =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_host(config.base_url)
    |> request.set_path(path)
    |> request.set_header("Authorization", "Token " <> config.api_token)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      NetworkError(
        "Failed to fetch preferences for user "
        <> int.to_string(user_id_int)
        <> ": "
        <> string_from_error(err),
      )
    }),
  )

  case resp.status {
    200 -> {
      use json_data <- result.try(
        json.decode(resp.body, dynamic.dynamic)
        |> result.map_error(fn(_) {
          ParseError("Failed to parse JSON response")
        }),
      )

      user_preference_decoder.decode(json_data)
      |> result.map_error(fn(errs) {
        ParseError(
          "Failed to decode preferences: " <> decode.errors_to_string(errs),
        )
      })
    }
    404 -> Error(ParseError("User not found"))
    _ ->
      Error(NetworkError(
        "HTTP " <> int.to_string(resp.status) <> ": " <> resp.body,
      ))
  }
}

/// Update user preferences
///
/// Calls PATCH /api/user-preference/{user_id}/ with partial update data.
/// Only provided fields (Some values) will be updated.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `user_id` - The ID of the user whose preferences to update
/// * `update` - Partial update with optional fields
///
/// # Returns
/// Result with updated preferences or error
pub fn update_user_preferences(
  config: ClientConfig,
  user_id user_id: ids.UserId,
  update update: UserPreferenceUpdateRequest,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = ids.user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"
  let body = json.to_string(user_preference_encoder.encode_update(update))

  let req =
    request.new()
    |> request.set_method(http.Patch)
    |> request.set_host(config.base_url)
    |> request.set_path(path)
    |> request.set_header("Authorization", "Token " <> config.api_token)
    |> request.set_header("Content-Type", "application/json")
    |> request.set_body(body)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) {
      NetworkError(
        "Failed to update preferences for user "
        <> int.to_string(user_id_int)
        <> ": "
        <> string_from_error(err),
      )
    }),
  )

  case resp.status {
    200 -> {
      use json_data <- result.try(
        json.decode(resp.body, dynamic.dynamic)
        |> result.map_error(fn(_) {
          ParseError("Failed to parse JSON response")
        }),
      )

      user_preference_decoder.decode(json_data)
      |> result.map_error(fn(errs) {
        ParseError(
          "Failed to decode updated preferences: "
          <> decode.errors_to_string(errs),
        )
      })
    }
    400 -> Error(ParseError("Invalid preferences data: " <> resp.body))
    404 -> Error(ParseError("User not found"))
    _ ->
      Error(NetworkError(
        "HTTP " <> int.to_string(resp.status) <> ": " <> resp.body,
      ))
  }
}

// Helper to convert httpc errors to strings
fn string_from_error(err: httpc.HttpError) -> String {
  case err {
    httpc.InvalidUtf8Response -> "Invalid UTF-8 in response"
    httpc.NetworkError(msg) -> msg
  }
}
