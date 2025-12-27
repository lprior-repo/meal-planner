// Shared Tandoor module types to break circular imports
// This module contains types that are referenced by multiple modules in the tandoor package
// to avoid circular import cycles between food, ingredient, client, and supermarket modules

import gleam/dynamic/decode
import gleam/option.{type Option}

// Complete Food type definition (21 fields) - used by both food and ingredient modules
pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    recipe: Option(FoodSimple),
    food_onhand: Option(Bool),
    supermarket_category: Option(SupermarketCategory),
    ignore_shopping: Bool,
    shopping: String,
    url: Option(String),
    properties: Option(List(Property)),
    properties_food_amount: Float,
    properties_food_unit: Option(Unit),
    fdc_id: Option(Int),
    parent: Option(Int),
    numchild: Int,
    inherit_fields: Option(List(FoodInheritField)),
    full_name: String,
  )
}

// Minimal food type for embedded references
pub type FoodSimple {
  FoodSimple(id: Int, name: String, plural_name: Option(String))
}

// Ingredient type definition
pub type Ingredient {
  Ingredient(
    id: Int,
    food: Option(Food),
    unit: Option(Unit),
    amount: Float,
    note: Option(String),
    order: Int,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

// SupermarketCategory type definition
pub type SupermarketCategory {
  SupermarketCategory(id: Int, name: String, parent: Option(Int))
}

// Nutrition facts type
pub type NutritionFacts {
  NutritionFacts(calories: Float, protein: Float, carbs: Float, fat: Float)
}

// Client configuration type
pub type ClientConfig {
  ClientConfig(base_url: String, api_key: String, timeout: Int)
}

// Tandoor-specific error type
pub type TandoorError {
  TandoorError(message: String, code: Int)
}

// ============================================================================
// Decoder Functions
// ============================================================================

/// Decode a SupermarketCategory from JSON
pub fn supermarket_category_decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use parent <- decode.optional_field(
    "parent",
    None,
    decode.optional(decode.int),
  )

  decode.success(SupermarketCategory(id: id, name: name, parent: parent))
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
