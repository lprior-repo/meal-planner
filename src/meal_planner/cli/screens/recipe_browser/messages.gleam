/// Recipe Browser Messages - All possible events
///
/// This module contains all message types for the recipe browser screen
/// following the Elm/Shore architecture pattern.
import gleam/option.{type Option}
import meal_planner/cli/screens/recipe_browser/model.{
  type RecipeDetails, type RecipeListItem, type SearchType, type SortOption,
}
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Message Types
// ============================================================================

/// Messages for the recipe browser screen
pub type RecipeMsg {
  // Navigation
  ShowListView
  ShowDetailView(recipe_id: recipe_types.RecipeId)
  ShowFilterView
  ShowFavoritesView
  ShowDirectionsView
  ShowNutritionView
  ShowSearchPopup
  GoBack

  // Search
  SearchQueryChanged(query: String)
  SearchTypeChanged(search_type: SearchType)
  SearchStarted
  GotSearchResults(Result(#(List(RecipeListItem), Int), String))
  ClearSearch

  // Pagination
  NextPage
  PreviousPage
  GoToPage(page: Int)

  // Recipe Actions
  ViewRecipeDetails(recipe_id: recipe_types.RecipeId)
  GotRecipeDetails(Result(RecipeDetails, String))
  ToggleFavorite(recipe_id: recipe_types.RecipeId)
  AddToMealPlan(recipe_id: recipe_types.RecipeId)

  // Filters
  SetMaxCalories(calories: Option(Int))
  SetMaxPrepTime(minutes: Option(Int))
  SetMinProtein(grams: Option(Int))
  SetCuisineType(cuisine: Option(String))
  SetDietType(diet: Option(String))
  SetSortBy(sort: SortOption)
  ApplyFilters
  ClearFilters

  // UI
  ClearError
  KeyPressed(key: String)
  Refresh
  NoOp
}

/// Effects for the recipe browser screen
pub type RecipeEffect {
  NoEffect
  SearchRecipes(
    query: String,
    search_type: SearchType,
    page: Int,
    filters: model.RecipeFilters,
  )
  FetchRecipeDetails(recipe_id: recipe_types.RecipeId)
  SaveFavorite(recipe_id: recipe_types.RecipeId)
  RemoveFavorite(recipe_id: recipe_types.RecipeId)
  LoadFavorites
  BatchEffects(effects: List(RecipeEffect))
}
