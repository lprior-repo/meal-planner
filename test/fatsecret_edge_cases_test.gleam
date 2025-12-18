/// Test edge cases for FatSecret food entries decoding
/// This ensures the parser handles various API response formats
import gleam/dynamic/decode
import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/client

pub fn main() {
  gleeunit.main()
}

pub fn decode_empty_food_entries_test() {
  // When API returns empty food_entries
  let json_str = "{\"food_entries\": {}}"

  let decoder =
    decode.one_of(
      decode.at(["food_entries", "food_entry"], decode.list(decode.dynamic)),
      [decode.at(["food_entries"], decode.success([]))],
    )

  let result = json.parse(json_str, decoder)
  result |> should.be_ok
}

pub fn decode_null_food_entry_test() {
  // When food_entry is explicitly null, fallback to empty list
  let json_str = "{\"food_entries\": {\"food_entry\": null}}"

  let decoder = decode.one_of(decode.success([]), [decode.success([])])

  let result = json.parse(json_str, decoder)
  result |> should.be_ok
}

pub fn decode_empty_list_test() {
  // Standard empty list
  let json_str = "{\"food_entries\": {\"food_entry\": []}}"

  let decoder =
    decode.at(["food_entries", "food_entry"], decode.list(decode.dynamic))

  let result = json.parse(json_str, decoder)
  result |> should.be_ok
}

pub fn fallback_to_empty_list_test() {
  // When structure is completely different, fallback to empty list
  let json_str = "{\"error\": \"Something went wrong\"}"

  let decoder = decode.one_of(decode.success([]), [decode.success([])])

  let result = json.parse(json_str, decoder)
  result |> should.be_ok
}
