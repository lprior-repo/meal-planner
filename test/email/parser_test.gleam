/// Tests for email command parsing
import gleeunit
import gleeunit/should
import meal_planner/email/command.{EmailRequest}
import meal_planner/email/parser

pub fn main() {
  gleeunit.main()
}

pub fn parse_adjust_meal_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude adjust Friday dinner",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_ok()
}

pub fn parse_regenerate_week_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude regenerate week with high protein",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_ok()
}

pub fn parse_dislike_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude I hate Brussels sprouts",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_ok()
}

pub fn parse_add_preference_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude add more vegetables",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_ok()
}

pub fn parse_skip_meal_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Re: Meal Plan",
      body: "@Claude skip breakfast Monday",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_ok()
}

pub fn parse_no_claude_mention_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Random feedback",
      body: "This is just a regular email without any commands",
      is_reply: False,
    )

  parser.parse_email_command(email)
  |> should.be_error()
}

pub fn parse_invalid_command_test() {
  let email =
    EmailRequest(
      from_email: "lewis@example.com",
      subject: "Feedback",
      body: "@Claude please do something unclear",
      is_reply: True,
    )

  parser.parse_email_command(email)
  |> should.be_error()
}
