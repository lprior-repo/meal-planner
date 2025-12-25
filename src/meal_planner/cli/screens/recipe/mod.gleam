// Re-export types from model
/// Recipe View Screen - Main Module
///
/// This module re-exports the recipe browser screen components.
/// Implementation delegates to recipe_view for backward compatibility
/// while the refactoring is in progress.
import meal_planner/cli/screens/recipe/messages
import meal_planner/cli/screens/recipe/model
import meal_planner/cli/screens/recipe_view

// Re-export types
pub type PaginationState =
  model.PaginationState

pub type RecipeDetails =
  model.RecipeDetails

pub type RecipeEffect =
  model.RecipeEffect

pub type RecipeFilters =
  model.RecipeFilters

pub type RecipeIngredient =
  model.RecipeIngredient

pub type RecipeDirection =
  model.RecipeDirection

pub type RecipeListItem =
  model.RecipeListItem

pub type RecipeModel =
  model.RecipeModel

pub type RecipeNutrition =
  model.RecipeNutrition

pub type RecipeSearchState =
  model.RecipeSearchState

pub type RecipeViewState =
  model.RecipeViewState

pub type SearchType =
  model.SearchType

pub type SortOption =
  model.SortOption

pub type RecipeMsg =
  messages.RecipeMsg

// Re-export functions
pub const recipe_update = recipe_view.recipe_update

pub const recipe_view = recipe_view.recipe_view

pub const default_filters = model.default_filters

pub const init = model.init
