/// Tests for Tandoor User Management Client
///
/// Tests user and user preference operations:
/// - Getting current authenticated user
/// - Retrieving user preferences
/// - Updating user preferences
/// - Helper functions for preference management
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth}
import meal_planner/tandoor/clients/users
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/user.{
  type User, type UserPreference, type UserPreferenceUpdateRequest, User,
  UserPreference,
}

// ============================================================================
// Test Data Factories
// ============================================================================

/// Create a test client config with bearer authentication
fn test_config() -> ClientConfig {
  client.ClientConfig(
    base_url: "http://localhost:8000",
    auth: BearerAuth(token: "test-token"),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create a test user for use in tests
fn test_user() -> User {
  User(
    id: ids.user_id_from_int(1),
    username: "testuser",
    first_name: "Test",
    last_name: "User",
    display_name: "Test User",
    is_staff: False,
    is_superuser: False,
    is_active: True,
  )
}

/// Create a test user preference for use in tests
fn test_user_preference() -> UserPreference {
  UserPreference(
    user: test_user(),
    image: None,
    theme: "BOOTSTRAP",
    nav_bg_color: "#ffffff",
    nav_text_color: "DARK",
    nav_show_logo: True,
    default_unit: "g",
    default_page: "SEARCH",
    use_fractions: False,
    use_kj: False,
    plan_share: None,
    nav_sticky: True,
    ingredient_decimals: 2,
    comments: True,
    shopping_auto_sync: 30,
    mealplan_autoadd_shopping: False,
    food_inherit_default: "ENABLED",
    default_delay: 0.0,
    mealplan_autoinclude_related: False,
    mealplan_autoexclude_onhand: False,
    shopping_share: None,
    shopping_recent_days: 7,
    csv_delim: ",",
    csv_prefix: "",
    filter_to_supermarket: False,
    shopping_add_onhand: False,
    left_handed: False,
    show_step_ingredients: False,
    food_children_exist: False,
  )
}

// ============================================================================
// Default Update Tests
// ============================================================================

pub fn test_default_update_creates_empty_request() {
  let update = users.default_update()

  update.theme |> should.equal(Nil)
  update.nav_bg_color |> should.equal(Nil)
  update.nav_text_color |> should.equal(Nil)
  update.nav_show_logo |> should.equal(Nil)
  update.default_unit |> should.equal(Nil)
  update.default_page |> should.equal(Nil)
  update.use_fractions |> should.equal(Nil)
  update.use_kj |> should.equal(Nil)
}

pub fn test_default_update_all_fields_none() {
  let update = users.default_update()

  update.plan_share |> should.equal(Nil)
  update.nav_sticky |> should.equal(Nil)
  update.ingredient_decimals |> should.equal(Nil)
  update.comments |> should.equal(Nil)
  update.shopping_auto_sync |> should.equal(Nil)
  update.mealplan_autoadd_shopping |> should.equal(Nil)
}

pub fn test_default_update_can_be_modified() {
  let update = users.default_update()

  // Create a modified update using record update syntax
  let modified = UserPreferenceUpdateRequest(..update, theme: Some("FLATLY"))

  modified.theme |> should.equal(Some("FLATLY"))
  modified.nav_bg_color |> should.equal(Nil)
}

pub fn test_default_update_preserves_field_count() {
  let update = users.default_update()

  // All optional fields should be Nil initially
  case update {
    UserPreferenceUpdateRequest(
      theme,
      nav_bg_color,
      nav_text_color,
      nav_show_logo,
      default_unit,
      default_page,
      use_fractions,
      use_kj,
      plan_share,
      nav_sticky,
      ingredient_decimals,
      comments,
      shopping_auto_sync,
      mealplan_autoadd_shopping,
      default_delay,
      mealplan_autoinclude_related,
      mealplan_autoexclude_onhand,
      shopping_share,
      shopping_recent_days,
      csv_delim,
      csv_prefix,
      filter_to_supermarket,
      shopping_add_onhand,
      left_handed,
      show_step_ingredients,
    ) -> {
      theme |> should.equal(Nil)
      nav_bg_color |> should.equal(Nil)
      nav_text_color |> should.equal(Nil)
      nav_show_logo |> should.equal(Nil)
      default_unit |> should.equal(Nil)
      default_page |> should.equal(Nil)
      use_fractions |> should.equal(Nil)
      use_kj |> should.equal(Nil)
      plan_share |> should.equal(Nil)
      nav_sticky |> should.equal(Nil)
      ingredient_decimals |> should.equal(Nil)
      comments |> should.equal(Nil)
      shopping_auto_sync |> should.equal(Nil)
      mealplan_autoadd_shopping |> should.equal(Nil)
      default_delay |> should.equal(Nil)
      mealplan_autoinclude_related |> should.equal(Nil)
      mealplan_autoexclude_onhand |> should.equal(Nil)
      shopping_share |> should.equal(Nil)
      shopping_recent_days |> should.equal(Nil)
      csv_delim |> should.equal(Nil)
      csv_prefix |> should.equal(Nil)
      filter_to_supermarket |> should.equal(Nil)
      shopping_add_onhand |> should.equal(Nil)
      left_handed |> should.equal(Nil)
      show_step_ingredients |> should.equal(Nil)
    }
  }
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn test_config_is_valid_for_api_calls() {
  let config = test_config()

  config.base_url |> should.equal("http://localhost:8000")
  config.timeout_ms |> should.equal(10_000)
  config.retry_on_transient |> should.be_true
  config.max_retries |> should.equal(3)
}

// ============================================================================
// Test Data Structure Tests
// ============================================================================

pub fn test_user_structure_is_valid() {
  let user = test_user()

  user.username |> should.equal("testuser")
  user.first_name |> should.equal("Test")
  user.last_name |> should.equal("User")
  user.display_name |> should.equal("Test User")
  user.is_staff |> should.be_false
  user.is_superuser |> should.be_false
  user.is_active |> should.be_true
}

pub fn test_user_preference_structure_is_valid() {
  let pref = test_user_preference()

  pref.user.username |> should.equal("testuser")
  pref.theme |> should.equal("BOOTSTRAP")
  pref.nav_bg_color |> should.equal("#ffffff")
  pref.nav_text_color |> should.equal("DARK")
  pref.nav_show_logo |> should.be_true
  pref.default_unit |> should.equal("g")
  pref.default_page |> should.equal("SEARCH")
  pref.use_fractions |> should.be_false
  pref.use_kj |> should.be_false
  pref.nav_sticky |> should.be_true
  pref.ingredient_decimals |> should.equal(2)
  pref.comments |> should.be_true
  pref.shopping_auto_sync |> should.equal(30)
  pref.mealplan_autoadd_shopping |> should.be_false
  pref.food_inherit_default |> should.equal("ENABLED")
  pref.default_delay |> should.equal(0.0)
  pref.shopping_recent_days |> should.equal(7)
  pref.csv_delim |> should.equal(",")
  pref.csv_prefix |> should.equal("")
}
/// Note: Tests for actual API calls (get_current_user, get_user_preferences,
/// get_user_preferences_by_id, update_user_preferences_by_id) require
/// integration testing against a real Tandoor API server or mocked HTTP
/// responses. These functions are tested in the integration test suite.
///
/// Unit tests focus on helper functions and data structure validation.
/// API integration tests are located in test/tandoor/clients/integration/
// ============================================================================
// Integration Test Placeholders
// ============================================================================
