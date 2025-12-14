/// Tandoor SDK - Recipe Ingredient Type
///
/// Represents an ingredient used in a recipe with food, unit, and amount.
/// Based on the Tandoor API Ingredient schema.
import gleam/option.{type Option}

// Placeholder types for related entities (will be defined by other agents)
pub type FoodId =
  Int

pub type UnitId =
  Int

pub type Food {
  Food(id: Int, name: String)
}

pub type Unit {
  Unit(id: Int, name: String, abbreviation: String)
}

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
