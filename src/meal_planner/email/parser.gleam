/// Email command parser for natural language meal plan feedback
///
/// Parses Lewis's email replies to extract @Claude mentions and convert them
/// into structured EmailCommand types.

import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/email/command.{
  type Day, type EmailCommand, type MealType, type ParseResult, AdjustMeal,
  Breakfast, CommandFound, Dinner, Lunch, NoCommand, RotateFood, SkipMeal,
  Tuesday, Unknown, UpdatePreference,
}

/// Parse an email body and extract @Claude command
///
/// Returns ParseResult indicating:
/// - CommandFound: Successfully parsed an @Claude mention into a command
/// - NoCommand: Email doesn't contain @Claude mention
/// - ParseError: Email contains @Claude but parsing failed
pub fn parse_email(email_body: String) -> ParseResult {
  case extract_claude_mention(email_body) {
    Ok(mention) -> parse_command(mention)
    Error(_) -> NoCommand("No @Claude mention found in email")
  }
}

/// Extract text after @Claude mention
fn extract_claude_mention(email_body: String) -> Result(String, Nil) {
  case string.contains(email_body, "@Claude") {
    False -> Error(Nil)
    True -> {
      case string.split_once(email_body, "@Claude") {
        Ok(#(_before, after)) -> Ok(string.trim(after))
        Error(_) -> Error(Nil)
      }
    }
  }
}

/// Parse the command text into an EmailCommand
fn parse_command(text: String) -> ParseResult {
  let text = string.trim(string.lowercase(text))

  // Try matching different command patterns
  case parse_adjust_meal(text) {
    Some(cmd) -> CommandFound(cmd)
    None -> {
      case parse_rotate_food(text) {
        Some(cmd) -> CommandFound(cmd)
        None -> {
          case parse_prefer(text) {
            Some(cmd) -> CommandFound(cmd)
            None -> {
              case parse_regenerate(text) {
                Some(cmd) -> CommandFound(cmd)
                None -> {
                  case parse_skip_meal(text) {
                    Some(cmd) -> CommandFound(cmd)
                    None -> CommandFound(Unknown(text))
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

// Pattern: "adjust {day} {meal} [to {recipe}]"
fn parse_adjust_meal(text: String) -> Option(EmailCommand) {
  case string.starts_with(text, "adjust") {
    False -> None
    True -> {
      // Parse "adjust friday dinner to tacos"
      let words = string.split(text, " ")
      case words {
        ["adjust", day_str, meal_str, ..rest] -> {
          let day = parse_day(day_str)
          let meal = parse_meal(meal_str)
          case day, meal {
            Some(d), Some(m) -> {
              let recipe = case rest {
                ["to", recipe, ..] -> Some(recipe)
                _ -> None
              }
              Some(AdjustMeal(d, m, recipe))
            }
            _, _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

// Pattern: "i didn't like {food}" or "{food} was bad" etc
fn parse_rotate_food(text: String) -> Option(EmailCommand) {
  case string.contains(text, "didn't like") {
    False -> None
    True -> {
      case string.split_once(text, "didn't like") {
        Ok(#(_before, after)) -> {
          let food_phrase = string.trim(after)
          let food = extract_food_name(food_phrase)
          Some(RotateFood(food))
        }
        Error(_) -> None
      }
    }
  }
}

// Pattern: "add {preference}" or "more {preference}"
fn parse_prefer(text: String) -> Option(EmailCommand) {
  case string.contains(text, "add") || string.contains(text, "more") {
    False -> None
    True -> {
      let preference_str = case string.split_once(text, "add") {
        Ok(#(_before, after)) -> after
        Error(_) ->
          case string.split_once(text, "more") {
            Ok(#(_before, after)) -> after
            Error(_) -> ""
          }
      }
      let pref = string.trim(preference_str)
      // Extract just the first few words (before punctuation or next sentence)
      let pref = case string.split_once(pref, " to ") {
        Ok(#(before, _)) -> before
        Error(_) ->
          case string.split_once(pref, " i ") {
            Ok(#(before, _)) -> before
            Error(_) -> pref
          }
      }
      let pref = string.trim(pref)
      case pref {
        "" -> None
        _ -> {
          Some(UpdatePreference(command.Prefer(preference: pref)))
        }
      }
    }
  }
}

// Pattern: "regenerate {scope} [with {constraint}]"
fn parse_regenerate(text: String) -> Option(EmailCommand) {
  case string.starts_with(text, "regenerate") {
    False -> None
    True -> {
      let rest = string.drop_start(text, string.length("regenerate"))
      let rest = string.trim(rest)
      let words = string.split(rest, " ")

      case words {
        [scope_str, ..rest] -> {
          let scope = parse_regeneration_scope(scope_str)
          case scope {
            Some(s) -> {
              let constraint = case rest {
                ["with", ..rest_words] -> {
                  // Join remaining words as constraint
                  case rest_words {
                    [] -> None
                    words -> Some(string.join(words, " "))
                  }
                }
                _ -> None
              }
              Some(command.Regenerate(s, constraint))
            }
            None -> None
          }
        }
        _ -> None
      }
    }
  }
}

// Pattern: "skip {meal} {day}"
fn parse_skip_meal(text: String) -> Option(EmailCommand) {
  case string.starts_with(text, "skip") {
    False -> None
    True -> {
      let rest = string.drop_start(text, string.length("skip"))
      let rest = string.trim(rest)
      let words = string.split(rest, " ")

      case words {
        [meal_str, day_str, ..] -> {
          let meal = parse_meal(meal_str)
          let day = parse_day(day_str)
          case meal, day {
            Some(m), Some(d) -> Some(SkipMeal(d, m))
            _, _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

// Helper: Parse day name
fn parse_day(day_str: String) -> Option(Day) {
  case day_str {
    "monday" -> Some(command.Monday)
    "tuesday" -> Some(command.Tuesday)
    "wednesday" -> Some(command.Wednesday)
    "thursday" -> Some(command.Thursday)
    "friday" -> Some(command.Friday)
    "saturday" -> Some(command.Saturday)
    "sunday" -> Some(command.Sunday)
    _ -> None
  }
}

// Helper: Parse meal type
fn parse_meal(meal_str: String) -> Option(MealType) {
  case meal_str {
    "breakfast" -> Some(Breakfast)
    "lunch" -> Some(Lunch)
    "dinner" -> Some(Dinner)
    _ -> None
  }
}

// Helper: Parse regeneration scope
fn parse_regeneration_scope(scope_str: String) -> Option(command.RegenerationScope) {
  case scope_str {
    "week" -> Some(command.FullWeek)
    "day" -> Some(command.FullWeek)
    _ -> None
  }
}

// Helper: Extract food name from text
fn extract_food_name(text: String) -> String {
  let text = string.trim(text)
  // Remove trailing punctuation and extra text
  let text = case string.split_once(text, ",") {
    Ok(#(before, _after)) -> before
    Error(_) -> text
  }
  // Skip articles and take next 2 words as food name
  let words = string.split(text, " ")
  case words {
    ["the", w2, w3, ..] -> w2 <> " " <> w3
    ["a", w2, w3, ..] -> w2 <> " " <> w3
    [w1, w2, ..] -> w1 <> " " <> w2
    [w1] -> w1
    _ -> text
  }
}
