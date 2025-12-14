import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/unit/unit.{Unit}

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
  // This test verifies that name is a required field
  // by constructing a unit with only the required fields
  let unit =
    Unit(
      id: 5,
      name: "tablespoon",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  unit.name
  |> should.equal("tablespoon")
}
