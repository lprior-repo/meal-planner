/// Tandoor SDK - Recipe Book Type
///
/// Represents a collection of recipes organized by user.
/// Recipe books allow grouping recipes beyond keywords for better organization.
/// Based on the Tandoor API RecipeBook schema.
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import meal_planner/tandoor/types/mealplan/user.{type User}

// Type alias for recipe book ID references
pub type RecipeBookId =
  Int

/// A recipe book for organizing and categorizing recipes
///
/// Represents a collection that can group recipes for easier management
/// and organization. Recipe books can be shared with other users.
///
/// ## Fields
/// - `id`: Unique identifier for the recipe book
/// - `name`: Display name of the recipe book (max 128 chars)
/// - `description`: Detailed description of the recipe book's purpose
/// - `shared`: List of users who have access to this recipe book
/// - `created_by`: User who created this recipe book (readonly)
/// - `filter`: Optional custom filter for automatically including recipes (nullable)
pub type RecipeBook {
  RecipeBook(
    id: Int,
    name: String,
    description: String,
    shared: List(User),
    created_by: User,
    filter: Option(Dynamic),
  )
}
