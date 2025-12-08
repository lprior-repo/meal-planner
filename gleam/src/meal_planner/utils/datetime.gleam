////  Date/time utilities using Erlang FFI

import gleam/int
import gleam/string

/// Get today's date in YYYY-MM-DD format using Erlang's calendar module
@external(erlang, "meal_planner_ffi", "get_current_date")
pub fn get_today_date() -> String

/// Pad number with leading zero if needed (for months/days)
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
