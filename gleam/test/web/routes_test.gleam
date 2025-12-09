import gleeunit
import gleeunit/should
import meal_planner/web/routes

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Parse Route Tests
// ============================================================================

pub fn parse_route_home_test() {
  routes.parse_route([])
  |> should.equal(routes.Home)
}

pub fn parse_route_static_test() {
  routes.parse_route(["static", "styles.css"])
  |> should.equal(routes.StaticAsset(["styles.css"]))
}

pub fn parse_route_static_nested_test() {
  routes.parse_route(["static", "css", "main.css"])
  |> should.equal(routes.StaticAsset(["css", "main.css"]))
}

pub fn parse_route_recipes_test() {
  routes.parse_route(["recipes"])
  |> should.equal(routes.Recipes)
}

pub fn parse_route_recipes_new_test() {
  routes.parse_route(["recipes", "new"])
  |> should.equal(routes.RecipesNew)
}

pub fn parse_route_recipes_edit_test() {
  routes.parse_route(["recipes", "abc123", "edit"])
  |> should.equal(routes.RecipesEdit("abc123"))
}

pub fn parse_route_recipes_detail_test() {
  routes.parse_route(["recipes", "abc123"])
  |> should.equal(routes.RecipeDetail("abc123"))
}

pub fn parse_route_dashboard_test() {
  routes.parse_route(["dashboard"])
  |> should.equal(routes.Dashboard)
}

pub fn parse_route_profile_test() {
  routes.parse_route(["profile"])
  |> should.equal(routes.Profile)
}

pub fn parse_route_foods_test() {
  routes.parse_route(["foods"])
  |> should.equal(routes.Foods)
}

pub fn parse_route_food_detail_test() {
  routes.parse_route(["foods", "fdc123"])
  |> should.equal(routes.FoodDetail("fdc123"))
}

pub fn parse_route_log_meal_test() {
  routes.parse_route(["log"])
  |> should.equal(routes.LogMeal)
}

pub fn parse_route_log_meal_form_test() {
  routes.parse_route(["log", "recipe456"])
  |> should.equal(routes.LogMealForm("recipe456"))
}

pub fn parse_route_weekly_plan_test() {
  routes.parse_route(["weekly-plan"])
  |> should.equal(routes.WeeklyPlan)
}

pub fn parse_route_api_recipes_test() {
  routes.parse_route(["api", "recipes"])
  |> should.equal(routes.ApiRecipes)
}

pub fn parse_route_api_recipe_test() {
  routes.parse_route(["api", "recipes", "recipe789"])
  |> should.equal(routes.ApiRecipe("recipe789"))
}

pub fn parse_route_api_profile_test() {
  routes.parse_route(["api", "profile"])
  |> should.equal(routes.ApiProfile)
}

pub fn parse_route_api_foods_test() {
  routes.parse_route(["api", "foods"])
  |> should.equal(routes.ApiFoods)
}

pub fn parse_route_api_foods_search_test() {
  routes.parse_route(["api", "foods", "search"])
  |> should.equal(routes.ApiFoodsSearch)
}

pub fn parse_route_api_food_test() {
  routes.parse_route(["api", "foods", "fdc999"])
  |> should.equal(routes.ApiFood("fdc999"))
}

pub fn parse_route_api_logs_test() {
  routes.parse_route(["api", "logs"])
  |> should.equal(routes.ApiLogs)
}

pub fn parse_route_api_log_entry_test() {
  routes.parse_route(["api", "logs", "entry", "entry123"])
  |> should.equal(routes.ApiLogEntry("entry123"))
}

pub fn parse_route_api_swap_meal_test() {
  routes.parse_route(["api", "swap", "breakfast"])
  |> should.equal(routes.ApiSwapMeal("breakfast"))
}

pub fn parse_route_api_generate_test() {
  routes.parse_route(["api", "generate"])
  |> should.equal(routes.ApiGenerate)
}

pub fn parse_route_api_sync_todoist_test() {
  routes.parse_route(["api", "sync", "todoist"])
  |> should.equal(routes.ApiSyncTodoist)
}

pub fn parse_route_api_recipe_sources_test() {
  routes.parse_route(["api", "recipe-sources"])
  |> should.equal(routes.ApiRecipeSources)
}

pub fn parse_route_api_auto_meal_plan_test() {
  routes.parse_route(["api", "meal-plans", "auto"])
  |> should.equal(routes.ApiAutoMealPlan)
}

pub fn parse_route_api_auto_meal_plan_by_id_test() {
  routes.parse_route(["api", "meal-plans", "auto", "plan123"])
  |> should.equal(routes.ApiAutoMealPlanById("plan123"))
}

pub fn parse_route_api_filter_fragments_test() {
  routes.parse_route(["api", "fragments", "filters"])
  |> should.equal(routes.ApiFilterFragments)
}

pub fn parse_route_not_found_test() {
  routes.parse_route(["invalid", "path"])
  |> should.equal(routes.NotFound)
}

pub fn parse_route_not_found_deep_test() {
  routes.parse_route(["api", "invalid", "deep", "path"])
  |> should.equal(routes.NotFound)
}

// ============================================================================
// Route to Path Tests
// ============================================================================

pub fn route_to_path_home_test() {
  routes.route_to_path(routes.Home)
  |> should.equal("/")
}

pub fn route_to_path_static_test() {
  routes.route_to_path(routes.StaticAsset(["styles.css"]))
  |> should.equal("/static/styles.css")
}

pub fn route_to_path_static_nested_test() {
  routes.route_to_path(routes.StaticAsset(["css", "main.css"]))
  |> should.equal("/static/css/main.css")
}

pub fn route_to_path_recipes_test() {
  routes.route_to_path(routes.Recipes)
  |> should.equal("/recipes")
}

pub fn route_to_path_recipes_new_test() {
  routes.route_to_path(routes.RecipesNew)
  |> should.equal("/recipes/new")
}

pub fn route_to_path_recipes_edit_test() {
  routes.route_to_path(routes.RecipesEdit("abc123"))
  |> should.equal("/recipes/abc123/edit")
}

pub fn route_to_path_recipes_detail_test() {
  routes.route_to_path(routes.RecipeDetail("abc123"))
  |> should.equal("/recipes/abc123")
}

pub fn route_to_path_dashboard_test() {
  routes.route_to_path(routes.Dashboard)
  |> should.equal("/dashboard")
}

pub fn route_to_path_profile_test() {
  routes.route_to_path(routes.Profile)
  |> should.equal("/profile")
}

pub fn route_to_path_foods_test() {
  routes.route_to_path(routes.Foods)
  |> should.equal("/foods")
}

pub fn route_to_path_food_detail_test() {
  routes.route_to_path(routes.FoodDetail("fdc123"))
  |> should.equal("/foods/fdc123")
}

pub fn route_to_path_log_meal_test() {
  routes.route_to_path(routes.LogMeal)
  |> should.equal("/log")
}

pub fn route_to_path_log_meal_form_test() {
  routes.route_to_path(routes.LogMealForm("recipe456"))
  |> should.equal("/log/recipe456")
}

pub fn route_to_path_weekly_plan_test() {
  routes.route_to_path(routes.WeeklyPlan)
  |> should.equal("/weekly-plan")
}

pub fn route_to_path_api_recipes_test() {
  routes.route_to_path(routes.ApiRecipes)
  |> should.equal("/api/recipes")
}

pub fn route_to_path_api_recipe_test() {
  routes.route_to_path(routes.ApiRecipe("recipe789"))
  |> should.equal("/api/recipes/recipe789")
}

pub fn route_to_path_api_profile_test() {
  routes.route_to_path(routes.ApiProfile)
  |> should.equal("/api/profile")
}

pub fn route_to_path_api_foods_test() {
  routes.route_to_path(routes.ApiFoods)
  |> should.equal("/api/foods")
}

pub fn route_to_path_api_foods_search_test() {
  routes.route_to_path(routes.ApiFoodsSearch)
  |> should.equal("/api/foods/search")
}

pub fn route_to_path_api_food_test() {
  routes.route_to_path(routes.ApiFood("fdc999"))
  |> should.equal("/api/foods/fdc999")
}

pub fn route_to_path_api_logs_test() {
  routes.route_to_path(routes.ApiLogs)
  |> should.equal("/api/logs")
}

pub fn route_to_path_api_log_entry_test() {
  routes.route_to_path(routes.ApiLogEntry("entry123"))
  |> should.equal("/api/logs/entry/entry123")
}

pub fn route_to_path_api_swap_meal_test() {
  routes.route_to_path(routes.ApiSwapMeal("breakfast"))
  |> should.equal("/api/swap/breakfast")
}

pub fn route_to_path_api_generate_test() {
  routes.route_to_path(routes.ApiGenerate)
  |> should.equal("/api/generate")
}

pub fn route_to_path_api_sync_todoist_test() {
  routes.route_to_path(routes.ApiSyncTodoist)
  |> should.equal("/api/sync/todoist")
}

pub fn route_to_path_api_recipe_sources_test() {
  routes.route_to_path(routes.ApiRecipeSources)
  |> should.equal("/api/recipe-sources")
}

pub fn route_to_path_api_auto_meal_plan_test() {
  routes.route_to_path(routes.ApiAutoMealPlan)
  |> should.equal("/api/meal-plans/auto")
}

pub fn route_to_path_api_auto_meal_plan_by_id_test() {
  routes.route_to_path(routes.ApiAutoMealPlanById("plan123"))
  |> should.equal("/api/meal-plans/auto/plan123")
}

pub fn route_to_path_api_filter_fragments_test() {
  routes.route_to_path(routes.ApiFilterFragments)
  |> should.equal("/api/fragments/filters")
}

pub fn route_to_path_not_found_test() {
  routes.route_to_path(routes.NotFound)
  |> should.equal("/404")
}

// ============================================================================
// Round-trip Tests
// ============================================================================

pub fn round_trip_home_test() {
  routes.Home
  |> routes.route_to_path
  |> fn(path) {
    case path {
      "/" -> routes.parse_route([])
      _ -> routes.NotFound
    }
  }
  |> should.equal(routes.Home)
}

pub fn round_trip_recipes_test() {
  routes.RecipeDetail("abc123")
  |> routes.route_to_path
  |> fn(path) {
    case path {
      "/recipes/abc123" -> routes.parse_route(["recipes", "abc123"])
      _ -> routes.NotFound
    }
  }
  |> should.equal(routes.RecipeDetail("abc123"))
}

pub fn round_trip_api_route_test() {
  routes.ApiFood("fdc999")
  |> routes.route_to_path
  |> fn(path) {
    case path {
      "/api/foods/fdc999" -> routes.parse_route(["api", "foods", "fdc999"])
      _ -> routes.NotFound
    }
  }
  |> should.equal(routes.ApiFood("fdc999"))
}

// ============================================================================
// Helper Function Tests
// ============================================================================

pub fn is_api_route_true_test() {
  routes.is_api_route(routes.ApiRecipes)
  |> should.equal(True)
}

pub fn is_api_route_false_test() {
  routes.is_api_route(routes.Recipes)
  |> should.equal(False)
}

pub fn is_api_route_with_param_test() {
  routes.is_api_route(routes.ApiFood("fdc123"))
  |> should.equal(True)
}

pub fn is_static_route_true_test() {
  routes.is_static_route(routes.StaticAsset(["styles.css"]))
  |> should.equal(True)
}

pub fn is_static_route_false_test() {
  routes.is_static_route(routes.Recipes)
  |> should.equal(False)
}

pub fn route_params_no_params_test() {
  routes.route_params(routes.Home)
  |> should.equal([])
}

pub fn route_params_with_id_test() {
  routes.route_params(routes.RecipeDetail("abc123"))
  |> should.equal(["abc123"])
}

pub fn route_params_with_meal_type_test() {
  routes.route_params(routes.ApiSwapMeal("breakfast"))
  |> should.equal(["breakfast"])
}

pub fn route_params_static_path_test() {
  routes.route_params(routes.StaticAsset(["css", "main.css"]))
  |> should.equal(["css", "main.css"])
}
