import gleam/float
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/types.{
  Micronutrients, micronutrients_add, micronutrients_decoder,
  micronutrients_scale, micronutrients_sum, micronutrients_to_json,
  micronutrients_zero,
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Helper to compare floats with tolerance for floating point precision
fn float_close(actual: Float, expected: Float, tolerance: Float) -> Bool {
  float.absolute_value(actual -. expected) <. tolerance
}

/// Helper to compare optional floats with tolerance
fn option_float_close(
  actual: option.Option(Float),
  expected: option.Option(Float),
  tolerance: Float,
) -> Bool {
  case actual, expected {
    Some(a), Some(e) -> float_close(a, e, tolerance)
    None, None -> True
    _, _ -> False
  }
}

// ============================================================================
// Micronutrient Aggregation Tests
// ============================================================================

/// Test micronutrients_zero creates all None values
pub fn micronutrients_zero_test() {
  let m = micronutrients_zero()
  m.fiber |> should.equal(None)
  m.sugar |> should.equal(None)
  m.sodium |> should.equal(None)
  m.cholesterol |> should.equal(None)
  m.vitamin_a |> should.equal(None)
  m.vitamin_c |> should.equal(None)
  m.vitamin_d |> should.equal(None)
  m.vitamin_e |> should.equal(None)
  m.vitamin_k |> should.equal(None)
  m.vitamin_b6 |> should.equal(None)
  m.vitamin_b12 |> should.equal(None)
  m.folate |> should.equal(None)
  m.thiamin |> should.equal(None)
  m.riboflavin |> should.equal(None)
  m.niacin |> should.equal(None)
  m.calcium |> should.equal(None)
  m.iron |> should.equal(None)
  m.magnesium |> should.equal(None)
  m.phosphorus |> should.equal(None)
  m.potassium |> should.equal(None)
  m.zinc |> should.equal(None)
}

/// Test micronutrients_add with two fully populated values
pub fn micronutrients_add_both_some_test() {
  let m1 =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let m2 =
    Micronutrients(
      fiber: Some(3.0),
      sugar: Some(5.0),
      sodium: Some(100.0),
      cholesterol: Some(25.0),
      vitamin_a: Some(250.0),
      vitamin_c: Some(30.0),
      vitamin_d: Some(5.0),
      vitamin_e: Some(7.5),
      vitamin_k: Some(40.0),
      vitamin_b6: Some(1.0),
      vitamin_b12: Some(1.2),
      folate: Some(200.0),
      thiamin: Some(0.6),
      riboflavin: Some(0.65),
      niacin: Some(8.0),
      calcium: Some(500.0),
      iron: Some(9.0),
      magnesium: Some(200.0),
      phosphorus: Some(350.0),
      potassium: Some(1750.0),
      zinc: Some(5.5),
    )

  let result = micronutrients_add(m1, m2)

  result.fiber |> should.equal(Some(8.0))
  result.sugar |> should.equal(Some(15.0))
  result.sodium |> should.equal(Some(300.0))
  result.cholesterol |> should.equal(Some(75.0))
  result.vitamin_a |> should.equal(Some(750.0))
  result.vitamin_c |> should.equal(Some(90.0))
  result.vitamin_d |> should.equal(Some(15.0))
  result.vitamin_e |> should.equal(Some(22.5))
  result.vitamin_k |> should.equal(Some(120.0))
  result.vitamin_b6 |> should.equal(Some(3.0))
  option_float_close(result.vitamin_b12, Some(3.6), 0.0001)
  |> should.be_true()
  result.folate |> should.equal(Some(600.0))
  option_float_close(result.thiamin, Some(1.8), 0.0001)
  |> should.be_true()
  result.riboflavin |> should.equal(Some(1.95))
  result.niacin |> should.equal(Some(24.0))
  result.calcium |> should.equal(Some(1500.0))
  result.iron |> should.equal(Some(27.0))
  result.magnesium |> should.equal(Some(600.0))
  result.phosphorus |> should.equal(Some(1050.0))
  result.potassium |> should.equal(Some(5250.0))
  result.zinc |> should.equal(Some(16.5))
}

/// Test micronutrients_add with mixed Some and None values
pub fn micronutrients_add_mixed_test() {
  let m1 =
    Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: None,
      vitamin_d: Some(10.0),
      vitamin_e: None,
      vitamin_k: Some(80.0),
      vitamin_b6: None,
      vitamin_b12: Some(2.4),
      folate: None,
      thiamin: Some(1.2),
      riboflavin: None,
      niacin: Some(16.0),
      calcium: None,
      iron: Some(18.0),
      magnesium: None,
      phosphorus: Some(700.0),
      potassium: None,
      zinc: Some(11.0),
    )

  let m2 =
    Micronutrients(
      fiber: None,
      sugar: Some(5.0),
      sodium: None,
      cholesterol: Some(25.0),
      vitamin_a: None,
      vitamin_c: Some(30.0),
      vitamin_d: None,
      vitamin_e: Some(7.5),
      vitamin_k: None,
      vitamin_b6: Some(1.0),
      vitamin_b12: None,
      folate: Some(200.0),
      thiamin: None,
      riboflavin: Some(0.65),
      niacin: None,
      calcium: Some(500.0),
      iron: None,
      magnesium: Some(200.0),
      phosphorus: None,
      potassium: Some(1750.0),
      zinc: None,
    )

  let result = micronutrients_add(m1, m2)

  // Some + None = Some
  result.fiber |> should.equal(Some(5.0))
  result.sugar |> should.equal(Some(5.0))
  result.sodium |> should.equal(Some(200.0))
  result.cholesterol |> should.equal(Some(25.0))
  result.vitamin_a |> should.equal(Some(500.0))
  result.vitamin_c |> should.equal(Some(30.0))
  result.vitamin_d |> should.equal(Some(10.0))
  result.vitamin_e |> should.equal(Some(7.5))
  result.vitamin_k |> should.equal(Some(80.0))
  result.vitamin_b6 |> should.equal(Some(1.0))
  result.vitamin_b12 |> should.equal(Some(2.4))
  result.folate |> should.equal(Some(200.0))
  result.thiamin |> should.equal(Some(1.2))
  result.riboflavin |> should.equal(Some(0.65))
  result.niacin |> should.equal(Some(16.0))
  result.calcium |> should.equal(Some(500.0))
  result.iron |> should.equal(Some(18.0))
  result.magnesium |> should.equal(Some(200.0))
  result.phosphorus |> should.equal(Some(700.0))
  result.potassium |> should.equal(Some(1750.0))
  result.zinc |> should.equal(Some(11.0))
}

/// Test micronutrients_add with both None values
pub fn micronutrients_add_both_none_test() {
  let m1 = micronutrients_zero()
  let m2 = micronutrients_zero()
  let result = micronutrients_add(m1, m2)

  // None + None = None
  result.fiber |> should.equal(None)
  result.vitamin_c |> should.equal(None)
  result.calcium |> should.equal(None)
}

/// Test micronutrients_scale with positive factor
pub fn micronutrients_scale_positive_test() {
  let m =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let result = micronutrients_scale(m, 2.0)

  result.fiber |> should.equal(Some(10.0))
  result.sugar |> should.equal(Some(20.0))
  result.sodium |> should.equal(Some(400.0))
  result.vitamin_c |> should.equal(Some(120.0))
  result.calcium |> should.equal(Some(2000.0))
}

/// Test micronutrients_scale with fractional factor
pub fn micronutrients_scale_fractional_test() {
  let m =
    Micronutrients(
      fiber: Some(10.0),
      sugar: Some(20.0),
      sodium: Some(400.0),
      cholesterol: Some(100.0),
      vitamin_a: Some(1000.0),
      vitamin_c: Some(120.0),
      vitamin_d: Some(20.0),
      vitamin_e: Some(30.0),
      vitamin_k: Some(160.0),
      vitamin_b6: Some(4.0),
      vitamin_b12: Some(4.8),
      folate: Some(800.0),
      thiamin: Some(2.4),
      riboflavin: Some(2.6),
      niacin: Some(32.0),
      calcium: Some(2000.0),
      iron: Some(36.0),
      magnesium: Some(800.0),
      phosphorus: Some(1400.0),
      potassium: Some(7000.0),
      zinc: Some(22.0),
    )

  let result = micronutrients_scale(m, 0.5)

  result.fiber |> should.equal(Some(5.0))
  result.sugar |> should.equal(Some(10.0))
  result.sodium |> should.equal(Some(200.0))
  result.vitamin_c |> should.equal(Some(60.0))
  result.calcium |> should.equal(Some(1000.0))
}

/// Test micronutrients_scale with None values
pub fn micronutrients_scale_with_none_test() {
  let m =
    Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: None,
      vitamin_c: Some(60.0),
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: Some(1000.0),
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let result = micronutrients_scale(m, 3.0)

  result.fiber |> should.equal(Some(15.0))
  result.sugar |> should.equal(None)
  result.sodium |> should.equal(Some(600.0))
  result.cholesterol |> should.equal(None)
  result.vitamin_c |> should.equal(Some(180.0))
  result.calcium |> should.equal(Some(3000.0))
}

/// Test micronutrients_sum with empty list
pub fn micronutrients_sum_empty_list_test() {
  let result = micronutrients_sum([])
  let expected = micronutrients_zero()

  result.fiber |> should.equal(expected.fiber)
  result.vitamin_c |> should.equal(expected.vitamin_c)
  result.calcium |> should.equal(expected.calcium)
}

/// Test micronutrients_sum with single item
pub fn micronutrients_sum_single_item_test() {
  let m =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let result = micronutrients_sum([m])

  result.fiber |> should.equal(Some(5.0))
  result.vitamin_c |> should.equal(Some(60.0))
  result.calcium |> should.equal(Some(1000.0))
}

/// Test micronutrients_sum with multiple items
pub fn micronutrients_sum_multiple_items_test() {
  let m1 =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let m2 =
    Micronutrients(
      fiber: Some(3.0),
      sugar: Some(5.0),
      sodium: Some(100.0),
      cholesterol: Some(25.0),
      vitamin_a: Some(250.0),
      vitamin_c: Some(30.0),
      vitamin_d: Some(5.0),
      vitamin_e: Some(7.5),
      vitamin_k: Some(40.0),
      vitamin_b6: Some(1.0),
      vitamin_b12: Some(1.2),
      folate: Some(200.0),
      thiamin: Some(0.6),
      riboflavin: Some(0.65),
      niacin: Some(8.0),
      calcium: Some(500.0),
      iron: Some(9.0),
      magnesium: Some(200.0),
      phosphorus: Some(350.0),
      potassium: Some(1750.0),
      zinc: Some(5.5),
    )

  let m3 =
    Micronutrients(
      fiber: Some(2.0),
      sugar: Some(3.0),
      sodium: Some(50.0),
      cholesterol: Some(12.5),
      vitamin_a: Some(125.0),
      vitamin_c: Some(15.0),
      vitamin_d: Some(2.5),
      vitamin_e: Some(3.75),
      vitamin_k: Some(20.0),
      vitamin_b6: Some(0.5),
      vitamin_b12: Some(0.6),
      folate: Some(100.0),
      thiamin: Some(0.3),
      riboflavin: Some(0.325),
      niacin: Some(4.0),
      calcium: Some(250.0),
      iron: Some(4.5),
      magnesium: Some(100.0),
      phosphorus: Some(175.0),
      potassium: Some(875.0),
      zinc: Some(2.75),
    )

  let result = micronutrients_sum([m1, m2, m3])

  result.fiber |> should.equal(Some(10.0))
  result.sugar |> should.equal(Some(18.0))
  result.sodium |> should.equal(Some(350.0))
  result.cholesterol |> should.equal(Some(87.5))
  result.vitamin_a |> should.equal(Some(875.0))
  result.vitamin_c |> should.equal(Some(105.0))
  result.calcium |> should.equal(Some(1750.0))
  result.iron |> should.equal(Some(31.5))
  result.potassium |> should.equal(Some(6125.0))
}

/// Test micronutrients_sum with mixed Some and None values
pub fn micronutrients_sum_mixed_values_test() {
  let m1 =
    Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: None,
      vitamin_d: Some(10.0),
      vitamin_e: None,
      vitamin_k: Some(80.0),
      vitamin_b6: None,
      vitamin_b12: Some(2.4),
      folate: None,
      thiamin: Some(1.2),
      riboflavin: None,
      niacin: Some(16.0),
      calcium: None,
      iron: Some(18.0),
      magnesium: None,
      phosphorus: Some(700.0),
      potassium: None,
      zinc: Some(11.0),
    )

  let m2 =
    Micronutrients(
      fiber: None,
      sugar: Some(5.0),
      sodium: None,
      cholesterol: Some(25.0),
      vitamin_a: None,
      vitamin_c: Some(30.0),
      vitamin_d: None,
      vitamin_e: Some(7.5),
      vitamin_k: None,
      vitamin_b6: Some(1.0),
      vitamin_b12: None,
      folate: Some(200.0),
      thiamin: None,
      riboflavin: Some(0.65),
      niacin: None,
      calcium: Some(500.0),
      iron: None,
      magnesium: Some(200.0),
      phosphorus: None,
      potassium: Some(1750.0),
      zinc: None,
    )

  let m3 =
    Micronutrients(
      fiber: Some(2.0),
      sugar: Some(3.0),
      sodium: Some(50.0),
      cholesterol: None,
      vitamin_a: Some(125.0),
      vitamin_c: Some(15.0),
      vitamin_d: Some(2.5),
      vitamin_e: None,
      vitamin_k: Some(20.0),
      vitamin_b6: None,
      vitamin_b12: Some(0.6),
      folate: None,
      thiamin: Some(0.3),
      riboflavin: None,
      niacin: Some(4.0),
      calcium: None,
      iron: Some(4.5),
      magnesium: None,
      phosphorus: Some(175.0),
      potassium: None,
      zinc: Some(2.75),
    )

  let result = micronutrients_sum([m1, m2, m3])

  // Should sum all Some values across all items
  result.fiber |> should.equal(Some(7.0))
  result.sugar |> should.equal(Some(8.0))
  result.sodium |> should.equal(Some(250.0))
  result.cholesterol |> should.equal(Some(25.0))
  result.vitamin_a |> should.equal(Some(625.0))
  result.vitamin_c |> should.equal(Some(45.0))
  result.vitamin_d |> should.equal(Some(12.5))
  result.vitamin_e |> should.equal(Some(7.5))
  result.vitamin_k |> should.equal(Some(100.0))
  result.vitamin_b6 |> should.equal(Some(1.0))
  result.vitamin_b12 |> should.equal(Some(3.0))
  result.folate |> should.equal(Some(200.0))
  result.thiamin |> should.equal(Some(1.5))
  result.riboflavin |> should.equal(Some(0.65))
  result.niacin |> should.equal(Some(20.0))
  result.calcium |> should.equal(Some(500.0))
  result.iron |> should.equal(Some(22.5))
  result.magnesium |> should.equal(Some(200.0))
  result.phosphorus |> should.equal(Some(875.0))
  result.potassium |> should.equal(Some(1750.0))
  result.zinc |> should.equal(Some(13.75))
}

// ============================================================================
// JSON Encoding/Decoding Tests
// ============================================================================

/// Test JSON encoding of fully populated micronutrients
pub fn micronutrients_json_encode_full_test() {
  let m =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let json_value = micronutrients_to_json(m)
  let json_string = json.to_string(json_value)

  // Verify JSON contains all fields (check for key presence, values may have spacing)
  string.contains(json_string, "\"fiber\"")
  |> should.be_true()
  string.contains(json_string, "\"vitamin_c\"")
  |> should.be_true()
  string.contains(json_string, "\"calcium\"")
  |> should.be_true()
}

/// Test JSON encoding of micronutrients with partial data (mixed Some/None)
pub fn micronutrients_json_encode_partial_test() {
  let m =
    Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: None,
      vitamin_d: Some(10.0),
      vitamin_e: None,
      vitamin_k: Some(80.0),
      vitamin_b6: None,
      vitamin_b12: Some(2.4),
      folate: None,
      thiamin: Some(1.2),
      riboflavin: None,
      niacin: Some(16.0),
      calcium: None,
      iron: Some(18.0),
      magnesium: None,
      phosphorus: Some(700.0),
      potassium: None,
      zinc: Some(11.0),
    )

  let json_value = micronutrients_to_json(m)
  let json_string = json.to_string(json_value)

  // Verify JSON contains only Some fields
  string.contains(json_string, "\"fiber\"")
  |> should.be_true()
  string.contains(json_string, "\"sodium\"")
  |> should.be_true()

  // Verify JSON does not contain None fields (they should be omitted)
  string.contains(json_string, "\"sugar\"")
  |> should.be_false()
  string.contains(json_string, "\"cholesterol\"")
  |> should.be_false()
  string.contains(json_string, "\"vitamin_c\"")
  |> should.be_false()
}

/// Test JSON encoding of empty micronutrients (all None)
pub fn micronutrients_json_encode_empty_test() {
  let m = micronutrients_zero()
  let json_value = micronutrients_to_json(m)
  let json_string = json.to_string(json_value)

  // Should contain all fields with null values
  string.contains(json_string, "\"fiber\"")
  |> should.be_true()
  string.contains(json_string, "null")
  |> should.be_true()
}

/// Test JSON round-trip encoding/decoding with full data
pub fn micronutrients_json_roundtrip_full_test() {
  let original =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  // Encode to JSON
  let json_value = micronutrients_to_json(original)
  let json_string = json.to_string(json_value)

  // Decode back
  let decoded_result =
    json.parse(from: json_string, using: micronutrients_decoder())

  // Verify successful round-trip
  let decoded = decoded_result |> should.be_ok()

  // Verify all fields match
  decoded.fiber |> should.equal(original.fiber)
  decoded.sugar |> should.equal(original.sugar)
  decoded.sodium |> should.equal(original.sodium)
  decoded.cholesterol |> should.equal(original.cholesterol)
  decoded.vitamin_a |> should.equal(original.vitamin_a)
  decoded.vitamin_c |> should.equal(original.vitamin_c)
  decoded.vitamin_d |> should.equal(original.vitamin_d)
  decoded.vitamin_e |> should.equal(original.vitamin_e)
  decoded.vitamin_k |> should.equal(original.vitamin_k)
  decoded.vitamin_b6 |> should.equal(original.vitamin_b6)
  decoded.vitamin_b12 |> should.equal(original.vitamin_b12)
  decoded.folate |> should.equal(original.folate)
  decoded.thiamin |> should.equal(original.thiamin)
  decoded.riboflavin |> should.equal(original.riboflavin)
  decoded.niacin |> should.equal(original.niacin)
  decoded.calcium |> should.equal(original.calcium)
  decoded.iron |> should.equal(original.iron)
  decoded.magnesium |> should.equal(original.magnesium)
  decoded.phosphorus |> should.equal(original.phosphorus)
  decoded.potassium |> should.equal(original.potassium)
  decoded.zinc |> should.equal(original.zinc)
}

/// Test JSON round-trip with partial data (mixed Some/None)
pub fn micronutrients_json_roundtrip_partial_test() {
  let original =
    Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: None,
      vitamin_d: Some(10.0),
      vitamin_e: None,
      vitamin_k: Some(80.0),
      vitamin_b6: None,
      vitamin_b12: Some(2.4),
      folate: None,
      thiamin: Some(1.2),
      riboflavin: None,
      niacin: Some(16.0),
      calcium: None,
      iron: Some(18.0),
      magnesium: None,
      phosphorus: Some(700.0),
      potassium: None,
      zinc: Some(11.0),
    )

  // Encode to JSON
  let json_value = micronutrients_to_json(original)
  let json_string = json.to_string(json_value)

  // Decode back
  let decoded_result =
    json.parse(from: json_string, using: micronutrients_decoder())

  // Verify successful round-trip
  let decoded = decoded_result |> should.be_ok()

  // Verify Some fields match
  decoded.fiber |> should.equal(Some(5.0))
  decoded.sodium |> should.equal(Some(200.0))
  decoded.vitamin_a |> should.equal(Some(500.0))
  decoded.iron |> should.equal(Some(18.0))

  // Verify None fields remain None
  decoded.sugar |> should.equal(None)
  decoded.cholesterol |> should.equal(None)
  decoded.vitamin_c |> should.equal(None)
  decoded.calcium |> should.equal(None)
}

/// Test JSON round-trip with empty micronutrients (all None)
pub fn micronutrients_json_roundtrip_empty_test() {
  let original = micronutrients_zero()

  // Encode to JSON
  let json_value = micronutrients_to_json(original)
  let json_string = json.to_string(json_value)

  // Decode back
  let decoded_result =
    json.parse(from: json_string, using: micronutrients_decoder())

  // Verify successful round-trip
  let decoded = decoded_result |> should.be_ok()

  // All fields should be None
  decoded.fiber |> should.equal(None)
  decoded.sugar |> should.equal(None)
  decoded.vitamin_c |> should.equal(None)
  decoded.calcium |> should.equal(None)
}
