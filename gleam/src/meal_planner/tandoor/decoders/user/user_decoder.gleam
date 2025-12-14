/// User decoder for Tandoor SDK
///
/// This module provides JSON decoders for User types from Tandoor API responses.
import gleam/dynamic/decode
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/user/user.{User}

/// Decode a User from JSON
///
/// Decodes the complete User object with all fields from Tandoor API.
/// All fields are required in the API response.
///
/// ## Example JSON
/// ```json
/// {
///   "id": 1,
///   "username": "admin",
///   "first_name": "Admin",
///   "last_name": "User",
///   "display_name": "Admin User",
///   "is_staff": true,
///   "is_superuser": true,
///   "is_active": true
/// }
/// ```
pub fn decode(json: dynamic.Dynamic) -> Result(User, List(decode.DecodeError)) {
  use id <- decode.field("id", ids.user_id_decoder())
  use username <- decode.field("username", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  use display_name <- decode.field("display_name", decode.string)
  use is_staff <- decode.field("is_staff", decode.bool)
  use is_superuser <- decode.field("is_superuser", decode.bool)
  use is_active <- decode.field("is_active", decode.bool)

  decode.success(User(
    id: id,
    username: username,
    first_name: first_name,
    last_name: last_name,
    display_name: display_name,
    is_staff: is_staff,
    is_superuser: is_superuser,
    is_active: is_active,
  ))
  |> decode.run(json)
}
