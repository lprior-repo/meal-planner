/// User decoder for Tandoor SDK
///
/// Provides JSON decoders for simplified User type used in meal plan sharing.
import gleam/dynamic/decode
import meal_planner/tandoor/types/mealplan/user.{type User, User}

/// Decode a User from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "username": "chef123",
///   "first_name": "Gordon",
///   "last_name": "Ramsay",
///   "display_name": "Gordon Ramsay",
///   "is_staff": true,
///   "is_superuser": false,
///   "is_active": true
/// }
/// ```
pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
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
}
