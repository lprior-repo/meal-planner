/// Recipe Browser Model - State types and initialization
///
/// This module contains all the state types for the recipe browser screen
/// following the Elm/Shore architecture pattern.
import gleam/dict.{type Dict}
import gleam/option.{type Option, None}
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Model Types
// ============================================================================

/// Root state for the Recipe Browser TUI screen
pub type RecipeModel {
  RecipeModel(
    /// Current view state
    view_state: RecipeViewState,
    /// Search/browse results
    recipes: List(RecipeListItem),
    /// Currently selected recipe details
    selected_recipe: Option(RecipeDetails),
    /// Search state
    search_state: RecipeSearchState,
    /// Pagination state
    pagination: PaginationState,
    /// Loading state
    is_loading: Bool,
    /// Error message
    error_message: Option(String),
    /// Favorite recipe IDs
    favorites: List(String),
    /// Cache for recipe details
    recipe_cache: Dict(String, RecipeDetails),
    /// Filter settings
    filters: RecipeFilters,
    /// Recently viewed recipes
    recent_recipes: List(RecipeListItem),
  )
}

/// View state machine
pub type RecipeViewState {
  /// Recipe list/search view
  ListView
  /// Single recipe detail view
  DetailView
  /// Filter settings view
  FilterView
  /// Favorites list view
  FavoritesView
  /// Recipe directions/steps view
  DirectionsView
  /// Recipe nutrition view
  NutritionView
  /// Search popup
  SearchPopup
}

/// Recipe list item for browse/search results
pub type RecipeListItem {
  RecipeListItem(
    recipe_id: recipe_types.RecipeId,
    recipe_name: String,
    recipe_description: String,
    calories_per_serving: Option(Float),
    cooking_time_min: Option(Int),
    number_of_servings: Float,
    is_favorite: Bool,
    rating: Option(Float),
  )
}

/// Full recipe details
pub type RecipeDetails {
  RecipeDetails(
    /// Basic info
    recipe_id: recipe_types.RecipeId,
    recipe_name: String,
    recipe_description: String,
    recipe_url: String,
    /// Servings and prep
    number_of_servings: Float,
    preparation_time_min: Option(Int),
    cooking_time_min: Option(Int),
    /// Ingredients
    ingredients: List(RecipeIngredient),
    /// Directions
    directions: List(RecipeDirection),
    /// Categories
    categories: List(String),
    /// Nutrition per serving
    nutrition: RecipeNutrition,
    /// Rating info
    rating: Option(Float),
    rating_count: Option(Int),
  )
}

/// Recipe ingredient
pub type RecipeIngredient {
  RecipeIngredient(
    food_id: String,
    food_name: String,
    serving_id: String,
    number_of_units: Float,
    measurement_description: String,
    ingredient_description: String,
    ingredient_url: String,
  )
}

/// Recipe direction/step
pub type RecipeDirection {
  RecipeDirection(direction_number: Int, direction_description: String)
}

/// Recipe nutrition per serving
pub type RecipeNutrition {
  RecipeNutrition(
    calories: Float,
    carbohydrate: Float,
    protein: Float,
    fat: Float,
    fiber: Option(Float),
    sugar: Option(Float),
    saturated_fat: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
  )
}

/// Search state for recipe search
pub type RecipeSearchState {
  RecipeSearchState(
    query: String,
    search_type: SearchType,
    is_loading: Bool,
    error: Option(String),
  )
}

/// Type of search to perform
pub type SearchType {
  /// Search by recipe name
  ByName
  /// Search by ingredient
  ByIngredient
  /// Search by cuisine type
  ByCuisine
}

/// Pagination state
pub type PaginationState {
  PaginationState(
    current_page: Int,
    total_results: Int,
    results_per_page: Int,
    total_pages: Int,
  )
}

/// Recipe filter settings
pub type RecipeFilters {
  RecipeFilters(
    max_calories: Option(Int),
    max_prep_time: Option(Int),
    min_protein: Option(Int),
    cuisine_type: Option(String),
    diet_type: Option(String),
    sort_by: SortOption,
  )
}

/// Sort options for recipe list
pub type SortOption {
  SortByName
  SortByCalories
  SortByPrepTime
  SortByRating
  SortByRecent
}

/// Effects for the recipe browser screen
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

// ============================================================================
// Initialization
// ============================================================================

/// Create initial RecipeModel
pub fn init() -> RecipeModel {
  RecipeModel(
    view_state: ListView,
    recipes: [],
    selected_recipe: None,
    search_state: init_search_state(),
    pagination: PaginationState(
      current_page: 1,
      total_results: 0,
      results_per_page: 20,
      total_pages: 0,
    ),
    is_loading: False,
    error_message: None,
    favorites: [],
    recipe_cache: dict.new(),
    filters: default_filters(),
    recent_recipes: [],
  )
}

/// Initialize search state
pub fn init_search_state() -> RecipeSearchState {
  RecipeSearchState(
    query: "",
    search_type: ByName,
    is_loading: False,
    error: None,
  )
}

/// Default filter settings
pub fn default_filters() -> RecipeFilters {
  RecipeFilters(
    max_calories: None,
    max_prep_time: None,
    min_protein: None,
    cuisine_type: None,
    diet_type: None,
    sort_by: SortByName,
  )
}
