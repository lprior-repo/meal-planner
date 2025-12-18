//// Decoder Combinators - Consolidate JSON decoding patterns
////
//// This module provides reusable combinators for JSON decoding that reduce
//// boilerplate across the codebase. It consolidates:
//// - Error message formatting
//// - Decoder wrapping patterns
//// - Common field decoding patterns

import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/string

/// Format a list of decode errors into a readable error message
///
/// Combines all decode errors into a single formatted message with field paths
/// and expected types.
///
/// # Example
/// ```gleam
/// let errors = [
///   decode.DecodeError("String", ..., ["name"]),
///   decode.DecodeError("Int", ..., ["age"])
/// ]
/// let msg = format_decode_errors(errors)
/// // msg = "String at name, Int at age"
/// ```
pub fn format_decode_errors(errors: List(decode.DecodeError)) -> String {
  errors
  |> list.map(fn(e) {
    case e {
      decode.DecodeError(expected, _found, path) ->
        expected <> " at " <> string.join(path, ".")
    }
  })
  |> string.join(", ")
}

/// Run a decoder and format errors with a custom context message
///
/// This is the primary consolidation function. It wraps `decode.run()` and
/// converts decode errors to formatted String messages.
///
/// # Example
/// ```gleam
/// pub fn decoder(json_value: dynamic.Dynamic) -> Result(Recipe, String) {
///   run_decoder(json_value, recipe_decoder_internal(), "Failed to decode recipe")
/// }
/// ```
pub fn run_decoder(
  json_value: dynamic.Dynamic,
  decoder_fn: decode.Decoder(a),
  context: String,
) -> Result(a, String) {
  decode.run(json_value, decoder_fn)
  |> result.map_error(fn(errors) {
    context <> ": " <> format_decode_errors(errors)
  })
}
