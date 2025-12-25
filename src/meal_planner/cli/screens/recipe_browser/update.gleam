/// Recipe Browser Update - State Transitions
///
/// This module contains the update function and state transition logic
/// for the Recipe Browser screen. Following Shore Framework (Elm Architecture).
///
/// FUNCTIONS:
/// - recipe_update: Main state transition function
/// - Helper functions for processing state changes
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/cli/screens/recipe_browser/messages.{
  type RecipeEffect, type RecipeMsg,
}
import meal_planner/cli/screens/recipe_browser/model.{
  type RecipeDetails, type RecipeFilters, type RecipeListItem, type RecipeModel,
  type RecipeSearchState, type RecipeViewState,
}
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Update Function
// ============================================================================

/// Main update function for recipe view
pub fn recipe_update(
  model: RecipeModel,
  msg: RecipeMsg,
) -> #(RecipeModel, RecipeEffect) {
  case msg {
    // === Navigation ===
    messages.ShowListView -> {
      let updated = model.RecipeModel(..model, view_state: model.ListView)
      #(updated, messages.NoEffect)
    }

    messages.ShowDetailView(recipe_id) -> {
      // Check cache first
      let id_str = recipe_types.recipe_id_to_string(recipe_id)
      case dict.get(model.recipe_cache, id_str) {
        Ok(details) -> {
          let updated =
            model.RecipeModel(
              ..model,
              view_state: model.DetailView,
              selected_recipe: Some(details),
            )
          #(updated, messages.NoEffect)
        }
        Error(_) -> {
          let updated =
            model.RecipeModel(
              ..model,
              view_state: model.DetailView,
              is_loading: True,
            )
          #(updated, messages.FetchRecipeDetails(recipe_id))
        }
      }
    }

    messages.ShowFilterView -> {
      let updated = model.RecipeModel(..model, view_state: model.FilterView)
      #(updated, messages.NoEffect)
    }

    messages.ShowFavoritesView -> {
      let updated = model.RecipeModel(..model, view_state: model.FavoritesView)
      #(updated, messages.LoadFavorites)
    }

    messages.ShowDirectionsView -> {
      let updated = model.RecipeModel(..model, view_state: model.DirectionsView)
      #(updated, messages.NoEffect)
    }

    messages.ShowNutritionView -> {
      let updated = model.RecipeModel(..model, view_state: model.NutritionView)
      #(updated, messages.NoEffect)
    }

    messages.ShowSearchPopup -> {
      let updated = model.RecipeModel(..model, view_state: model.SearchPopup)
      #(updated, messages.NoEffect)
    }

    messages.GoBack -> {
      case model.view_state {
        model.DetailView -> {
          let updated =
            model.RecipeModel(
              ..model,
              view_state: model.ListView,
              selected_recipe: None,
            )
          #(updated, messages.NoEffect)
        }
        model.DirectionsView | model.NutritionView -> {
          let updated = model.RecipeModel(..model, view_state: model.DetailView)
          #(updated, messages.NoEffect)
        }
        model.FilterView | model.FavoritesView | model.SearchPopup -> {
          let updated = model.RecipeModel(..model, view_state: model.ListView)
          #(updated, messages.NoEffect)
        }
        model.ListView -> #(model, messages.NoEffect)
      }
    }

    // === Search ===
    messages.SearchQueryChanged(query) -> {
      let search = model.RecipeSearchState(..model.search_state, query: query)
      let updated = model.RecipeModel(..model, search_state: search)
      #(updated, messages.NoEffect)
    }

    messages.SearchTypeChanged(search_type) -> {
      let search =
        model.RecipeSearchState(..model.search_state, search_type: search_type)
      let updated = model.RecipeModel(..model, search_state: search)
      #(updated, messages.NoEffect)
    }

    messages.SearchStarted -> {
      let search =
        model.RecipeSearchState(
          ..model.search_state,
          is_loading: True,
          error: None,
        )
      let pagination =
        model.PaginationState(..model.pagination, current_page: 1)
      let updated =
        model.RecipeModel(
          ..model,
          search_state: search,
          pagination: pagination,
          view_state: model.ListView,
        )
      let effect =
        messages.SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          1,
          model.filters,
        )
      #(updated, effect)
    }

    messages.GotSearchResults(result) -> {
      case result {
        Ok(#(recipes, total)) -> {
          let total_pages =
            { total + model.pagination.results_per_page - 1 }
            / model.pagination.results_per_page
          let pagination =
            model.PaginationState(
              ..model.pagination,
              total_results: total,
              total_pages: total_pages,
            )
          let search =
            model.RecipeSearchState(..model.search_state, is_loading: False)
          let updated =
            model.RecipeModel(
              ..model,
              recipes: recipes,
              search_state: search,
              pagination: pagination,
              is_loading: False,
            )
          #(updated, messages.NoEffect)
        }
        Error(err) -> {
          let search =
            model.RecipeSearchState(
              ..model.search_state,
              is_loading: False,
              error: Some(err),
            )
          let updated =
            model.RecipeModel(..model, search_state: search, is_loading: False)
          #(updated, messages.NoEffect)
        }
      }
    }

    messages.ClearSearch -> {
      let search =
        model.RecipeSearchState(
          query: "",
          search_type: model.ByName,
          is_loading: False,
          error: None,
        )
      let updated =
        model.RecipeModel(..model, search_state: search, recipes: [])
      #(updated, messages.NoEffect)
    }

    // === Pagination ===
    messages.NextPage -> {
      case model.pagination.current_page < model.pagination.total_pages {
        True -> {
          let new_page = model.pagination.current_page + 1
          let pagination =
            model.PaginationState(..model.pagination, current_page: new_page)
          let updated =
            model.RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            messages.SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              new_page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, messages.NoEffect)
      }
    }

    messages.PreviousPage -> {
      case model.pagination.current_page > 1 {
        True -> {
          let new_page = model.pagination.current_page - 1
          let pagination =
            model.PaginationState(..model.pagination, current_page: new_page)
          let updated =
            model.RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            messages.SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              new_page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, messages.NoEffect)
      }
    }

    messages.GoToPage(page) -> {
      case page >= 1 && page <= model.pagination.total_pages {
        True -> {
          let pagination =
            model.PaginationState(..model.pagination, current_page: page)
          let updated =
            model.RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            messages.SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, messages.NoEffect)
      }
    }

    // === Recipe Actions ===
    messages.ViewRecipeDetails(recipe_id) -> {
      recipe_update(model, messages.ShowDetailView(recipe_id))
    }

    messages.GotRecipeDetails(result) -> {
      case result {
        Ok(details) -> {
          // Add to cache
          let id_str = recipe_types.recipe_id_to_string(details.recipe_id)
          let new_cache = dict.insert(model.recipe_cache, id_str, details)

          // Add to recent
          let list_item = recipe_details_to_list_item(details, model.favorites)
          let recent = [list_item, ..list.take(model.recent_recipes, 9)]

          let updated =
            model.RecipeModel(
              ..model,
              selected_recipe: Some(details),
              recipe_cache: new_cache,
              recent_recipes: recent,
              is_loading: False,
            )
          #(updated, messages.NoEffect)
        }
        Error(err) -> {
          let updated =
            model.RecipeModel(
              ..model,
              error_message: Some(err),
              is_loading: False,
            )
          #(updated, messages.NoEffect)
        }
      }
    }

    messages.ToggleFavorite(recipe_id) -> {
      let id_str = recipe_types.recipe_id_to_string(recipe_id)
      let is_favorite = list.contains(model.favorites, id_str)
      case is_favorite {
        True -> {
          let favorites = list.filter(model.favorites, fn(id) { id != id_str })
          let updated = model.RecipeModel(..model, favorites: favorites)
          #(updated, messages.RemoveFavorite(recipe_id))
        }
        False -> {
          let favorites = [id_str, ..model.favorites]
          let updated = model.RecipeModel(..model, favorites: favorites)
          #(updated, messages.SaveFavorite(recipe_id))
        }
      }
    }

    messages.AddToMealPlan(_recipe_id) -> {
      // TODO: Implement add to meal plan flow
      #(model, messages.NoEffect)
    }

    // === Filters ===
    messages.SetMaxCalories(calories) -> {
      let filters = model.RecipeFilters(..model.filters, max_calories: calories)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.SetMaxPrepTime(minutes) -> {
      let filters = model.RecipeFilters(..model.filters, max_prep_time: minutes)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.SetMinProtein(grams) -> {
      let filters = model.RecipeFilters(..model.filters, min_protein: grams)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.SetCuisineType(cuisine) -> {
      let filters = model.RecipeFilters(..model.filters, cuisine_type: cuisine)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.SetDietType(diet) -> {
      let filters = model.RecipeFilters(..model.filters, diet_type: diet)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.SetSortBy(sort) -> {
      let filters = model.RecipeFilters(..model.filters, sort_by: sort)
      let updated = model.RecipeModel(..model, filters: filters)
      #(updated, messages.NoEffect)
    }

    messages.ApplyFilters -> {
      let pagination =
        model.PaginationState(..model.pagination, current_page: 1)
      let updated =
        model.RecipeModel(
          ..model,
          pagination: pagination,
          is_loading: True,
          view_state: model.ListView,
        )
      let effect =
        messages.SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          1,
          model.filters,
        )
      #(updated, effect)
    }

    messages.ClearFilters -> {
      let updated = model.RecipeModel(..model, filters: model.default_filters())
      #(updated, messages.NoEffect)
    }

    // === UI ===
    messages.ClearError -> {
      let updated = model.RecipeModel(..model, error_message: None)
      #(updated, messages.NoEffect)
    }

    messages.KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    messages.Refresh -> {
      let updated = model.RecipeModel(..model, is_loading: True)
      let effect =
        messages.SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          model.pagination.current_page,
          model.filters,
        )
      #(updated, effect)
    }

    messages.NoOp -> #(model, messages.NoEffect)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Handle keyboard input
fn handle_key_press(
  model: RecipeModel,
  key_str: String,
) -> #(RecipeModel, RecipeEffect) {
  case model.view_state {
    model.ListView -> {
      case key_str {
        "/" -> recipe_update(model, messages.ShowSearchPopup)
        "f" -> recipe_update(model, messages.ShowFilterView)
        "F" -> recipe_update(model, messages.ShowFavoritesView)
        "n" -> recipe_update(model, messages.NextPage)
        "p" -> recipe_update(model, messages.PreviousPage)
        "r" -> recipe_update(model, messages.Refresh)
        "\u{001B}" -> #(model, messages.NoEffect)
        _ -> #(model, messages.NoEffect)
      }
    }

    model.DetailView -> {
      case key_str {
        "d" -> recipe_update(model, messages.ShowDirectionsView)
        "n" -> recipe_update(model, messages.ShowNutritionView)
        "f" -> {
          case model.selected_recipe {
            Some(details) ->
              recipe_update(model, messages.ToggleFavorite(details.recipe_id))
            None -> #(model, messages.NoEffect)
          }
        }
        "\u{001B}" -> recipe_update(model, messages.GoBack)
        _ -> #(model, messages.NoEffect)
      }
    }

    model.DirectionsView | model.NutritionView -> {
      case key_str {
        "\u{001B}" -> recipe_update(model, messages.GoBack)
        _ -> #(model, messages.NoEffect)
      }
    }

    model.FilterView -> {
      case key_str {
        "\r" -> recipe_update(model, messages.ApplyFilters)
        "c" -> recipe_update(model, messages.ClearFilters)
        "\u{001B}" -> recipe_update(model, messages.GoBack)
        _ -> #(model, messages.NoEffect)
      }
    }

    model.FavoritesView -> {
      case key_str {
        "\u{001B}" -> recipe_update(model, messages.GoBack)
        _ -> #(model, messages.NoEffect)
      }
    }

    model.SearchPopup -> {
      case key_str {
        "\r" -> recipe_update(model, messages.SearchStarted)
        "\u{001B}" -> recipe_update(model, messages.GoBack)
        _ -> #(model, messages.NoEffect)
      }
    }
  }
}

/// Convert RecipeDetails to RecipeListItem
fn recipe_details_to_list_item(
  details: RecipeDetails,
  favorites: List(String),
) -> RecipeListItem {
  let id_str = recipe_types.recipe_id_to_string(details.recipe_id)
  model.RecipeListItem(
    recipe_id: details.recipe_id,
    recipe_name: details.recipe_name,
    recipe_description: details.recipe_description,
    calories_per_serving: Some(details.nutrition.calories),
    cooking_time_min: details.cooking_time_min,
    number_of_servings: details.number_of_servings,
    is_favorite: list.contains(favorites, id_str),
    rating: details.rating,
  )
}
