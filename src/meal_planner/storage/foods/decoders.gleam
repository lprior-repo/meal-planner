/// Database result decoders for food storage
import gleam/dynamic/decode
import meal_planner/id
import meal_planner/types/custom_food.{type CustomFood, CustomFood}
import meal_planner/types/macros.{Macros}
import meal_planner/utils/micronutrients as micro_utils

/// Decoder for CustomFood from database result row
pub fn custom_food_decoder() -> decode.Decoder(CustomFood) {
  use custom_food_id_str <- decode.field(0, decode.string)
  use user_id_str <- decode.field(1, decode.string)
  use name <- decode.field(2, decode.string)
  use brand <- decode.field(3, decode.optional(decode.string))
  use description <- decode.field(4, decode.optional(decode.string))
  use serving_size <- decode.field(5, decode.float)
  use serving_unit <- decode.field(6, decode.string)
  use protein <- decode.field(7, decode.float)
  use fat <- decode.field(8, decode.float)
  use carbs <- decode.field(9, decode.float)
  use calories <- decode.field(10, decode.float)
  use fiber <- decode.field(11, decode.optional(decode.float))
  use sugar <- decode.field(12, decode.optional(decode.float))
  use sodium <- decode.field(13, decode.optional(decode.float))
  use cholesterol <- decode.field(14, decode.optional(decode.float))
  use vitamin_a <- decode.field(15, decode.optional(decode.float))
  use vitamin_c <- decode.field(16, decode.optional(decode.float))
  use vitamin_d <- decode.field(17, decode.optional(decode.float))
  use vitamin_e <- decode.field(18, decode.optional(decode.float))
  use vitamin_k <- decode.field(19, decode.optional(decode.float))
  use vitamin_b6 <- decode.field(20, decode.optional(decode.float))
  use vitamin_b12 <- decode.field(21, decode.optional(decode.float))
  use folate <- decode.field(22, decode.optional(decode.float))
  use thiamin <- decode.field(23, decode.optional(decode.float))
  use riboflavin <- decode.field(24, decode.optional(decode.float))
  use niacin <- decode.field(25, decode.optional(decode.float))
  use calcium <- decode.field(26, decode.optional(decode.float))
  use iron <- decode.field(27, decode.optional(decode.float))
  use magnesium <- decode.field(28, decode.optional(decode.float))
  use phosphorus <- decode.field(29, decode.optional(decode.float))
  use potassium <- decode.field(30, decode.optional(decode.float))
  use zinc <- decode.field(31, decode.optional(decode.float))

  let micronutrients =
    micro_utils.build_micronutrients(
      fiber,
      sugar,
      sodium,
      cholesterol,
      vitamin_a,
      vitamin_c,
      vitamin_d,
      vitamin_e,
      vitamin_k,
      vitamin_b6,
      vitamin_b12,
      folate,
      thiamin,
      riboflavin,
      niacin,
      calcium,
      iron,
      magnesium,
      phosphorus,
      potassium,
      zinc,
    )

  decode.success(CustomFood(
    id: id.custom_food_id(custom_food_id_str),
    user_id: id.user_id(user_id_str),
    name: name,
    brand: brand,
    description: description,
    serving_size: serving_size,
    serving_unit: serving_unit,
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    calories: calories,
    micronutrients: micronutrients,
  ))
}
