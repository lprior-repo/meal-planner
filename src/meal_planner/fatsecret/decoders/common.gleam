/// Common decoder helpers for FatSecret API responses
///
/// FatSecret API returns some numeric values as strings instead of numbers.
/// This module provides reusable decoders that handle this quirk.
///
/// Usage:
/// ```gleam
/// import meal_planner/fatsecret/decoders/common.{float_string_decoder, int_string_decoder}
///
/// // Parse a float that comes as "95.5"
/// use value <- decode.field("calories", float_string_decoder())
/// ```
import gleam/dynamic/decode
import gleam/float
import gleam/int

/// Decode a float from a string value.
///
/// FatSecret API returns many numeric fields as strings (e.g., "95.5" instead of 95.5).
/// This decoder handles both string-encoded numbers and actual float numbers.
///
/// ## Examples
/// - "95.5" -> 95.5
/// - "100" -> 100.0
/// - 50.5 (actual number) -> 50.5
pub fn float_string_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, or: [
    {
      use s <- decode.then(decode.string)
      case float.parse(s) {
        Ok(f) -> decode.success(f)
        Error(_) -> {
          // Fallback: Try parsing as int then converting
          case int.parse(s) {
            Ok(i) -> decode.success(int.to_float(i))
            Error(_) -> decode.failure(0.0, "Float")
          }
        }
      }
    },
  ])
}

/// Decode an int from a string value.
///
/// FatSecret API returns many numeric fields as strings (e.g., "95" instead of 95).
/// This decoder handles both string-encoded numbers and actual int numbers.
///
/// ## Examples
/// - "95" -> 95
/// - "100" -> 100
/// - 50 (actual number) -> 50
pub fn int_string_decoder() -> decode.Decoder(Int) {
  decode.one_of(decode.int, or: [
    {
      use s <- decode.then(decode.string)
      case int.parse(s) {
        Ok(i) -> decode.success(i)
        Error(_) -> decode.failure(0, "Int")
      }
    },
  ])
}
