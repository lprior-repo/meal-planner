//// Integration Workflow Tests - Phase 3 (RED)
////
//// These tests validate complete end-to-end workflows.
//// All tests MUST FAIL until implementations are complete.

import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import meal_planner/email/confirmation
import meal_planner/email/parser
import meal_planner/generator/weekly
import meal_planner/id
import meal_planner/types.{type Macros, AdjustMeal, Dinner, Friday, Macros}

// ============================================================================
// Test Helpers
// ============================================================================

fn test_target_macros() -> Macros {
  Macros(protein: 180.0, fat: 60.0, carbs: 200.0)
}

fn sample_recipe(recipe_id: String, name: String) -> types.Recipe {
  types.Recipe(
    id: id.recipe_id(recipe_id),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
    servings: 1,
    category: "Dinner",
    fodmap_level: types.Low,
    vertical_compliant: True,
  )
}

// ============================================================================
// Test 1: Constraint to Generation to Email Workflow
// ============================================================================

pub fn test_constraint_to_generation_to_email_workflow() {
  let recipes = [
    sample_recipe("recipe-101", "Protein Smoothie"),
    sample_recipe("recipe-201", "Grilled Chicken Salad"),
    sample_recipe("recipe-301", "Salmon with Vegetables"),
  ]

  let generation_result =
    weekly.generate_weekly_plan("2025-12-22", recipes, test_target_macros())

  generation_result
  |> should.be_ok

  // Email generation not implemented yet
  should.fail()
}

// ============================================================================
// Test 2: Email Feedback Loop
// ============================================================================

pub fn test_email_feedback_loop_updates_meal_plan() {
  let email_request =
    types.EmailRequest(
      from_email: "lewis@example.com",
      subject: "Meal plan feedback",
      body: "@Claude adjust Friday dinner to pasta primavera",
      is_reply: False,
    )

  let parse_result = parser.parse_email_command(email_request)

  parse_result
  |> should.be_ok

  case parse_result {
    Ok(AdjustMeal(day, meal_type, recipe_id)) -> {
      day
      |> should.equal(Friday)

      meal_type
      |> should.equal(Dinner)

      let exec_result =
        types.CommandExecutionResult(
          success: True,
          message: "Updated Friday dinner",
          command: Some(AdjustMeal(Friday, Dinner, recipe_id)),
        )

      let _confirmation =
        confirmation.generate_confirmation(exec_result, "lewis@example.com")

      // Email sender not implemented
      should.fail()
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Test 3: Weekly Sync Rhythm
// ============================================================================

pub fn test_weekly_sync_rhythm_completes_full_cycle() {
  let recipes = [
    sample_recipe("recipe-101", "Protein Pancakes"),
    sample_recipe("recipe-201", "Grilled Chicken Salad"),
    sample_recipe("recipe-301", "Salmon Dinner"),
  ]

  let generation_result =
    weekly.generate_weekly_plan("2025-12-22", recipes, test_target_macros())

  generation_result
  |> should.be_ok

  case generation_result {
    Ok(meal_plan) -> {
      meal_plan.days
      |> list.length
      |> should.equal(7)

      // Auto-sync, advisor emails, and trends not implemented
      should.fail()
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 4: Combined Constraints
// ============================================================================

pub fn test_generation_respects_combined_constraints() {
  let recipes = [
    sample_recipe("recipe-101", "Protein Smoothie"),
    sample_recipe("recipe-201", "Grilled Chicken Salad"),
    sample_recipe("recipe-301", "Salmon with Vegetables"),
    sample_recipe("recipe-302", "Shrimp Stir Fry"),
  ]

  let adjusted_macros = Macros(protein: 200.0, fat: 65.0, carbs: 180.0)

  let generation_result =
    weekly.generate_weekly_plan("2025-12-22", recipes, adjusted_macros)

  generation_result
  |> should.be_ok

  case generation_result {
    Ok(meal_plan) -> {
      meal_plan.days
      |> list.length
      |> should.equal(7)

      // Multi-constraint generation not implemented
      should.fail()
    }
    Error(_) -> should.fail()
  }
}
