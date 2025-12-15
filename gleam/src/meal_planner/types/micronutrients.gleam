/// Micronutrient types and operations
///
/// Handles vitamins, minerals, fiber, sugar, sodium tracking.
/// All values are optional as not all foods have complete micronutrient data.
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

/// Micronutrient values (vitamins and minerals)
/// All fields are optional as not all foods have complete micronutrient data
pub type Micronutrients {
  Micronutrients(
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    vitamin_d: Option(Float),
    vitamin_e: Option(Float),
    vitamin_k: Option(Float),
    vitamin_b6: Option(Float),
    vitamin_b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}

/// MicronutrientGoals - same structure as Micronutrients but used for targets/goals
/// All fields are optional to allow users to set only the goals they care about
pub type MicronutrientGoals =
  Micronutrients

/// FDA Recommended Daily Allowance (RDA) values for adult males
/// Based on FDA nutrition labeling guidelines
/// Units: fiber(g), sugar(g), sodium(mg), cholesterol(mg), vitamins(mcg/mg), minerals(mg)
pub fn fda_rda_defaults() -> MicronutrientGoals {
  Micronutrients(
    fiber: Some(28.0),
    // Dietary fiber (g)
    sugar: Some(50.0),
    // Added sugars daily limit (g)
    sodium: Some(2300.0),
    // Sodium daily limit (mg)
    cholesterol: Some(300.0),
    // Cholesterol daily limit (mg)
    vitamin_a: Some(900.0),
    // Vitamin A (mcg RAE)
    vitamin_c: Some(90.0),
    // Vitamin C (mg)
    vitamin_d: Some(20.0),
    // Vitamin D (mcg)
    vitamin_e: Some(15.0),
    // Vitamin E (mg alpha-tocopherol)
    vitamin_k: Some(120.0),
    // Vitamin K (mcg)
    vitamin_b6: Some(1.7),
    // Vitamin B6 (mg)
    vitamin_b12: Some(2.4),
    // Vitamin B12 (mcg)
    folate: Some(400.0),
    // Folate (mcg DFE)
    thiamin: Some(1.2),
    // Thiamin/B1 (mg)
    riboflavin: Some(1.3),
    // Riboflavin/B2 (mg)
    niacin: Some(16.0),
    // Niacin/B3 (mg)
    calcium: Some(1000.0),
    // Calcium (mg)
    iron: Some(8.0),
    // Iron (mg)
    magnesium: Some(420.0),
    // Magnesium (mg)
    phosphorus: Some(700.0),
    // Phosphorus (mg)
    potassium: Some(3400.0),
    // Potassium (mg)
    zinc: Some(11.0),
  )
}

/// Empty micronutrients (all None)
pub fn zero() -> Micronutrients {
  Micronutrients(
    fiber: None,
    sugar: None,
    sodium: None,
    cholesterol: None,
    vitamin_a: None,
    vitamin_c: None,
    vitamin_d: None,
    vitamin_e: None,
    vitamin_k: None,
    vitamin_b6: None,
    vitamin_b12: None,
    folate: None,
    thiamin: None,
    riboflavin: None,
    niacin: None,
    calcium: None,
    iron: None,
    magnesium: None,
    phosphorus: None,
    potassium: None,
    zinc: None,
  )
}

/// Add two Micronutrients together
pub fn add(a: Micronutrients, b: Micronutrients) -> Micronutrients {
  Micronutrients(
    fiber: add_optional(a.fiber, b.fiber),
    sugar: add_optional(a.sugar, b.sugar),
    sodium: add_optional(a.sodium, b.sodium),
    cholesterol: add_optional(a.cholesterol, b.cholesterol),
    vitamin_a: add_optional(a.vitamin_a, b.vitamin_a),
    vitamin_c: add_optional(a.vitamin_c, b.vitamin_c),
    vitamin_d: add_optional(a.vitamin_d, b.vitamin_d),
    vitamin_e: add_optional(a.vitamin_e, b.vitamin_e),
    vitamin_k: add_optional(a.vitamin_k, b.vitamin_k),
    vitamin_b6: add_optional(a.vitamin_b6, b.vitamin_b6),
    vitamin_b12: add_optional(a.vitamin_b12, b.vitamin_b12),
    folate: add_optional(a.folate, b.folate),
    thiamin: add_optional(a.thiamin, b.thiamin),
    riboflavin: add_optional(a.riboflavin, b.riboflavin),
    niacin: add_optional(a.niacin, b.niacin),
    calcium: add_optional(a.calcium, b.calcium),
    iron: add_optional(a.iron, b.iron),
    magnesium: add_optional(a.magnesium, b.magnesium),
    phosphorus: add_optional(a.phosphorus, b.phosphorus),
    potassium: add_optional(a.potassium, b.potassium),
    zinc: add_optional(a.zinc, b.zinc),
  )
}

/// Scale micronutrients by a factor
pub fn scale(m: Micronutrients, factor: Float) -> Micronutrients {
  Micronutrients(
    fiber: scale_optional(m.fiber, factor),
    sugar: scale_optional(m.sugar, factor),
    sodium: scale_optional(m.sodium, factor),
    cholesterol: scale_optional(m.cholesterol, factor),
    vitamin_a: scale_optional(m.vitamin_a, factor),
    vitamin_c: scale_optional(m.vitamin_c, factor),
    vitamin_d: scale_optional(m.vitamin_d, factor),
    vitamin_e: scale_optional(m.vitamin_e, factor),
    vitamin_k: scale_optional(m.vitamin_k, factor),
    vitamin_b6: scale_optional(m.vitamin_b6, factor),
    vitamin_b12: scale_optional(m.vitamin_b12, factor),
    folate: scale_optional(m.folate, factor),
    thiamin: scale_optional(m.thiamin, factor),
    riboflavin: scale_optional(m.riboflavin, factor),
    niacin: scale_optional(m.niacin, factor),
    calcium: scale_optional(m.calcium, factor),
    iron: scale_optional(m.iron, factor),
    magnesium: scale_optional(m.magnesium, factor),
    phosphorus: scale_optional(m.phosphorus, factor),
    potassium: scale_optional(m.potassium, factor),
    zinc: scale_optional(m.zinc, factor),
  )
}

/// Sum a list of micronutrients
pub fn sum(micros: List(Micronutrients)) -> Micronutrients {
  list.fold(micros, zero(), add)
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn to_json(m: Micronutrients) -> Json {
  let optional_float = fn(opt) {
    case opt {
      Some(v) -> json.float(v)
      None -> json.null()
    }
  }

  json.object([
    #("fiber", optional_float(m.fiber)),
    #("sugar", optional_float(m.sugar)),
    #("sodium", optional_float(m.sodium)),
    #("cholesterol", optional_float(m.cholesterol)),
    #("vitamin_a", optional_float(m.vitamin_a)),
    #("vitamin_c", optional_float(m.vitamin_c)),
    #("vitamin_d", optional_float(m.vitamin_d)),
    #("vitamin_e", optional_float(m.vitamin_e)),
    #("vitamin_k", optional_float(m.vitamin_k)),
    #("vitamin_b6", optional_float(m.vitamin_b6)),
    #("vitamin_b12", optional_float(m.vitamin_b12)),
    #("folate", optional_float(m.folate)),
    #("thiamin", optional_float(m.thiamin)),
    #("riboflavin", optional_float(m.riboflavin)),
    #("niacin", optional_float(m.niacin)),
    #("calcium", optional_float(m.calcium)),
    #("iron", optional_float(m.iron)),
    #("magnesium", optional_float(m.magnesium)),
    #("phosphorus", optional_float(m.phosphorus)),
    #("potassium", optional_float(m.potassium)),
    #("zinc", optional_float(m.zinc)),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

pub fn decoder() -> Decoder(Micronutrients) {
  use fiber <- decode.optional_field(
    "fiber",
    None,
    decode.optional(decode.float),
  )
  use sugar <- decode.optional_field(
    "sugar",
    None,
    decode.optional(decode.float),
  )
  use sodium <- decode.optional_field(
    "sodium",
    None,
    decode.optional(decode.float),
  )
  use cholesterol <- decode.optional_field(
    "cholesterol",
    None,
    decode.optional(decode.float),
  )
  use vitamin_a <- decode.optional_field(
    "vitamin_a",
    None,
    decode.optional(decode.float),
  )
  use vitamin_c <- decode.optional_field(
    "vitamin_c",
    None,
    decode.optional(decode.float),
  )
  use vitamin_d <- decode.optional_field(
    "vitamin_d",
    None,
    decode.optional(decode.float),
  )
  use vitamin_e <- decode.optional_field(
    "vitamin_e",
    None,
    decode.optional(decode.float),
  )
  use vitamin_k <- decode.optional_field(
    "vitamin_k",
    None,
    decode.optional(decode.float),
  )
  use vitamin_b6 <- decode.optional_field(
    "vitamin_b6",
    None,
    decode.optional(decode.float),
  )
  use vitamin_b12 <- decode.optional_field(
    "vitamin_b12",
    None,
    decode.optional(decode.float),
  )
  use folate <- decode.optional_field(
    "folate",
    None,
    decode.optional(decode.float),
  )
  use thiamin <- decode.optional_field(
    "thiamin",
    None,
    decode.optional(decode.float),
  )
  use riboflavin <- decode.optional_field(
    "riboflavin",
    None,
    decode.optional(decode.float),
  )
  use niacin <- decode.optional_field(
    "niacin",
    None,
    decode.optional(decode.float),
  )
  use calcium <- decode.optional_field(
    "calcium",
    None,
    decode.optional(decode.float),
  )
  use iron <- decode.optional_field("iron", None, decode.optional(decode.float))
  use magnesium <- decode.optional_field(
    "magnesium",
    None,
    decode.optional(decode.float),
  )
  use phosphorus <- decode.optional_field(
    "phosphorus",
    None,
    decode.optional(decode.float),
  )
  use potassium <- decode.optional_field(
    "potassium",
    None,
    decode.optional(decode.float),
  )
  use zinc <- decode.optional_field("zinc", None, decode.optional(decode.float))
  decode.success(Micronutrients(
    fiber: fiber,
    sugar: sugar,
    sodium: sodium,
    cholesterol: cholesterol,
    vitamin_a: vitamin_a,
    vitamin_c: vitamin_c,
    vitamin_d: vitamin_d,
    vitamin_e: vitamin_e,
    vitamin_k: vitamin_k,
    vitamin_b6: vitamin_b6,
    vitamin_b12: vitamin_b12,
    folate: folate,
    thiamin: thiamin,
    riboflavin: riboflavin,
    niacin: niacin,
    calcium: calcium,
    iron: iron,
    magnesium: magnesium,
    phosphorus: phosphorus,
    potassium: potassium,
    zinc: zinc,
  ))
}

// ============================================================================
// Helper Functions
// ============================================================================

fn add_optional(a: Option(Float), b: Option(Float)) -> Option(Float) {
  case a, b {
    Some(x), Some(y) -> Some(x +. y)
    Some(x), None -> Some(x)
    None, Some(y) -> Some(y)
    None, None -> None
  }
}

fn scale_optional(v: Option(Float), factor: Float) -> Option(Float) {
  case v {
    Some(x) -> Some(x *. factor)
    None -> None
  }
}
