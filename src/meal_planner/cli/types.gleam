/// CLI-specific types for the Shore TUI application
import gleam/option.{type Option}
import meal_planner/config.{type Config}
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/fatsecret/exercise/types as exercise_types
import meal_planner/fatsecret/foods/types as foods_types
import meal_planner/fatsecret/recipes/types as recipe_types
import meal_planner/fatsecret/weight/types as weight_types

pub type Model {
  Model(
    config: Config,
    current_screen: Screen,
    navigation_stack: List(Screen),
    selected_domain: Option(Domain),
    search_query: String,
    results: Option(Results),
    loading: Bool,
    error: Option(String),
    pagination_offset: Int,
    pagination_limit: Int,
  )
}

pub type Screen {
  MainMenu
  DomainMenu(Domain)
  FoodSearch
  DiaryView
  ExerciseView
  FavoritesView
  RecipeView
  SavedMealsView
  ProfileView
  WeightView
  BrandSearchView
  TandoorRecipes
  DatabaseFoods
  MealPlanGenerator
  NutritionAnalysis
  SchedulerView
  ErrorScreen(String)
  LoadingScreen(String)
}

pub type Domain {
  FatSecretDomain
  TandoorDomain
  DatabaseDomain
  MealPlanningDomain
  NutritionDomain
  SchedulerDomain
}

/// Output format for CLI commands
pub type OutputFormat {
  JsonFormat
  TableFormat
  CsvFormat
}

/// CLI command results
pub type Results {
  FoodResults(List(foods_types.Food))
  DiaryResults(List(diary_types.FoodEntry))
  ExerciseResults(List(exercise_types.ExerciseEntry))
  RecipeResults(List(recipe_types.Recipe))
  WeightResults(List(weight_types.WeightEntry))
  TextResults(String)
  ErrorResult(String)
}

pub type Msg {
  // Navigation
  SelectDomain(Domain)
  SelectScreen(Screen)
  GoBack
  Quit
  Refresh

  // Input
  UpdateSearchQuery(String)
  UpdateDate(String)
  UpdateQuantity(Int)
  ClearInput

  // FatSecret Foods
  SearchFoods
  GotSearchResults(Result(List(foods_types.Food), String))
  GetFoodDetails(String)
  GotFoodDetails(Result(String, String))

  // System
  KeyPress(String)
  NoOp
}
