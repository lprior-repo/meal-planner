// Shared Tandoor module types to break circular imports
// This module contains types that are referenced by multiple modules in the tandoor package
// to avoid circular import cycles between food, ingredient, client, and supermarket modules

import gleam/dynamic/decode
import gleam/option.{type Option, None}

// SupermarketCategory type definition
pub type SupermarketCategory {
  SupermarketCategory(
    id: Int,
    name: String,
    description: Option(String),
    open_data_slug: Option(String),
  )
}

// Nutrition facts type
pub type NutritionFacts {
  NutritionFacts(calories: Float, protein: Float, carbs: Float, fat: Float)
}

// ============================================================================
// Decoder Functions
// ============================================================================

/// Decode a SupermarketCategory from JSON
pub fn supermarket_category_decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use open_data_slug <- decode.optional_field(
    "open_data_slug",
    None,
    decode.optional(decode.string),
  )

  decode.success(SupermarketCategory(
    id: id,
    name: name,
    description: description,
    open_data_slug: open_data_slug,
  ))
}

/// Decode a NutritionFacts from JSON
pub fn nutrition_facts_decoder() -> decode.Decoder(NutritionFacts) {
  use calories <- decode.field("calories", decode.float)
  use protein <- decode.field("protein", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  use fat <- decode.field("fat", decode.float)

  decode.success(NutritionFacts(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  ))
}
