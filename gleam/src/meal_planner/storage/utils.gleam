/// Common utility functions for storage modules
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/string
import pog

/// Format a pog.QueryError into a human-readable string
pub fn format_pog_error(err: pog.QueryError) -> String {
  case err {
    pog.ConnectionUnavailable -> "Database connection unavailable"

    pog.ConstraintViolated(msg, constraint, _detail) ->
      "Constraint violated: " <> constraint <> " - " <> msg

    pog.PostgresqlError(_code, _name, msg) -> "PostgreSQL error: " <> msg

    pog.UnexpectedArgumentCount(expected, got) ->
      "Expected "
      <> int.to_string(expected)
      <> " arguments, got "
      <> int.to_string(got)

    pog.UnexpectedArgumentType(expected, got) ->
      "Expected type " <> expected <> ", got " <> got

    pog.UnexpectedResultType(errs) -> {
      let msgs =
        list.map(errs, fn(e) {
          case e {
            decode.DecodeError(expected, found, path) ->
              "Expected "
              <> expected
              <> " at "
              <> string.join(path, ".")
              <> ", found "
              <> found
          }
        })

      "Decode error: " <> string.join(msgs, "; ")
    }

    pog.QueryTimeout -> "Database query timeout"
  }
}
