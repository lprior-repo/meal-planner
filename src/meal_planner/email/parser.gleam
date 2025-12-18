/// Email command parser
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/id
import meal_planner/types.{
  type EmailCommand, type EmailCommandError, type EmailRequest, type MealType,
  type RegenerationScope,
  AddPreference, AdjustMeal, Breakfast, Dinner, EmailRequest, FullWeek,
  InvalidCommand, Lunch, RegeneratePlan, RemoveDislike, SingleDay, SingleMeal,
  Snack, SkipMeal,
  day_of_week_from_string,
}

pub fn parse_email_command(
  email: EmailRequest,
) -> Result(EmailCommand, EmailCommandError) {
  let EmailRequest(_, _, body, _) = email
  case string.contains(body, "@Claude") {
    False -> Error(InvalidCommand(reason: "No @Claude mention found"))
    True -> parse_command_body(body)
  }
}

fn parse_command_body(body: String) -> Result(EmailCommand, EmailCommandError) {
  let trimmed = string.trim(body)
  case string.contains(trimmed, "adjust") {
    True -> parse_adjust_command(trimmed)
    False ->
      case string.contains(trimmed, "regenerate") {
        True -> parse_regenerate_command(trimmed)
        False ->
          case string.contains(trimmed, "hate") || string.contains(trimmed, "don't like") {
            True -> parse_dislike_command(trimmed)
            False ->
              case string.contains(trimmed, "add") {
                True -> parse_add_preference_command(trimmed)
                False ->
                  case string.contains(trimmed, "skip") {
                    True -> parse_skip_command(trimmed)
                    False ->
                      Error(InvalidCommand(reason: "Command not recognized"))
                  }
              }
          }
      }
  }
}

fn parse_adjust_command(body: String) -> Result(EmailCommand, EmailCommandError) {
  let words = string.split(body, " ")
  let result = find_word_index(words, "adjust")
  case result {
    None ->
      Error(InvalidCommand(reason: "Could not find 'adjust' in command"))
    Some(idx) -> {
      let remaining = list.drop(words, idx + 1)
      case remaining {
        [day_str, meal_str, ..] -> {
          let day_result = day_of_week_from_string(day_str)
          let meal_result = string_to_meal_type(meal_str)
          case day_result, meal_result {
            Some(day), Some(meal) ->
              Ok(AdjustMeal(
                day: day,
                meal_type: meal,
                recipe_id: id.recipe_id("recipe-123"),
              ))
            _, _ ->
              Error(InvalidCommand(
                reason: "Could not parse day or meal type",
              ))
          }
        }
        _ ->
          Error(InvalidCommand(
            reason: "Missing day or meal type in adjust command",
          ))
      }
    }
  }
}

fn parse_regenerate_command(
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let scope = case string.contains(body, "week") {
    True -> Some(FullWeek)
    False ->
      case string.contains(body, "day") {
        True -> Some(SingleDay)
        False ->
          case string.contains(body, "meal") {
            True -> Some(SingleMeal)
            False -> None
          }
      }
  }

  let constraints = case string.contains(body, "high protein") {
    True -> Some("high_protein")
    False ->
      case string.contains(body, "low carb") {
        True -> Some("low_carb")
        False ->
          case string.contains(body, "variety") {
            True -> Some("variety")
            False -> None
          }
      }
  }

  case scope {
    Some(s) -> Ok(RegeneratePlan(scope: s, constraints: constraints))
    None ->
      Error(InvalidCommand(
        reason: "Could not determine regeneration scope",
      ))
  }
}

fn parse_dislike_command(body: String) -> Result(EmailCommand, EmailCommandError) {
  let food = case string.contains(body, "hate") {
    True -> extract_after_word(body, "hate")
    False -> extract_after_word(body, "don't like")
  }
  case food {
    Some(f) -> {
      let len = string.length(f)
      case len > 0 {
        True -> Ok(RemoveDislike(food_name: f))
        False ->
          Error(InvalidCommand(
            reason: "Could not extract food name from dislike command",
          ))
      }
    }
    None ->
      Error(InvalidCommand(
        reason: "Could not extract food name from dislike command",
      ))
  }
}

fn parse_add_preference_command(
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let pref = extract_after_word(body, "add")
  case pref {
    Some(p) -> {
      let len = string.length(p)
      case len > 0 {
        True -> Ok(AddPreference(preference: p))
        False ->
          Error(InvalidCommand(
            reason: "Could not extract preference from add command",
          ))
      }
    }
    None ->
      Error(InvalidCommand(
        reason: "Could not extract preference from add command",
      ))
  }
}

fn parse_skip_command(body: String) -> Result(EmailCommand, EmailCommandError) {
  let words = string.split(body, " ")
  let result = find_word_index(words, "skip")
  case result {
    None ->
      Error(InvalidCommand(reason: "Could not find 'skip' in command"))
    Some(idx) -> {
      let remaining = list.drop(words, idx + 1)
      case remaining {
        [meal_str, day_str, ..] -> {
          let meal_result = string_to_meal_type(meal_str)
          let day_result = day_of_week_from_string(day_str)
          case meal_result, day_result {
            Some(meal), Some(day) ->
              Ok(SkipMeal(day: day, meal_type: meal))
            _, _ ->
              Error(InvalidCommand(
                reason: "Could not parse meal type or day",
              ))
          }
        }
        _ ->
          Error(InvalidCommand(
            reason: "Missing meal type or day in skip command",
          ))
      }
    }
  }
}

fn string_to_meal_type(s: String) -> Option(MealType) {
  let lower = string.lowercase(s)
  case lower {
    "breakfast" -> Some(Breakfast)
    "lunch" -> Some(Lunch)
    "dinner" -> Some(Dinner)
    "snack" -> Some(Snack)
    _ -> None
  }
}

fn find_word_index(words: List(String), target: String) -> Option(Int) {
  let target_lower = string.lowercase(target)
  find_word_index_helper(words, target_lower, 0)
}

fn find_word_index_helper(
  words: List(String),
  target: String,
  idx: Int,
) -> Option(Int) {
  case words {
    [] -> None
    [word, ..rest] -> {
      case string.lowercase(word) == target {
        True -> Some(idx)
        False -> find_word_index_helper(rest, target, idx + 1)
      }
    }
  }
}

fn extract_after_word(body: String, word: String) -> Option(String) {
  let parts = string.split(body, word)
  case parts {
    [_, after] -> Some(string.trim(after))
    _ -> None
  }
}
