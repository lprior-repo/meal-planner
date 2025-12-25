/// Email command parser - Refactored for extensibility
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/email/command.{
  type DayOfWeek, type EmailCommand, type EmailCommandError, type EmailRequest,
  type MealType, type RegenerationScope, AddPreference, AdjustMeal, Breakfast,
  Dinner, EmailRequest, FullWeek, InvalidCommand, Lunch, RegeneratePlan,
  RemoveDislike, SkipMeal, Snack, day_of_week_from_string,
}
import meal_planner/id

/// Command pattern matching configuration
type CommandPattern {
  CommandPattern(
    keywords: List(String),
    parser: fn(String) -> Result(EmailCommand, EmailCommandError),
  )
}

/// Parse email command with @Claude mention validation
pub fn parse_email_command(
  email: EmailRequest,
) -> Result(EmailCommand, EmailCommandError) {
  let EmailRequest(_, _, body, _) = email
  let body_lower = string.lowercase(body)
  case string.contains(body_lower, "@claude") {
    False -> Error(InvalidCommand(reason: "No @Claude mention found"))
    True -> parse_command_body(body)
  }
}

/// Parse command body using pattern matching
fn parse_command_body(body: String) -> Result(EmailCommand, EmailCommandError) {
  let trimmed = string.trim(body)
  let patterns = build_command_patterns()
  match_command_pattern(trimmed, patterns)
}

/// Build command pattern matchers in priority order
fn build_command_patterns() -> List(CommandPattern) {
  [
    CommandPattern(keywords: ["adjust"], parser: parse_adjust_command),
    CommandPattern(keywords: ["regenerate"], parser: parse_regenerate_command),
    CommandPattern(
      keywords: ["hate", "don't like"],
      parser: parse_dislike_command,
    ),
    CommandPattern(keywords: ["add"], parser: parse_add_preference_command),
    CommandPattern(keywords: ["skip"], parser: parse_skip_command),
  ]
}

/// Match command against patterns
fn match_command_pattern(
  body: String,
  patterns: List(CommandPattern),
) -> Result(EmailCommand, EmailCommandError) {
  case patterns {
    [] -> Error(InvalidCommand(reason: "Command not recognized"))
    [CommandPattern(keywords, parser), ..rest] -> {
      case matches_any_keyword(body, keywords) {
        True -> parser(body)
        False -> match_command_pattern(body, rest)
      }
    }
  }
}

/// Check if body contains any of the keywords
fn matches_any_keyword(body: String, keywords: List(String)) -> Bool {
  list.any(keywords, fn(keyword) { string.contains(body, keyword) })
}

/// Parse adjust command: "@Claude adjust Friday dinner to pasta"
fn parse_adjust_command(body: String) -> Result(EmailCommand, EmailCommandError) {
  let words = string.split(body, " ")
  case find_word_index(words, "adjust") {
    None -> build_command_error("Could not find 'adjust' in command")
    Some(idx) -> parse_adjust_arguments(words, idx, body)
  }
}

fn parse_adjust_arguments(
  words: List(String),
  adjust_idx: Int,
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let remaining = list.drop(words, adjust_idx + 1)
  case remaining {
    [day_str, meal_str, ..] -> {
      let day_result = day_of_week_from_string(day_str)
      let meal_result = string_to_meal_type(meal_str)
      let recipe_id = extract_recipe_from_body(body)

      build_adjust_command(day_result, meal_result, recipe_id)
    }
    _ -> build_command_error("Missing day or meal type in adjust command")
  }
}

fn extract_recipe_from_body(body: String) -> id.RecipeId {
  case string.split(body, " to ") {
    [_, recipe_name] -> id.recipe_id(string.trim(recipe_name))
    _ -> id.recipe_id("recipe-123")
  }
}

fn build_adjust_command(
  day: Option(DayOfWeek),
  meal: Option(MealType),
  recipe_id: id.RecipeId,
) -> Result(EmailCommand, EmailCommandError) {
  case day, meal {
    Some(d), Some(m) ->
      Ok(AdjustMeal(day: d, meal_type: m, recipe_id: recipe_id))
    _, _ -> build_command_error("Could not parse day or meal type")
  }
}

/// Parse regenerate command: "@Claude regenerate week with high protein"
fn parse_regenerate_command(
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let scope = extract_regeneration_scope(body)
  let constraints = extract_regeneration_constraints(body)

  case scope {
    Some(s) -> Ok(RegeneratePlan(scope: s, constraints: constraints))
    None -> build_command_error("Could not determine regeneration scope")
  }
}

fn extract_regeneration_scope(body: String) -> Option(RegenerationScope) {
  case string.contains(body, "week") {
    True -> Some(FullWeek)
    False -> extract_regeneration_scope_fallback(body)
  }
}

fn extract_regeneration_scope_fallback(
  body: String,
) -> Option(RegenerationScope) {
  // SingleDay and SingleMeal require day/meal parameters from the body
  // For now, we return None since the parser can't extract those details yet
  // TODO: Extract day of week and meal type from body to create SingleDay/SingleMeal
  case string.contains(body, "day"), string.contains(body, "meal") {
    True, _ -> None
    _, True -> None
    False, False -> None
  }
}

fn extract_regeneration_constraints(body: String) -> Option(String) {
  case string.contains(body, "high protein") {
    True -> Some("high_protein")
    False -> extract_regeneration_constraints_fallback(body)
  }
}

fn extract_regeneration_constraints_fallback(body: String) -> Option(String) {
  case string.contains(body, "low carb") {
    True -> Some("low_carb")
    False ->
      case string.contains(body, "variety") {
        True -> Some("variety")
        False -> None
      }
  }
}

/// Parse dislike command: "@Claude I hate Brussels sprouts"
fn parse_dislike_command(
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let food = case string.contains(body, "hate") {
    True -> extract_after_word(body, "hate")
    False -> extract_after_word(body, "don't like")
  }

  validate_extracted_text(food, "food name", fn(f) {
    RemoveDislike(food_name: f)
  })
}

/// Parse add preference command: "@Claude add more vegetables"
fn parse_add_preference_command(
  body: String,
) -> Result(EmailCommand, EmailCommandError) {
  let pref = extract_after_word(body, "add")
  validate_extracted_text(pref, "preference", fn(p) {
    AddPreference(preference: p)
  })
}

/// Parse skip command: "@Claude skip breakfast Monday"
fn parse_skip_command(body: String) -> Result(EmailCommand, EmailCommandError) {
  let words = string.split(body, " ")
  case find_word_index(words, "skip") {
    None -> build_command_error("Could not find 'skip' in command")
    Some(idx) -> parse_skip_arguments(words, idx)
  }
}

fn parse_skip_arguments(
  words: List(String),
  skip_idx: Int,
) -> Result(EmailCommand, EmailCommandError) {
  let remaining = list.drop(words, skip_idx + 1)
  case remaining {
    [meal_str, day_str, ..] -> {
      let meal_result = string_to_meal_type(meal_str)
      let day_result = day_of_week_from_string(day_str)
      build_skip_command(meal_result, day_result)
    }
    _ -> build_command_error("Missing meal type or day in skip command")
  }
}

fn build_skip_command(
  meal: Option(MealType),
  day: Option(DayOfWeek),
) -> Result(EmailCommand, EmailCommandError) {
  case meal, day {
    Some(m), Some(d) -> Ok(SkipMeal(day: d, meal_type: m))
    _, _ -> build_command_error("Could not parse meal type or day")
  }
}

/// Validate extracted text and build command
fn validate_extracted_text(
  text: Option(String),
  field_name: String,
  builder: fn(String) -> EmailCommand,
) -> Result(EmailCommand, EmailCommandError) {
  case text {
    Some(t) ->
      case string.length(t) > 0 {
        True -> Ok(builder(t))
        False -> build_extraction_error(field_name)
      }
    None -> build_extraction_error(field_name)
  }
}

/// Helper functions for parsing
fn string_to_meal_type(s: String) -> Option(MealType) {
  case string.lowercase(s) {
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
  case string.split(body, word) {
    [_, after] -> Some(string.trim(after))
    _ -> None
  }
}

/// Consolidated error builders
fn build_command_error(
  reason: String,
) -> Result(EmailCommand, EmailCommandError) {
  Error(InvalidCommand(reason: reason))
}

fn build_extraction_error(
  field_name: String,
) -> Result(EmailCommand, EmailCommandError) {
  build_command_error("Could not extract " <> field_name <> " from command")
}
