/// Recipe View Screen - Implementation (being refactored)
///
/// This module implements the recipe browser screen following Shore Framework
/// (Elm Architecture) for browsing and viewing recipes from FatSecret.
///
/// REFACTORING IN PROGRESS:
/// Types moved to: recipe/model.gleam and recipe/messages.gleam
/// Main module: recipe/mod.gleam
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/cli/screens/recipe/messages.{
  type RecipeMsg, AddToMealPlan, ApplyFilters, ClearError, ClearFilters,
  ClearSearch, GoBack, GoToPage, GotRecipeDetails, GotSearchResults, KeyPressed,
  NextPage, NoOp, PreviousPage, Refresh, SearchQueryChanged, SearchStarted,
  SearchTypeChanged, SetCuisineType, SetDietType, SetMaxCalories, SetMaxPrepTime,
  SetMinProtein, SetSortBy, ShowDetailView, ShowDirectionsView,
  ShowFavoritesView, ShowFilterView, ShowListView, ShowNutritionView,
  ShowSearchPopup, ToggleFavorite, ViewRecipeDetails,
}
import meal_planner/cli/screens/recipe/model.{
  type PaginationState, type RecipeDetails, type RecipeDirection,
  type RecipeEffect, type RecipeFilters, type RecipeIngredient,
  type RecipeListItem, type RecipeModel, type RecipeNutrition,
  type RecipeSearchState, type RecipeViewState, type SearchType, type SortOption,
  BatchEffects, ByCuisine, ByIngredient, ByName, DetailView, DirectionsView,
  FavoritesView, FetchRecipeDetails, FilterView, ListView, LoadFavorites,
  NoEffect, NutritionView, PaginationState, RecipeDetails, RecipeFilters,
  RecipeListItem, RecipeModel, RecipeSearchState, RemoveFavorite, SaveFavorite,
  SearchPopup, SearchRecipes, SortByCalories, SortByName, SortByPrepTime,
  SortByRating, SortByRecent, default_filters, init,
}
import meal_planner/fatsecret/recipes/types as recipe_types
import shore
import shore/style
import shore/ui

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
    ShowListView -> {
      let updated = RecipeModel(..model, view_state: ListView)
      #(updated, NoEffect)
    }

    ShowDetailView(recipe_id) -> {
      // Check cache first
      let id_str = recipe_types.recipe_id_to_string(recipe_id)
      case dict.get(model.recipe_cache, id_str) {
        Ok(details) -> {
          let updated =
            RecipeModel(
              ..model,
              view_state: DetailView,
              selected_recipe: Some(details),
            )
          #(updated, NoEffect)
        }
        Error(_) -> {
          let updated =
            RecipeModel(..model, view_state: DetailView, is_loading: True)
          #(updated, FetchRecipeDetails(recipe_id))
        }
      }
    }

    ShowFilterView -> {
      let updated = RecipeModel(..model, view_state: FilterView)
      #(updated, NoEffect)
    }

    ShowFavoritesView -> {
      let updated = RecipeModel(..model, view_state: FavoritesView)
      #(updated, LoadFavorites)
    }

    ShowDirectionsView -> {
      let updated = RecipeModel(..model, view_state: DirectionsView)
      #(updated, NoEffect)
    }

    ShowNutritionView -> {
      let updated = RecipeModel(..model, view_state: NutritionView)
      #(updated, NoEffect)
    }

    ShowSearchPopup -> {
      let updated = RecipeModel(..model, view_state: SearchPopup)
      #(updated, NoEffect)
    }

    GoBack -> {
      case model.view_state {
        DetailView -> {
          let updated =
            RecipeModel(..model, view_state: ListView, selected_recipe: None)
          #(updated, NoEffect)
        }
        DirectionsView | NutritionView -> {
          let updated = RecipeModel(..model, view_state: DetailView)
          #(updated, NoEffect)
        }
        FilterView | FavoritesView | SearchPopup -> {
          let updated = RecipeModel(..model, view_state: ListView)
          #(updated, NoEffect)
        }
        ListView -> #(model, NoEffect)
      }
    }

    // === Search ===
    SearchQueryChanged(query) -> {
      let search = RecipeSearchState(..model.search_state, query: query)
      let updated = RecipeModel(..model, search_state: search)
      #(updated, NoEffect)
    }

    SearchTypeChanged(search_type) -> {
      let search =
        RecipeSearchState(..model.search_state, search_type: search_type)
      let updated = RecipeModel(..model, search_state: search)
      #(updated, NoEffect)
    }

    SearchStarted -> {
      let search =
        RecipeSearchState(..model.search_state, is_loading: True, error: None)
      let pagination = PaginationState(..model.pagination, current_page: 1)
      let updated =
        RecipeModel(
          ..model,
          search_state: search,
          pagination: pagination,
          view_state: ListView,
        )
      let effect =
        SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          1,
          model.filters,
        )
      #(updated, effect)
    }

    GotSearchResults(result) -> {
      case result {
        Ok(#(recipes, total)) -> {
          let total_pages =
            { total + model.pagination.results_per_page - 1 }
            / model.pagination.results_per_page
          let pagination =
            PaginationState(
              ..model.pagination,
              total_results: total,
              total_pages: total_pages,
            )
          let search =
            RecipeSearchState(..model.search_state, is_loading: False)
          let updated =
            RecipeModel(
              ..model,
              recipes: recipes,
              search_state: search,
              pagination: pagination,
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let search =
            RecipeSearchState(
              ..model.search_state,
              is_loading: False,
              error: Some(err),
            )
          let updated =
            RecipeModel(..model, search_state: search, is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    ClearSearch -> {
      let search =
        RecipeSearchState(
          query: "",
          search_type: ByName,
          is_loading: False,
          error: None,
        )
      let updated = RecipeModel(..model, search_state: search, recipes: [])
      #(updated, NoEffect)
    }

    // === Pagination ===
    NextPage -> {
      case model.pagination.current_page < model.pagination.total_pages {
        True -> {
          let new_page = model.pagination.current_page + 1
          let pagination =
            PaginationState(..model.pagination, current_page: new_page)
          let updated =
            RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              new_page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, NoEffect)
      }
    }

    PreviousPage -> {
      case model.pagination.current_page > 1 {
        True -> {
          let new_page = model.pagination.current_page - 1
          let pagination =
            PaginationState(..model.pagination, current_page: new_page)
          let updated =
            RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              new_page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, NoEffect)
      }
    }

    GoToPage(page) -> {
      case page >= 1 && page <= model.pagination.total_pages {
        True -> {
          let pagination =
            PaginationState(..model.pagination, current_page: page)
          let updated =
            RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect =
            SearchRecipes(
              model.search_state.query,
              model.search_state.search_type,
              page,
              model.filters,
            )
          #(updated, effect)
        }
        False -> #(model, NoEffect)
      }
    }

    // === Recipe Actions ===
    ViewRecipeDetails(recipe_id) -> {
      recipe_update(model, ShowDetailView(recipe_id))
    }

    GotRecipeDetails(result) -> {
      case result {
        Ok(details) -> {
          // Add to cache
          let id_str = recipe_types.recipe_id_to_string(details.recipe_id)
          let new_cache = dict.insert(model.recipe_cache, id_str, details)

          // Add to recent
          let list_item = recipe_details_to_list_item(details, model.favorites)
          let recent = [list_item, ..list.take(model.recent_recipes, 9)]

          let updated =
            RecipeModel(
              ..model,
              selected_recipe: Some(details),
              recipe_cache: new_cache,
              recent_recipes: recent,
              is_loading: False,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated =
            RecipeModel(..model, error_message: Some(err), is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    ToggleFavorite(recipe_id) -> {
      let id_str = recipe_types.recipe_id_to_string(recipe_id)
      let is_favorite = list.contains(model.favorites, id_str)
      case is_favorite {
        True -> {
          let favorites = list.filter(model.favorites, fn(id) { id != id_str })
          let updated = RecipeModel(..model, favorites: favorites)
          #(updated, RemoveFavorite(recipe_id))
        }
        False -> {
          let favorites = [id_str, ..model.favorites]
          let updated = RecipeModel(..model, favorites: favorites)
          #(updated, SaveFavorite(recipe_id))
        }
      }
    }

    AddToMealPlan(_recipe_id) -> {
      // TODO: Implement add to meal plan flow
      #(model, NoEffect)
    }

    // === Filters ===
    SetMaxCalories(calories) -> {
      let filters = RecipeFilters(..model.filters, max_calories: calories)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    SetMaxPrepTime(minutes) -> {
      let filters = RecipeFilters(..model.filters, max_prep_time: minutes)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    SetMinProtein(grams) -> {
      let filters = RecipeFilters(..model.filters, min_protein: grams)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    SetCuisineType(cuisine) -> {
      let filters = RecipeFilters(..model.filters, cuisine_type: cuisine)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    SetDietType(diet) -> {
      let filters = RecipeFilters(..model.filters, diet_type: diet)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    SetSortBy(sort) -> {
      let filters = RecipeFilters(..model.filters, sort_by: sort)
      let updated = RecipeModel(..model, filters: filters)
      #(updated, NoEffect)
    }

    ApplyFilters -> {
      let pagination = PaginationState(..model.pagination, current_page: 1)
      let updated =
        RecipeModel(
          ..model,
          pagination: pagination,
          is_loading: True,
          view_state: ListView,
        )
      let effect =
        SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          1,
          model.filters,
        )
      #(updated, effect)
    }

    ClearFilters -> {
      let updated = RecipeModel(..model, filters: default_filters())
      #(updated, NoEffect)
    }

    // === UI ===
    ClearError -> {
      let updated = RecipeModel(..model, error_message: None)
      #(updated, NoEffect)
    }

    KeyPressed(key_str) -> {
      handle_key_press(model, key_str)
    }

    Refresh -> {
      let updated = RecipeModel(..model, is_loading: True)
      let effect =
        SearchRecipes(
          model.search_state.query,
          model.search_state.search_type,
          model.pagination.current_page,
          model.filters,
        )
      #(updated, effect)
    }

    NoOp -> #(model, NoEffect)
  }
}

/// Handle keyboard input
fn handle_key_press(
  model: RecipeModel,
  key_str: String,
) -> #(RecipeModel, RecipeEffect) {
  case model.view_state {
    ListView -> {
      case key_str {
        "/" -> recipe_update(model, ShowSearchPopup)
        "f" -> recipe_update(model, ShowFilterView)
        "F" -> recipe_update(model, ShowFavoritesView)
        "n" -> recipe_update(model, NextPage)
        "p" -> recipe_update(model, PreviousPage)
        "r" -> recipe_update(model, Refresh)
        "\u{001B}" -> #(model, NoEffect)
        _ -> #(model, NoEffect)
      }
    }

    DetailView -> {
      case key_str {
        "d" -> recipe_update(model, ShowDirectionsView)
        "n" -> recipe_update(model, ShowNutritionView)
        "f" -> {
          case model.selected_recipe {
            Some(details) ->
              recipe_update(model, ToggleFavorite(details.recipe_id))
            None -> #(model, NoEffect)
          }
        }
        "\u{001B}" -> recipe_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }

    DirectionsView | NutritionView -> {
      case key_str {
        "\u{001B}" -> recipe_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }

    FilterView -> {
      case key_str {
        "\r" -> recipe_update(model, ApplyFilters)
        "c" -> recipe_update(model, ClearFilters)
        "\u{001B}" -> recipe_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }

    FavoritesView -> {
      case key_str {
        "\u{001B}" -> recipe_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }

    SearchPopup -> {
      case key_str {
        "\r" -> recipe_update(model, SearchStarted)
        "\u{001B}" -> recipe_update(model, GoBack)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert RecipeDetails to RecipeListItem
fn recipe_details_to_list_item(
  details: RecipeDetails,
  favorites: List(String),
) -> RecipeListItem {
  let id_str = recipe_types.recipe_id_to_string(details.recipe_id)
  RecipeListItem(
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

/// Format float to string with 1 decimal
fn float_to_string(value: Float) -> String {
  let rounded = float.truncate(value *. 10.0) |> int.to_float
  float.to_string(rounded /. 10.0)
}

/// Format optional int
fn format_optional_int(value: Option(Int), suffix: String) -> String {
  case value {
    Some(v) -> int.to_string(v) <> suffix
    None -> "N/A"
  }
}

/// Format optional float
fn format_optional_float(value: Option(Float), suffix: String) -> String {
  case value {
    Some(v) -> float_to_string(v) <> suffix
    None -> "N/A"
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the recipe view screen
pub fn recipe_view(model: RecipeModel) -> shore.Node(RecipeMsg) {
  case model.view_state {
    ListView -> view_list(model)
    DetailView -> view_detail(model)
    FilterView -> view_filters(model)
    FavoritesView -> view_favorites(model)
    DirectionsView -> view_directions(model)
    NutritionView -> view_nutrition(model)
    SearchPopup -> view_search_popup(model)
  }
}

/// Render recipe list view
fn view_list(model: RecipeModel) -> shore.Node(RecipeMsg) {
  let page = model.pagination
  let page_info =
    "Page "
    <> int.to_string(page.current_page)
    <> " of "
    <> int.to_string(page.total_pages)
    <> " ("
    <> int.to_string(page.total_results)
    <> " recipes)"

  let header_section = [
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🍳 Recipe Browser", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
  ]

  let error_section = case model.error_message {
    Some(err) -> [ui.br(), ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let search_info_section = [
    ui.br(),
    case model.search_state.query {
      "" -> ui.text("Showing popular recipes")
      q -> ui.text("Results for: " <> q)
    },
    ui.br(),
  ]

  let nav_section = [
    ui.text_styled(
      "[/] Search  [f] Filters  [F] Favorites  [n/p] Page  [Enter] View",
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
    ui.br(),
    ui.text(page_info),
    ui.br(),
  ]

  let loading_section = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let recipes_section = case model.recipes {
    [] -> [ui.text("No recipes found. Try a different search.")]
    recipes -> list.index_map(recipes, render_recipe_list_item)
  }

  let footer_section = [
    ui.br(),
    ui.hr(),
    ui.text_styled(
      "[p] Previous  [n] Next  [1-9] Select recipe",
      Some(style.Cyan),
      None,
    ),
  ]

  ui.col(
    list.flatten([
      header_section,
      error_section,
      search_info_section,
      nav_section,
      loading_section,
      [ui.br()],
      recipes_section,
      footer_section,
    ]),
  )
}

/// Render a recipe list item
fn render_recipe_list_item(
  recipe: RecipeListItem,
  index: Int,
) -> shore.Node(RecipeMsg) {
  let fav_icon = case recipe.is_favorite {
    True -> "★ "
    False -> "  "
  }
  let cal_str = format_optional_float(recipe.calories_per_serving, " cal")
  let time_str = format_optional_int(recipe.cooking_time_min, " min")
  let rating_str = format_optional_float(recipe.rating, "⭐")

  ui.text(
    fav_icon
    <> int.to_string(index + 1)
    <> ". "
    <> recipe.recipe_name
    <> " | "
    <> cal_str
    <> " | "
    <> time_str
    <> " | "
    <> rating_str,
  )
}

/// Render recipe detail view
fn view_detail(model: RecipeModel) -> shore.Node(RecipeMsg) {
  case model.selected_recipe {
    None -> {
      ui.col([
        ui.br(),
        ui.text_styled("Loading recipe details...", Some(style.Yellow), None),
      ])
    }
    Some(recipe) -> {
      let id_str = recipe_types.recipe_id_to_string(recipe.recipe_id)
      let is_favorite = list.contains(model.favorites, id_str)
      let fav_text = case is_favorite {
        True -> "★ Favorite"
        False -> "☆ Add to Favorites"
      }

      ui.col([
        // Header
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📖 " <> recipe.recipe_name, Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        // Basic info
        ui.text("Description: " <> recipe.recipe_description),
        ui.br(),
        ui.text("Servings: " <> float_to_string(recipe.number_of_servings)),
        ui.text(
          "Prep Time: "
          <> format_optional_int(recipe.preparation_time_min, " min"),
        ),
        ui.text(
          "Cook Time: " <> format_optional_int(recipe.cooking_time_min, " min"),
        ),
        ui.text("Rating: " <> format_optional_float(recipe.rating, "/5")),
        ui.br(),

        // Nutrition summary
        ui.text_styled("Nutrition (per serving):", Some(style.Yellow), None),
        ui.text(
          "  Calories: "
          <> float_to_string(recipe.nutrition.calories)
          <> " | Protein: "
          <> float_to_string(recipe.nutrition.protein)
          <> "g"
          <> " | Carbs: "
          <> float_to_string(recipe.nutrition.carbohydrate)
          <> "g"
          <> " | Fat: "
          <> float_to_string(recipe.nutrition.fat)
          <> "g",
        ),
        ui.br(),

        // Ingredients summary
        ui.text_styled(
          "Ingredients ("
            <> int.to_string(list.length(recipe.ingredients))
            <> "):",
          Some(style.Yellow),
          None,
        ),
        ..list.append(
          list.take(recipe.ingredients, 5)
            |> list.map(fn(ing) {
              ui.text("  • " <> ing.ingredient_description)
            }),
          [
            case list.length(recipe.ingredients) > 5 {
              True ->
                ui.text(
                  "  ... and "
                  <> int.to_string(list.length(recipe.ingredients) - 5)
                  <> " more",
                )
              False -> ui.text("")
            },
            ui.br(),

            // Actions
            ui.hr(),
            ui.text_styled(fav_text, Some(style.Cyan), None),
            ui.br(),
            ui.text_styled(
              "[d] Directions  [n] Full Nutrition  [f] Toggle Favorite  [Esc] Back",
              Some(style.Cyan),
              None,
            ),
          ],
        )
      ])
    }
  }
}

/// Render directions view
fn view_directions(model: RecipeModel) -> shore.Node(RecipeMsg) {
  case model.selected_recipe {
    None -> ui.col([ui.text("No recipe selected")])
    Some(recipe) -> {
      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📝 Cooking Directions", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        ui.text("Recipe: " <> recipe.recipe_name),
        ui.br(),
        ui.hr(),
        ui.br(),
        ..list.append(
          case recipe.directions {
            [] -> [ui.text("No directions available.")]
            directions -> {
              list.map(directions, fn(dir) {
                ui.text(
                  int.to_string(dir.direction_number)
                  <> ". "
                  <> dir.direction_description,
                )
              })
            }
          },
          [
            ui.br(),
            ui.hr(),
            ui.text_styled("[Esc] Back to recipe", Some(style.Cyan), None),
          ],
        )
      ])
    }
  }
}

/// Render nutrition view
fn view_nutrition(model: RecipeModel) -> shore.Node(RecipeMsg) {
  case model.selected_recipe {
    None -> ui.col([ui.text("No recipe selected")])
    Some(recipe) -> {
      let n = recipe.nutrition

      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("🥗 Nutrition Facts", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),

        ui.text("Recipe: " <> recipe.recipe_name),
        ui.text("Servings: " <> float_to_string(recipe.number_of_servings)),
        ui.br(),
        ui.hr(),
        ui.text_styled("Per Serving:", Some(style.Yellow), None),
        ui.br(),

        // Macros
        ui.text("  Calories:      " <> float_to_string(n.calories)),
        ui.text("  Protein:       " <> float_to_string(n.protein) <> "g"),
        ui.text("  Carbohydrates: " <> float_to_string(n.carbohydrate) <> "g"),
        ui.text("  Fat:           " <> float_to_string(n.fat) <> "g"),
        ui.br(),

        // Additional nutrients
        ui.text("  Fiber:         " <> format_optional_float(n.fiber, "g")),
        ui.text("  Sugar:         " <> format_optional_float(n.sugar, "g")),
        ui.text(
          "  Saturated Fat: " <> format_optional_float(n.saturated_fat, "g"),
        ),
        ui.text("  Sodium:        " <> format_optional_float(n.sodium, "mg")),
        ui.text(
          "  Cholesterol:   " <> format_optional_float(n.cholesterol, "mg"),
        ),
        ui.br(),

        ui.hr(),
        ui.text_styled("[Esc] Back to recipe", Some(style.Cyan), None),
      ])
    }
  }
}

/// Render filter view
fn view_filters(model: RecipeModel) -> shore.Node(RecipeMsg) {
  let f = model.filters

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚙ Filter Settings", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Max Calories: " <> format_optional_int(f.max_calories, "")),
    ui.text("Max Prep Time: " <> format_optional_int(f.max_prep_time, " min")),
    ui.text("Min Protein: " <> format_optional_int(f.min_protein, "g")),
    ui.text("Cuisine: " <> option.unwrap(f.cuisine_type, "Any")),
    ui.text("Diet: " <> option.unwrap(f.diet_type, "Any")),
    ui.text("Sort by: " <> sort_option_to_string(f.sort_by)),
    ui.br(),

    ui.hr(),
    ui.text_styled(
      "[Enter] Apply  [c] Clear All  [Esc] Cancel",
      Some(style.Cyan),
      None,
    ),
  ])
}

/// Convert sort option to string
fn sort_option_to_string(sort: SortOption) -> String {
  case sort {
    SortByName -> "Name"
    SortByCalories -> "Calories"
    SortByPrepTime -> "Prep Time"
    SortByRating -> "Rating"
    SortByRecent -> "Recent"
  }
}

/// Render favorites view
fn view_favorites(model: RecipeModel) -> shore.Node(RecipeMsg) {
  let favorite_recipes =
    model.recipes
    |> list.filter(fn(r) {
      list.contains(
        model.favorites,
        recipe_types.recipe_id_to_string(r.recipe_id),
      )
    })

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⭐ Favorite Recipes", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.text("Total favorites: " <> int.to_string(list.length(model.favorites))),
    ui.br(),
    ui.hr(),
    ui.br(),
    ..list.append(
      case favorite_recipes {
        [] -> [ui.text("No favorites yet. Press [f] on a recipe to add it.")]
        recipes -> list.index_map(recipes, render_recipe_list_item)
      },
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Esc] Back", Some(style.Cyan), None),
      ],
    )
  ])
}

/// Render search popup
fn view_search_popup(model: RecipeModel) -> shore.Node(RecipeMsg) {
  let search = model.search_state

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🔍 Search Recipes", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),

    ui.input("Search:", search.query, style.Pct(80), fn(q) {
      SearchQueryChanged(q)
    }),
    ui.br(),

    ui.text("Search type: " <> search_type_to_string(search.search_type)),
    ui.br(),
    // Loading / Error
    ..list.append(
      case search.is_loading {
        True -> [ui.text_styled("Searching...", Some(style.Yellow), None)]
        False -> []
      },
      list.append(
        case search.error {
          Some(err) -> [ui.text_styled("Error: " <> err, Some(style.Red), None)]
          None -> []
        },
        [
          ui.br(),
          ui.hr(),
          ui.text_styled(
            "[Enter] Search  [Tab] Change Type  [Esc] Cancel",
            Some(style.Cyan),
            None,
          ),
        ],
      ),
    )
  ])
}

/// Convert search type to string
fn search_type_to_string(st: SearchType) -> String {
  case st {
    ByName -> "By Name"
    ByIngredient -> "By Ingredient"
    ByCuisine -> "By Cuisine"
  }
}
