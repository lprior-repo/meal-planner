import gleam/string
import gleam/list
import gleam/float
import gleam/int
import gleam/result
import gleam/dict.{type Dict}

// Unit types for measurement categories
pub type UnitType {
  Weight
  Volume
  Count
  Other
}

// Unit represents a measurement unit with conversion properties
pub type Unit {
  Unit(
    name: String,
    unit_type: UnitType,
    base_value: Float,
    aliases: List(String),
  )
}

// ParsedQuantity represents a parsed quantity with numeric value and unit
pub type ParsedQuantity {
  ParsedQuantity(amount: Float, unit: Unit, raw: String)
}

// Common units with their conversion values
pub fn unit_oz() -> Unit {
  Unit(name: "oz", unit_type: Weight, base_value: 1.0, aliases: [
    "ounce", "ounces",
  ])
}

pub fn unit_lb() -> Unit {
  Unit(name: "lb", unit_type: Weight, base_value: 16.0, aliases: [
    "lbs", "pound", "pounds",
  ])
}

pub fn unit_tsp() -> Unit {
  Unit(name: "tsp", unit_type: Volume, base_value: 1.0, aliases: [
    "teaspoon", "teaspoons",
  ])
}

pub fn unit_tbsp() -> Unit {
  Unit(name: "tbsp", unit_type: Volume, base_value: 3.0, aliases: [
    "tablespoon", "tablespoons",
  ])
}

pub fn unit_cup() -> Unit {
  Unit(name: "cup", unit_type: Volume, base_value: 48.0, aliases: ["cups"])
}

pub fn unit_count() -> Unit {
  Unit(name: "", unit_type: Count, base_value: 1.0, aliases: [])
}

pub fn unit_unknown() -> Unit {
  Unit(name: "", unit_type: Other, base_value: 0.0, aliases: [])
}

// Create lookup map for unit parsing
fn create_unit_lookup() -> Dict(String, Unit) {
  dict.new()
  |> dict.insert("oz", unit_oz())
  |> dict.insert("ounce", unit_oz())
  |> dict.insert("ounces", unit_oz())
  |> dict.insert("lb", unit_lb())
  |> dict.insert("lbs", unit_lb())
  |> dict.insert("pound", unit_lb())
  |> dict.insert("pounds", unit_lb())
  |> dict.insert("tsp", unit_tsp())
  |> dict.insert("teaspoon", unit_tsp())
  |> dict.insert("teaspoons", unit_tsp())
  |> dict.insert("tbsp", unit_tbsp())
  |> dict.insert("tablespoon", unit_tbsp())
  |> dict.insert("tablespoons", unit_tbsp())
  |> dict.insert("cup", unit_cup())
  |> dict.insert("cups", unit_cup())
}

// Parse a number string, handling fractions like "1/2"
fn parse_number(s: String) -> Result(Float, Nil) {
  let trimmed = string.trim(s)

  case string.contains(trimmed, "/") {
    True -> {
      case string.split(trimmed, "/") {
        [num_str, denom_str] -> {
          let num_result = case float.parse(string.trim(num_str)) {
            Ok(n) -> Ok(n)
            Error(_) -> case int.parse(string.trim(num_str)) {
              Ok(n) -> Ok(int.to_float(n))
              Error(_) -> Error(Nil)
            }
          }
          let denom_result = case float.parse(string.trim(denom_str)) {
            Ok(d) -> Ok(d)
            Error(_) -> case int.parse(string.trim(denom_str)) {
              Ok(d) -> Ok(int.to_float(d))
              Error(_) -> Error(Nil)
            }
          }
          case num_result, denom_result {
            Ok(num), Ok(denom) -> {
              case denom == 0.0 {
                True -> Error(Nil)
                False -> Ok(num /. denom)
              }
            }
            _, _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
    False -> {
      case float.parse(trimmed) {
        Ok(val) -> Ok(val)
        Error(_) -> {
          case int.parse(trimmed) {
            Ok(val) -> Ok(int.to_float(val))
            Error(_) -> Error(Nil)
          }
        }
      }
    }
  }
}

// ParseQuantity parses a quantity string like "1 lb", "2.5 cups", "1/2 tsp"
pub fn parse_quantity(s: String) -> ParsedQuantity {
  let trimmed = string.trim(s)

  case trimmed {
    "" -> ParsedQuantity(amount: 0.0, unit: unit_unknown(), raw: s)
    _ -> {
      let parts = string.split(trimmed, " ")

      case parts {
        [] -> ParsedQuantity(amount: 0.0, unit: unit_unknown(), raw: s)
        [num_part] -> {
          case parse_number(num_part) {
            Ok(amount) -> ParsedQuantity(amount: amount, unit: unit_count(), raw: s)
            Error(_) -> ParsedQuantity(amount: 0.0, unit: unit_unknown(), raw: s)
          }
        }
        [num_part, ..rest] -> {
          case parse_number(num_part) {
            Ok(amount) -> {
              let unit_lookup = create_unit_lookup()
              let unit_str = string.lowercase(list.first(rest) |> result.unwrap(""))

              case dict.get(unit_lookup, unit_str) {
                Ok(unit) -> ParsedQuantity(amount: amount, unit: unit, raw: s)
                Error(_) -> ParsedQuantity(amount: amount, unit: unit_unknown(), raw: s)
              }
            }
            Error(_) -> ParsedQuantity(amount: 0.0, unit: unit_unknown(), raw: s)
          }
        }
      }
    }
  }
}

// CanConvert checks if two units can be converted to each other
pub fn can_convert(a: Unit, b: Unit) -> Bool {
  case a.unit_type, b.unit_type {
    Other, _ -> False
    _, Other -> False
    type_a, type_b if type_a == type_b -> True
    _, _ -> False
  }
}

// ConvertToBase converts a quantity to its base unit (oz for weight, tsp for volume)
pub fn convert_to_base(q: ParsedQuantity) -> Float {
  q.amount *. q.unit.base_value
}

// Format a float, removing unnecessary decimals
fn format_float(f: Float) -> String {
  let rounded = int.to_float(float.round(f *. 10.0)) /. 10.0
  let i = float.truncate(rounded)
  case int.to_float(i) == rounded {
    True -> int.to_string(i)
    False -> float.to_string(rounded)
  }
}

// AggregateQuantities combines multiple quantities of the same ingredient
pub fn aggregate_quantities(quantities: List(ParsedQuantity)) -> String {
  case quantities {
    [] -> ""
    [single] -> single.raw
    _ -> {
      // Group by unit type
      let #(weight_total, volume_total, count_total, other_parts) =
        list.fold(quantities, #(0.0, 0.0, 0.0, []), fn(acc, q) {
          let #(w, v, c, o) = acc
          case q.unit.unit_type {
            Weight -> #(w +. convert_to_base(q), v, c, o)
            Volume -> #(w, v +. convert_to_base(q), c, o)
            Count -> #(w, v, c +. q.amount, o)
            Other -> #(w, v, c, [q.raw, ..o])
          }
        })

      let result = []

      // Format weight (prefer lb for >= 16 oz)
      let result = case weight_total >. 0.0 {
        True -> {
          case weight_total >=. 16.0 {
            True -> {
              let lbs = float.truncate(weight_total) / 16
              let oz = weight_total -. int.to_float(lbs * 16)
              case oz >. 0.0 {
                True -> [int.to_string(lbs) <> " lb " <> format_float(oz) <> " oz", ..result]
                False -> [int.to_string(lbs) <> " lb", ..result]
              }
            }
            False -> [format_float(weight_total) <> " oz", ..result]
          }
        }
        False -> result
      }

      // Format volume (prefer cups for >= 48 tsp, tbsp for >= 3 tsp)
      let result = case volume_total >. 0.0 {
        True -> {
          case volume_total >=. 48.0 {
            True -> {
              let cups = volume_total /. 48.0
              [format_float(cups) <> " cups", ..result]
            }
            False -> {
              case volume_total >=. 3.0 {
                True -> {
                  let tbsp = volume_total /. 3.0
                  [format_float(tbsp) <> " tbsp", ..result]
                }
                False -> [format_float(volume_total) <> " tsp", ..result]
              }
            }
          }
        }
        False -> result
      }

      // Format count
      let result = case count_total >. 0.0 {
        True -> [format_float(count_total), ..result]
        False -> result
      }

      // Add other parts that couldn't be parsed
      let result = list.append(result, list.reverse(other_parts))

      string.join(list.reverse(result), " + ")
    }
  }
}
