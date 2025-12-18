import gleam/option.{type Option}

/// Recipe overview type for list responses
/// Contains a subset of recipe data optimized for pagination and list views
/// Lighter than full Recipe type, suitable for API list endpoints
pub type RecipeOverview {
  RecipeOverview(
    /// Tandoor recipe ID
    id: Int,
    /// Recipe name
    name: String,
    /// Recipe description
    description: String,
    /// Optional recipe image URL
    image: Option(String),
    /// List of keyword/tag names
    keywords: List(String),
    /// Optional user rating (0.0 - 5.0)
    rating: Option(Float),
    /// Optional last cooked date (ISO 8601 format)
    last_cooked: Option(String),
  )
}
