/// Integration tests for User Preferences API
///
/// Tests the complete preferences API workflow:
/// - Getting current user preferences
/// - Getting preferences by user ID
/// - Updating preferences with partial updates
/// - Error handling for invalid operations
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/user/preferences
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/user/user_preference_encoder.{
  type UserPreferenceUpdateRequest, UserPreferenceUpdateRequest,
}
import test_setup

pub fn get_current_user_preferences_test() {
  // Skip if no integration test environment
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      // Get current user's preferences
      let result = preferences.get_current_user_preferences(config)

      // Should succeed and return valid preferences
      should.be_ok(result)
      let assert Ok(prefs) = result

      // Verify required fields are present
      prefs.theme |> should.not_equal("")
      prefs.default_unit |> should.not_equal("")
      prefs.default_page |> should.not_equal("")

      // Verify numeric fields are reasonable
      prefs.ingredient_decimals |> should.be_true(fn(d) { d >= 0 && d <= 10 })
      prefs.shopping_auto_sync |> should.be_true(fn(s) { s >= 0 })
      prefs.shopping_recent_days |> should.be_true(fn(d) { d > 0 })

      // Verify user data is populated
      prefs.user.username |> should.not_equal("")
      prefs.user.id |> ids.user_id_to_int |> should.be_true(fn(id) { id > 0 })
    }
  }
}

pub fn get_user_preferences_by_id_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      // First get current user to get their ID
      let assert Ok(current_prefs) =
        preferences.get_current_user_preferences(config)

      let user_id = current_prefs.user.id

      // Get preferences by user ID
      let result = preferences.get_user_preferences(config, user_id: user_id)

      should.be_ok(result)
      let assert Ok(prefs) = result

      // Should match current user's preferences
      prefs.user.id |> should.equal(user_id)
      prefs.theme |> should.equal(current_prefs.theme)
      prefs.default_unit |> should.equal(current_prefs.default_unit)
    }
  }
}

pub fn update_user_preferences_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      // Get current preferences
      let assert Ok(current_prefs) =
        preferences.get_current_user_preferences(config)

      let user_id = current_prefs.user.id

      // Create update request - toggle use_fractions
      let update = UserPreferenceUpdateRequest(
        theme: None,
        nav_bg_color: None,
        nav_text_color: None,
        nav_show_logo: None,
        default_unit: None,
        default_page: None,
        use_fractions: Some(!current_prefs.use_fractions),
        use_kj: None,
        plan_share: None,
        nav_sticky: None,
        ingredient_decimals: None,
        comments: None,
        shopping_auto_sync: None,
        mealplan_autoadd_shopping: None,
        default_delay: None,
        mealplan_autoinclude_related: None,
        mealplan_autoexclude_onhand: None,
        shopping_share: None,
        shopping_recent_days: None,
        csv_delim: None,
        csv_prefix: None,
        filter_to_supermarket: None,
        shopping_add_onhand: None,
        left_handed: None,
        show_step_ingredients: None,
      )

      // Update preferences
      let result = preferences.update_user_preferences(
        config,
        user_id: user_id,
        update: update,
      )

      should.be_ok(result)
      let assert Ok(updated_prefs) = result

      // Verify the update was applied
      updated_prefs.use_fractions
        |> should.equal(!current_prefs.use_fractions)

      // Verify other fields remained unchanged
      updated_prefs.theme |> should.equal(current_prefs.theme)
      updated_prefs.default_unit |> should.equal(current_prefs.default_unit)
      updated_prefs.ingredient_decimals
        |> should.equal(current_prefs.ingredient_decimals)

      // Restore original setting
      let restore = UserPreferenceUpdateRequest(
        use_fractions: Some(current_prefs.use_fractions),
        theme: None,
        nav_bg_color: None,
        nav_text_color: None,
        nav_show_logo: None,
        default_unit: None,
        default_page: None,
        use_kj: None,
        plan_share: None,
        nav_sticky: None,
        ingredient_decimals: None,
        comments: None,
        shopping_auto_sync: None,
        mealplan_autoadd_shopping: None,
        default_delay: None,
        mealplan_autoinclude_related: None,
        mealplan_autoexclude_onhand: None,
        shopping_share: None,
        shopping_recent_days: None,
        csv_delim: None,
        csv_prefix: None,
        filter_to_supermarket: None,
        shopping_add_onhand: None,
        left_handed: None,
        show_step_ingredients: None,
      )

      let assert Ok(_) = preferences.update_user_preferences(
        config,
        user_id: user_id,
        update: restore,
      )
    }
  }
}

pub fn update_multiple_fields_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      let assert Ok(current_prefs) =
        preferences.get_current_user_preferences(config)

      let user_id = current_prefs.user.id

      // Update multiple fields at once
      let update = UserPreferenceUpdateRequest(
        nav_sticky: Some(!current_prefs.nav_sticky),
        left_handed: Some(!current_prefs.left_handed),
        comments: Some(!current_prefs.comments),
        theme: None,
        nav_bg_color: None,
        nav_text_color: None,
        nav_show_logo: None,
        default_unit: None,
        default_page: None,
        use_fractions: None,
        use_kj: None,
        plan_share: None,
        ingredient_decimals: None,
        shopping_auto_sync: None,
        mealplan_autoadd_shopping: None,
        default_delay: None,
        mealplan_autoinclude_related: None,
        mealplan_autoexclude_onhand: None,
        shopping_share: None,
        shopping_recent_days: None,
        csv_delim: None,
        csv_prefix: None,
        filter_to_supermarket: None,
        shopping_add_onhand: None,
        show_step_ingredients: None,
      )

      let result = preferences.update_user_preferences(
        config,
        user_id: user_id,
        update: update,
      )

      should.be_ok(result)
      let assert Ok(updated) = result

      // Verify all three updates were applied
      updated.nav_sticky |> should.equal(!current_prefs.nav_sticky)
      updated.left_handed |> should.equal(!current_prefs.left_handed)
      updated.comments |> should.equal(!current_prefs.comments)

      // Restore
      let restore = UserPreferenceUpdateRequest(
        nav_sticky: Some(current_prefs.nav_sticky),
        left_handed: Some(current_prefs.left_handed),
        comments: Some(current_prefs.comments),
        theme: None,
        nav_bg_color: None,
        nav_text_color: None,
        nav_show_logo: None,
        default_unit: None,
        default_page: None,
        use_fractions: None,
        use_kj: None,
        plan_share: None,
        ingredient_decimals: None,
        shopping_auto_sync: None,
        mealplan_autoadd_shopping: None,
        default_delay: None,
        mealplan_autoinclude_related: None,
        mealplan_autoexclude_onhand: None,
        shopping_share: None,
        shopping_recent_days: None,
        csv_delim: None,
        csv_prefix: None,
        filter_to_supermarket: None,
        shopping_add_onhand: None,
        show_step_ingredients: None,
      )

      let assert Ok(_) = preferences.update_user_preferences(
        config,
        user_id: user_id,
        update: restore,
      )
    }
  }
}

pub fn convenience_functions_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      // Test get_preferences alias
      let result1 = preferences.get_preferences(config)
      let result2 = preferences.get_current_user_preferences(config)

      should.be_ok(result1)
      should.be_ok(result2)

      let assert Ok(prefs1) = result1
      let assert Ok(prefs2) = result2

      // Should return same data
      prefs1.user.id |> should.equal(prefs2.user.id)
      prefs1.theme |> should.equal(prefs2.theme)
    }
  }
}

pub fn get_invalid_user_preferences_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      // Try to get preferences for non-existent user
      let invalid_user_id = ids.user_id(999_999_999)

      let result = preferences.get_user_preferences(
        config,
        user_id: invalid_user_id,
      )

      // Should return an error (404 or similar)
      should.be_error(result)
    }
  }
}

pub fn update_with_invalid_data_test() {
  case test_setup.get_test_config() {
    Error(_) -> Nil
    Ok(config) -> {
      let assert Ok(current_prefs) =
        preferences.get_current_user_preferences(config)

      let user_id = current_prefs.user.id

      // Try to update with invalid decimal places (should be 0-10)
      let update = UserPreferenceUpdateRequest(
        ingredient_decimals: Some(99),
        theme: None,
        nav_bg_color: None,
        nav_text_color: None,
        nav_show_logo: None,
        default_unit: None,
        default_page: None,
        use_fractions: None,
        use_kj: None,
        plan_share: None,
        nav_sticky: None,
        comments: None,
        shopping_auto_sync: None,
        mealplan_autoadd_shopping: None,
        default_delay: None,
        mealplan_autoinclude_related: None,
        mealplan_autoexclude_onhand: None,
        shopping_share: None,
        shopping_recent_days: None,
        csv_delim: None,
        csv_prefix: None,
        filter_to_supermarket: None,
        shopping_add_onhand: None,
        left_handed: None,
        show_step_ingredients: None,
      )

      let result = preferences.update_user_preferences(
        config,
        user_id: user_id,
        update: update,
      )

      // Should return an error (validation failure)
      should.be_error(result)
    }
  }
}
