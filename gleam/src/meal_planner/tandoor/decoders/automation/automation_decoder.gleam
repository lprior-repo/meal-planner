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
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use automation_type <- decode.field("type", automation_type_decoder())
  use param_1 <- decode.field("param_1", decode.string)
  use param_2 <- decode.field("param_2", decode.string)
  use param_3 <- decode.field("param_3", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use disabled <- decode.field("disabled", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Automation(
    id: id,
    name: name,
    description: description,
    automation_type: automation_type,
    param_1: param_1,
    param_2: param_2,
    param_3: param_3,
    order: order,
    disabled: disabled,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
