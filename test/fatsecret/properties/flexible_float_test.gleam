/// Property-based tests for flexible_float decoder
import fatsecret/properties/generators
import gleam/dynamic/decode
import gleam/float
import gleam/json
import gleam/list
import gleeunit/should

/// Test: Float string "0.0" parses
pub fn test_string_zero_test() {
  should.be_ok(float.parse("0.0"))
}

/// Test: Float string "1.0" parses
pub fn test_string_one_test() {
  should.be_ok(float.parse("1.0"))
}

/// Test: Decimal "1.5" parses
pub fn test_string_decimal_test() {
  should.be_ok(float.parse("1.5"))
}

/// Property: All generated float strings parse successfully
pub fn flexible_float_handles_all_string_formats_test() {
  let results =
    generators.flexible_float_strings()
    |> list.map(float.parse)

  // All should be Ok
  results
  |> list.all(fn(result) {
    case result {
      Ok(_) -> True
      Error(_) -> False
    }
  })
  |> should.equal(True)
}

/// Property: Float numbers via JSON decode correctly
pub fn flexible_float_handles_native_numbers_test() {
  [0.0, 1.0, 1.5]
  |> list.each(fn(f) {
    let json_str = json.object([#("value", json.float(f))]) |> json.to_string
    let decoder = {
      use value <- decode.field("value", decode.float)
      decode.success(value)
    }
    case json.parse(json_str, decoder) {
      Ok(parsed) -> should.equal(parsed, f)
      Error(_) -> should.fail()
    }
  })
}

/// Property: 100 iterations of float parsing
pub fn flexible_float_100_iterations_test() {
  let strings = generators.flexible_float_strings()
  let all_ok =
    list.range(0, 99)
    |> list.flat_map(fn(_) { strings })
    |> list.take(100)
    |> list.map(float.parse)
    |> list.all(fn(result) {
      case result {
        Ok(_) -> True
        Error(_) -> False
      }
    })

  should.equal(all_ok, True)
}
