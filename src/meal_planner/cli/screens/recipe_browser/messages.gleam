/// Recipe Browser Messages - Events and Effects
///
/// This module contains all message types and effects for the Recipe Browser screen.
/// Following Shore Framework (Elm Architecture) MVC pattern.
///
/// TYPES:
/// - RecipeMsg: All possible user and system events
/// - RecipeEffect: Side effects to execute
import gleam/option.{type Option}
import meal_planner/cli/screens/recipe_browser/model.{
  type RecipeFilters, type SearchType, type SortOption,
}
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Messages
// ============================================================================

/// Messages for the recipe screen
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
  GotSearchResults(Result(#(List(model.RecipeListItem), Int), String))
  ClearSearch

  // Pagination
  NextPage
  PreviousPage
  GoToPage(page: Int)

  // Recipe Actions
  ViewRecipeDetails(recipe_id: recipe_types.RecipeId)
  GotRecipeDetails(Result(model.RecipeDetails, String))
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

// ============================================================================
// Effects
// ============================================================================

/// Effects for the recipe screen
pub type RecipeEffect {
  NoEffect
  SearchRecipes(
    query: String,
    search_type: SearchType,
    page: Int,
    filters: RecipeFilters,
  )
  FetchRecipeDetails(recipe_id: recipe_types.RecipeId)
  SaveFavorite(recipe_id: recipe_types.RecipeId)
  RemoveFavorite(recipe_id: recipe_types.RecipeId)
  LoadFavorites
  BatchEffects(effects: List(RecipeEffect))
}
