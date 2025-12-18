/// Tests for email confirmation generator
///
/// Tests verify that confirmation emails are properly generated
/// with correct subject, body, and HTML content for each command type.

import gleam/option.{Some}
import gleeunit
import gleeunit/should

import meal_planner/email/confirmation
import meal_planner/id
import meal_planner/types.{
  AdjustMeal, Breakfast, CommandExecutionResult, Friday, FullWeek, RemoveDislike,
  RegeneratePlan,
}

pub fn main() {
  gleeunit.main()
}

/// Test generating confirmation for AdjustMeal command
pub fn generate_adjust_meal_confirmation_test() {
  let result = CommandExecutionResult(
    success: True,
    message: "Updated Friday breakfast to oatmeal",
    command: Some(AdjustMeal(
      day: Friday,
      meal_type: Breakfast,
      recipe_id: id.recipe_id("recipe-test-1"),
    )),
  )

  let email = confirmation.generate_confirmation(result, "user@example.com")

  email.to_email
  |> should.equal("user@example.com")

  email.subject
  |> should.equal("Meal Updated! 🍽️")

  // Verify body has content
  {
    email.body != ""
  }
  |> should.be_true()
}

/// Test generating confirmation for RemoveDislike command
pub fn generate_remove_dislike_confirmation_test() {
  let result = CommandExecutionResult(
    success: True,
    message: "Added broccoli to dislike list",
    command: Some(RemoveDislike(food_name: "broccoli")),
  )

  let email = confirmation.generate_confirmation(result, "user@example.com")

  email.subject
  |> should.equal("Dislike Noted ✓")

  {
    email.body != ""
  }
  |> should.be_true()
}

/// Test generating confirmation for RegeneratePlan command
pub fn generate_regenerate_plan_confirmation_test() {
  let result = CommandExecutionResult(
    success: True,
    message: "Regenerating full week with high protein constraint",
    command: Some(RegeneratePlan(
      scope: FullWeek,
      constraints: Some("high protein"),
    )),
  )

  let email = confirmation.generate_confirmation(result, "user@example.com")

  email.subject
  |> should.equal("Plan Regeneration Started 🔄")

  {
    email.html_body != ""
  }
  |> should.be_true()
}

/// Test email has HTML body field
pub fn confirmation_email_has_html_body_test() {
  let result = CommandExecutionResult(
    success: True,
    message: "Test message",
    command: Some(RemoveDislike(food_name: "test")),
  )

  let email = confirmation.generate_confirmation(result, "user@example.com")

  {
    email.html_body != ""
  }
  |> should.be_true()
}

/// Test email has required fields
pub fn confirmation_email_structure_test() {
  let result = CommandExecutionResult(
    success: True,
    message: "Test",
    command: Some(RemoveDislike(food_name: "test")),
  )

  let email = confirmation.generate_confirmation(result, "test@example.com")

  // Verify all required fields are present and non-empty
  {
    email.to_email != "" && email.subject != "" && email.body != "" && email.html_body != ""
  }
  |> should.be_true()
}
