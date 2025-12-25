//// Email command executor module
////
//// Handles execution of email-related commands from the meal planner.

import meal_planner/email/command.{type EmailCommand}

/// Execute an email-related command
pub fn execute(command: EmailCommand) -> Nil {
  let _ = command
  Nil
}
