/// Tests for email command parsing with recipe name extraction
import gleeunit
import gleeunit/should
import meal_planner/email/command.{
  AdjustMeal, Breakfast, Dinner, EmailRequest, Friday, Lunch, Monday, Tuesday,
}
import meal_planner/email/parser
import meal_planner/id

pub fn main() {
  gleeunit.main()
}

/// RED: Test parsing adjust command with recipe name
/// Input: "@Claude adjust Friday dinner to pasta"
/// Expected: AdjustMeal(day: Friday, meal_type: Dinner, recipe_id: RecipeId("pasta"))
/// This test MUST FAIL initially - the parser does not extract recipe names yet
pub fn email_parser_extracts_adjust_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude adjust Friday dinner to pasta",
      is_reply: True,
    )

  let result = parser.parse_email_command(email)

  // Assert command parsing succeeds
  result
  |> should.be_ok()

  // Assert correct command type and fields
  let assert Ok(command) = result
  case command {
    AdjustMeal(day: day, meal_type: meal, recipe_id: recipe) -> {
      // Verify day
      day
      |> should.equal(Friday)

      // Verify meal type
      meal
      |> should.equal(Dinner)

      // RED PHASE: This will FAIL - parser currently hardcodes "recipe-123"
      // We expect the recipe name "pasta" to be extracted from command
      recipe
      |> should.equal(id.recipe_id("pasta"))
    }
    _ -> panic as "Expected AdjustMeal command"
  }
}

/// RED: Test parsing adjust command with multi-word recipe name
/// Input: "@Claude adjust Monday breakfast to scrambled eggs"
/// Expected: Recipe name "scrambled eggs" extracted
pub fn email_parser_extracts_multiword_recipe_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude adjust Monday breakfast to scrambled eggs",
      is_reply: True,
    )

  let result = parser.parse_email_command(email)

  result
  |> should.be_ok()

  let assert Ok(command) = result
  case command {
    AdjustMeal(day: day, meal_type: meal, recipe_id: recipe) -> {
      day
      |> should.equal(Monday)

      meal
      |> should.equal(Breakfast)

      // RED PHASE: This will FAIL - parser does not extract multi-word recipes
      recipe
      |> should.equal(id.recipe_id("scrambled eggs"))
    }
    _ -> panic as "Expected AdjustMeal command"
  }
}

/// RED: Test parsing adjust command without "to" keyword
/// Input: "@Claude adjust Tuesday lunch"
/// Expected: Recipe ID should be empty or default (current behavior)
pub fn email_parser_adjust_without_recipe_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude adjust Tuesday lunch",
      is_reply: True,
    )

  let result = parser.parse_email_command(email)

  // Should still parse successfully (recipe is optional in UX)
  result
  |> should.be_ok()

  let assert Ok(command) = result
  case command {
    AdjustMeal(day: day, meal_type: meal, recipe_id: _recipe) -> {
      day
      |> should.equal(Tuesday)

      meal
      |> should.equal(Lunch)
      // Recipe ID will be hardcoded to "recipe-123" currently
      // This is acceptable when no recipe specified
    }
    _ -> panic as "Expected AdjustMeal command"
  }
}
