/// Custom food types and operations
///
/// User-defined foods with complete nutritional information.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, Some}
import meal_planner/id.{type CustomFoodId, type UserId}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/micronutrients.{type Micronutrients}

/// User-defined custom food with complete nutritional information
pub type CustomFood {
  CustomFood(
    id: CustomFoodId,
    user_id: UserId,
    name: String,
    brand: Option(String),
    description: Option(String),
    serving_size: Float,
    serving_unit: String,
    macros: Macros,
    calories: Float,
    micronutrients: Option(Micronutrients),
  )
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn to_json(f: CustomFood) -> Json {
  let fields = [
    #("id", id.custom_food_id_to_json(f.id)),
    #("user_id", id.user_id_to_json(f.user_id)),
    #("name", json.string(f.name)),
    #("serving_size", json.float(f.serving_size)),
    #("serving_unit", json.string(f.serving_unit)),
    #("macros", macros.to_json(f.macros)),
    #("calories", json.float(f.calories)),
  ]

  let fields = case f.brand {
    Some(brand) -> [#("brand", json.string(brand)), ..fields]
    option.None -> fields
  }

  let fields = case f.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    option.None -> fields
  }

  let fields = case f.micronutrients {
    Some(micros) -> [
      #("micronutrients", micronutrients.to_json(micros)),
      ..fields
    ]
    option.None -> fields
  }

  json.object(fields)
}

// ============================================================================
// JSON Deserialization
// ============================================================================

pub fn decoder() -> Decoder(CustomFood) {
  use food_id <- decode.field("id", id.custom_food_id_decoder())
  use user_id <- decode.field("user_id", id.user_id_decoder())
  use name <- decode.field("name", decode.string)
  use brand <- decode.field("brand", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use serving_size <- decode.field("serving_size", decode.float)
  use serving_unit <- decode.field("serving_unit", decode.string)
  use macros_val <- decode.field("macros", macros.decoder())
  use calories <- decode.field("calories", decode.float)
  use micronutrients <- decode.field(
    "micronutrients",
    decode.optional(micronutrients.decoder()),
  )
  decode.success(CustomFood(
    id: food_id,
    user_id: user_id,
    name: name,
    brand: brand,
    description: description,
    serving_size: serving_size,
    serving_unit: serving_unit,
    macros: macros_val,
    calories: calories,
    micronutrients: micronutrients,
  ))
}
