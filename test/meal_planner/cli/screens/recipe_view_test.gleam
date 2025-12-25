/// Tests for Recipe View Screen
///
/// Tests cover:
/// - Model initialization
/// - View state transitions
/// - Search state management
/// - Pagination state
/// - Recipe filters
/// - Recipe details and nutrition
/// - Message and effect variants
import gleam/dict
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/recipe/messages.{
  type RecipeMsg, AddToMealPlan, ApplyFilters, ClearError, ClearFilters,
  ClearSearch, GoBack, GoToPage, GotRecipeDetails, GotSearchResults, KeyPressed,
  NextPage, NoOp, PreviousPage, Refresh, SearchQueryChanged, SearchStarted,
  SearchTypeChanged, SetCuisineType, SetDietType, SetMaxCalories, SetMaxPrepTime,
  SetMinProtein, SetSortBy, ShowDetailView, ShowDirectionsView,
  ShowFavoritesView, ShowFilterView, ShowListView, ShowNutritionView,
  ShowSearchPopup, ToggleFavorite, ViewRecipeDetails,
}
import meal_planner/cli/screens/recipe/mod as recipe_view
import meal_planner/cli/screens/recipe/model.{
  type PaginationState, type RecipeDetails, type RecipeDirection,
  type RecipeEffect, type RecipeFilters, type RecipeIngredient,
  type RecipeListItem, type RecipeNutrition, type RecipeSearchState,
  type RecipeViewState, type SearchType, type SortOption, BatchEffects,
  ByCuisine, ByIngredient, ByName, DetailView, DirectionsView, FavoritesView,
  FetchRecipeDetails, FilterView, ListView, LoadFavorites, NoEffect,
  NutritionView, PaginationState, RecipeDetails, RecipeDirection, RecipeFilters,
  RecipeIngredient, RecipeListItem, RecipeNutrition, RecipeSearchState,
  RemoveFavorite, SaveFavorite, SearchPopup, SearchRecipes, SortByCalories,
  SortByName, SortByPrepTime, SortByRating, SortByRecent,
}
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Initialization Tests
// ============================================================================

pub fn init_creates_valid_model_test() {
  // WHEN: Initializing RecipeModel
  let model = recipe_view.init()

  // THEN: Model should have correct initial state
  model.view_state
  |> should.equal(ListView)

  model.recipes
  |> should.equal([])

  model.selected_recipe
  |> should.equal(None)

  model.is_loading
  |> should.equal(False)

  model.error_message
  |> should.equal(None)

  model.favorites
  |> should.equal([])

  model.recent_recipes
  |> should.equal([])

  // AND: Recipe cache should be empty
  model.recipe_cache
  |> dict.size
  |> should.equal(0)
}

pub fn init_search_state_empty_test() {
  // GIVEN: Initial model
  let model = recipe_view.init()

  // THEN: Search state should be initialized
  model.search_state.query
  |> should.equal("")

  model.search_state.search_type
  |> should.equal(ByName)

  model.search_state.is_loading
  |> should.equal(False)

  model.search_state.error
  |> should.equal(None)
}

pub fn init_pagination_state_test() {
  // GIVEN: Initial model
  let model = recipe_view.init()

  // THEN: Pagination should be at page 1
  model.pagination.current_page
  |> should.equal(1)

  model.pagination.total_results
  |> should.equal(0)

  model.pagination.results_per_page
  |> should.equal(20)

  model.pagination.total_pages
  |> should.equal(0)
}

// ============================================================================
// View State Tests
// ============================================================================

pub fn view_state_list_view_test() {
  let view_state: RecipeViewState = ListView
  case view_state {
    ListView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_detail_view_test() {
  let view_state: RecipeViewState = DetailView
  case view_state {
    DetailView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_filter_view_test() {
  let view_state: RecipeViewState = FilterView
  case view_state {
    FilterView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_favorites_view_test() {
  let view_state: RecipeViewState = FavoritesView
  case view_state {
    FavoritesView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_directions_view_test() {
  let view_state: RecipeViewState = DirectionsView
  case view_state {
    DirectionsView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_nutrition_view_test() {
  let view_state: RecipeViewState = NutritionView
  case view_state {
    NutritionView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn view_state_search_popup_test() {
  let view_state: RecipeViewState = SearchPopup
  case view_state {
    SearchPopup -> True
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// Search State Tests
// ============================================================================

pub fn search_state_construction_test() {
  let search =
    RecipeSearchState(
      query: "chicken parmesan",
      search_type: ByName,
      is_loading: True,
      error: None,
    )

  search.query
  |> should.equal("chicken parmesan")

  search.search_type
  |> should.equal(ByName)

  search.is_loading
  |> should.equal(True)
}

pub fn search_type_all_variants_test() {
  let _types: List(SearchType) = [ByName, ByIngredient, ByCuisine]

  True
  |> should.be_true
}

// ============================================================================
// Pagination State Tests
// ============================================================================

pub fn pagination_state_construction_test() {
  let pagination =
    PaginationState(
      current_page: 3,
      total_results: 150,
      results_per_page: 20,
      total_pages: 8,
    )

  pagination.current_page
  |> should.equal(3)

  pagination.total_results
  |> should.equal(150)

  pagination.total_pages
  |> should.equal(8)
}

// ============================================================================
// Recipe Filters Tests
// ============================================================================

pub fn recipe_filters_construction_test() {
  let filters =
    RecipeFilters(
      max_calories: Some(500),
      max_prep_time: Some(30),
      min_protein: Some(20),
      cuisine_type: Some("Italian"),
      diet_type: Some("Vegetarian"),
      sort_by: SortByRating,
    )

  filters.max_calories
  |> should.equal(Some(500))

  filters.cuisine_type
  |> should.equal(Some("Italian"))

  filters.sort_by
  |> should.equal(SortByRating)
}

pub fn default_filters_test() {
  let filters = recipe_view.default_filters()

  filters.max_calories
  |> should.equal(None)

  filters.max_prep_time
  |> should.equal(None)

  filters.sort_by
  |> should.equal(SortByRating)
}

pub fn sort_option_all_variants_test() {
  let _options: List(SortOption) = [
    SortByName,
    SortByCalories,
    SortByPrepTime,
    SortByRating,
    SortByRecent,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Recipe List Item Tests
// ============================================================================

pub fn recipe_list_item_construction_test() {
  let recipe_id = recipe_types.recipe_id("recipe_123")

  let item =
    RecipeListItem(
      recipe_id: recipe_id,
      recipe_name: "Grilled Chicken Salad",
      recipe_description: "A healthy salad with grilled chicken breast",
      calories_per_serving: Some(350.0),
      cooking_time_min: Some(25),
      number_of_servings: 4.0,
      is_favorite: False,
      rating: Some(4.5),
    )

  item.recipe_name
  |> should.equal("Grilled Chicken Salad")

  item.calories_per_serving
  |> should.equal(Some(350.0))

  item.is_favorite
  |> should.equal(False)

  item.rating
  |> should.equal(Some(4.5))
}

// ============================================================================
// Recipe Details Tests
// ============================================================================

pub fn recipe_details_construction_test() {
  let recipe_id = recipe_types.recipe_id("recipe_456")

  let nutrition =
    RecipeNutrition(
      calories: 450.0,
      carbohydrate: 35.0,
      protein: 40.0,
      fat: 15.0,
      fiber: Some(5.0),
      sugar: Some(8.0),
      saturated_fat: Some(3.0),
      sodium: Some(600.0),
      cholesterol: Some(85.0),
    )

  let details =
    RecipeDetails(
      recipe_id: recipe_id,
      recipe_name: "Pasta Primavera",
      recipe_description: "Fresh vegetable pasta dish",
      recipe_url: "https://example.com/recipe",
      number_of_servings: 4.0,
      preparation_time_min: Some(15),
      cooking_time_min: Some(20),
      ingredients: [],
      directions: [],
      categories: ["Italian", "Vegetarian"],
      nutrition: nutrition,
      rating: Some(4.2),
      rating_count: Some(150),
    )

  details.recipe_name
  |> should.equal("Pasta Primavera")

  details.number_of_servings
  |> should.equal(4.0)

  details.preparation_time_min
  |> should.equal(Some(15))

  details.nutrition.protein
  |> should.equal(40.0)
}

// ============================================================================
// Recipe Ingredient Tests
// ============================================================================

pub fn recipe_ingredient_construction_test() {
  let ingredient =
    RecipeIngredient(
      food_id: "food_123",
      food_name: "Olive Oil",
      serving_id: "serving_1",
      number_of_units: 2.0,
      measurement_description: "tablespoons",
      ingredient_description: "2 tbsp olive oil",
      ingredient_url: "https://example.com/food/olive-oil",
    )

  ingredient.food_name
  |> should.equal("Olive Oil")

  ingredient.number_of_units
  |> should.equal(2.0)

  ingredient.measurement_description
  |> should.equal("tablespoons")
}

// ============================================================================
// Recipe Direction Tests
// ============================================================================

pub fn recipe_direction_construction_test() {
  let direction =
    RecipeDirection(
      direction_number: 1,
      direction_description: "Preheat oven to 375°F (190°C).",
    )

  direction.direction_number
  |> should.equal(1)

  direction.direction_description
  |> should.equal("Preheat oven to 375°F (190°C).")
}

// ============================================================================
// Recipe Nutrition Tests
// ============================================================================

pub fn recipe_nutrition_construction_test() {
  let nutrition =
    RecipeNutrition(
      calories: 500.0,
      carbohydrate: 45.0,
      protein: 35.0,
      fat: 20.0,
      fiber: Some(8.0),
      sugar: None,
      saturated_fat: Some(5.0),
      sodium: Some(800.0),
      cholesterol: None,
    )

  nutrition.calories
  |> should.equal(500.0)

  nutrition.protein
  |> should.equal(35.0)

  nutrition.fiber
  |> should.equal(Some(8.0))

  nutrition.sugar
  |> should.equal(None)
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn recipe_msg_all_variants_compile_test() {
  let recipe_id = recipe_types.recipe_id("test")

  let _msgs: List(RecipeMsg) = [
    // Navigation
    ShowListView,
    ShowDetailView(recipe_id),
    ShowFilterView,
    ShowFavoritesView,
    ShowDirectionsView,
    ShowNutritionView,
    ShowSearchPopup,
    GoBack,
    // Search
    SearchQueryChanged("chicken"),
    SearchTypeChanged(ByIngredient),
    SearchStarted,
    GotSearchResults(Ok(#([], 0))),
    ClearSearch,
    // Pagination
    NextPage,
    PreviousPage,
    GoToPage(5),
    // Recipe actions
    ViewRecipeDetails(recipe_id),
    ToggleFavorite(recipe_id),
    AddToMealPlan(recipe_id),
    // Filters
    SetMaxCalories(Some(500)),
    SetMaxPrepTime(Some(30)),
    SetMinProtein(Some(20)),
    SetCuisineType(Some("Mexican")),
    SetDietType(Some("Keto")),
    SetSortBy(SortByCalories),
    ApplyFilters,
    ClearFilters,
    // UI
    ClearError,
    KeyPressed("s"),
    Refresh,
    NoOp,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Effect Variant Tests
// ============================================================================

pub fn recipe_effect_all_variants_compile_test() {
  let recipe_id = recipe_types.recipe_id("test")
  let filters = recipe_view.default_filters()

  let _effects: List(RecipeEffect) = [
    NoEffect,
    SearchRecipes("pasta", ByName, 1, filters),
    FetchRecipeDetails(recipe_id),
    SaveFavorite(recipe_id),
    RemoveFavorite(recipe_id),
    LoadFavorites,
    BatchEffects([]),
  ]

  True
  |> should.be_true
}
