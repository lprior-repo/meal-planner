/// FatSecret Weight API Tests
///
/// Tests for weight management functionality, including decoder tests
/// and specific tests for API errors 205 (date too far) and 206 (date earlier than existing).
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/weight/decoders
import meal_planner/fatsecret/weight/types.{
  WeightDaySummary, WeightEntry, WeightMonthSummary, WeightUpdate,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Error Code Tests - Specific to Weight API
// ============================================================================

/// Test that error code 205 maps to WeightDateTooFar
pub fn error_205_weight_date_too_far_test() {
  errors.code_from_int(205)
  |> should.equal(errors.WeightDateTooFar)
}

/// Test that error code 206 maps to WeightDateEarlier
pub fn error_206_weight_date_earlier_test() {
  errors.code_from_int(206)
  |> should.equal(errors.WeightDateEarlier)
}

/// Test error 205 to int conversion
pub fn error_205_to_int_test() {
  errors.code_to_int(errors.WeightDateTooFar)
  |> should.equal(205)
}

/// Test error 206 to int conversion
pub fn error_206_to_int_test() {
  errors.code_to_int(errors.WeightDateEarlier)
  |> should.equal(206)
}

/// Test error 205 string representation
pub fn error_205_to_string_test() {
  errors.code_to_string(errors.WeightDateTooFar)
  |> should.equal("Weight Date Too Far in Future")
}

/// Test error 206 string representation
pub fn error_206_to_string_test() {
  errors.code_to_string(errors.WeightDateEarlier)
  |> should.equal("Weight Date Earlier Than Expected")
}

// ============================================================================
// Error Response Parsing Tests
// ============================================================================

/// Test parsing API error 205 from JSON response
pub fn parse_error_205_json_test() {
  let json =
    "{\"error\": {\"code\": 205, \"message\": \"Date is more than 2 days from today\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      code |> should.equal(errors.WeightDateTooFar)
      message |> should.equal("Date is more than 2 days from today")
    }
    _ -> should.fail()
  }
}

/// Test parsing API error 206 from JSON response
pub fn parse_error_206_json_test() {
  let json =
    "{\"error\": {\"code\": 206, \"message\": \"Cannot update earlier date\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      code |> should.equal(errors.WeightDateEarlier)
      message |> should.equal("Cannot update earlier date")
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Error Message Formatting Tests
// ============================================================================

/// Test full error message for error 205
pub fn error_205_full_message_test() {
  let error =
    errors.ApiError(
      errors.WeightDateTooFar,
      "Date is more than 2 days from today",
    )

  errors.error_to_string(error)
  |> should.equal(
    "Weight Date Too Far in Future (code 205): Date is more than 2 days from today",
  )
}

/// Test full error message for error 206
pub fn error_206_full_message_test() {
  let error =
    errors.ApiError(
      errors.WeightDateEarlier,
      "Cannot update a date earlier than an existing weight entry",
    )

  errors.error_to_string(error)
  |> should.equal(
    "Weight Date Earlier Than Expected (code 206): Cannot update a date earlier than an existing weight entry",
  )
}

// ============================================================================
// Round-trip Tests
// ============================================================================

/// Test that error 205 survives round-trip conversion
pub fn error_205_round_trip_test() {
  errors.code_from_int(205)
  |> errors.code_to_int
  |> should.equal(205)
}

/// Test that error 206 survives round-trip conversion
pub fn error_206_round_trip_test() {
  errors.code_from_int(206)
  |> errors.code_to_int
  |> should.equal(206)
}

// ============================================================================
// WeightEntry Decoder Tests
// ============================================================================

/// Test decoding WeightEntry with all fields
pub fn decode_weight_entry_complete_test() {
  let json_str =
    "{\"date_int\": \"19723\", \"weight_kg\": \"75.5\", \"weight_comment\": \"Morning weight\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(19_723)
      entry.weight_kg |> should.equal(75.5)
      entry.weight_comment |> should.equal(Some("Morning weight"))
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightEntry without optional comment
pub fn decode_weight_entry_no_comment_test() {
  let json_str = "{\"date_int\": \"19723\", \"weight_kg\": \"75.5\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(19_723)
      entry.weight_kg |> should.equal(75.5)
      entry.weight_comment |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightEntry with integer weight (should convert to float)
pub fn decode_weight_entry_integer_weight_test() {
  let json_str =
    "{\"date_int\": \"19723\", \"weight_kg\": \"75\", \"weight_comment\": \"Rounded\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(19_723)
      entry.weight_kg |> should.equal(75.0)
      entry.weight_comment |> should.equal(Some("Rounded"))
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightEntry with realistic weight value
pub fn decode_weight_entry_realistic_test() {
  let json_str =
    "{\"date_int\": \"14276\", \"weight_kg\": \"82.000\", \"weight_comment\": \"Post-workout\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(14_276)
      entry.weight_kg |> should.equal(82.0)
      entry.weight_comment |> should.equal(Some("Post-workout"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// WeightDaySummary Decoder Tests
// ============================================================================

/// Test decoding WeightDaySummary
pub fn decode_weight_day_summary_test() {
  let json_str = "{\"date_int\": \"19723\", \"weight_kg\": \"75.5\"}"

  case json.parse(json_str, decoders.weight_day_summary_decoder()) {
    Ok(summary) -> {
      summary.date_int |> should.equal(19_723)
      summary.weight_kg |> should.equal(75.5)
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightDaySummary with trailing zeros
pub fn decode_weight_day_summary_trailing_zeros_test() {
  let json_str = "{\"date_int\": \"14276\", \"weight_kg\": \"82.000\"}"

  case json.parse(json_str, decoders.weight_day_summary_decoder()) {
    Ok(summary) -> {
      summary.date_int |> should.equal(14_276)
      summary.weight_kg |> should.equal(82.0)
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightDaySummary with integer weight
pub fn decode_weight_day_summary_integer_test() {
  let json_str = "{\"date_int\": \"14277\", \"weight_kg\": \"81\"}"

  case json.parse(json_str, decoders.weight_day_summary_decoder()) {
    Ok(summary) -> {
      summary.date_int |> should.equal(14_277)
      summary.weight_kg |> should.equal(81.0)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// WeightMonthSummary Decoder Tests
// ============================================================================

/// Test decoding WeightMonthSummary with multiple days
pub fn decode_weight_month_summary_multiple_days_test() {
  let json_str =
    "{
      \"month\": {
        \"from_date_int\": \"14276\",
        \"to_date_int\": \"14303\",
        \"day\": [
          {\"date_int\": \"14276\", \"weight_kg\": \"82.000\"},
          {\"date_int\": \"14277\", \"weight_kg\": \"81.500\"},
          {\"date_int\": \"14278\", \"weight_kg\": \"81.200\"}
        ]
      }
    }"

  case json.parse(json_str, decoders.weight_month_summary_decoder()) {
    Ok(summary) -> {
      summary.from_date_int |> should.equal(14_276)
      summary.to_date_int |> should.equal(14_303)
      summary.days
      |> should.equal([
        WeightDaySummary(date_int: 14_276, weight_kg: 82.0),
        WeightDaySummary(date_int: 14_277, weight_kg: 81.5),
        WeightDaySummary(date_int: 14_278, weight_kg: 81.2),
      ])
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightMonthSummary with single day (object, not array)
pub fn decode_weight_month_summary_single_day_test() {
  let json_str =
    "{
      \"month\": {
        \"from_date_int\": \"14276\",
        \"to_date_int\": \"14303\",
        \"day\": {\"date_int\": \"14276\", \"weight_kg\": \"82.000\"}
      }
    }"

  case json.parse(json_str, decoders.weight_month_summary_decoder()) {
    Ok(summary) -> {
      summary.from_date_int |> should.equal(14_276)
      summary.to_date_int |> should.equal(14_303)
      summary.days
      |> should.equal([WeightDaySummary(date_int: 14_276, weight_kg: 82.0)])
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightMonthSummary with realistic FatSecret API response
pub fn decode_weight_month_summary_realistic_test() {
  let json_str =
    "{
      \"month\": {
        \"from_date_int\": \"19720\",
        \"to_date_int\": \"19751\",
        \"day\": [
          {\"date_int\": \"19720\", \"weight_kg\": \"75.500\"},
          {\"date_int\": \"19721\", \"weight_kg\": \"75.300\"},
          {\"date_int\": \"19722\", \"weight_kg\": \"75.100\"},
          {\"date_int\": \"19723\", \"weight_kg\": \"74.900\"}
        ]
      }
    }"

  case json.parse(json_str, decoders.weight_month_summary_decoder()) {
    Ok(summary) -> {
      summary.from_date_int |> should.equal(19_720)
      summary.to_date_int |> should.equal(19_751)
      summary.days
      |> should.equal([
        WeightDaySummary(date_int: 19_720, weight_kg: 75.5),
        WeightDaySummary(date_int: 19_721, weight_kg: 75.3),
        WeightDaySummary(date_int: 19_722, weight_kg: 75.1),
        WeightDaySummary(date_int: 19_723, weight_kg: 74.9),
      ])
    }
    Error(_) -> should.fail()
  }
}

/// Test decoding WeightMonthSummary with empty day list
pub fn decode_weight_month_summary_empty_days_test() {
  let json_str =
    "{
      \"month\": {
        \"from_date_int\": \"19720\",
        \"to_date_int\": \"19751\",
        \"day\": []
      }
    }"

  case json.parse(json_str, decoders.weight_month_summary_decoder()) {
    Ok(summary) -> {
      summary.from_date_int |> should.equal(19_720)
      summary.to_date_int |> should.equal(19_751)
      summary.days |> should.equal([])
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// WeightUpdate Type Construction Tests
// ============================================================================

/// Test creating WeightUpdate with all fields
pub fn weight_update_complete_test() {
  let update =
    WeightUpdate(
      current_weight_kg: 75.5,
      date_int: 19_723,
      goal_weight_kg: Some(70.0),
      height_cm: Some(175.0),
      comment: Some("Morning weight"),
    )

  update.current_weight_kg |> should.equal(75.5)
  update.date_int |> should.equal(19_723)
  update.goal_weight_kg |> should.equal(Some(70.0))
  update.height_cm |> should.equal(Some(175.0))
  update.comment |> should.equal(Some("Morning weight"))
}

/// Test creating WeightUpdate with only required fields
pub fn weight_update_minimal_test() {
  let update =
    WeightUpdate(
      current_weight_kg: 75.5,
      date_int: 19_723,
      goal_weight_kg: None,
      height_cm: None,
      comment: None,
    )

  update.current_weight_kg |> should.equal(75.5)
  update.date_int |> should.equal(19_723)
  update.goal_weight_kg |> should.equal(None)
  update.height_cm |> should.equal(None)
  update.comment |> should.equal(None)
}

/// Test creating WeightUpdate with partial optional fields
pub fn weight_update_partial_test() {
  let update =
    WeightUpdate(
      current_weight_kg: 82.0,
      date_int: 14_276,
      goal_weight_kg: Some(75.0),
      height_cm: None,
      comment: Some("Target reached"),
    )

  update.current_weight_kg |> should.equal(82.0)
  update.date_int |> should.equal(14_276)
  update.goal_weight_kg |> should.equal(Some(75.0))
  update.height_cm |> should.equal(None)
  update.comment |> should.equal(Some("Target reached"))
}
