/// Automation decoder for Tandoor SDK
///
/// This module provides JSON decoders for Automation types.
/// Handles all automation types: FOOD_ALIAS, UNIT_ALIAS, KEYWORD_ALIAS, DESCRIPTION_REPLACE.
import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/types/automation/automation.{
  type Automation, type AutomationType, Automation, DescriptionReplace, FoodAlias,
  KeywordAlias, UnitAlias,
}

/// Decode AutomationType from JSON string
fn automation_type_decoder() -> decode.Decoder(AutomationType) {
  use type_string <- decode.then(decode.string)
  case type_string {
    "FOOD_ALIAS" -> decode.success(FoodAlias)
    "UNIT_ALIAS" -> decode.success(UnitAlias)
    "KEYWORD_ALIAS" -> decode.success(KeywordAlias)
    "DESCRIPTION_REPLACE" -> decode.success(DescriptionReplace)
    _ ->
      decode.failure(
        FoodAlias,
        "Unknown automation type: " <> type_string,
      )
  }
}

/// Decode Automation from JSON
///
/// # Returns
/// Decoder for Automation type
pub fn automation_decoder() -> decode.Decoder(Automation) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use description <- decode.parameter
    use automation_type <- decode.parameter
    use param_1 <- decode.parameter
    use param_2 <- decode.parameter
    use param_3 <- decode.parameter
    use order <- decode.parameter
    use disabled <- decode.parameter
    use created_at <- decode.parameter
    use updated_at <- decode.parameter

    Automation(
      id:,
      name:,
      description:,
      automation_type:,
      param_1:,
      param_2:,
      param_3:,
      order:,
      disabled:,
      created_at:,
      updated_at:,
    )
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("description", decode.string)
  |> decode.field("type", automation_type_decoder())
  |> decode.field("param_1", decode.string)
  |> decode.field("param_2", decode.string)
  |> decode.field("param_3", decode.optional(decode.string))
  |> decode.field("order", decode.int)
  |> decode.field("disabled", decode.bool)
  |> decode.field("created_at", decode.string)
  |> decode.field("updated_at", decode.string)
}
