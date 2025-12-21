/// Update - Message handling (Elm Architecture)
///
/// Handles all user actions and produces new model states with effects
import meal_planner/cli/commands
import meal_planner/cli/model
import meal_planner/cli/types

/// Process a message and return updated model with effects
/// Effects are functions fn() -> Msg that Shore will execute
pub fn update(
  model: types.Model,
  msg: types.Msg,
) -> #(types.Model, List(fn() -> types.Msg)) {
  case msg {
    // Navigation
    types.SelectDomain(domain) -> {
      let updated = model.select_domain(model, domain)
      #(updated, [])
    }

    types.SelectScreen(screen) -> {
      let updated = model.navigate_to(model, screen)
      #(updated, [])
    }

    types.SelectCommand(command) -> {
      let screen = command_to_screen(command)
      let updated = model.navigate_to(model, screen)
      #(updated, [])
    }

    types.GoBack -> {
      let updated = model.go_back(model)
      #(updated, [])
    }

    types.Quit -> {
      // In a real TUI, this would gracefully shutdown
      // For now, just clear and exit
      #(model, [])
    }

    types.Refresh -> {
      // Refresh current view - could refetch data
      #(model, [])
    }

    // Input handling
    types.UpdateSearchQuery(query) -> {
      let updated = model.update_search_query(model, query)
      #(updated, [])
    }

    types.UpdateDate(_date) -> {
      // Handle date updates
      #(model, [])
    }

    types.UpdateQuantity(_qty) -> {
      // Handle quantity updates
      #(model, [])
    }

    types.ClearInput -> {
      let updated = model.update_search_query(model, "")
      #(updated, [])
    }

    // FatSecret Foods
    types.SearchFoods -> {
      let loading_model = model.set_loading(model, True)
      let cmd =
        commands.search_foods(model.search_query, types.GotSearchResults)
      #(loading_model, [cmd])
    }

    types.GotSearchResults(result) -> {
      case result {
        Ok(foods) -> {
          let updated = model.set_results(model, types.FoodResults(foods))
          #(updated, [])
        }
        Error(err) -> {
          let updated = model.set_error(model, err)
          #(updated, [])
        }
      }
    }

    types.GetFoodDetails(food_id) -> {
      let loading_model = model.set_loading(model, True)
      let cmd = commands.get_food_details(food_id, types.GotFoodDetails)
      #(loading_model, [cmd])
    }

    types.GotFoodDetails(result) -> {
      case result {
        Ok(_details) -> {
          // Display food details in a new screen
          #(model, [])
        }
        Error(err) -> {
          let updated = model.set_error(model, err)
          #(updated, [])
        }
      }
    }

    // System
    types.KeyPress(_key) -> {
      // Handle keyboard input
      #(model, [])
    }

    types.NoOp -> {
      // No operation
      #(model, [])
    }
  }
}

/// Map domain commands to their target screens
fn command_to_screen(command: types.DomainCommand) -> types.Screen {
  case command {
    // FatSecret commands
    types.FatSecretFoodsSearch -> types.FoodSearch
    types.FatSecretFoodsDetail -> types.FoodSearch
    types.FatSecretDiaryGet -> types.DiaryView
    types.FatSecretExerciseList -> types.ExerciseView
    types.FatSecretFavoritesList -> types.FavoritesView
    types.FatSecretRecipesSearch -> types.RecipeView
    types.FatSecretProfileGet -> types.ProfileView
    types.FatSecretWeightLog -> types.WeightView
    // Tandoor commands
    types.TandoorSync -> types.TandoorRecipes
    types.TandoorCategories -> types.TandoorRecipes
    types.TandoorUpdate -> types.TandoorRecipes
    types.TandoorDelete -> types.TandoorRecipes
    // Database commands
    types.DatabaseFoodsSearch -> types.DatabaseFoods
    types.DatabaseFoodsDetail -> types.DatabaseFoods
    types.DatabaseSync -> types.DatabaseFoods
    // Meal Planning commands
    types.MealPlanGenerate -> types.MealPlanGenerator
    types.MealPlanShow -> types.MealPlanGenerator
    types.MealPlanRegenerate -> types.MealPlanGenerator
    // Nutrition commands
    types.NutritionGoalsShow -> types.NutritionAnalysis
    types.NutritionGoalsSet -> types.NutritionAnalysis
    types.NutritionAnalyze -> types.NutritionAnalysis
    // Scheduler commands
    types.SchedulerList -> types.SchedulerView
    types.SchedulerEnable -> types.SchedulerView
    types.SchedulerDisable -> types.SchedulerView
    types.SchedulerRun -> types.SchedulerView
  }
}
