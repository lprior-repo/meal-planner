import gleeunit
import gleeunit/should
import meal_planner/quantity

pub fn main() {
  gleeunit.main()
}

// Test parsing simple quantities
pub fn parse_simple_number_test() {
  let result = quantity.parse_quantity("4")
  result.amount |> should.equal(4.0)
  result.unit.name |> should.equal("")
  result.unit.unit_type |> should.equal(quantity.Count)
}

pub fn parse_oz_test() {
  let result = quantity.parse_quantity("8 oz")
  result.amount |> should.equal(8.0)
  result.unit.name |> should.equal("oz")
  result.unit.unit_type |> should.equal(quantity.Weight)
}

pub fn parse_lb_test() {
  let result = quantity.parse_quantity("2 lb")
  result.amount |> should.equal(2.0)
  result.unit.name |> should.equal("lb")
  result.unit.unit_type |> should.equal(quantity.Weight)
}

pub fn parse_tsp_test() {
  let result = quantity.parse_quantity("1 tsp")
  result.amount |> should.equal(1.0)
  result.unit.name |> should.equal("tsp")
  result.unit.unit_type |> should.equal(quantity.Volume)
}

pub fn parse_tbsp_test() {
  let result = quantity.parse_quantity("2 tbsp")
  result.amount |> should.equal(2.0)
  result.unit.name |> should.equal("tbsp")
  result.unit.unit_type |> should.equal(quantity.Volume)
}

pub fn parse_cup_test() {
  let result = quantity.parse_quantity("1.5 cups")
  result.amount |> should.equal(1.5)
  result.unit.name |> should.equal("cup")
  result.unit.unit_type |> should.equal(quantity.Volume)
}

pub fn parse_fraction_test() {
  let result = quantity.parse_quantity("1/2 tsp")
  result.amount |> should.equal(0.5)
  result.unit.name |> should.equal("tsp")
}

pub fn parse_unknown_unit_test() {
  let result = quantity.parse_quantity("2 somethingweird")
  result.amount |> should.equal(2.0)
  result.unit.unit_type |> should.equal(quantity.Other)
}

pub fn parse_empty_string_test() {
  let result = quantity.parse_quantity("")
  result.raw |> should.equal("")
  result.unit.unit_type |> should.equal(quantity.Other)
}

// Test unit conversion
pub fn can_convert_same_type_test() {
  let oz = quantity.unit_oz()
  let lb = quantity.unit_lb()
  quantity.can_convert(oz, lb) |> should.be_true()
}

pub fn can_convert_different_types_test() {
  let oz = quantity.unit_oz()
  let tsp = quantity.unit_tsp()
  quantity.can_convert(oz, tsp) |> should.be_false()
}

pub fn convert_to_base_oz_test() {
  let parsed = quantity.parse_quantity("2 lb")
  let base = quantity.convert_to_base(parsed)
  base |> should.equal(32.0)  // 2 lb = 32 oz
}

pub fn convert_to_base_tbsp_test() {
  let parsed = quantity.parse_quantity("2 tbsp")
  let base = quantity.convert_to_base(parsed)
  base |> should.equal(6.0)  // 2 tbsp = 6 tsp
}

// Test aggregation
pub fn aggregate_single_quantity_test() {
  let q1 = quantity.parse_quantity("1 lb")
  let result = quantity.aggregate_quantities([q1])
  result |> should.equal("1 lb")
}

pub fn aggregate_weight_quantities_test() {
  let q1 = quantity.parse_quantity("1 lb")
  let q2 = quantity.parse_quantity("8 oz")
  let result = quantity.aggregate_quantities([q1, q2])
  result |> should.equal("1 lb 8 oz")
}

pub fn aggregate_volume_quantities_test() {
  let q1 = quantity.parse_quantity("1 cup")
  let q2 = quantity.parse_quantity("2 tbsp")
  let result = quantity.aggregate_quantities([q1, q2])
  // 1 cup = 48 tsp, 2 tbsp = 6 tsp, total = 54 tsp = 1.1 cups
  result |> should.equal("1.1 cups")
}

pub fn aggregate_count_quantities_test() {
  let q1 = quantity.parse_quantity("2")
  let q2 = quantity.parse_quantity("3")
  let result = quantity.aggregate_quantities([q1, q2])
  result |> should.equal("5")
}
