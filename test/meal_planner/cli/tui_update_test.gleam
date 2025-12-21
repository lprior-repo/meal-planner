/// TUI Update Tests - Domain Menu Navigation
///
/// Tests for the Shore-based TUI update function following TDD:
/// - Domain selection navigates to domain menu
/// - Domain menu displays command options
/// - Command selection triggers appropriate screen/action
/// - Keyboard shortcuts (1-9) select commands
/// - ESC navigates back to main menu
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/model
import meal_planner/cli/tui
import meal_planner/cli/types
import meal_planner/config

// ============================================================================
// Test Helpers
// ============================================================================

fn test_config() -> config.Config {
  config.Config(
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      user: "test",
      password: "test",
      database: "test",
      pool_size: 5,
    ),
    fatsecret: config.FatSecretConfig(
      consumer_key: "test",
      consumer_secret: "test",
      base_url: "https://test.com",
      timeout_ms: 5000,
    ),
    tandoor: config.TandoorConfig(
      base_url: "https://test.com",
      api_token: "test",
      timeout_ms: 5000,
    ),
    web: config.WebConfig(host: "localhost", port: 8080, base_path: "/"),
    logging: config.LoggingConfig(level: "info", format: "text"),
  )
}

fn init_model() -> types.Model {
  model.init(test_config())
}

// ============================================================================
// Domain Selection Tests
// ============================================================================

pub fn select_fatsecret_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting FatSecret domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // THEN: Should navigate to FatSecret domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.FatSecretDomain))

  // AND: Domain should be selected
  updated.selected_domain
  |> should.equal(Some(types.FatSecretDomain))

  // AND: Navigation stack should contain main menu
  updated.navigation_stack
  |> list.length
  |> should.equal(1)
}

pub fn select_tandoor_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting Tandoor domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.TandoorDomain))

  // THEN: Should navigate to Tandoor domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.TandoorDomain))

  updated.selected_domain
  |> should.equal(Some(types.TandoorDomain))
}

pub fn select_database_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting Database domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.DatabaseDomain))

  // THEN: Should navigate to Database domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.DatabaseDomain))
}

pub fn select_meal_planning_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting Meal Planning domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.MealPlanningDomain))

  // THEN: Should navigate to Meal Planning domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.MealPlanningDomain))
}

pub fn select_nutrition_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting Nutrition domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.NutritionDomain))

  // THEN: Should navigate to Nutrition domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.NutritionDomain))
}

pub fn select_scheduler_domain_navigates_to_domain_menu_test() {
  // GIVEN: Initial model on main menu
  let initial = init_model()

  // WHEN: Selecting Scheduler domain
  let #(updated, _effects) =
    tui.update(initial, types.SelectDomain(types.SchedulerDomain))

  // THEN: Should navigate to Scheduler domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.SchedulerDomain))
}

// ============================================================================
// Command Selection Tests - FatSecret Domain
// ============================================================================

pub fn select_fatsecret_foods_search_command_navigates_to_food_search_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting foods search command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretFoodsSearch))

  // THEN: Should navigate to food search screen
  updated.current_screen
  |> should.equal(types.FoodSearch)
}

pub fn select_fatsecret_diary_command_navigates_to_diary_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting diary command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretDiaryGet))

  // THEN: Should navigate to diary view
  updated.current_screen
  |> should.equal(types.DiaryView)
}

pub fn select_fatsecret_exercise_command_navigates_to_exercise_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting exercise command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretExerciseList))

  // THEN: Should navigate to exercise view
  updated.current_screen
  |> should.equal(types.ExerciseView)
}

pub fn select_fatsecret_favorites_command_navigates_to_favorites_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting favorites command
  let #(updated, _effects) =
    tui.update(
      on_domain_menu,
      types.SelectCommand(types.FatSecretFavoritesList),
    )

  // THEN: Should navigate to favorites view
  updated.current_screen
  |> should.equal(types.FavoritesView)
}

pub fn select_fatsecret_recipes_command_navigates_to_recipe_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting recipes command
  let #(updated, _effects) =
    tui.update(
      on_domain_menu,
      types.SelectCommand(types.FatSecretRecipesSearch),
    )

  // THEN: Should navigate to recipe view
  updated.current_screen
  |> should.equal(types.RecipeView)
}

pub fn select_fatsecret_profile_command_navigates_to_profile_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting profile command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretProfileGet))

  // THEN: Should navigate to profile view
  updated.current_screen
  |> should.equal(types.ProfileView)
}

pub fn select_fatsecret_weight_command_navigates_to_weight_view_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Selecting weight command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretWeightLog))

  // THEN: Should navigate to weight view
  updated.current_screen
  |> should.equal(types.WeightView)
}

// ============================================================================
// Command Selection Tests - Other Domains
// ============================================================================

pub fn select_tandoor_sync_command_navigates_to_tandoor_recipes_test() {
  // GIVEN: Model on Tandoor domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.TandoorDomain))

  // WHEN: Selecting sync command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.TandoorSync))

  // THEN: Should navigate to Tandoor recipes view
  updated.current_screen
  |> should.equal(types.TandoorRecipes)
}

pub fn select_database_search_command_navigates_to_database_foods_test() {
  // GIVEN: Model on Database domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.DatabaseDomain))

  // WHEN: Selecting foods search command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.DatabaseFoodsSearch))

  // THEN: Should navigate to Database foods view
  updated.current_screen
  |> should.equal(types.DatabaseFoods)
}

pub fn select_meal_plan_generate_command_navigates_to_meal_plan_generator_test() {
  // GIVEN: Model on Meal Planning domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.MealPlanningDomain))

  // WHEN: Selecting generate command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.MealPlanGenerate))

  // THEN: Should navigate to Meal Plan Generator view
  updated.current_screen
  |> should.equal(types.MealPlanGenerator)
}

pub fn select_nutrition_goals_show_command_navigates_to_nutrition_analysis_test() {
  // GIVEN: Model on Nutrition domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.NutritionDomain))

  // WHEN: Selecting goals show command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.NutritionGoalsShow))

  // THEN: Should navigate to Nutrition Analysis view
  updated.current_screen
  |> should.equal(types.NutritionAnalysis)
}

pub fn select_scheduler_list_command_navigates_to_scheduler_view_test() {
  // GIVEN: Model on Scheduler domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.SchedulerDomain))

  // WHEN: Selecting list command
  let #(updated, _effects) =
    tui.update(on_domain_menu, types.SelectCommand(types.SchedulerList))

  // THEN: Should navigate to Scheduler view
  updated.current_screen
  |> should.equal(types.SchedulerView)
}

// ============================================================================
// Navigation Tests
// ============================================================================

pub fn go_back_from_domain_menu_returns_to_main_menu_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Going back
  let #(updated, _effects) = tui.update(on_domain_menu, types.GoBack)

  // THEN: Should return to main menu
  updated.current_screen
  |> should.equal(types.MainMenu)
}

pub fn go_back_from_food_search_returns_to_domain_menu_test() {
  // GIVEN: Model on food search screen (navigated from FatSecret domain)
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))
  let #(on_food_search, _) =
    tui.update(on_domain_menu, types.SelectCommand(types.FatSecretFoodsSearch))

  // WHEN: Going back
  let #(updated, _effects) = tui.update(on_food_search, types.GoBack)

  // THEN: Should return to FatSecret domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.FatSecretDomain))
}

pub fn go_back_from_main_menu_stays_on_main_menu_test() {
  // GIVEN: Model on main menu
  let initial = init_model()

  // WHEN: Going back (at root)
  let #(updated, _effects) = tui.update(initial, types.GoBack)

  // THEN: Should stay on main menu
  updated.current_screen
  |> should.equal(types.MainMenu)
}

// ============================================================================
// Keyboard Navigation Tests
// ============================================================================

pub fn key_press_1_on_main_menu_selects_fatsecret_test() {
  // GIVEN: Model on main menu
  let initial = init_model()

  // WHEN: Pressing '1'
  let #(updated, _effects) = tui.handle_key_press(initial, "1")

  // THEN: Should navigate to FatSecret domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.FatSecretDomain))
}

pub fn key_press_2_on_main_menu_selects_tandoor_test() {
  // GIVEN: Model on main menu
  let initial = init_model()

  // WHEN: Pressing '2'
  let #(updated, _effects) = tui.handle_key_press(initial, "2")

  // THEN: Should navigate to Tandoor domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.TandoorDomain))
}

pub fn key_press_3_on_main_menu_selects_database_test() {
  // GIVEN: Model on main menu
  let initial = init_model()

  // WHEN: Pressing '3'
  let #(updated, _effects) = tui.handle_key_press(initial, "3")

  // THEN: Should navigate to Database domain menu
  updated.current_screen
  |> should.equal(types.DomainMenu(types.DatabaseDomain))
}

pub fn key_press_escape_on_domain_menu_goes_back_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Pressing ESC (unicode escape character)
  let #(updated, _effects) = tui.handle_key_press(on_domain_menu, "\u{001B}")

  // THEN: Should return to main menu
  updated.current_screen
  |> should.equal(types.MainMenu)
}

// ============================================================================
// Key Press on Domain Menu Tests
// ============================================================================

pub fn key_press_1_on_fatsecret_domain_menu_selects_foods_search_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Pressing '1' (Foods Search is first command)
  let #(updated, _effects) = tui.handle_key_press(on_domain_menu, "1")

  // THEN: Should navigate to food search screen
  updated.current_screen
  |> should.equal(types.FoodSearch)
}

pub fn key_press_2_on_fatsecret_domain_menu_selects_food_detail_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Pressing '2' (Food Detail is second command)
  let #(updated, _effects) = tui.handle_key_press(on_domain_menu, "2")

  // THEN: Should navigate to food search screen (for detail lookup)
  updated.current_screen
  |> should.equal(types.FoodSearch)
}

pub fn key_press_3_on_fatsecret_domain_menu_selects_diary_test() {
  // GIVEN: Model on FatSecret domain menu
  let initial = init_model()
  let #(on_domain_menu, _) =
    tui.update(initial, types.SelectDomain(types.FatSecretDomain))

  // WHEN: Pressing '3' (Diary is third command)
  let #(updated, _effects) = tui.handle_key_press(on_domain_menu, "3")

  // THEN: Should navigate to diary view
  updated.current_screen
  |> should.equal(types.DiaryView)
}

// ============================================================================
// Error and Loading State Tests
// ============================================================================

pub fn search_foods_sets_loading_state_test() {
  // GIVEN: Model on food search screen with query
  let initial = init_model()
  let with_query = model.update_search_query(initial, "chicken")

  // WHEN: Triggering search
  let #(updated, effects) = tui.update(with_query, types.SearchFoods)

  // THEN: Should set loading to true
  updated.loading
  |> should.be_true

  // AND: Should return effect for API call
  effects
  |> list.length
  |> should.equal(1)
}

pub fn got_search_results_ok_clears_loading_and_sets_results_test() {
  // GIVEN: Model in loading state
  let initial = init_model()
  let loading = model.set_loading(initial, True)

  // WHEN: Receiving successful results
  let #(updated, _effects) =
    tui.update(loading, types.GotSearchResults(Ok([])))

  // THEN: Should clear loading
  updated.loading
  |> should.be_false

  // AND: Should set results
  updated.results
  |> should.not_equal(None)
}

pub fn got_search_results_error_sets_error_state_test() {
  // GIVEN: Model in loading state
  let initial = init_model()
  let loading = model.set_loading(initial, True)

  // WHEN: Receiving error result
  let #(updated, _effects) =
    tui.update(loading, types.GotSearchResults(Error("Network error")))

  // THEN: Should clear loading
  updated.loading
  |> should.be_false

  // AND: Should set error
  updated.error
  |> should.equal(Some("Network error"))
}
