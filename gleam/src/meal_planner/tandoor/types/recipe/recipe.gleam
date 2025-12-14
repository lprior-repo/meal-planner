import gleam/option.{type Option}

/// Complete recipe type with full metadata
/// Used for detailed recipe views and full recipe data operations
pub type Recipe {
  Recipe(
    /// Tandoor recipe ID
    id: Int,
    /// Recipe name
    name: String,
    /// Recipe description
    description: String,
    /// Optional recipe image URL
    image: Option(String),
    /// Number of servings
    servings: Int,
    /// List of keyword/tag names
    keywords: List(String),
    /// Working/prep time in minutes
    working_time: Int,
    /// Waiting/cooking time in minutes
    waiting_time: Int,
    /// Optional external source URL
    source_url: Option(String),
    /// Whether this is an internal recipe (not from external source)
    internal: Bool,
    /// Optional nutrition information (format TBD)
    nutrition: Option(String),
    /// List of step instructions
    steps: List(String),
    /// User ID who created the recipe
    created_by: Int,
    /// Creation timestamp (ISO 8601 format)
    created_at: String,
    /// Last update timestamp (ISO 8601 format)
    updated_at: String,
  )
}
