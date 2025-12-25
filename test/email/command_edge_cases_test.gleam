/// Tests for email command parser edge cases
/// RED phase tests for case sensitivity, scope extraction, preference parsing, and malformed commands
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import meal_planner/email/command.{
  AddPreference, AdjustMeal, Dinner, EmailRequest, Friday, FullWeek,
  InvalidCommand, RegeneratePlan, RemoveDislike,
}
import meal_planner/email/parser

pub fn main() {
  gleeunit.main()
}

/// RED: Test case-insensitive @Claude mention parsing
/// Input: "@claude adjust Friday dinner" (lowercase 'claude')
/// Expected: Command should parse successfully (case should not matter)
/// This test MUST FAIL initially - parser currently requires exact "@Claude" match
pub fn email_parser_handles_case_insensitive_commands_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@claude adjust Friday dinner",
      is_reply: True,
    )

  let result = parser.parse_email_command(email)

  // RED PHASE: This will FAIL - parser checks for "@Claude" with capital C
  // Should accept @claude, @CLAUDE, @Claude, etc.
  result
  |> should.be_ok()

  let assert Ok(command) = result
  case command {
    AdjustMeal(day: day, meal_type: meal, recipe_id: _recipe) -> {
      day
      |> should.equal(Friday)

      meal
      |> should.equal(Dinner)
    }
    _ -> panic as "Expected AdjustMeal command"
  }
}

/// RED: Test regenerate scope extraction (full week vs single meal)
/// Input: "@Claude regenerate week with high protein"
/// Expected: RegeneratePlan(scope: FullWeek, constraints: Some("high_protein"))
/// This test validates that scope extraction works correctly
pub fn email_parser_extracts_regenerate_scope_test() {
  let email_week =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude regenerate week with high protein",
      is_reply: True,
    )

  let result_week = parser.parse_email_command(email_week)

  result_week
  |> should.be_ok()

  let assert Ok(command_week) = result_week
  case command_week {
    RegeneratePlan(scope: scope, constraints: constraints) -> {
      scope
      |> should.equal(FullWeek)

      constraints
      |> should.equal(Some("high_protein"))
    }
    _ -> panic as "Expected RegeneratePlan command"
  }

  // Test single meal scope - currently parser cannot extract day/meal info
  // TODO: Implement day and meal extraction from email body
  let email_meal =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude regenerate meal",
      is_reply: True,
    )

  let result_meal = parser.parse_email_command(email_meal)

  // Parser cannot extract required parameters for SingleMeal, returns error
  result_meal
  |> should.be_error()

  // Test single day scope - currently parser cannot extract day info
  // TODO: Implement day extraction from email body
  let email_day =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude regenerate day",
      is_reply: True,
    )

  let result_day = parser.parse_email_command(email_day)

  // Parser cannot extract required parameters for SingleDay, returns error
  result_day
  |> should.be_error()
}

/// RED: Test preference update command variations
/// Input: "@Claude add more vegetables" and "@Claude I hate Brussels sprouts"
/// Expected: AddPreference and RemoveDislike commands
/// This test validates preference parsing with different phrasings
pub fn email_parser_handles_preference_updates_test() {
  // Test "add" preference command
  let email_add =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude add more vegetables",
      is_reply: True,
    )

  let result_add = parser.parse_email_command(email_add)

  result_add
  |> should.be_ok()

  let assert Ok(command_add) = result_add
  case command_add {
    AddPreference(preference: pref) -> {
      // Should extract "more vegetables" after "add"
      pref
      |> should.equal("more vegetables")
    }
    _ -> panic as "Expected AddPreference command"
  }

  // Test "hate" dislike command (alternative to "don't like")
  let email_hate =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude I hate Brussels sprouts",
      is_reply: True,
    )

  let result_hate = parser.parse_email_command(email_hate)

  result_hate
  |> should.be_ok()

  let assert Ok(command_hate) = result_hate
  case command_hate {
    RemoveDislike(food_name: food) -> {
      // Should extract "Brussels sprouts" after "hate"
      food
      |> should.equal("Brussels sprouts")
    }
    _ -> panic as "Expected RemoveDislike command"
  }

  // Test "don't like" variant
  let email_dislike =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude I don't like tofu",
      is_reply: True,
    )

  let result_dislike = parser.parse_email_command(email_dislike)

  result_dislike
  |> should.be_ok()

  let assert Ok(command_dislike) = result_dislike
  case command_dislike {
    RemoveDislike(food_name: food) -> {
      // Should extract "tofu" after "don't like"
      food
      |> should.equal("tofu")
    }
    _ -> panic as "Expected RemoveDislike command"
  }
}

/// RED: Test malformed command rejection
/// Input: Various invalid command formats
/// Expected: InvalidCommand errors with descriptive reasons
/// This test validates parser error handling
pub fn email_parser_rejects_malformed_commands_test() {
  // Test missing @Claude mention
  let email_no_mention =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "adjust Friday dinner",
      is_reply: True,
    )

  let result_no_mention = parser.parse_email_command(email_no_mention)

  result_no_mention
  |> should.be_error()

  let assert Error(error) = result_no_mention
  case error {
    InvalidCommand(reason: reason) -> {
      reason
      |> should.equal("No @Claude mention found")
    }
    _ -> panic as "Expected InvalidCommand error"
  }

  // Test unrecognized command
  let email_unknown =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude dance party",
      is_reply: True,
    )

  let result_unknown = parser.parse_email_command(email_unknown)

  result_unknown
  |> should.be_error()

  let assert Error(error_unknown) = result_unknown
  case error_unknown {
    InvalidCommand(reason: reason) -> {
      reason
      |> should.equal("Command not recognized")
    }
    _ -> panic as "Expected InvalidCommand error"
  }

  // Test adjust command missing required fields
  let email_incomplete =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude adjust Friday",
      is_reply: True,
    )

  let result_incomplete = parser.parse_email_command(email_incomplete)

  // RED PHASE: This should fail with error about missing meal type
  result_incomplete
  |> should.be_error()

  let assert Error(error_incomplete) = result_incomplete
  case error_incomplete {
    InvalidCommand(reason: _reason) -> {
      // Should get error about missing day or meal type
      // The exact error message may vary depending on implementation
      Nil
    }
    _ -> panic as "Expected InvalidCommand error"
  }

  // Test regenerate command without scope
  let email_no_scope =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude regenerate please",
      is_reply: True,
    )

  let result_no_scope = parser.parse_email_command(email_no_scope)

  result_no_scope
  |> should.be_error()

  let assert Error(error_no_scope) = result_no_scope
  case error_no_scope {
    InvalidCommand(reason: reason) -> {
      reason
      |> should.equal("Could not determine regeneration scope")
    }
    _ -> panic as "Expected InvalidCommand error"
  }
}
