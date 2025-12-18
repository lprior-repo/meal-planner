/// Tandoor SDK - Recipe Ingredient Type
///
/// Represents an ingredient used in a recipe with food, unit, and amount.
/// Based on the Tandoor API Ingredient schema (API 2.3.6).
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import meal_planner/tandoor/types/food/food.{type Food}
import meal_planner/tandoor/types/unit/unit.{type Unit}

// Type aliases for foreign key references
pub type FoodId =
  Int

pub type UnitId =
  Int

/// An ingredient in a recipe with food, amount, and units
///
/// Represents a single ingredient entry with full details including
/// the food item, measurement unit, quantity, and additional notes.
///
/// ## Fields
/// - `id`: Unique identifier for the ingredient
/// - `food`: The food item (nullable - can be null for custom/unknown foods)
/// - `unit`: The measurement unit (nullable - can be null for dimensionless amounts)
/// - `amount`: Quantity of the ingredient
/// - `note`: Additional notes or preparation instructions (max 256 chars)
/// - `order`: Display order in the recipe (lower = earlier)
/// - `is_header`: If true, display as section header (e.g., "For the sauce:")
/// - `no_amount`: If true, amount is not specified (e.g., "Salt to taste")
/// - `original_text`: Original text as parsed/entered (max 512 chars)
/// - `conversions`: Unit conversion options for this ingredient (readonly)
/// - `used_in_recipes`: Recipes using this food as an ingredient (readonly)
/// - `always_use_plural_unit`: Whether to always pluralize the unit
/// - `always_use_plural_food`: Whether to always pluralize the food name
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
    conversions: List(Dynamic),
    used_in_recipes: List(Dynamic),
    always_use_plural_unit: Bool,
    always_use_plural_food: Bool,
  )
}
