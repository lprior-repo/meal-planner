//// Integration tests for Email → Generation → Sync workflow
////
//// Tests the complete data flow:
//// 1. Email parsing → EmailCommand extraction
//// 2. Command execution → Meal plan update
//// 3. Generation → Recalculate macros with new meal
//// 4. Sync → Log meals to FatSecret with correct nutrition
////
//// Expected failures: NO IMPLEMENTATIONS YET (RED phase)

import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import integration/harness.{type TestContext}
import meal_planner/email/executor
import meal_planner/email/parser
import meal_planner/fatsecret/core/config as fatsecret_config
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/id
import meal_planner/meal_sync
import meal_planner/tandoor/client as tandoor_client
import meal_planner/types.{
  type CommandExecutionResult, type DayOfWeek, type EmailCommand,
  type EmailRequest, type Macros, type MealType, AdjustMeal, Breakfast,
  CommandExecutionResult, Dinner, EmailRequest, Friday, Lunch, Macros, Monday,
}
import simplifile

// ============================================================================
// Test Data Types
// ============================================================================

/// Test meal plan from fixture
type TestMealPlan {
  TestMealPlan(
    week_of: String,
    target_macros: Macros,
    total_macros: Macros,
    days: List(TestDay),
  )
}

type TestDay {
  TestDay(
    day: String,
    breakfast: TestMeal,
    lunch: TestMeal,
    dinner: TestMeal,
    macros: TestDayMacros,
  )
}

type TestMeal {
  TestMeal(
    id: String,
    name: String,
    servings: Float,
    macros: Macros,
    image: String,
    prep_time: Int,
    cook_time: Int,
  )
}

type TestDayMacros {
  TestDayMacros(actual: Macros, calories: Float)
}

// ============================================================================
// Test Setup
// ============================================================================

fn load_test_meal_plan() -> Result(TestMealPlan, String) {
  use fixture_content <- result.try(
    simplifile.read(
      "/home/lewis/src/meal-planner/test/fixtures/meal_plan/complete_week_balanced.json",
    )
    |> result.map_error(fn(_) { "Failed to read fixture file" }),
  )

  // Parse JSON fixture
  // TODO: Implement JSON parsing using gleam/json decoder
  // For now, return error to make test fail (RED phase)
  Error("JSON parsing not implemented yet")
}

fn create_test_email(body: String) -> EmailRequest {
  EmailRequest(
    from_email: "lewis@example.com",
    subject: "Meal plan adjustment",
    body: body,
    is_reply: False,
  )
}

// ============================================================================
// Integration Test 1: Email Parsing Extracts Command
// ============================================================================

pub fn email_parsing_extracts_command_test() {
  // Given: User sends email with @Claude command
  let email_body = "@Claude adjust Friday dinner to pasta"
  let email = create_test_email(email_body)

  // When: Parser extracts command
  let result = parser.parse_email_command(email)

  // Then: Command extracted correctly
  result
  |> should.be_ok

  // Verify command details
  case result {
    Ok(AdjustMeal(day, meal_type, recipe_id)) -> {
      day
      |> should.equal(Friday)

      meal_type
      |> should.equal(Dinner)

      // Recipe ID should be extracted from "pasta"
      recipe_id
      |> id.recipe_id_to_string
      |> string.contains("pasta")
      |> should.be_true
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Integration Test 2: Command Execution Updates Plan
// ============================================================================

pub fn command_execution_updates_plan_test() {
  // Setup: Load test context (credentials)
  let ctx = harness.setup()

  // Skip if database not available
  case ctx.server_available {
    False -> should.fail()
    True -> {
      // Given: Parsed command (Friday dinner → pasta)
      let pasta_recipe_id = id.recipe_id("recipe-pasta-123")
      let _command = AdjustMeal(Friday, Dinner, pasta_recipe_id)

      // When: Execute command with database connection
      // TODO: Get database connection from harness
      // For now, this will fail because execute_command needs connection
      let result: Result(CommandExecutionResult, String) =
        Error("Database connection not implemented in test harness")

      // Then: Command execution succeeds
      result
      |> should.be_ok

      case result {
        Ok(CommandExecutionResult(success, message, _)) -> {
          success
          |> should.be_true

          message
          |> string.contains("Friday")
          |> should.be_true

          message
          |> string.contains("Dinner")
          |> should.be_true
        }
        Error(_err) -> should.fail()
      }
    }
  }
}

// ============================================================================
// Integration Test 3: Generation Recalculates Macros
// ============================================================================

pub fn generation_recalculates_macros_test() {
  // Given: Meal plan with original Friday dinner (Salmon with Roasted Vegetables)
  let fixture_result = load_test_meal_plan()

  fixture_result
  |> should.be_ok

  case fixture_result {
    Ok(meal_plan) -> {
      // Find Friday in the plan
      let friday_day =
        meal_plan.days
        |> list.find(fn(day) { day.day == "Friday" })

      friday_day
      |> should.be_ok

      case friday_day {
        Ok(friday) -> {
          // Original Friday dinner: Salmon (recipe-301)
          friday.dinner.id
          |> should.equal("recipe-301")

          friday.dinner.name
          |> should.equal("Salmon with Roasted Vegetables")

          // Original macros: protein=62.0, fat=21.0, carbs=65.0
          friday.dinner.macros.protein
          |> should.equal(62.0)

          // When: Update to pasta (recipe-pasta-123)
          // TODO: Implement meal plan update logic
          // This should:
          // 1. Fetch pasta recipe nutrition from Tandoor
          // 2. Replace Friday dinner with pasta
          // 3. Recalculate Friday's total macros
          // 4. Ensure other days remain unchanged

          // Then: Friday dinner macros change, other days stay same
          // This will fail because update logic not implemented (RED phase)
          should.fail()
        }
        Error(_) -> should.fail()
      }
    }
    Error(_err) -> should.fail()
  }
}

// ============================================================================
// Integration Test 4: Sync Logs to FatSecret
// ============================================================================

pub fn sync_logs_to_fatsecret_test() {
  // Setup: Load test context (credentials)
  let ctx = harness.setup()

  // Skip if FatSecret not configured
  case ctx.credentials.fatsecret.oauth_token {
    "" -> should.fail()
    _token -> {
      // Given: Updated meal plan with pasta on Friday dinner
      // Pasta nutrition: protein=45.0, fat=12.0, carbs=85.0 (example values)
      let pasta_macros = Macros(protein: 45.0, fat: 12.0, carbs: 85.0)
      let _pasta_calories = types.macros_calories(pasta_macros)

      // Build meal selection for sync
      let _meal_selection =
        meal_sync.MealSelection(
          date: "2025-12-22",
          // Friday from fixture
          meal_type: "dinner",
          recipe_id: 999,
          // Pasta recipe ID (placeholder)
          servings: 4.0,
        )

      // When: Sync meal to FatSecret
      // TODO: Build FatSecret config and access token from test credentials
      // This will fail because we need:
      // 1. FatSecret config (consumer key/secret)
      // 2. Access token (oauth_token/oauth_token_secret)
      // 3. Tandoor config (base_url/credentials)

      let sync_result: Result(List(meal_sync.MealSyncResult), String) =
        Error("FatSecret sync not configured in test harness")

      // Then: Meal logged with correct macros
      sync_result
      |> should.be_ok

      case sync_result {
        Ok(results) -> {
          // Verify at least one result
          results
          |> list.length
          |> should.equal(1)

          // Verify first result is success
          case list.first(results) {
            Ok(first_result) -> {
              case first_result.sync_status {
                meal_sync.Success(message) -> {
                  message
                  |> string.contains("pasta")
                  |> should.be_true

                  message
                  |> string.contains("FatSecret")
                  |> should.be_true

                  // Verify nutrition matches
                  first_result.nutrition.protein_g
                  |> should.equal(45.0)

                  first_result.nutrition.fat_g
                  |> should.equal(12.0)

                  first_result.nutrition.carbs_g
                  |> should.equal(85.0)
                }
                meal_sync.Failed(_error) -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_err) -> should.fail()
      }
    }
  }
}
