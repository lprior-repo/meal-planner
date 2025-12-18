import gleam/option.{type Option}
import meal_planner/tandoor/types/keyword/keyword_label.{type KeywordLabel}
import meal_planner/tandoor/types/mealplan/user.{type User}

/// Recipe overview type for list responses
/// Contains a subset of recipe data optimized for pagination and list views
/// Lighter than full Recipe type, suitable for API list endpoints
///
/// Aligned with Tandoor API 2.3.6 specification.
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
    /// List of keyword/tag labels (lightweight keyword references)
    keywords: List(KeywordLabel),
    /// Optional user rating (0.0 - 5.0)
    rating: Option(Float),
    /// Optional last cooked date (ISO 8601 format)
    last_cooked: Option(String),
    /// Time to prepare recipe in minutes (readonly)
    working_time: Int,
    /// Time to wait (cooling, marinating, etc.) in minutes (readonly)
    waiting_time: Int,
    /// User who created this recipe (readonly)
    created_by: User,
    /// Creation timestamp in ISO 8601 format (readonly)
    created_at: String,
    /// Last update timestamp in ISO 8601 format (readonly)
    updated_at: String,
    /// Whether recipe is internal/system recipe (readonly)
    internal: Bool,
    /// Whether recipe is private to the user
    private: Bool,
    /// Default number of servings (readonly)
    servings: Int,
    /// Human-readable servings text (readonly)
    servings_text: String,
  )
}
