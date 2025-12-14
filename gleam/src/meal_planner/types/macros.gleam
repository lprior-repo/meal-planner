/// Macronutrient calculations and operations
///
/// Handles protein, fat, carbohydrate values and calorie calculations.
/// Uses: 4cal/g protein, 9cal/g fat, 4cal/g carbs

import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list

/// Macronutrient values (protein, fat, carbs in grams)
pub type Macros {
  Macros(protein: Float, fat: Float, carbs: Float)
}

/// Calculate total calories from macros
/// Uses: 4cal/g protein, 9cal/g fat, 4cal/g carbs
pub fn calories(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

/// Add two Macros together
pub fn add(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: a.protein +. b.protein,
    fat: a.fat +. b.fat,
    carbs: a.carbs +. b.carbs,
  )
}

/// Subtract two Macros (a - b)
pub fn subtract(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: a.protein -. b.protein,
    fat: a.fat -. b.fat,
    carbs: a.carbs -. b.carbs,
  )
}

/// Scale macros by a factor
pub fn scale(m: Macros, factor: Float) -> Macros {
  Macros(
    protein: m.protein *. factor,
    fat: m.fat *. factor,
    carbs: m.carbs *. factor,
  )
}

/// Empty macros (zero values)
pub fn zero() -> Macros {
  Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
}

/// Sum a list of macros
pub fn sum(macros: List(Macros)) -> Macros {
  list.fold(macros, zero(), add)
}

/// Average a list of macros
/// Returns zero macros if list is empty
pub fn average(macros: List(Macros)) -> Macros {
  let count = list.length(macros)
  case count {
    0 -> zero()
    _ -> {
      let total = sum(macros)
      scale(total, 1.0 /. int_to_float(count))
    }
  }
}

/// Calculate protein as a percentage of total calories (0.0 to 1.0)
pub fn protein_ratio(m: Macros) -> Float {
  let total_cals = calories(m)
  case total_cals >. 0.0 {
    True -> { m.protein *. 4.0 } /. total_cals
    False -> 0.0
  }
}

/// Calculate carbs as a percentage of total calories (0.0 to 1.0)
pub fn carb_ratio(m: Macros) -> Float {
  let total_cals = calories(m)
  case total_cals >. 0.0 {
    True -> { m.carbs *. 4.0 } /. total_cals
    False -> 0.0
  }
}

/// Calculate fat as a percentage of total calories (0.0 to 1.0)
pub fn fat_ratio(m: Macros) -> Float {
  let total_cals = calories(m)
  case total_cals >. 0.0 {
    True -> { m.fat *. 9.0 } /. total_cals
    False -> 0.0
  }
}

/// Check if macros are balanced (30% protein, 30% fat, 40% carbs +/- 10%)
pub fn is_balanced(m: Macros) -> Bool {
  let p_ratio = protein_ratio(m)
  let f_ratio = fat_ratio(m)
  let c_ratio = carb_ratio(m)
  let protein_ok = p_ratio >=. 0.2 && p_ratio <=. 0.4
  let fat_ok = f_ratio >=. 0.2 && f_ratio <=. 0.4
  let carb_ok = c_ratio >=. 0.3 && c_ratio <=. 0.5
  protein_ok && fat_ok && carb_ok
}

/// Check if macros are empty (all zeros)
pub fn is_empty(m: Macros) -> Bool {
  m.protein == 0.0 && m.fat == 0.0 && m.carbs == 0.0
}

/// Check if any macro value is negative
pub fn has_negative_values(m: Macros) -> Bool {
  m.protein <. 0.0 || m.fat <. 0.0 || m.carbs <. 0.0
}

/// Calculate protein calories only
pub fn protein_calories(m: Macros) -> Float {
  m.protein *. 4.0
}

/// Calculate carb calories only
pub fn carb_calories(m: Macros) -> Float {
  m.carbs *. 4.0
}

/// Calculate fat calories only
pub fn fat_calories(m: Macros) -> Float {
  m.fat *. 9.0
}

/// Compare two Macros for approximate equality (0.1g tolerance)
pub fn approximately_equal(a: Macros, b: Macros) -> Bool {
  let tolerance = 0.1
  let protein_close = float_abs(a.protein -. b.protein) <. tolerance
  let fat_close = float_abs(a.fat -. b.fat) <. tolerance
  let carbs_close = float_abs(a.carbs -. b.carbs) <. tolerance
  protein_close && fat_close && carbs_close
}

/// Negate all macro values (useful for calculating deficits)
pub fn negate(m: Macros) -> Macros {
  Macros(protein: 0.0 -. m.protein, fat: 0.0 -. m.fat, carbs: 0.0 -. m.carbs)
}

/// Get absolute values for all macros
pub fn abs(m: Macros) -> Macros {
  Macros(
    protein: float_abs(m.protein),
    fat: float_abs(m.fat),
    carbs: float_abs(m.carbs),
  )
}

/// Get component-wise minimum of two Macros
pub fn min(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: float_min(a.protein, b.protein),
    fat: float_min(a.fat, b.fat),
    carbs: float_min(a.carbs, b.carbs),
  )
}

/// Get component-wise maximum of two Macros
pub fn max(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: float_max(a.protein, b.protein),
    fat: float_max(a.fat, b.fat),
    carbs: float_max(a.carbs, b.carbs),
  )
}

/// Clamp macro values to a minimum and maximum range
pub fn clamp(m: Macros, min_val: Float, max_val: Float) -> Macros {
  Macros(
    protein: float_clamp(m.protein, min_val, max_val),
    fat: float_clamp(m.fat, min_val, max_val),
    carbs: float_clamp(m.carbs, min_val, max_val),
  )
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn to_json(m: Macros) -> Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
    #("calories", json.float(calories(m))),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

import gleam/dynamic/decode.{type Decoder}

pub fn decoder() -> Decoder(Macros) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(Macros(protein: protein, fat: fat, carbs: carbs))
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format macros as a compact string (e.g., "P:40g F:20g C:30g")
pub fn to_string(m: Macros) -> String {
  let p = float_to_int_rounded(m.protein)
  let f = float_to_int_rounded(m.fat)
  let c = float_to_int_rounded(m.carbs)

  "P:"
  <> int.to_string(p)
  <> "g F:"
  <> int.to_string(f)
  <> "g C:"
  <> int.to_string(c)
  <> "g"
}

/// Format macros with calories (e.g., "P:40g F:20g C:30g (200 cal)")
pub fn to_string_with_calories(m: Macros) -> String {
  let cal = float_to_int_rounded(calories(m))
  to_string(m) <> " (" <> int.to_string(cal) <> " cal)"
}

// ============================================================================
// Helper Functions
// ============================================================================

fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

fn float_min(a: Float, b: Float) -> Float {
  case a <. b {
    True -> a
    False -> b
  }
}

fn float_max(a: Float, b: Float) -> Float {
  case a >. b {
    True -> a
    False -> b
  }
}

fn float_clamp(x: Float, min_val: Float, max_val: Float) -> Float {
  case x <. min_val {
    True -> min_val
    False ->
      case x >. max_val {
        True -> max_val
        False -> x
      }
  }
}

fn float_to_int_rounded(f: Float) -> Int {
  float.round(f)
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
