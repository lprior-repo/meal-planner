/// Tests for FatSecret Weight API client and decoders
///
/// Verifies correct parsing of weight API responses including:
/// - Weight entries
/// - Monthly weight summaries
/// - Weight update validation
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/weight/decoders
import meal_planner/fatsecret/weight/types

// ============================================================================
// Weight Entry Decoder Tests
// ============================================================================

pub fn decode_weight_entry_complete_test() {
  let json_str = weight_entry_fixture()

  let result =
    json.parse(json_str, decoders.weight_entry_decoder())
    |> should.be_ok

  result.date_int |> should.equal(19_723)
  result.weight_kg |> should.equal(75.5)
  result.weight_comment |> should.equal(Some("Morning weight"))
}

pub fn decode_weight_entry_minimal_test() {
  let json_str = weight_entry_minimal_fixture()

  let result =
    json.parse(json_str, decoders.weight_entry_decoder())
    |> should.be_ok

  result.date_int |> should.equal(19_723)
  result.weight_kg |> should.equal(75.5)
  result.weight_comment |> should.equal(None)
}

// ============================================================================
// Weight Month Summary Decoder Tests
// ============================================================================

pub fn decode_weight_month_summary_multiple_test() {
  let json_str = weight_month_summary_fixture()

  let result =
    json.parse(json_str, decoders.weight_month_summary_decoder())
    |> should.be_ok

  result.from_date_int |> should.equal(19_721)
  result.to_date_int |> should.equal(19_751)
  result.days |> list.length |> should.equal(3)

  // Verify first entry
  let assert [first, ..] = result.days
  first.date_int |> should.equal(19_721)
  first.weight_kg |> should.equal(76.0)
}

pub fn decode_weight_month_summary_single_test() {
  let json_str = weight_month_summary_single_fixture()

  let result =
    json.parse(json_str, decoders.weight_month_summary_decoder())
    |> should.be_ok

  // Single entry should be wrapped in list
  result.days |> list.length |> should.equal(1)
}

// ============================================================================
// WeightUpdate Type Tests
// ============================================================================

pub fn weight_update_complete_test() {
  let update =
    types.WeightUpdate(
      current_weight_kg: 75.5,
      date_int: 19_723,
      goal_weight_kg: Some(70.0),
      height_cm: Some(175.0),
      comment: Some("Morning weight"),
    )

  update.current_weight_kg |> should.equal(75.5)
  update.date_int |> should.equal(19_723)
  update.goal_weight_kg |> should.equal(Some(70.0))
}

pub fn weight_update_minimal_test() {
  let update =
    types.WeightUpdate(
      current_weight_kg: 75.5,
      date_int: 19_723,
      goal_weight_kg: None,
      height_cm: None,
      comment: None,
    )

  update.current_weight_kg |> should.equal(75.5)
  update.goal_weight_kg |> should.equal(None)
}

// ============================================================================
// WeightDaySummary Decoder Tests
// ============================================================================

pub fn decode_weight_day_summary_test() {
  let json_str = weight_day_summary_fixture()

  let result =
    json.parse(json_str, decoders.weight_day_summary_decoder())
    |> should.be_ok

  result.date_int |> should.equal(19_723)
  result.weight_kg |> should.equal(75.5)
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn weight_entry_fixture() -> String {
  "{
    \"date_int\": \"19723\",
    \"weight_kg\": \"75.5\",
    \"weight_comment\": \"Morning weight\"
  }"
}

fn weight_entry_minimal_fixture() -> String {
  "{
    \"date_int\": \"19723\",
    \"weight_kg\": \"75.5\"
  }"
}

fn weight_day_summary_fixture() -> String {
  "{
    \"date_int\": \"19723\",
    \"weight_kg\": \"75.5\"
  }"
}

fn weight_month_summary_fixture() -> String {
  "{
    \"month\": {
      \"from_date_int\": \"19721\",
      \"to_date_int\": \"19751\",
      \"day\": [
        {\"date_int\": \"19721\", \"weight_kg\": \"76.0\"},
        {\"date_int\": \"19722\", \"weight_kg\": \"75.8\"},
        {\"date_int\": \"19723\", \"weight_kg\": \"75.5\"}
      ]
    }
  }"
}

fn weight_month_summary_single_fixture() -> String {
  "{
    \"month\": {
      \"from_date_int\": \"19721\",
      \"to_date_int\": \"19751\",
      \"day\": {\"date_int\": \"19723\", \"weight_kg\": \"75.5\"}
    }
  }"
}
