/// Tests for Tandoor Unit module
///
/// Consolidated tests covering type construction, JSON encoding/decoding,
/// and CRUD API operations for measurement units.
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/client
import meal_planner/tandoor/unit.{type Unit, Unit}

// ============================================================================
// Type Construction Tests
// ============================================================================

pub fn unit_full_constructor_test() {
  let unit =
    Unit(
      id: 1,
      name: "gram",
      plural_name: Some("grams"),
      description: Some("Metric unit of mass"),
      base_unit: Some("kilogram"),
      open_data_slug: Some("g"),
    )

  unit.id |> should.equal(1)
  unit.name |> should.equal("gram")
  unit.plural_name |> should.equal(Some("grams"))
  unit.description |> should.equal(Some("Metric unit of mass"))
  unit.base_unit |> should.equal(Some("kilogram"))
  unit.open_data_slug |> should.equal(Some("g"))
}

pub fn unit_minimal_test() {
  let unit =
    Unit(
      id: 2,
      name: "piece",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  unit.id |> should.equal(2)
  unit.name |> should.equal("piece")
  unit.plural_name |> should.equal(None)
  unit.description |> should.equal(None)
  unit.base_unit |> should.equal(None)
  unit.open_data_slug |> should.equal(None)
}

pub fn unit_optional_fields_test() {
  let unit1 =
    Unit(
      id: 3,
      name: "liter",
      plural_name: Some("liters"),
      description: Some("Metric unit of volume"),
      base_unit: None,
      open_data_slug: Some("l"),
    )

  let unit2 =
    Unit(
      id: 4,
      name: "cup",
      plural_name: Some("cups"),
      description: None,
      base_unit: Some("liter"),
      open_data_slug: None,
    )

  should.equal(unit1.plural_name, Some("liters"))
  should.equal(unit1.description, Some("Metric unit of volume"))
  should.equal(unit1.base_unit, None)
  should.equal(unit1.open_data_slug, Some("l"))

  should.equal(unit2.plural_name, Some("cups"))
  should.equal(unit2.description, None)
  should.equal(unit2.base_unit, Some("liter"))
  should.equal(unit2.open_data_slug, None)
}

pub fn unit_name_required_test() {
  let unit =
    Unit(
      id: 5,
      name: "tablespoon",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  unit.name |> should.equal("tablespoon")
}

// ============================================================================
// Decoder Tests
// ============================================================================

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

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

  case result {
    Ok(u) -> {
      u.id |> should.equal(1)
      u.name |> should.equal("gram")
      u.plural_name |> should.equal(Some("grams"))
      u.description |> should.equal(Some("Metric unit of mass"))
      u.base_unit |> should.equal(Some("kilogram"))
      u.open_data_slug |> should.equal(Some("g"))
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

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

  case result {
    Ok(u) -> {
      u.id |> should.equal(2)
      u.name |> should.equal("piece")
      u.plural_name |> should.equal(None)
      u.description |> should.equal(None)
      u.base_unit |> should.equal(None)
      u.open_data_slug |> should.equal(None)
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

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

  case result {
    Ok(u) -> {
      u.id |> should.equal(3)
      u.name |> should.equal("liter")
      u.plural_name |> should.equal(Some("liters"))
      u.description |> should.equal(Some("Metric unit of volume"))
      u.base_unit |> should.equal(None)
      u.open_data_slug |> should.equal(Some("l"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_unit_invalid_json_test() {
  let json_str = "{\"id\": \"not_a_number\"}"

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_unit_missing_required_fields_test() {
  let json_str = "{\"id\": 1}"

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

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

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

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

  let result: Result(Unit, _) = json.parse(json_str, using: unit.decode_unit())

  case result {
    Ok(u) -> {
      u.id |> should.equal(6)
      u.name |> should.equal("cup")
      u.plural_name |> should.equal(Some(""))
      u.description |> should.equal(Some(""))
      u.base_unit |> should.equal(Some(""))
      u.open_data_slug |> should.equal(Some(""))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Encoder Tests
// ============================================================================

pub fn encode_unit_full_test() {
  let u =
    Unit(
      id: 1,
      name: "gram",
      plural_name: Some("grams"),
      description: Some("Metric unit of mass"),
      base_unit: Some("kilogram"),
      open_data_slug: Some("g"),
    )

  let encoded = unit.encode_unit(u)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"id\":1,\"name\":\"gram\",\"plural_name\":\"grams\",\"description\":\"Metric unit of mass\",\"base_unit\":\"kilogram\",\"open_data_slug\":\"g\"}",
  )
}

pub fn encode_unit_minimal_test() {
  let u =
    Unit(
      id: 2,
      name: "piece",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let encoded = unit.encode_unit(u)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"id\":2,\"name\":\"piece\",\"plural_name\":null,\"description\":null,\"base_unit\":null,\"open_data_slug\":null}",
  )
}

pub fn encode_unit_partial_test() {
  let u =
    Unit(
      id: 3,
      name: "liter",
      plural_name: Some("liters"),
      description: Some("Metric unit of volume"),
      base_unit: None,
      open_data_slug: Some("l"),
    )

  let encoded = unit.encode_unit(u)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "{\"id\":3,\"name\":\"liter\",\"plural_name\":\"liters\",\"description\":\"Metric unit of volume\",\"base_unit\":null,\"open_data_slug\":\"l\"}",
  )
}

pub fn encode_unit_create_test() {
  let encoded = unit.encode_unit_create("tablespoon")
  let json_string = json.to_string(encoded)

  json_string |> should.equal("{\"name\":\"tablespoon\"}")
}

pub fn encode_unit_create_special_chars_test() {
  let encoded = unit.encode_unit_create("cafe spoon")
  let json_string = json.to_string(encoded)

  json_string |> should.equal("{\"name\":\"cafe spoon\"}")
}

pub fn encode_multiple_units_test() {
  let units = [
    Unit(
      id: 1,
      name: "gram",
      plural_name: Some("grams"),
      description: None,
      base_unit: None,
      open_data_slug: Some("g"),
    ),
    Unit(
      id: 2,
      name: "liter",
      plural_name: Some("liters"),
      description: None,
      base_unit: None,
      open_data_slug: Some("l"),
    ),
  ]

  let encoded = json.array(units, unit.encode_unit)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal(
    "[{\"id\":1,\"name\":\"gram\",\"plural_name\":\"grams\",\"description\":null,\"base_unit\":null,\"open_data_slug\":\"g\"},{\"id\":2,\"name\":\"liter\",\"plural_name\":\"liters\",\"description\":null,\"base_unit\":null,\"open_data_slug\":\"l\"}]",
  )
}

// ============================================================================
// API CRUD Tests
// ============================================================================

/// Port that's guaranteed to not have a server running
const no_server_url = "http://localhost:59999"

pub fn get_unit_delegates_to_client_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.get_unit(config, unit_id: 1)
  should.be_error(result)
}

pub fn create_unit_delegates_to_client_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.create_unit(config, name: "tablespoon")
  should.be_error(result)
}

pub fn update_unit_delegates_to_client_test() {
  let config = client.bearer_config(no_server_url, "test-token")

  let u =
    Unit(
      id: 1,
      name: "updated_unit",
      plural_name: Some("updated_units"),
      description: Some("Updated description"),
      base_unit: None,
      open_data_slug: Some("upd"),
    )

  let result = unit.update_unit(config, unit_id: 1, unit: u)
  should.be_error(result)
}

pub fn delete_unit_delegates_to_client_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.delete_unit(config, unit_id: 1)
  should.be_error(result)
}

pub fn create_unit_with_special_characters_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.create_unit(config, name: "cafe spoon")
  should.be_error(result)
}

pub fn create_unit_with_unicode_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.create_unit(config, name: "test unit")
  should.be_error(result)
}

pub fn create_unit_empty_name_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.create_unit(config, name: "")
  should.be_error(result)
}

pub fn get_unit_with_zero_id_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.get_unit(config, unit_id: 0)
  should.be_error(result)
}

pub fn get_unit_with_negative_id_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.get_unit(config, unit_id: -1)
  should.be_error(result)
}

pub fn update_unit_with_all_optional_fields_test() {
  let config = client.bearer_config(no_server_url, "test-token")

  let u =
    Unit(
      id: 1,
      name: "complete_unit",
      plural_name: Some("complete_units"),
      description: Some("A unit with all fields populated"),
      base_unit: Some("gram"),
      open_data_slug: Some("cu"),
    )

  let result = unit.update_unit(config, unit_id: 1, unit: u)
  should.be_error(result)
}

pub fn update_unit_with_no_optional_fields_test() {
  let config = client.bearer_config(no_server_url, "test-token")

  let u =
    Unit(
      id: 1,
      name: "minimal_unit",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let result = unit.update_unit(config, unit_id: 1, unit: u)
  should.be_error(result)
}

pub fn delete_unit_with_zero_id_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let result = unit.delete_unit(config, unit_id: 0)
  should.be_error(result)
}

pub fn create_unit_very_long_name_test() {
  let config = client.bearer_config(no_server_url, "test-token")
  let long_name = "very_long_unit_name_" <> string.repeat("x", 480)
  let result = unit.create_unit(config, name: long_name)
  should.be_error(result)
}

// ============================================================================
// API List Tests
// ============================================================================

pub fn list_units_delegates_to_client_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let result = unit.list_units(config, limit: Some(10), page: Some(1))
  should.be_error(result)
}

pub fn list_units_accepts_none_params_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let result = unit.list_units(config, limit: None, page: None)
  should.be_error(result)
}

pub fn list_units_with_pagination_test() {
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let result = unit.list_units(config, limit: Some(25), page: Some(2))
  should.be_error(result)
}
