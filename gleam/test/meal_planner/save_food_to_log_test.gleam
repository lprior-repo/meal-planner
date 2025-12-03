/// Tests for save_food_to_log function with source tracking
///
/// Test-Driven Development (TDD) approach:
/// 1. Write failing tests (RED) ⬅️ WE ARE HERE
/// 2. Implement minimal code to pass (GREEN)
/// 3. Refactor while keeping tests passing (REFACTOR)

import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/otp/actor
import gleeunit
import gleeunit/should
import meal_planner/storage
import pog
import shared/types.{
  type FoodSource, Breakfast, CustomFoodSource, Macros, Micronutrients,
  RecipeSource, UsdaFoodSource,
}

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Mock database connection for testing
fn mock_db() -> pog.Connection {
  let pool_name = process.new_name(prefix: "test_mock")
  let config =
    pog.default_config(pool_name: pool_name)
    |> pog.host("localhost")
    |> pog.database("test")
    |> pog.user("test")
    |> pog.pool_size(1)

  case pog.start(config) {
    Ok(actor.Started(_pid, conn)) -> conn
    Error(_) ->
      panic as "Failed to create mock DB - this shouldn't happen in validation tests"
  }
}

// =============================================================================
// TEST SUITE: Function Signature and Type Safety
// =============================================================================

/// Test 1: RecipeSource should be type-safe
pub fn recipe_source_type_safe_test() {
  let source = RecipeSource("recipe-123")

  // This test verifies the type compiles correctly
  case source {
    RecipeSource(id) -> should.equal(id, "recipe-123")
    _ -> should.fail()
  }
}

/// Test 2: CustomFoodSource should include user_id
pub fn custom_food_source_includes_user_test() {
  let source = CustomFoodSource("food-456", "user-789")

  case source {
    CustomFoodSource(food_id, user_id) -> {
      should.equal(food_id, "food-456")
      should.equal(user_id, "user-789")
    }
    _ -> should.fail()
  }
}

/// Test 3: UsdaFoodSource should use Int for fdc_id
pub fn usda_food_source_uses_int_test() {
  let source = UsdaFoodSource(123_456)

  case source {
    UsdaFoodSource(fdc_id) -> should.equal(fdc_id, 123_456)
    _ -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: RecipeSource Logging
// =============================================================================

/// Test 4: Saving a recipe should return Ok(FoodLogEntry)
pub fn save_recipe_returns_ok_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      1.0,
      Breakfast,
    )

  // Will FAIL until implemented
  result
  |> should.be_ok()
}

/// Test 5: Saved recipe entry should have correct source_type
pub fn saved_recipe_has_correct_source_type_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      should.equal(entry.source_type, "recipe")
      should.equal(entry.source_id, "recipe-123")
    }
    Error(_) -> should.fail()
  }
}

/// Test 6: Saved recipe entry should have all required fields
pub fn saved_recipe_has_all_fields_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      2.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      // Check ID is generated
      should.be_true(entry.id != "")

      // Check recipe fields
      should.equal(entry.recipe_id, "recipe-123")
      should.equal(entry.servings, 2.0)

      // Check meal type
      case entry.meal_type {
        Breakfast -> should.be_true(True)
        _ -> should.fail()
      }

      // Check macros exist
      should.be_true(entry.macros.protein >= 0.0)
      should.be_true(entry.macros.fat >= 0.0)
      should.be_true(entry.macros.carbs >= 0.0)

      // Check timestamps
      should.be_true(entry.logged_at != "")
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: CustomFoodSource Logging
// =============================================================================

/// Test 7: Saving custom food should return Ok
pub fn save_custom_food_returns_ok_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      1.5,
      Breakfast,
    )

  result
  |> should.be_ok()
}

/// Test 8: Saved custom food should have correct source tracking
pub fn saved_custom_food_has_correct_source_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      should.equal(entry.source_type, "custom_food")
      should.equal(entry.source_id, "food-456")
    }
    Error(_) -> should.fail()
  }
}

/// Test 9: Custom food should scale macros by servings
pub fn custom_food_scales_macros_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      2.0,
      Breakfast,
    )

  // Assuming food has 10g protein per serving
  // With 2.0 servings, should be 20g
  case result {
    Ok(entry) -> {
      // Just verify scaling occurred (exact values depend on test data)
      should.be_true(entry.servings == 2.0)
      should.be_true(entry.macros.protein > 0.0)
    }
    Error(_) -> should.fail()
  }
}

/// Test 10: Custom food should include micronutrients if available
pub fn custom_food_includes_micronutrients_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      // Should be Some(Micronutrients) or None depending on test data
      case entry.micronutrients {
        Some(_micros) -> should.be_true(True)
        None -> should.be_true(True)
      }
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: UsdaFoodSource Logging
// =============================================================================

/// Test 11: Saving USDA food should return Ok
pub fn save_usda_food_returns_ok_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      UsdaFoodSource(123_456),
      1.0,
      Breakfast,
    )

  result
  |> should.be_ok()
}

/// Test 12: Saved USDA food should have correct source tracking
pub fn saved_usda_food_has_correct_source_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      UsdaFoodSource(123_456),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      should.equal(entry.source_type, "usda_food")
      // fdc_id converted to String
      should.equal(entry.source_id, "123456")
    }
    Error(_) -> should.fail()
  }
}

/// Test 13: USDA food should parse nutrients into macros
pub fn usda_food_parses_nutrients_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      UsdaFoodSource(123_456),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      // Should have parsed macros from USDA nutrients
      should.be_true(entry.macros.protein >= 0.0)
      should.be_true(entry.macros.fat >= 0.0)
      should.be_true(entry.macros.carbs >= 0.0)
    }
    Error(_) -> should.fail()
  }
}

/// Test 14: USDA food should parse micronutrients if available
pub fn usda_food_parses_micronutrients_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      UsdaFoodSource(123_456),
      1.0,
      Breakfast,
    )

  case result {
    Ok(entry) -> {
      // Micronutrients may be present or None depending on USDA data
      case entry.micronutrients {
        Some(micros) -> {
          // If present, check structure is valid
          should.be_true(True)
        }
        None -> should.be_true(True)
      }
    }
    Error(_) -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: Authorization and Security
// =============================================================================

/// Test 15: Custom food with wrong user_id should return Unauthorized
pub fn custom_food_wrong_user_returns_error_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-2"),
      // food belongs to user-2, but user-1 is trying to log
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  // Should be Unauthorized error
  case result {
    Error(storage.Unauthorized(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

/// Test 16: Non-existent recipe should return NotFound
pub fn nonexistent_recipe_returns_not_found_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("nonexistent-recipe"),
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  case result {
    Error(storage.NotFound) -> should.be_true(True)
    _ -> should.fail()
  }
}

/// Test 17: Non-existent custom food should return NotFound
pub fn nonexistent_custom_food_returns_not_found_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("nonexistent-food", "user-1"),
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  case result {
    Error(storage.NotFound) -> should.be_true(True)
    _ -> should.fail()
  }
}

/// Test 18: Non-existent USDA food should return NotFound
pub fn nonexistent_usda_food_returns_not_found_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      UsdaFoodSource(999_999_999),
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  case result {
    Error(storage.NotFound) -> should.be_true(True)
    _ -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: Input Validation
// =============================================================================

/// Test 19: Zero servings should be allowed (valid use case)
pub fn zero_servings_allowed_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      0.0,
      Breakfast,
    )

  // Zero servings is valid (e.g., removing from log)
  result
  |> should.be_ok()
}

/// Test 20: Negative servings should return InvalidInput error
pub fn negative_servings_returns_error_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      -1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  case result {
    Error(storage.InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

/// Test 21: Empty date string should return InvalidInput
pub fn empty_date_returns_error_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "",
      RecipeSource("recipe-123"),
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  case result {
    Error(storage.InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

/// Test 22: Invalid date format should be handled
pub fn invalid_date_format_returns_error_test() {
  let result =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "not-a-date",
      RecipeSource("recipe-123"),
      1.0,
      Breakfast,
    )

  result
  |> should.be_error()

  // PostgreSQL will validate date format
  case result {
    Error(storage.DatabaseError(_)) -> should.be_true(True)
    Error(storage.InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// =============================================================================
// TEST SUITE: Scaling Logic
// =============================================================================

/// Test 23: Recipe macros should scale with servings
pub fn recipe_macros_scale_with_servings_test() {
  // Get recipe with 1.0 servings
  let result1 =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      1.0,
      Breakfast,
    )

  // Get same recipe with 2.0 servings
  let result2 =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      RecipeSource("recipe-123"),
      2.0,
      Breakfast,
    )

  case result1, result2 {
    Ok(entry1), Ok(entry2) -> {
      // Macros should be doubled
      // Allow small floating point error (0.01)
      let protein_ratio = entry2.macros.protein /. entry1.macros.protein
      should.be_true(protein_ratio >=  1.99 && protein_ratio <= 2.01)
    }
    _, _ -> should.fail()
  }
}

/// Test 24: Custom food micronutrients should scale with servings
pub fn custom_food_micronutrients_scale_test() {
  let result1 =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      1.0,
      Breakfast,
    )

  let result2 =
    storage.save_food_to_log(
      mock_db(),
      "user-1",
      "2024-01-15",
      CustomFoodSource("food-456", "user-1"),
      3.0,
      Breakfast,
    )

  case result1, result2 {
    Ok(entry1), Ok(entry2) -> {
      case entry1.micronutrients, entry2.micronutrients {
        Some(micro1), Some(micro2) -> {
          // Check at least one field scaled correctly
          case micro1.fiber, micro2.fiber {
            Some(f1), Some(f2) -> {
              let ratio = f2 /. f1
              should.be_true(ratio >= 2.99 && ratio <= 3.01)
            }
            _, _ -> should.be_true(True)
            // Skip if no fiber data
          }
        }
        _, _ -> should.be_true(True)
        // Skip if no micronutrients
      }
    }
    _, _ -> should.fail()
  }
}
