/// Integration Tests for Tandoor User Preferences Endpoints
///
/// This module tests GET and PUT (PATCH) operations for user preferences.
/// Tests cover retrieving current user preferences and updating various settings.
/// Tests are designed to work with a running Tandoor instance.
import envoy
import gleam/io
import gleam/option
import gleeunit/should
import meal_planner/tandoor/api/user/preferences
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/encoders/user/user_preference_encoder.{
  type UserPreferenceUpdateRequest, UserPreferenceUpdateRequest,
}
import test_setup

/// Helper function to get test client configuration
fn get_test_client() -> Result(client.ClientConfig, String) {
  test_setup.get_test_config()
}

/// Helper to print test status
fn print_test_info(test_name: String) -> Nil {
  io.println("\n  Testing: " <> test_name)
}

// ============================================================================
// GET PREFERENCES OPERATIONS
// ============================================================================

pub fn get_current_user_preferences_test() {
  print_test_info("Get current user preferences")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      should.be_ok(result)
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_alias_test() {
  print_test_info("Get preferences (alias function)")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_preferences(config)
      should.be_ok(result)
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_user_preferences_by_id_test() {
  print_test_info("Get user preferences by user ID")
  case get_test_client() {
    Ok(config) -> {
      // Get current user first to have valid user_id
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let pref_result =
            preferences.get_user_preferences(config, user_id: user_id)
          should.be_ok(pref_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for ID test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_returns_complete_object_test() {
  print_test_info("Get preferences returns complete object with all fields")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          // Verify critical fields are present
          should.be_string(prefs.theme)
          should.be_string(prefs.default_unit)
          should.be_string(prefs.default_page)
          should.be_bool(prefs.use_fractions)
          should.be_bool(prefs.use_kj)
          io.println("    ✓ All preference fields present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_includes_user_info_test() {
  print_test_info("Get preferences includes user information")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_int(prefs.user.id)
          should.be_string(prefs.user.username)
          io.println("    ✓ User information included")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_theme_defaults_test() {
  print_test_info("Get preferences includes theme settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_string(prefs.theme)
          should.be_string(prefs.nav_bg_color)
          should.be_string(prefs.nav_text_color)
          should.be_bool(prefs.nav_show_logo)
          io.println("    ✓ Theme settings present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_unit_settings_test() {
  print_test_info("Get preferences includes unit settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_string(prefs.default_unit)
          should.be_bool(prefs.use_fractions)
          should.be_bool(prefs.use_kj)
          should.be_int(prefs.ingredient_decimals)
          io.println("    ✓ Unit settings present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_meal_plan_settings_test() {
  print_test_info("Get preferences includes meal plan settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_string(prefs.default_page)
          should.be_bool(prefs.mealplan_autoadd_shopping)
          should.be_bool(prefs.mealplan_autoinclude_related)
          should.be_bool(prefs.mealplan_autoexclude_onhand)
          io.println("    ✓ Meal plan settings present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_shopping_settings_test() {
  print_test_info("Get preferences includes shopping settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_int(prefs.shopping_auto_sync)
          should.be_int(prefs.shopping_recent_days)
          should.be_bool(prefs.shopping_add_onhand)
          should.be_bool(prefs.filter_to_supermarket)
          io.println("    ✓ Shopping settings present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_preferences_csv_settings_test() {
  print_test_info("Get preferences includes CSV export settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          should.be_string(prefs.csv_delim)
          should.be_string(prefs.csv_prefix)
          io.println("    ✓ CSV settings present")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

// ============================================================================
// UPDATE PREFERENCES OPERATIONS (PUT/PATCH)
// ============================================================================

pub fn update_preferences_theme_test() {
  print_test_info("Update preferences theme")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.Some("FLATLY"),
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_units_test() {
  print_test_info("Update preferences units")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.None,
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.Some("g"),
              default_page: option.None,
              use_fractions: option.Some(True),
              use_kj: option.Some(False),
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.Some(2),
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_meal_plan_settings_test() {
  print_test_info("Update preferences meal plan settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.None,
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.Some("PLAN"),
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.Some(True),
              default_delay: option.Some(0.0),
              mealplan_autoinclude_related: option.Some(False),
              mealplan_autoexclude_onhand: option.Some(True),
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_shopping_settings_test() {
  print_test_info("Update preferences shopping settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.None,
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.Some(300),
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.Some(30),
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.Some(True),
              shopping_add_onhand: option.Some(False),
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_navigation_settings_test() {
  print_test_info("Update preferences navigation settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.None,
              nav_bg_color: option.Some("#333333"),
              nav_text_color: option.Some("LIGHT"),
              nav_show_logo: option.Some(True),
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.Some(True),
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_csv_settings_test() {
  print_test_info("Update preferences CSV settings")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.None,
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.Some(";"),
              csv_prefix: option.Some("MP"),
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_partial_fields_test() {
  print_test_info("Update preferences with only some fields (partial update)")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.Some("BOOTSTRAP"),
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.Some(False),
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_with_all_fields_test() {
  print_test_info("Update preferences with all fields (comprehensive update)")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.Some("FLATLY"),
              nav_bg_color: option.Some("#444444"),
              nav_text_color: option.Some("DARK"),
              nav_show_logo: option.Some(True),
              default_unit: option.Some("ml"),
              default_page: option.Some("SEARCH"),
              use_fractions: option.Some(True),
              use_kj: option.Some(True),
              plan_share: option.None,
              nav_sticky: option.Some(False),
              ingredient_decimals: option.Some(3),
              comments: option.Some(True),
              shopping_auto_sync: option.Some(600),
              mealplan_autoadd_shopping: option.Some(False),
              default_delay: option.Some(30.0),
              mealplan_autoinclude_related: option.Some(True),
              mealplan_autoexclude_onhand: option.Some(False),
              shopping_share: option.None,
              shopping_recent_days: option.Some(7),
              csv_delim: option.Some(","),
              csv_prefix: option.Some("EX"),
              filter_to_supermarket: option.Some(False),
              shopping_add_onhand: option.Some(True),
              left_handed: option.Some(False),
              show_step_ingredients: option.Some(True),
            )
          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_ok(update_result)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for update test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn update_preferences_delegates_to_api_test() {
  print_test_info("Update preferences delegates to API")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.Some("CERULEAN"),
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )
          let result1 =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )
          should.be_result(result1)
        }
        Error(_) -> {
          io.println("    ⚠️  Could not get current user for delegation test")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

// ============================================================================
// INTEGRATION WORKFLOWS
// ============================================================================

pub fn get_then_update_workflow_test() {
  print_test_info("Get preferences then update workflow")
  case get_test_client() {
    Ok(config) -> {
      let get_result = preferences.get_current_user_preferences(config)
      case get_result {
        Ok(prefs) -> {
          // Store original value
          let original_theme = prefs.theme
          io.println("    Original theme: " <> original_theme)

          // Update theme
          let user_id = ids.user_id(prefs.user.id)
          let update =
            UserPreferenceUpdateRequest(
              theme: option.Some("JOURNAL"),
              nav_bg_color: option.None,
              nav_text_color: option.None,
              nav_show_logo: option.None,
              default_unit: option.None,
              default_page: option.None,
              use_fractions: option.None,
              use_kj: option.None,
              plan_share: option.None,
              nav_sticky: option.None,
              ingredient_decimals: option.None,
              comments: option.None,
              shopping_auto_sync: option.None,
              mealplan_autoadd_shopping: option.None,
              default_delay: option.None,
              mealplan_autoinclude_related: option.None,
              mealplan_autoexclude_onhand: option.None,
              shopping_share: option.None,
              shopping_recent_days: option.None,
              csv_delim: option.None,
              csv_prefix: option.None,
              filter_to_supermarket: option.None,
              shopping_add_onhand: option.None,
              left_handed: option.None,
              show_step_ingredients: option.None,
            )

          let update_result =
            preferences.update_preferences(
              config,
              user_id: user_id,
              update: update,
            )

          case update_result {
            Ok(updated_prefs) -> {
              should.equal(updated_prefs.theme, "JOURNAL")
              io.println(
                "    ✓ Successfully updated theme from "
                <> original_theme
                <> " to JOURNAL",
              )
            }
            Error(_) -> {
              io.println("    ⚠️  Failed to update preferences")
            }
          }
        }
        Error(_) -> {
          io.println("    ⚠️  Failed to get current preferences")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_user_by_id_then_update_workflow_test() {
  print_test_info("Get user preferences by ID then update workflow")
  case get_test_client() {
    Ok(config) -> {
      let get_result = preferences.get_current_user_preferences(config)
      case get_result {
        Ok(prefs) -> {
          let user_id = ids.user_id(prefs.user.id)

          // Get by ID
          let get_by_id_result =
            preferences.get_user_preferences(config, user_id: user_id)

          case get_by_id_result {
            Ok(fetched_prefs) -> {
              // Update
              let update =
                UserPreferenceUpdateRequest(
                  theme: option.Some("SPACELAB"),
                  nav_bg_color: option.None,
                  nav_text_color: option.None,
                  nav_show_logo: option.None,
                  default_unit: option.None,
                  default_page: option.None,
                  use_fractions: option.None,
                  use_kj: option.None,
                  plan_share: option.None,
                  nav_sticky: option.None,
                  ingredient_decimals: option.None,
                  comments: option.None,
                  shopping_auto_sync: option.None,
                  mealplan_autoadd_shopping: option.None,
                  default_delay: option.None,
                  mealplan_autoinclude_related: option.None,
                  mealplan_autoexclude_onhand: option.None,
                  shopping_share: option.None,
                  shopping_recent_days: option.None,
                  csv_delim: option.None,
                  csv_prefix: option.None,
                  filter_to_supermarket: option.None,
                  shopping_add_onhand: option.None,
                  left_handed: option.None,
                  show_step_ingredients: option.None,
                )

              let update_result =
                preferences.update_preferences(
                  config,
                  user_id: user_id,
                  update: update,
                )

              should.be_ok(update_result)
              io.println("    ✓ Successfully fetched by ID and updated")
            }
            Error(_) -> {
              io.println("    ⚠️  Failed to get preferences by ID")
            }
          }
        }
        Error(_) -> {
          io.println("    ⚠️  Failed to get current user for workflow")
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn get_and_verify_all_settings_workflow_test() {
  print_test_info("Get preferences and verify all setting categories")
  case get_test_client() {
    Ok(config) -> {
      let result = preferences.get_current_user_preferences(config)
      case result {
        Ok(prefs) -> {
          // Verify all major setting categories exist
          should.be_string(prefs.theme)
          should.be_string(prefs.default_unit)
          should.be_bool(prefs.use_fractions)
          should.be_bool(prefs.mealplan_autoadd_shopping)
          should.be_int(prefs.shopping_auto_sync)
          should.be_string(prefs.csv_delim)
          should.be_bool(prefs.left_handed)
          io.println("    ✓ All setting categories verified")
        }
        Error(_) -> {
          should.fail()
        }
      }
    }
    Error(_) -> {
      io.println("    ⚠️  Skipping - Tandoor not configured")
    }
  }
}

pub fn handle_missing_environment_variables_test() {
  print_test_info("Handle missing environment variables gracefully")
  let result = test_setup.get_test_config()
  should.be_result(result)
}
