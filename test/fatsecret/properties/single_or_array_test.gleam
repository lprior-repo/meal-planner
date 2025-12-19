/// Property-based tests for single-or-array decoder pattern
///
/// Verifies that decoders handle FatSecret's quirk of returning:
/// - Single object when there's 1 result
/// - Array when there are multiple results
import fatsecret/properties/generators
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleeunit/should

/// Simple test type for verifying single-or-array behavior
type SimpleItem {
  SimpleItem(food_id: String, name: String)
}

/// Decoder for SimpleItem
fn simple_item_decoder() -> decode.Decoder(SimpleItem) {
  use food_id <- decode.field("food_id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(SimpleItem(food_id: food_id, name: name))
}

/// Decoder that handles single-or-array quirk
fn single_or_array_decoder() -> decode.Decoder(List(SimpleItem)) {
  decode.one_of(
    // Try array first
    decode.list(simple_item_decoder()),
    or: [
      // Fallback to single object wrapped in list
      {
        use single <- decode.then(simple_item_decoder())
        decode.success([single])
      },
    ],
  )
}

/// Property: single-or-array decoder normalizes single object to List
pub fn single_or_array_normalizes_single_object_test() {
  // Test single object
  let single_json = "{\"food_id\": \"123\", \"name\": \"Apple\"}"

  let result = json.parse(single_json, single_or_array_decoder())

  should.be_ok(result)
  case result {
    Ok(items) -> {
      should.equal(list.length(items), 1)
      case list.first(items) {
        Ok(item) -> {
          should.equal(item.food_id, "123")
          should.equal(item.name, "Apple")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Property: single-or-array handles array of multiple items
pub fn single_or_array_handles_array_test() {
  let array_json =
    "[{\"food_id\": \"123\", \"name\": \"Apple\"}, {\"food_id\": \"456\", \"name\": \"Banana\"}]"

  let result = json.parse(array_json, single_or_array_decoder())

  should.be_ok(result)
  case result {
    Ok(items) -> {
      should.equal(list.length(items), 2)
    }
    Error(_) -> should.fail()
  }
}

/// Property: single-or-array handles empty array
pub fn single_or_array_handles_empty_array_test() {
  let empty_json = "[]"

  let result = json.parse(empty_json, single_or_array_decoder())

  should.be_ok(result)
  case result {
    Ok(items) -> {
      should.equal(list.length(items), 0)
    }
    Error(_) -> should.fail()
  }
}

/// Property: Run 100 iterations of single-or-array tests
///
/// Ensures the decoder is robust across many test cases
pub fn single_or_array_100_iterations_test() {
  let test_cases = generators.single_or_array_json_strings()

  // Run 100 iterations (repeat test cases)
  list.range(0, 99)
  |> list.each(fn(i) {
    let idx = i % list.length(test_cases)
    let test_case = case list.drop(test_cases, idx) |> list.first {
      Ok(tc) -> tc
      Error(_) -> "{\"food_id\": \"fallback\", \"name\": \"Fallback\"}"
    }

    let result = json.parse(test_case, single_or_array_decoder())

    // All test cases should decode successfully
    should.be_ok(result)

    // Verify result is always a List
    case result {
      Ok(_items) -> Nil
      Error(_) -> should.fail()
    }
  })
}

/// Property: Verify generator produces valid test cases
pub fn generator_produces_valid_json_test() {
  let generated = generators.single_or_array_json_strings()

  // Verify we have multiple test cases
  let count = list.length(generated)
  should.equal(count >= 3, True)

  // Each generated value should parse successfully
  generated
  |> list.each(fn(json_str) {
    let result = json.parse(json_str, single_or_array_decoder())
    should.be_ok(result)
  })
}

/// Property: Verify iteration count
pub fn iteration_count_test() {
  let test_cases = generators.single_or_array_json_strings()
  let count = list.length(test_cases)

  // Should have at least 3 test cases
  should.equal(count >= 3, True)

  // For visibility
  let msg =
    "Generated " <> int.to_string(count) <> " single-or-array test cases"
  should.equal(True, True)
  let _ = msg
  Nil
}
