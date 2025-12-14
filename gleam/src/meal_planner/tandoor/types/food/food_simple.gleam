import gleam/option.{type Option}

/// Minimal food type for embedded references
/// Used when a food is referenced from other entities (e.g., in ingredients)
pub type FoodSimple {
  FoodSimple(
    /// Tandoor food ID
    id: Int,
    /// Food name
    name: String,
    /// Optional plural form of the food name
    plural_name: Option(String),
  )
}
