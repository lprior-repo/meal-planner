import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type FoodId}
import meal_planner/tandoor/types/food/food_simple.{type FoodSimple}

/// Complete food type with full metadata
/// Used for detailed food views and full food data operations
///
/// Note: This is a simplified version focusing on core fields.
/// Additional fields from the Tandoor API (url, properties, fdc_id, etc.)
/// can be added as needed.
pub type Food {
  Food(
    /// Tandoor food ID
    id: FoodId,
    /// Food name
    name: String,
    /// Optional plural form of the food name
    plural_name: Option(String),
    /// Food description
    description: String,
    /// Optional associated recipe (for recipe-based foods)
    recipe: Option(FoodSimple),
    /// Whether food is on hand (in inventory)
    food_onhand: Option(Bool),
    /// Optional supermarket category reference
    /// Future: Can be expanded to full SupermarketCategory type
    supermarket_category: Option(Int),
    /// Whether to ignore this food in shopping lists
    ignore_shopping: Bool,
  )
}
