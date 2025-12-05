/// Routes module - Handles route pattern matching and reverse routing
///
/// This module extracts route definitions from web.gleam to improve modularity
/// and maintainability. All route parsing logic is centralized here.
import gleam/list
import gleam/string

pub type Route {
  Home
  StaticAsset(path: List(String))
  Recipes
  RecipesNew
  RecipesEdit(id: String)
  RecipeDetail(id: String)
  Dashboard
  Profile
  Foods
  FoodDetail(id: String)
  LogMeal
  LogMealForm(recipe_id: String)
  WeeklyPlan
  ApiRecipes
  ApiRecipe(id: String)
  ApiProfile
  ApiFoods
  ApiFoodsSearch
  ApiFood(id: String)
  ApiLogs
  ApiLogEntry(id: String)
  ApiSwapMeal(meal_type: String)
  ApiGenerate
  ApiSyncTodoist
  ApiRecipeSources
  ApiAutoMealPlan
  ApiAutoMealPlanById(id: String)
  ApiFilterFragments
  NotFound
}

/// Parse HTTP request path into a Route
///
/// Pattern matches on wisp path segments to determine which route was requested.
pub fn parse_route(segments: List(String)) -> Route {
  case segments {
    // Home page
    [] -> Home

    // Static assets
    ["static", ..rest] -> StaticAsset(rest)

    // SSR Pages
    ["recipes"] -> Recipes
    ["recipes", "new"] -> RecipesNew
    ["recipes", id, "edit"] -> RecipesEdit(id)
    ["recipes", id] -> RecipeDetail(id)
    ["dashboard"] -> Dashboard
    ["profile"] -> Profile
    ["foods"] -> Foods
    ["foods", id] -> FoodDetail(id)
    ["log"] -> LogMeal
    ["log", recipe_id] -> LogMealForm(recipe_id)
    ["weekly-plan"] -> WeeklyPlan

    // API Routes
    ["api", "recipes"] -> ApiRecipes
    ["api", "recipes", id] -> ApiRecipe(id)
    ["api", "profile"] -> ApiProfile
    ["api", "foods"] -> ApiFoods
    ["api", "foods", "search"] -> ApiFoodsSearch
    ["api", "foods", id] -> ApiFood(id)
    ["api", "logs"] -> ApiLogs
    ["api", "logs", "entry", id] -> ApiLogEntry(id)
    ["api", "swap", meal_type] -> ApiSwapMeal(meal_type)
    ["api", "generate"] -> ApiGenerate
    ["api", "sync", "todoist"] -> ApiSyncTodoist
    ["api", "recipe-sources"] -> ApiRecipeSources
    ["api", "meal-plans", "auto"] -> ApiAutoMealPlan
    ["api", "meal-plans", "auto", id] -> ApiAutoMealPlanById(id)
    ["api", "fragments", "filters"] -> ApiFilterFragments

    // 404 - Not Found
    _ -> NotFound
  }
}

/// Convert a Route back to its URL path
///
/// Useful for generating links and redirects programmatically.
pub fn route_to_path(route: Route) -> String {
  case route {
    Home -> "/"
    StaticAsset(path) -> "/static/" <> string.join(path, "/")
    Recipes -> "/recipes"
    RecipesNew -> "/recipes/new"
    RecipesEdit(id) -> "/recipes/" <> id <> "/edit"
    RecipeDetail(id) -> "/recipes/" <> id
    Dashboard -> "/dashboard"
    Profile -> "/profile"
    Foods -> "/foods"
    FoodDetail(id) -> "/foods/" <> id
    LogMeal -> "/log"
    LogMealForm(recipe_id) -> "/log/" <> recipe_id
    WeeklyPlan -> "/weekly-plan"
    ApiRecipes -> "/api/recipes"
    ApiRecipe(id) -> "/api/recipes/" <> id
    ApiProfile -> "/api/profile"
    ApiFoods -> "/api/foods"
    ApiFoodsSearch -> "/api/foods/search"
    ApiFood(id) -> "/api/foods/" <> id
    ApiLogs -> "/api/logs"
    ApiLogEntry(id) -> "/api/logs/entry/" <> id
    ApiSwapMeal(meal_type) -> "/api/swap/" <> meal_type
    ApiGenerate -> "/api/generate"
    ApiSyncTodoist -> "/api/sync/todoist"
    ApiRecipeSources -> "/api/recipe-sources"
    ApiAutoMealPlan -> "/api/meal-plans/auto"
    ApiAutoMealPlanById(id) -> "/api/meal-plans/auto/" <> id
    ApiFilterFragments -> "/api/fragments/filters"
    NotFound -> "/404"
  }
}

/// Check if a route is an API route
pub fn is_api_route(route: Route) -> Bool {
  case route {
    ApiRecipes
    | ApiRecipe(_)
    | ApiProfile
    | ApiFoods
    | ApiFoodsSearch
    | ApiFood(_)
    | ApiLogs
    | ApiLogEntry(_)
    | ApiSwapMeal(_)
    | ApiGenerate
    | ApiSyncTodoist
    | ApiRecipeSources
    | ApiAutoMealPlan
    | ApiAutoMealPlanById(_)
    | ApiFilterFragments -> True
    _ -> False
  }
}

/// Check if a route is a static asset route
pub fn is_static_route(route: Route) -> Bool {
  case route {
    StaticAsset(_) -> True
    _ -> False
  }
}

/// Extract route parameters from a Route variant
/// Returns a list of parameter values for routes with IDs
pub fn route_params(route: Route) -> List(String) {
  case route {
    RecipesEdit(id)
    | RecipeDetail(id)
    | FoodDetail(id)
    | LogMealForm(id)
    | ApiRecipe(id)
    | ApiFood(id)
    | ApiLogEntry(id)
    | ApiAutoMealPlanById(id) -> [id]
    ApiSwapMeal(meal_type) -> [meal_type]
    StaticAsset(path) -> path
    _ -> []
  }
}
