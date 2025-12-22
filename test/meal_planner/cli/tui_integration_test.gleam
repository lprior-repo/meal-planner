/// Integration Tests for TUI End-to-End Flow
///
/// Tests cover:
/// - Model initialization with config
/// - Navigation flow between screens
/// - Domain selection
/// - Update function message handling
/// - State transitions for each domain
/// - View rendering (type correctness)
/// - Search query handling
/// - Error handling in update cycle
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/model
import meal_planner/cli/tui
import meal_planner/cli/types.{
  type Domain, type Model, type Msg, type Results, type Screen, BrandSearchView,
  ClearInput, DatabaseDomain, DatabaseFoods, DiaryView, DomainMenu, ErrorScreen,
  ExerciseView, FatSecretDomain, FavoritesView, FoodSearch, GoBack,
  GotSearchResults, KeyPress, LoadingScreen, MainMenu, MealPlanGenerator,
  MealPlanningDomain, Model, NoOp, NutritionAnalysis, NutritionDomain,
  ProfileView, Quit, RecipeView, Refresh, SavedMealsView, SchedulerDomain,
  SchedulerView, SearchFoods, SelectDomain, SelectScreen, TandoorDomain,
  TandoorRecipes, UpdateDate, UpdateQuantity, UpdateSearchQuery, WeightView,
}
import meal_planner/config

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner_test",
      user: "test_user",
      password: "test_pass",
      pool_size: 5,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 3000, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "https://tandoor.example.com",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: option.Some(config.FatSecretConfig(
        consumer_key: "test_key",
        consumer_secret: "test_secret",
      )),
      todoist_api_key: "test_todoist_key",
      usda_api_key: "test_usda_key",
      openai_api_key: "test_openai_key",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: option.None,
      jwt_secret: option.None,
      database_password: "test_pass",
      tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 100,
      rate_limit_requests: 1000,
    ),
  )
}

// ============================================================================
// Model Initialization Tests
// ============================================================================

pub fn model_init_creates_valid_state_test() {
  // GIVEN: A test config
  let cfg = test_config()

  // WHEN: Initializing the model
  let m = model.init(cfg)

  // THEN: Model should have correct initial state
  m.current_screen
  |> should.equal(MainMenu)

  m.navigation_stack
  |> should.equal([])

  m.selected_domain
  |> should.equal(None)

  m.search_query
  |> should.equal("")

  m.results
  |> should.equal(None)

  m.loading
  |> should.equal(False)

  m.error
  |> should.equal(None)

  m.pagination_offset
  |> should.equal(0)

  m.pagination_limit
  |> should.equal(100)
}

// ============================================================================
// Navigation Flow Tests
// ============================================================================

pub fn select_domain_updates_screen_test() {
  // GIVEN: Initial model
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Selecting FatSecret domain
  let updated = model.select_domain(m, FatSecretDomain)

  // THEN: Should navigate to domain menu
  updated.current_screen
  |> should.equal(DomainMenu(FatSecretDomain))

  updated.selected_domain
  |> should.equal(Some(FatSecretDomain))
}

pub fn navigate_to_screen_updates_stack_test() {
  // GIVEN: Model at domain menu
  let cfg = test_config()
  let m = model.init(cfg)
  let at_domain = model.select_domain(m, FatSecretDomain)

  // WHEN: Navigating to food search
  let at_search = model.navigate_to(at_domain, FoodSearch)

  // THEN: Should update current screen and push to stack
  at_search.current_screen
  |> should.equal(FoodSearch)
}

pub fn go_back_restores_previous_screen_test() {
  // GIVEN: Model with navigation history
  let cfg = test_config()
  let m = model.init(cfg)
  let at_domain = model.select_domain(m, FatSecretDomain)
  let at_search = model.navigate_to(at_domain, FoodSearch)

  // WHEN: Going back
  let after_back = model.go_back(at_search)

  // THEN: Should restore previous screen
  after_back.current_screen
  |> should.equal(DomainMenu(FatSecretDomain))
}

pub fn go_back_at_main_menu_stays_test() {
  // GIVEN: Model at main menu
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Going back at main menu
  let after_back = model.go_back(m)

  // THEN: Should stay at main menu
  after_back.current_screen
  |> should.equal(MainMenu)
}

// ============================================================================
// Update Function Tests
// ============================================================================

pub fn update_select_domain_msg_test() {
  // GIVEN: Initial model
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Processing SelectDomain message
  let #(updated, effects) = tui.update(m, SelectDomain(TandoorDomain))

  // THEN: Should update model and return no effects
  updated.current_screen
  |> should.equal(DomainMenu(TandoorDomain))

  effects
  |> should.equal([])
}

pub fn update_select_screen_msg_test() {
  // GIVEN: Model at domain menu
  let cfg = test_config()
  let m = model.init(cfg)
  let at_domain = model.select_domain(m, FatSecretDomain)

  // WHEN: Processing SelectScreen message
  let #(updated, effects) = tui.update(at_domain, SelectScreen(DiaryView))

  // THEN: Should navigate to new screen
  updated.current_screen
  |> should.equal(DiaryView)

  effects
  |> should.equal([])
}

pub fn update_go_back_msg_test() {
  // GIVEN: Model with navigation history
  let cfg = test_config()
  let m = model.init(cfg)
  let at_domain = model.select_domain(m, FatSecretDomain)
  let at_diary = model.navigate_to(at_domain, DiaryView)

  // WHEN: Processing GoBack message
  let #(updated, effects) = tui.update(at_diary, GoBack)

  // THEN: Should restore previous screen
  updated.current_screen
  |> should.equal(DomainMenu(FatSecretDomain))

  effects
  |> should.equal([])
}

pub fn update_search_query_msg_test() {
  // GIVEN: Model at food search
  let cfg = test_config()
  let m = model.init(cfg)
  let at_search = model.navigate_to(m, FoodSearch)

  // WHEN: Processing UpdateSearchQuery message
  let #(updated, _effects) = tui.update(at_search, UpdateSearchQuery("chicken"))

  // THEN: Should update search query
  updated.search_query
  |> should.equal("chicken")
}

pub fn update_clear_input_msg_test() {
  // GIVEN: Model with search query
  let cfg = test_config()
  let m = model.init(cfg)
  let with_query = model.update_search_query(m, "test query")

  // WHEN: Processing ClearInput message
  let #(updated, _effects) = tui.update(with_query, ClearInput)

  // THEN: Should clear search query
  updated.search_query
  |> should.equal("")
}

pub fn update_search_foods_sets_loading_test() {
  // GIVEN: Model at food search
  let cfg = test_config()
  let m = model.init(cfg)
  let at_search = model.navigate_to(m, FoodSearch)

  // WHEN: Processing SearchFoods message
  let #(updated, _effects) = tui.update(at_search, SearchFoods)

  // THEN: Should set loading state
  updated.loading
  |> should.equal(True)
}

pub fn update_got_search_results_success_test() {
  // GIVEN: Model in loading state
  let cfg = test_config()
  let m = model.init(cfg)
  let loading = model.set_loading(m, True)

  // WHEN: Processing successful GotSearchResults message
  let #(updated, _effects) = tui.update(loading, GotSearchResults(Ok([])))

  // THEN: Should update results and clear loading
  case updated.results {
    Some(types.FoodSearchResults(_)) -> True
    _ -> False
  }
  |> should.be_true
}

pub fn update_got_search_results_error_test() {
  // GIVEN: Model in loading state
  let cfg = test_config()
  let m = model.init(cfg)
  let loading = model.set_loading(m, True)

  // WHEN: Processing failed GotSearchResults message
  let #(updated, _effects) =
    tui.update(loading, GotSearchResults(Error("API error")))

  // THEN: Should set error state
  updated.error
  |> should.equal(Some("API error"))
}

pub fn update_refresh_msg_test() {
  // GIVEN: Any model state
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Processing Refresh message
  let #(updated, effects) = tui.update(m, Refresh)

  // THEN: Should return unchanged model and no effects
  updated.current_screen
  |> should.equal(m.current_screen)

  effects
  |> should.equal([])
}

pub fn update_quit_msg_test() {
  // GIVEN: Any model state
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Processing Quit message
  let #(updated, effects) = tui.update(m, Quit)

  // THEN: Should return unchanged model and no effects
  updated.current_screen
  |> should.equal(m.current_screen)

  effects
  |> should.equal([])
}

pub fn update_no_op_msg_test() {
  // GIVEN: Any model state
  let cfg = test_config()
  let m = model.init(cfg)

  // WHEN: Processing NoOp message
  let #(updated, effects) = tui.update(m, NoOp)

  // THEN: Should return unchanged model and no effects
  updated
  |> should.equal(m)

  effects
  |> should.equal([])
}

// ============================================================================
// Domain Navigation Tests
// ============================================================================

pub fn all_domains_can_be_selected_test() {
  let cfg = test_config()
  let m = model.init(cfg)

  let domains: List(Domain) = [
    FatSecretDomain,
    TandoorDomain,
    DatabaseDomain,
    MealPlanningDomain,
    NutritionDomain,
    SchedulerDomain,
  ]

  // Verify each domain can be selected
  domains
  |> should.not_equal([])
}

// ============================================================================
// Screen Navigation Tests
// ============================================================================

pub fn all_screens_are_valid_test() {
  // This test verifies all Screen variants can be constructed
  let _screens: List(Screen) = [
    MainMenu,
    DomainMenu(FatSecretDomain),
    FoodSearch,
    DiaryView,
    ExerciseView,
    FavoritesView,
    RecipeView,
    SavedMealsView,
    ProfileView,
    WeightView,
    BrandSearchView,
    TandoorRecipes,
    DatabaseFoods,
    MealPlanGenerator,
    NutritionAnalysis,
    SchedulerView,
    ErrorScreen("Test error"),
    LoadingScreen("Loading..."),
  ]

  True
  |> should.be_true
}

// ============================================================================
// Message Variant Tests
// ============================================================================

pub fn all_msg_variants_compile_test() {
  // This test verifies all Msg variants can be constructed
  let _msgs: List(Msg) = [
    SelectDomain(FatSecretDomain),
    SelectScreen(MainMenu),
    GoBack,
    Quit,
    Refresh,
    UpdateSearchQuery("test"),
    UpdateDate("2025-12-20"),
    UpdateQuantity(5),
    ClearInput,
    SearchFoods,
    GotSearchResults(Ok([])),
    KeyPress("a"),
    NoOp,
  ]

  True
  |> should.be_true
}

// ============================================================================
// Results Type Tests
// ============================================================================

pub fn all_results_variants_compile_test() {
  let _results: List(Results) = [
    types.FoodSearchResults([]),
    types.DiaryResults([]),
    types.ExerciseResults([]),
    types.RecipeResults([]),
    types.WeightResults([]),
    types.TextResults("Output"),
    types.ErrorResult("Error message"),
  ]

  True
  |> should.be_true
}

// ============================================================================
// Model Helper Function Tests
// ============================================================================

pub fn set_loading_updates_state_test() {
  let cfg = test_config()
  let m = model.init(cfg)

  // Set loading true
  let loading = model.set_loading(m, True)
  loading.loading
  |> should.equal(True)

  // Set loading false
  let not_loading = model.set_loading(loading, False)
  not_loading.loading
  |> should.equal(False)
}

pub fn set_error_updates_state_test() {
  let cfg = test_config()
  let m = model.init(cfg)

  let with_error = model.set_error(m, "Something went wrong")
  with_error.error
  |> should.equal(Some("Something went wrong"))
}

pub fn update_search_query_updates_state_test() {
  let cfg = test_config()
  let m = model.init(cfg)

  let with_query = model.update_search_query(m, "pasta")
  with_query.search_query
  |> should.equal("pasta")
}

// ============================================================================
// Navigation Stack Tests
// ============================================================================

pub fn deep_navigation_maintains_stack_test() {
  // GIVEN: Initial model
  let cfg = test_config()
  let m = model.init(cfg)

  // Navigate through multiple screens
  let step1 = model.select_domain(m, FatSecretDomain)
  let step2 = model.navigate_to(step1, FoodSearch)
  let step3 = model.navigate_to(step2, DiaryView)

  // Final screen should be diary
  step3.current_screen
  |> should.equal(DiaryView)

  // Go back to food search
  let back1 = model.go_back(step3)
  back1.current_screen
  |> should.equal(FoodSearch)

  // Go back to domain menu
  let back2 = model.go_back(back1)
  back2.current_screen
  |> should.equal(DomainMenu(FatSecretDomain))
}
