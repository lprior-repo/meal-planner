/// UserFileView decoder for Tandoor SDK
///
/// This module provides JSON decoders for UserFileView types from Tandoor API.
import gleam/dynamic
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/user/user_decoder
import meal_planner/tandoor/types/user/user_file_view.{
  type UserFileView, UserFileView,
}

/// UserFileView decoder - returns a Decoder for use with decode.field, decode.run, etc.
pub fn user_file_view_decoder() -> decode.Decoder(UserFileView) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use file_download <- decode.field("file_download", decode.string)
  use preview <- decode.field("preview", decode.string)
  use file_size_kb <- decode.field("file_size_kb", decode.int)
  use created_by <- decode.field("created_by", user_decoder.user_decoder())
  use created_at <- decode.field("created_at", decode.string)

  decode.success(UserFileView(
    id: id,
    name: name,
    file_download: file_download,
    preview: preview,
    file_size_kb: file_size_kb,
    created_by: created_by,
    created_at: created_at,
  ))
}

/// Decode a UserFileView from JSON - convenience wrapper
///
/// Decodes a readonly view of a user-uploaded file.
/// All fields are required as they come from the API.
///
/// ## Example JSON
/// ```json
/// {
///   "id": 10,
///   "name": "avatar.jpg",
///   "file_download": "https://example.com/avatar.jpg",
///   "preview": "https://example.com/avatar_preview.jpg",
///   "file_size_kb": 150,
///   "created_by": { ...user object... },
///   "created_at": "2025-12-01T10:30:00Z"
/// }
/// ```
pub fn decode(
  json: dynamic.Dynamic,
) -> Result(UserFileView, List(decode.DecodeError)) {
  decode.run(json, user_file_view_decoder())
}
