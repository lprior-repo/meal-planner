/// View - Screen rendering (Elm Architecture)
///
/// Renders the current screen based on model state
import gleam/option.{None, Some}
import meal_planner/cli/types

/// Render the current screen
pub fn view(model: types.Model) -> String {
  case model.current_screen {
    types.MainMenu -> view_main_menu(model)
    types.DomainMenu(domain) -> view_domain_menu(model, domain)
    types.FoodSearch -> view_food_search(model)
    types.DiaryView -> view_diary(model)
    types.ExerciseView -> view_exercise(model)
    types.FavoritesView -> view_favorites(model)
    types.RecipeView -> view_recipes(model)
    types.SavedMealsView -> view_saved_meals(model)
    types.ProfileView -> view_profile(model)
    types.WeightView -> view_weight(model)
    types.BrandSearchView -> view_brand_search(model)
    types.TandoorRecipes -> view_tandoor_recipes(model)
    types.DatabaseFoods -> view_database_foods(model)
    types.MealPlanGenerator -> view_meal_plan_generator(model)
    types.NutritionAnalysis -> view_nutrition_analysis(model)
    types.SchedulerView -> view_scheduler(model)
    types.ErrorScreen(err) -> view_error(err)
    types.LoadingScreen(msg) -> view_loading(msg)
  }
}

fn view_main_menu(_model: types.Model) -> String {
  "═══════════════════════════════════════════════════════════
🍽️  Meal Planner - Main Menu
═══════════════════════════════════════════════════════════

Select a domain:

  1. 🔥 FatSecret API      - Foods, diary, exercise, profiles
  2. 👨‍🍳 Tandoor Recipes     - Recipes and meal collections
  3. 🗂️  Database           - USDA foods, custom entries
  4. 📋 Meal Planning      - Generate and manage plans
  5. 📊 Nutrition Analysis - Track and analyze nutrition
  6. ⏰ Scheduler          - Manage scheduled tasks

Controls:

  [1-6]     Select domain
  [?]       Help
  [q]       Quit

═══════════════════════════════════════════════════════════"
}

fn view_domain_menu(_model: types.Model, domain: types.Domain) -> String {
  let domain_name = case domain {
    types.FatSecretDomain -> "FatSecret API"
    types.TandoorDomain -> "Tandoor Recipes"
    types.DatabaseDomain -> "Database"
    types.MealPlanningDomain -> "Meal Planning"
    types.NutritionDomain -> "Nutrition"
    types.SchedulerDomain -> "Scheduler"
  }
  "Domain: " <> domain_name <> " (submenu not yet implemented)"
}

fn view_food_search(model: types.Model) -> String {
  "FatSecret Foods Search
Query: " <> model.search_query <> "
Loading: " <> case model.loading {
    True -> "Yes"
    False -> "No"
  } <> "
Results: " <> case model.results {
    Some(_) -> "Available"
    None -> "None"
  }
}

fn view_diary(_model: types.Model) -> String {
  "Diary View (Not yet implemented)"
}

fn view_exercise(_model: types.Model) -> String {
  "Exercise View (Not yet implemented)"
}

fn view_favorites(_model: types.Model) -> String {
  "Favorites View (Not yet implemented)"
}

fn view_recipes(_model: types.Model) -> String {
  "Recipes View (Not yet implemented)"
}

fn view_saved_meals(_model: types.Model) -> String {
  "Saved Meals View (Not yet implemented)"
}

fn view_profile(_model: types.Model) -> String {
  "Profile View (Not yet implemented)"
}

fn view_weight(_model: types.Model) -> String {
  "Weight View (Not yet implemented)"
}

fn view_brand_search(_model: types.Model) -> String {
  "Brand Search View (Not yet implemented)"
}

fn view_tandoor_recipes(_model: types.Model) -> String {
  "Tandoor Recipes View (Not yet implemented)"
}

fn view_database_foods(_model: types.Model) -> String {
  "Database Foods View (Not yet implemented)"
}

fn view_meal_plan_generator(_model: types.Model) -> String {
  "Meal Plan Generator View (Not yet implemented)"
}

fn view_nutrition_analysis(_model: types.Model) -> String {
  "Nutrition Analysis View (Not yet implemented)"
}

fn view_scheduler(_model: types.Model) -> String {
  "Scheduler View (Not yet implemented)"
}

fn view_error(err: String) -> String {
  "❌ Error: " <> err
}

fn view_loading(msg: String) -> String {
  "⏳ " <> msg <> "..."
}
