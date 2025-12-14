import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/types/unit/unit.{type Unit}

pub fn decode_unit_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"gram\",
      \"plural_name\": \"grams\",
      \"description\": \"Metric unit of mass\",
      \"base_unit\": \"kilogram\",
      \"open_data_slug\": \"g\"
    }"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(unit) -> {
      unit.id
      |> should.equal(1)
      unit.name
      |> should.equal("gram")
      unit.plural_name
      |> should.equal(Some("grams"))
      unit.description
      |> should.equal(Some("Metric unit of mass"))
      unit.base_unit
      |> should.equal(Some("kilogram"))
      unit.open_data_slug
      |> should.equal(Some("g"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_unit_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"name\": \"piece\",
      \"plural_name\": null,
      \"description\": null,
      \"base_unit\": null,
      \"open_data_slug\": null
    }"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(unit) -> {
      unit.id
      |> should.equal(2)
      unit.name
      |> should.equal("piece")
      unit.plural_name
      |> should.equal(None)
      unit.description
      |> should.equal(None)
      unit.base_unit
      |> should.equal(None)
      unit.open_data_slug
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_unit_partial_fields_test() {
  let json_str =
    "{
      \"id\": 3,
      \"name\": \"liter\",
      \"plural_name\": \"liters\",
      \"description\": \"Metric unit of volume\",
      \"base_unit\": null,
      \"open_data_slug\": \"l\"
    }"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(unit) -> {
      unit.id
      |> should.equal(3)
      unit.name
      |> should.equal("liter")
      unit.plural_name
      |> should.equal(Some("liters"))
      unit.description
      |> should.equal(Some("Metric unit of volume"))
      unit.base_unit
      |> should.equal(None)
      unit.open_data_slug
      |> should.equal(Some("l"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_unit_invalid_json_test() {
  let json_str = "{\"id\": \"not_a_number\"}"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_unit_missing_required_fields_test() {
  let json_str = "{\"id\": 1}"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_unit_missing_name_test() {
  let json_str =
    "{
      \"id\": 5,
      \"plural_name\": \"tablespoons\",
      \"description\": \"Common cooking measurement\",
      \"base_unit\": null,
      \"open_data_slug\": \"tbsp\"
    }"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_unit_empty_strings_test() {
  let json_str =
    "{
      \"id\": 6,
      \"name\": \"cup\",
      \"plural_name\": \"\",
      \"description\": \"\",
      \"base_unit\": \"\",
      \"open_data_slug\": \"\"
    }"

  let result: Result(Unit, _) =
    json.parse(json_str, using: unit_decoder.decode_unit())

  case result {
    Ok(unit) -> {
      unit.id
      |> should.equal(6)
      unit.name
      |> should.equal("cup")
      // Empty strings should be treated as Some("")
      unit.plural_name
      |> should.equal(Some(""))
      unit.description
      |> should.equal(Some(""))
      unit.base_unit
      |> should.equal(Some(""))
      unit.open_data_slug
      |> should.equal(Some(""))
    }
    Error(_) -> should.fail()
  }
}
