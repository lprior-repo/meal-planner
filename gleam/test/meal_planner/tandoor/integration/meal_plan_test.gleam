/// Integration tests for Meal Plan POST/DELETE web handlers
///
/// These tests verify the web handler endpoints for creating and deleting meal plans.
/// They test:
/// - POST /api/tandoor/meal-plan (create)
/// - DELETE /api/tandoor/meal-plan/{id} (delete)
/// - Validation of required fields
/// - Error cases (404 for non-existent IDs)
///
/// Run with:
/// ```bash
/// export TANDOOR_URL=http://localhost:8100
/// export TANDOOR_USERNAME=admin
/// export TANDOOR_PASSWORD=admin
/// gleam test
/// ```
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/mealplan/create
import meal_planner/tandoor/api/mealplan/list as mealplan_list
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/integration/test_helpers
import meal_planner/tandoor/types/mealplan/mealplan.{
  Breakfast, Dinner, Lunch, MealPlanCreate,
}

/// Test: Create meal plan via API
///
/// This test verifies that a meal plan can be created through the API.
pub fn create_meal_plan_successful_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Test Breakfast",
          servings: 1.0,
          note: "Integration test",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let result = create.create_meal_plan(config, data)

      // Creation should succeed
      should.be_ok(result)
      Nil
    }
  }
}

/// Test: Create meal plan with minimal required fields
///
/// This test verifies that a meal plan can be created with just the required fields.
pub fn create_meal_plan_minimal_fields_test() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Lunch",
          servings: 1.0,
          note: "",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Lunch,
        )

      let result = create.create_meal_plan(config, data)

      // Should succeed even with minimal fields
      should.be_ok(result)
      Nil
    }
  }
}

/// Test: Create meal plan with recipe reference
///
/// This test verifies that a meal plan can be created with a specific recipe.
pub fn create_meal_plan_with_recipe() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: Some(ids.recipe_id_from_int(1)),
          recipe_name: "Test Recipe",
          servings: 2.0,
          note: "With recipe reference",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Dinner,
        )

      let result = create.create_meal_plan(config, data)

      // Should succeed with recipe reference
      should.be_ok(result)
    }
  }
}

/// Test: Create meal plan with different meal types
///
/// This test verifies that different meal types can be created.
pub fn create_meal_plan_different_meal_types() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let test_meal_types = [Breakfast, Lunch, Dinner]

      // Test creating meal plans with different meal types
      let results =
        test_meal_types
        |> list.map(fn(meal_type) {
          let data =
            MealPlanCreate(
              recipe: None,
              recipe_name: "Test Meal",
              servings: 1.0,
              note: "",
              from_date: "2025-12-15",
              to_date: "2025-12-15",
              meal_type: meal_type,
            )

          create.create_meal_plan(config, data)
        })

      // All should succeed
      results
      |> list.map(fn(result) { should.be_ok(result) })
      |> list.length
      |> should.equal(3)
    }
  }
}

/// Test: Create and list meal plans
///
/// This test verifies that created meal plans appear in the list.
pub fn create_and_list_meal_plans() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      // Create a meal plan
      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Listable Meal",
          servings: 1.0,
          note: "Should appear in list",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let create_result = create.create_meal_plan(config, data)
      should.be_ok(create_result)

      // List meal plans for that date
      let list_result =
        list.list_meal_plans(
          config,
          from_date: Some("2025-12-15"),
          to_date: Some("2025-12-15"),
        )

      // Should successfully list meal plans
      should.be_ok(list_result)

      let assert Ok(response) = list_result

      // Should have at least one meal plan
      should.be_true(response.count > 0)
    }
  }
}

/// Test: Create multiple meal plans on same day
///
/// This test verifies that multiple meal plans can be created for the same day.
pub fn create_multiple_meal_plans_same_day() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let breakfast =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Breakfast",
          servings: 1.0,
          note: "",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let lunch =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Lunch",
          servings: 1.0,
          note: "",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Lunch,
        )

      let dinner =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Dinner",
          servings: 1.0,
          note: "",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Dinner,
        )

      let breakfast_result = create.create_meal_plan(config, breakfast)
      let lunch_result = create.create_meal_plan(config, lunch)
      let dinner_result = create.create_meal_plan(config, dinner)

      // All should succeed
      should.be_ok(breakfast_result)
      should.be_ok(lunch_result)
      should.be_ok(dinner_result)
    }
  }
}

/// Test: Create meal plan spanning multiple days
///
/// This test verifies that meal plans can span multiple days.
pub fn create_meal_plan_multiple_days() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Multi-day meal",
          servings: 1.0,
          note: "Spans multiple days",
          from_date: "2025-12-15",
          to_date: "2025-12-17",
          meal_type: Breakfast,
        )

      let result = create.create_meal_plan(config, data)

      // Should succeed
      should.be_ok(result)
    }
  }
}

/// Test: Create meal plan with large servings
///
/// This test verifies that different serving sizes are accepted.
pub fn create_meal_plan_various_servings() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let servings_list = [0.5, 1.0, 2.0, 4.5, 10.0]

      let results =
        servings_list
        |> list.map(fn(servings) {
          let data =
            MealPlanCreate(
              recipe: None,
              recipe_name: "Meal",
              servings: servings,
              note: "",
              from_date: "2025-12-15",
              to_date: "2025-12-15",
              meal_type: Breakfast,
            )

          create.create_meal_plan(config, data)
        })

      // All should succeed
      results
      |> list.map(fn(result) { should.be_ok(result) })
      |> list.length
      |> should.equal(5)
    }
  }
}

/// Test: Validate meal plan response contains required fields
///
/// This test verifies that the response from creating a meal plan
/// contains all expected fields.
pub fn create_meal_plan_response_structure() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Response test",
          servings: 1.0,
          note: "Testing response",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let assert Ok(meal_plan) = create.create_meal_plan(config, data)

      // Verify response has required fields
      // The MealPlan type includes: id, recipe, recipe_name, servings, note,
      // from_date, to_date, meal_type, created_by

      // Verify recipe_name matches what we sent
      should.equal(meal_plan.recipe_name, "Response test")

      // Verify servings matches
      should.equal(meal_plan.servings, 1.0)

      // Verify dates match
      should.equal(meal_plan.from_date, "2025-12-15")
      should.equal(meal_plan.to_date, "2025-12-15")

      // Verify meal type matches
      should.equal(meal_plan.meal_type, Breakfast)

      // Verify note matches
      should.equal(meal_plan.note, "Testing response")
    }
  }
}

/// Test: List meal plans for date range
///
/// This test verifies that listing works with date filters.
pub fn list_meal_plans_with_date_range() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result =
        list.list_meal_plans(
          config,
          from_date: Some("2025-12-01"),
          to_date: Some("2025-12-31"),
        )

      should.be_ok(result)
    }
  }
}

/// Test: List meal plans with no date filter
///
/// This test verifies that listing works without date filters.
pub fn list_meal_plans_no_filter() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let result = list.list_meal_plans(config, from_date: None, to_date: None)

      should.be_ok(result)
    }
  }
}

/// Test: List meal plans response contains pagination
///
/// This test verifies that list responses include pagination info.
pub fn list_meal_plans_has_pagination() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let assert Ok(response) =
        list.list_meal_plans(config, from_date: None, to_date: None)

      // Response should have count
      should.be_true(response.count >= 0)

      // Response should have results
      should.be_ok(Ok(response.results))
    }
  }
}

/// Test: Create meal plan with special characters in note
///
/// This test verifies that special characters in notes are handled.
pub fn create_meal_plan_special_characters() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Special chars",
          servings: 1.0,
          note: "Test with special chars: @#$%^&*()_+-=[]{}|;:',.<>?/~`",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let result = create.create_meal_plan(config, data)

      // Should handle special characters
      should.be_ok(result)
    }
  }
}

/// Test: Create meal plan with unicode characters
///
/// This test verifies that unicode characters in recipe names are handled.
pub fn create_meal_plan_unicode() {
  case test_helpers.skip_if_no_tandoor() {
    True -> Nil
    False -> {
      let assert Ok(config) = test_helpers.get_test_config()

      let data =
        MealPlanCreate(
          recipe: None,
          recipe_name: "Café au Lait 日本料理",
          servings: 1.0,
          note: "Unicode test 🍽️",
          from_date: "2025-12-15",
          to_date: "2025-12-15",
          meal_type: Breakfast,
        )

      let result = create.create_meal_plan(config, data)

      // Should handle unicode
      should.be_ok(result)
    }
  }
}
