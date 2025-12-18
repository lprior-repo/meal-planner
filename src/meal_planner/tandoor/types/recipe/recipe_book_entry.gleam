/// Tandoor SDK - Recipe Book Entry Type
///
/// Represents an individual recipe within a recipe book.
/// Maps recipes to recipe books for organizing collections.
/// Based on the Tandoor API RecipeBookEntry schema.
import meal_planner/tandoor/recipe.{type RecipeOverview}
import meal_planner/tandoor/types/recipe/recipe_book.{type RecipeBook}

// Type aliases for foreign key references
pub type RecipeBookId =
  Int

pub type RecipeId =
  Int

/// An entry linking a recipe to a recipe book
///
/// Represents the association between a recipe and a recipe book collection.
/// Each entry includes both the IDs and full object representations.
///
/// ## Fields
/// - `id`: Unique identifier for this entry
/// - `book`: ID of the parent recipe book
/// - `book_content`: Full recipe book object (readonly)
/// - `recipe`: ID of the recipe in this collection
/// - `recipe_content`: Full recipe overview object (readonly)
pub type RecipeBookEntry {
  RecipeBookEntry(
    id: Int,
    book: RecipeBookId,
    book_content: RecipeBook,
    recipe: RecipeId,
    recipe_content: RecipeOverview,
  )
}
