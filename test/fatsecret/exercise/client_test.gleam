/// Tests for FatSecret Exercise API client and decoders
///
/// Verifies correct parsing of exercise API responses including:
/// - Exercise entries for dates
/// - Monthly summaries
/// - Exercise types
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/fatsecret/exercise/decoders
import meal_planner/fatsecret/exercise/types

// ============================================================================
// Exercise Entry Decoder Tests
// ============================================================================

pub fn decode_exercise_entries_multiple_test() {
  let json_str = exercise_entries_fixture()

  let result =
    json.parse(json_str, decoders.decode_exercise_entries_response())
    |> should.be_ok

  result |> list.length |> should.equal(2)

  let assert [first, ..] = result
  types.exercise_entry_id_to_string(first.exercise_entry_id)
  |> should.equal("123456")
  first.exercise_name |> should.equal("Running")
  first.duration_min |> should.equal(30)
  first.calories |> should.equal(300.0)
}

pub fn decode_exercise_entries_single_test() {
  let json_str = exercise_entries_single_fixture()

  let result =
    json.parse(json_str, decoders.decode_exercise_entries_response())
    |> should.be_ok

  // Single entry should be wrapped in list
  result |> list.length |> should.equal(1)
}

pub fn decode_exercise_entries_empty_test() {
  let json_str = exercise_entries_empty_fixture()

  let result =
    json.parse(json_str, decoders.decode_exercise_entries_response())
    |> should.be_ok

  result |> list.length |> should.equal(0)
}

// ============================================================================
// Exercise Decoder Tests (2-legged)
// ============================================================================

pub fn decode_exercise_test() {
  let json_str = exercise_fixture()

  let result =
    json.parse(json_str, decoders.exercise_decoder())
    |> should.be_ok

  types.exercise_id_to_string(result.exercise_id) |> should.equal("1")
  result.exercise_name |> should.equal("Running")
  result.calories_per_hour |> should.equal(600.0)
}

// ============================================================================
// Month Summary Decoder Tests
// ============================================================================

pub fn decode_exercise_month_summary_test() {
  let json_str = exercise_month_summary_fixture()

  let result =
    json.parse(json_str, decoders.decode_exercise_month_summary())
    |> should.be_ok

  result.month |> should.equal(12)
  result.year |> should.equal(2024)
  result.days |> list.length |> should.equal(2)

  let assert [first, ..] = result.days
  first.date_int |> should.equal(19_723)
  first.exercise_calories |> should.equal(300.0)
}

// ============================================================================
// Types Tests
// ============================================================================

pub fn exercise_id_round_trip_test() {
  let id = types.exercise_id("12345")
  types.exercise_id_to_string(id) |> should.equal("12345")
}

pub fn exercise_entry_id_round_trip_test() {
  let id = types.exercise_entry_id("67890")
  types.exercise_entry_id_to_string(id) |> should.equal("67890")
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn exercise_fixture() -> String {
  "{
    \"exercise_id\": \"1\",
    \"exercise_name\": \"Running\",
    \"calories_per_hour\": \"600\"
  }"
}

fn exercise_entries_fixture() -> String {
  "{
    \"exercise_entries\": {
      \"exercise_entry\": [
        {
          \"exercise_entry_id\": \"123456\",
          \"exercise_id\": \"1\",
          \"exercise_name\": \"Running\",
          \"duration_min\": \"30\",
          \"calories\": \"300\",
          \"date_int\": \"19723\"
        },
        {
          \"exercise_entry_id\": \"123457\",
          \"exercise_id\": \"2\",
          \"exercise_name\": \"Weight Lifting\",
          \"duration_min\": \"45\",
          \"calories\": \"200\",
          \"date_int\": \"19723\"
        }
      ]
    }
  }"
}

fn exercise_entries_single_fixture() -> String {
  "{
    \"exercise_entries\": {
      \"exercise_entry\": {
        \"exercise_entry_id\": \"123456\",
        \"exercise_id\": \"1\",
        \"exercise_name\": \"Running\",
        \"duration_min\": \"30\",
        \"calories\": \"300\",
        \"date_int\": \"19723\"
      }
    }
  }"
}

fn exercise_entries_empty_fixture() -> String {
  "{
    \"exercise_entries\": {}
  }"
}

fn exercise_month_summary_fixture() -> String {
  "{
    \"month\": {
      \"month\": \"12\",
      \"year\": \"2024\",
      \"day\": [
        {\"date_int\": \"19723\", \"exercise_calories\": \"300\"},
        {\"date_int\": \"19724\", \"exercise_calories\": \"450\"}
      ]
    }
  }"
}
