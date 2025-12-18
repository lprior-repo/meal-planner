import gleam/option.{type Option}

/// Minimal recipe type for embedded references
/// Used when a recipe is referenced from other entities (e.g., in meal plans)
pub type RecipeSimple {
  RecipeSimple(
    /// Tandoor recipe ID
    id: Int,
    /// Recipe name
    name: String,
    /// Optional recipe image URL
    image: Option(String),
  )
}
