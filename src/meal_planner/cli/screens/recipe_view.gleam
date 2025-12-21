/// Recipe View Screen - Complete TUI Implementation
///
/// This module implements the recipe browser screen following Shore Framework
/// (Elm Architecture) for browsing and viewing recipes from FatSecret.
///
/// SCREEN FEATURES:
/// - Browse recipes with pagination
/// - Search recipes by name/keyword
/// - View recipe details with ingredients
/// - View nutrition information per serving
/// - Save favorites
/// - View cooking directions
///
/// ARCHITECTURE:
/// - Model: RecipeModel (state container)
/// - Msg: RecipeMsg (all possible events)
/// - Update: recipe_update (state transitions)
/// - View: recipe_view (rendering)
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/recipes/types as recipe_types
import shore
import shore/key
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Root state for the Recipe TUI screen
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
  RecipeDirection(
    direction_number: Int,
    direction_description: String,
  )
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

/// Effects for the recipe screen
pub type RecipeEffect {
  NoEffect
  SearchRecipes(query: String, search_type: SearchType, page: Int, filters: RecipeFilters)
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
    search_state: RecipeSearchState(
      query: "",
      search_type: ByName,
      is_loading: False,
      error: None,
    ),
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

/// Default filter settings
pub fn default_filters() -> RecipeFilters {
  RecipeFilters(
    max_calories: None,
    max_prep_time: None,
    min_protein: None,
    cuisine_type: None,
    diet_type: None,
    sort_by: SortByRating,
  )
}

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
          let updated = RecipeModel(
            ..model,
            view_state: DetailView,
            selected_recipe: Some(details),
          )
          #(updated, NoEffect)
        }
        Error(_) -> {
          let updated = RecipeModel(..model, view_state: DetailView, is_loading: True)
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
          let updated = RecipeModel(..model, view_state: ListView, selected_recipe: None)
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
      let search = RecipeSearchState(..model.search_state, search_type: search_type)
      let updated = RecipeModel(..model, search_state: search)
      #(updated, NoEffect)
    }

    SearchStarted -> {
      let search = RecipeSearchState(..model.search_state, is_loading: True, error: None)
      let pagination = PaginationState(..model.pagination, current_page: 1)
      let updated = RecipeModel(
        ..model,
        search_state: search,
        pagination: pagination,
        view_state: ListView,
      )
      let effect = SearchRecipes(
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
          let total_pages = { total + model.pagination.results_per_page - 1 } / model.pagination.results_per_page
          let pagination = PaginationState(
            ..model.pagination,
            total_results: total,
            total_pages: total_pages,
          )
          let search = RecipeSearchState(..model.search_state, is_loading: False)
          let updated = RecipeModel(
            ..model,
            recipes: recipes,
            search_state: search,
            pagination: pagination,
            is_loading: False,
          )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let search = RecipeSearchState(..model.search_state, is_loading: False, error: Some(err))
          let updated = RecipeModel(..model, search_state: search, is_loading: False)
          #(updated, NoEffect)
        }
      }
    }

    ClearSearch -> {
      let search = RecipeSearchState(
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
          let pagination = PaginationState(..model.pagination, current_page: new_page)
          let updated = RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect = SearchRecipes(
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
          let pagination = PaginationState(..model.pagination, current_page: new_page)
          let updated = RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect = SearchRecipes(
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
          let pagination = PaginationState(..model.pagination, current_page: page)
          let updated = RecipeModel(..model, pagination: pagination, is_loading: True)
          let effect = SearchRecipes(
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

          let updated = RecipeModel(
            ..model,
            selected_recipe: Some(details),
            recipe_cache: new_cache,
            recent_recipes: recent,
            is_loading: False,
          )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated = RecipeModel(..model, error_message: Some(err), is_loading: False)
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
      let updated = RecipeModel(..model, pagination: pagination, is_loading: True, view_state: ListView)
      let effect = SearchRecipes(
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
      let effect = SearchRecipes(
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
            Some(details) -> recipe_update(model, ToggleFavorite(details.recipe_id))
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
fn recipe_details_to_list_item(details: RecipeDetails, favorites: List(String)) -> RecipeListItem {
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
  let page_info = "Page " <> int.to_string(page.current_page) <> " of " <> int.to_string(page.total_pages)
    <> " (" <> int.to_string(page.total_results) <> " recipes)"

  ui.col([
    // Header
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🍳 Recipe Browser", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),

    // Error message
    ..list.append(
      case model.error_message {
        Some(err) -> [ui.br(), ui.text_styled("⚠ " <> err, Some(style.Red), None)]
        None -> []
      },
      [
        // Search bar info
        ui.br(),
        case model.search_state.query {
          "" -> ui.text("Showing popular recipes")
          q -> ui.text("Results for: " <> q)
        },
        ui.br(),

        // Navigation hints
        ui.text_styled(
          "[/] Search  [f] Filters  [F] Favorites  [n/p] Page  [Enter] View",
          Some(style.Cyan),
          None,
        ),
        ui.hr(),

        // Pagination info
        ui.br(),
        ui.text(page_info),
        ui.br(),

        // Loading indicator
        ..list.append(
          case model.is_loading {
            True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
            False -> []
          },
          [
            ui.br(),
            // Recipe list
            ..list.append(
              case model.recipes {
                [] -> [ui.text("No recipes found. Try a different search.")]
                recipes -> list.index_map(recipes, render_recipe_list_item)
              },
              [
                ui.br(),
                ui.hr(),
                // Pagination controls
                ui.text_styled(
                  "[p] Previous  [n] Next  [1-9] Select recipe",
                  Some(style.Cyan),
                  None,
                ),
              ]
            )
          ]
        )
      ]
    )
  ])
}

/// Render a recipe list item
fn render_recipe_list_item(recipe: RecipeListItem, index: Int) -> shore.Node(RecipeMsg) {
  let fav_icon = case recipe.is_favorite {
    True -> "★ "
    False -> "  "
  }
  let cal_str = format_optional_float(recipe.calories_per_serving, " cal")
  let time_str = format_optional_int(recipe.cooking_time_min, " min")
  let rating_str = format_optional_float(recipe.rating, "⭐")

  ui.text(
    fav_icon <> int.to_string(index + 1) <> ". " <> recipe.recipe_name
    <> " | " <> cal_str <> " | " <> time_str <> " | " <> rating_str,
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
        ui.text("Prep Time: " <> format_optional_int(recipe.preparation_time_min, " min")),
        ui.text("Cook Time: " <> format_optional_int(recipe.cooking_time_min, " min")),
        ui.text("Rating: " <> format_optional_float(recipe.rating, "/5")),
        ui.br(),

        // Nutrition summary
        ui.text_styled("Nutrition (per serving):", Some(style.Yellow), None),
        ui.text(
          "  Calories: " <> float_to_string(recipe.nutrition.calories)
          <> " | Protein: " <> float_to_string(recipe.nutrition.protein) <> "g"
          <> " | Carbs: " <> float_to_string(recipe.nutrition.carbohydrate) <> "g"
          <> " | Fat: " <> float_to_string(recipe.nutrition.fat) <> "g",
        ),
        ui.br(),

        // Ingredients summary
        ui.text_styled(
          "Ingredients (" <> int.to_string(list.length(recipe.ingredients)) <> "):",
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
              True -> ui.text("  ... and " <> int.to_string(list.length(recipe.ingredients) - 5) <> " more")
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
          ]
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
                  int.to_string(dir.direction_number) <> ". " <> dir.direction_description,
                )
              })
            }
          },
          [
            ui.br(),
            ui.hr(),
            ui.text_styled("[Esc] Back to recipe", Some(style.Cyan), None),
          ]
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
        ui.text("  Saturated Fat: " <> format_optional_float(n.saturated_fat, "g")),
        ui.text("  Sodium:        " <> format_optional_float(n.sodium, "mg")),
        ui.text("  Cholesterol:   " <> format_optional_float(n.cholesterol, "mg")),
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
      list.contains(model.favorites, recipe_types.recipe_id_to_string(r.recipe_id))
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
      ]
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

    ui.input(
      "Search:",
      search.query,
      style.Pct(80),
      fn(q) { SearchQueryChanged(q) },
    ),
    ui.br(),

    ui.text("Search type: " <> search_type_to_string(search.search_type)),
    ui.br(),

    // Loading / Error
    ..list.append(
      case search.is_loading {
        True -> [ui.text_styled("Searching...", Some(style.Yellow), None)]
        False -> []
      },
      [
        ..list.append(
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
          ]
        )
      ]
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
