/// Plan CLI domain - handles meal plan generation and regeneration
import birl
import gleam/int
import gleam/io
import gleam/result
import glint
import meal_planner/config.{type Config}
import meal_planner/meal_sync.{type MealSelection, MealSelection}
import meal_planner/orchestrator
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth, ClientConfig}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse and validate date in YYYY-MM-DD format
pub fn parse_date(date_str: String) -> Result(birl.Time, String) {
  case birl.from_naive(date_str <> "T00:00:00") {
    Ok(time) -> Ok(time)
    Error(_) ->
      Error("Invalid date format. Expected YYYY-MM-DD, got: " <> date_str)
  }
}

/// Create Tandoor client config from app config
fn create_tandoor_config(config: Config) -> ClientConfig {
  ClientConfig(
    base_url: config.tandoor.base_url,
    auth: BearerAuth(token: config.tandoor.api_token),
    timeout_ms: config.tandoor.request_timeout_ms,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create meal selections for a given start date and number of days
fn create_meal_selections_for_range(
  start_date: String,
  _days: Int,
) -> List(MealSelection) {
  // For now, create a simple selection for the start date
  // TODO: Generate actual meal plans for the full date range
  [
    MealSelection(
      date: start_date,
      meal_type: "lunch",
      recipe_id: 1,
      servings: 1.0,
    ),
    MealSelection(
      date: start_date,
      meal_type: "dinner",
      recipe_id: 2,
      servings: 1.0,
    ),
  ]
}

/// Regenerate meals for a given date range
pub fn regenerate_meals(
  config: Config,
  start_date: String,
  days: Int,
) -> Result(String, String) {
  // Validate date format
  use _ <- result.try(parse_date(start_date))

  // Create Tandoor config
  let tandoor_config = create_tandoor_config(config)

  // Create meal selections for the date range
  let meal_selections = create_meal_selections_for_range(start_date, days)

  // Call orchestrator to plan meals
  use plan <- result.try(orchestrator.plan_meals(
    tandoor_config,
    meal_selections,
  ))

  // Format and return the result
  let output =
    "Regenerated meal plan starting "
    <> start_date
    <> " for "
    <> int.to_string(days)
    <> " days:\n\n"
    <> orchestrator.format_meal_plan(plan)

  Ok(output)
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Plan domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Generate and manage meal plans")
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days to generate plan for")
    |> glint.flag_default(7),
  )
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Start date (YYYY-MM-DD)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["generate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      io.println(
        "Generating plan for " <> int.to_string(days_val) <> " days...",
      )
      // TODO: Implement meal plan generation
      Ok(Nil)
    }
    ["regenerate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      let start_date = date(flags) |> result.unwrap("2025-12-19")

      // Call regenerate_meals helper
      case regenerate_meals(config, start_date, days_val) {
        Ok(output) -> {
          io.println(output)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error regenerating meal plan: " <> err)
          Error(Nil)
        }
      }
    }
    ["sync"] -> {
      io.println("Syncing meal plan with Tandoor...")
      Ok(Nil)
    }
    _ -> {
      io.println("Plan commands:")
      io.println("  mp plan generate --days 7")
      io.println("  mp plan regenerate --date 2025-12-19 --days 7")
      io.println("  mp plan sync")
      Ok(Nil)
    }
  }
}
