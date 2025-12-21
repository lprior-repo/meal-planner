import gleam/option.{type Option}
import meal_planner/tandoor/client.{type NutritionInfo}
import meal_planner/tandoor/keyword.{type Keyword}
import meal_planner/tandoor/property.{type Property}
import meal_planner/tandoor/step.{type Step}
import meal_planner/tandoor/user.{type User}

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
    /// Human-readable servings text (e.g., "4 servings")
    servings_text: String,
    /// List of keyword/tag objects
    keywords: List(Keyword),
    /// Working/prep time in minutes
    working_time: Int,
    /// Waiting/cooking time in minutes
    waiting_time: Int,
    /// Optional external source URL
    source_url: Option(String),
    /// Whether this is an internal recipe (not from external source)
    internal: Bool,
    /// Full nutrition information object
    nutrition: Option(NutritionInfo),
    /// List of cooking step objects
    steps: List(Step),
    /// User who created the recipe
    created_by: User,
    /// Whether ingredient overview is shown
    show_ingredient_overview: Bool,
    /// File path for recipe resources
    file_path: String,
    /// Whether recipe is private
    private: Bool,
    /// List of custom properties for this recipe
    properties: List(Property),
    /// Food properties (readonly)
    food_properties: List(Property),
    /// Recipe rating (readonly)
    rating: Option(Float),
    /// Last date this recipe was cooked (readonly)
    last_cooked: Option(String),
    /// List of users this recipe is shared with
    shared: List(User),
    /// Creation timestamp (ISO 8601 format)
    created_at: String,
    /// Last update timestamp (ISO 8601 format)
    updated_at: String,
  )
}
