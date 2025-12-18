import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/email/command as cmd
import meal_planner/email/parser

pub fn main() {
  gleeunit.main()
}

// Test: Extract @Claude mention and parse "adjust Friday dinner"
pub fn parse_adjust_meal_test() {
  let email =
    "I got tacos from a new place and want to try them on Friday dinner instead of the planned meal. @Claude adjust Friday dinner to tacos"

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.AdjustMeal(day, meal, recipe) -> {
          should.equal(day, cmd.Friday)
          should.equal(meal, cmd.Dinner)
          should.equal(recipe, option.Some("tacos"))
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}

// Test: Extract @Claude mention and parse "I didn't like the tacos"
pub fn parse_rotate_food_test() {
  let email =
    "Thanks for the meals but @Claude I didn't like the Brussels sprouts, they were too bitter."

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.RotateFood(food) -> {
          should.equal(food, "brussels sprouts")
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}

// Test: Extract @Claude mention and parse "add more vegetables"
pub fn parse_prefer_test() {
  let email =
    "Could you @Claude add more vegetables to the meal plan? I want to increase my greens."

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.UpdatePreference(pref) -> {
          case pref {
            cmd.Prefer(preference) -> {
              should.equal(preference, "more vegetables")
            }
            _ -> should.be_true(False)
          }
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}

// Test: Extract @Claude mention and parse "regenerate week"
pub fn parse_regenerate_test() {
  let email =
    "I'm feeling like I want more protein this week. @Claude regenerate week with high protein"

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.Regenerate(scope, constraint) -> {
          should.equal(scope, cmd.FullWeek)
          should.equal(constraint, option.Some("high protein"))
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}

// Test: Extract @Claude mention and parse "skip breakfast Tuesday"
pub fn parse_skip_meal_test() {
  let email =
    "I'm traveling on Tuesday so I won't need breakfast. @Claude skip breakfast Tuesday"

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.SkipMeal(day, meal) -> {
          should.equal(day, cmd.Tuesday)
          should.equal(meal, cmd.Breakfast)
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}

// Test: Email without @Claude mention
pub fn no_command_test() {
  let email =
    "Hey, just wanted to let you know I enjoyed the salmon this week!"

  let result = parser.parse_email(email)

  case result {
    cmd.NoCommand(_reason) -> {
      should.equal(True, True)
    }
    _ -> should.be_true(False)
  }
}

// Test: Unknown command returns Unknown variant
pub fn unknown_command_test() {
  let email = "Hey @Claude can you do something weird with the meal plan?"

  let result = parser.parse_email(email)

  case result {
    cmd.CommandFound(command) -> {
      case command {
        cmd.Unknown(_raw) -> {
          should.equal(True, True)
        }
        _ -> should.be_true(False)
      }
    }
    _ -> should.be_true(False)
  }
}
