/// Tests for FatSecret Exercise module
import gleam/dynamic/decode
import gleam/json
import gleeunit/should
import meal_planner/fatsecret/exercise/decoders
import meal_planner/fatsecret/exercise/types

// ============================================================================
// Opaque Type Tests
// ============================================================================

pub fn exercise_id_constructor_test() {
  let id = types.exercise_id("12345")
  let id_str = types.exercise_id_to_string(id)
  id_str
  |> should.equal("12345")
}

pub fn exercise_entry_id_constructor_test() {
  let id = types.exercise_entry_id("67890")
  let id_str = types.exercise_entry_id_to_string(id)
  id_str
  |> should.equal("67890")
}

// ============================================================================
// Exercise Decoder Tests
// ============================================================================

pub fn exercise_decoder_numeric_strings_test() {
  let json_str =
    "{
    \"exercise\": {
      \"exercise_id\": \"1\",
      \"exercise_name\": \"Running\",
      \"calories_per_hour\": \"600\"
    }
  }"

  let decoder = decode.at(["exercise"], decoders.exercise_decoder())
  let result = json.parse(json_str, decoder)

  case result {
    Ok(exercise) -> {
      types.exercise_id_to_string(exercise.exercise_id)
      |> should.equal("1")
      exercise.exercise_name
      |> should.equal("Running")
      exercise.calories_per_hour
      |> should.equal(600.0)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Date Conversion Tests
// ============================================================================

pub fn date_to_int_epoch_test() {
  let result = types.date_to_int("1970-01-01")
  result
  |> should.be_ok()
  |> should.equal(0)
}

pub fn date_to_int_2024_test() {
  let result = types.date_to_int("2024-01-01")
  result
  |> should.be_ok()
  |> should.equal(19_723)
}

pub fn int_to_date_epoch_test() {
  let result = types.int_to_date(0)
  result
  |> should.equal("1970-01-01")
}

pub fn int_to_date_2024_test() {
  let result = types.int_to_date(19_723)
  result
  |> should.equal("2024-01-01")
}

pub fn int_to_date_round_trip_test() {
  let original = "2024-12-15"
  let date_int =
    types.date_to_int(original)
    |> should.be_ok()
  let result = types.int_to_date(date_int)
  result
  |> should.equal(original)
}
