/// Tests for Property decoder
///
/// This module tests JSON decoding of Property types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleeunit/should
import meal_planner/tandoor/decoders/property/property_decoder

/// Test decoding a property with amount
pub fn decode_property_with_amount_test() {
  let json_string =
    "{\"id\":1,\"property_amount\":10.5,\"property_type\":{\"id\":1,\"name\":\"Weight\",\"unit\":\"kg\",\"description\":null,\"order\":1,\"open_data_slug\":null,\"fdc_id\":null}}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
}

/// Test decoding a property without amount
pub fn decode_property_without_amount_test() {
  let json_string =
    "{\"id\":2,\"property_amount\":null,\"property_type\":{\"id\":2,\"name\":\"Volume\",\"unit\":\"ml\",\"description\":null,\"order\":2,\"open_data_slug\":null,\"fdc_id\":null}}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
}

/// Test decoding a single property
pub fn decode_single_property_test() {
  let json_string =
    "{\"id\":3,\"property_amount\":5.2,\"property_type\":{\"id\":3,\"name\":\"Temp\",\"unit\":\"C\",\"description\":null,\"order\":3,\"open_data_slug\":null,\"fdc_id\":null}}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
}

/// Test decoding list of properties
pub fn decode_property_list_test() {
  let json_string =
    "[{\"id\":1,\"property_amount\":10.5,\"property_type\":{\"id\":1,\"name\":\"Weight\",\"unit\":\"kg\",\"description\":null,\"order\":1,\"open_data_slug\":null,\"fdc_id\":null}},{\"id\":2,\"property_amount\":null,\"property_type\":{\"id\":2,\"name\":\"Volume\",\"unit\":\"ml\",\"description\":null,\"order\":2,\"open_data_slug\":null,\"fdc_id\":null}}]"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(decode.list(property_decoder.property_decoder()))

  result
  |> should.be_ok
  |> list.length
  |> should.equal(2)
}

/// Test decoding property with minimal fields
pub fn decode_property_minimal_test() {
  let json_string =
    "{\"id\":4,\"property_amount\":null,\"property_type\":{\"id\":4,\"name\":\"Count\",\"unit\":\"pieces\",\"description\":null,\"order\":4,\"open_data_slug\":null,\"fdc_id\":null}}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
}
