//// Helper functions for web server

import gleam/int
import shared/types
import wisp

@external(erlang, "calendar", "local_time")
fn erlang_local_time() -> #(#(Int, Int, Int), #(Int, Int, Int))

pub fn get_today_date() -> String {
  let #(#(year, month, day), _) = erlang_local_time()
  int.to_string(year) <> "-" <> pad_int(month) <> "-" <> pad_int(day)
}

fn pad_int(i: Int) -> String {
  case i < 10 {
    True -> "0" <> int.to_string(i)
    False -> int.to_string(i)
  }
}

pub fn get_timestamp() -> String {
  let #(#(year, month, day), #(hour, min, sec)) = erlang_local_time()
  int.to_string(year)
  <> "-"
  <> pad_int(month)
  <> "-"
  <> pad_int(day)
  <> "T"
  <> pad_int(hour)
  <> ":"
  <> pad_int(min)
  <> ":"
  <> pad_int(sec)
  <> "Z"
}

pub fn generate_id() -> String {
  "log-" <> wisp.random_string(8)
}

pub fn parse_meal_type(s: String) -> types.MealType {
  case s {
    "breakfast" -> types.Breakfast
    "lunch" -> types.Lunch
    "dinner" -> types.Dinner
    _ -> types.Snack
  }
}

pub fn suggest_meal_type() -> types.MealType {
  let #(_, #(hour, _, _)) = erlang_local_time()
  case hour {
    5 | 6 | 7 | 8 | 9 | 10 -> types.Breakfast
    11 | 12 | 13 | 14 -> types.Lunch
    15 | 16 | 17 | 18 | 19 | 20 -> types.Dinner
    _ -> types.Snack
  }
}

pub fn suggest_meal_type_string() -> String {
  case suggest_meal_type() {
    types.Breakfast -> "breakfast"
    types.Lunch -> "lunch"
    types.Dinner -> "dinner"
    types.Snack -> "snack"
  }
}
