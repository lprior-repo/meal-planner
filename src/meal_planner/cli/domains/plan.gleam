/// Plan CLI domain - handles meal plan generation and regeneration
import birl
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/meal_sync.{type MealSelection, MealSelection}
import meal_planner/orchestrator
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth, ClientConfig}
import meal_planner/tandoor/mealplan.{
  type MealPlanEntry, type MealPlanListResponse,
}

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
// Meal Plan List Functions
// ============================================================================

/// List all meal plans without filters
///
/// # Arguments
/// * `config` - Application configuration
///
/// # Returns
/// Formatted string with meal plans grouped by date or error message
pub fn list_meal_plans(config: Config) -> Result(String, String) {
  list_meal_plans_with_filters(config, start_date: None, end_date: None)
}

/// List meal plans with optional date range filters
///
/// # Arguments
/// * `config` - Application configuration
/// * `start_date` - Optional start date filter (YYYY-MM-DD)
/// * `end_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Formatted string with meal plans grouped by date or error message
pub fn list_meal_plans_with_filters(
  config: Config,
  start_date start_date: Option(String),
  end_date end_date: Option(String),
) -> Result(String, String) {
  // Create Tandoor config
  let tandoor_config = create_tandoor_config(config)

  // Call Tandoor API to list meal plans
  use response <- result.try(
    mealplan.list_meal_plans(
      tandoor_config,
      from_date: start_date,
      to_date: end_date,
    )
    |> result.map_error(fn(err) {
      "Failed to fetch meal plans: " <> string.inspect(err)
    }),
  )

  // Extract meal plan entries from response
  let meal_plan_entries = convert_to_entries(response.results)

  // Format and return the meal plans
  Ok(format_meal_plans_grouped_by_date(meal_plan_entries))
}

/// Convert MealPlan list to MealPlanEntry list
///
/// Extracts the essential fields needed for display from full MealPlan objects
fn convert_to_entries(
  meal_plans: List(mealplan.MealPlan),
) -> List(MealPlanEntry) {
  list.map(meal_plans, fn(mp) {
    mealplan.MealPlanEntry(
      id: mp.id,
      title: mp.title,
      recipe_id: case mp.recipe {
        Some(r) -> Some(r.id)
        None -> None
      },
      recipe_name: mp.recipe_name,
      servings: mp.servings,
      from_date: mp.from_date,
      to_date: mp.to_date,
      meal_type_id: mp.meal_type.id,
      meal_type_name: mp.meal_type_name,
      shopping: mp.shopping,
    )
  })
}

/// Format meal plans grouped by date with meals ordered by type
///
/// # Arguments
/// * `meal_plans` - List of meal plan entries to format
///
/// # Returns
/// Formatted string with meal plans grouped by date
///
/// # Output Format
/// ```
/// 2025-12-20
///   Breakfast: Oatmeal (1 serving)
///   Lunch: Chicken Salad (1 serving)
///   Dinner: Grilled Salmon (1 serving)
///
/// 2025-12-21
///   Breakfast: Scrambled Eggs (1 serving)
///   ...
/// ```
pub fn format_meal_plans_grouped_by_date(
  meal_plans: List(MealPlanEntry),
) -> String {
  case meal_plans {
    [] -> "No meal plans found"
    _ -> {
      // Group meal plans by date
      let grouped = group_by_date(meal_plans)

      // Sort dates
      let sorted_dates =
        dict.keys(grouped)
        |> list.sort(string.compare)

      // Format each date group
      sorted_dates
      |> list.map(fn(date) {
        let meals =
          dict.get(grouped, date)
          |> result.unwrap([])
          |> sort_by_meal_type

        format_date_group(date, meals)
      })
      |> string.join("\n\n")
    }
  }
}

/// Group meal plan entries by their from_date
///
/// Extracts the date portion (YYYY-MM-DD) from the ISO datetime string
fn group_by_date(
  meal_plans: List(MealPlanEntry),
) -> Dict(String, List(MealPlanEntry)) {
  list.fold(meal_plans, dict.new(), fn(acc, meal_plan) {
    let date = extract_date(meal_plan.from_date)
    dict.upsert(acc, date, fn(existing) {
      case existing {
        Some(meals) -> [meal_plan, ..meals]
        None -> [meal_plan]
      }
    })
  })
}

/// Extract date portion (YYYY-MM-DD) from ISO datetime string
///
/// # Example
/// "2025-12-19T18:00:00Z" -> "2025-12-19"
fn extract_date(datetime: String) -> String {
  case string.split(datetime, "T") {
    [date, ..] -> date
    _ -> datetime
  }
}

/// Sort meal plans by meal type (Breakfast, Lunch, Dinner, others)
///
/// Uses meal_type_id for ordering. Assumes common convention:
/// - 1 = Breakfast
/// - 2 = Lunch
/// - 3 = Dinner
fn sort_by_meal_type(meals: List(MealPlanEntry)) -> List(MealPlanEntry) {
  list.sort(meals, fn(a, b) { int.compare(a.meal_type_id, b.meal_type_id) })
}

/// Format a single date group with its meals
///
/// # Example output
/// ```
/// 2025-12-20
///   Breakfast: Oatmeal (1 serving)
///   Lunch: Chicken Salad (1 serving)
/// ```
fn format_date_group(date: String, meals: List(MealPlanEntry)) -> String {
  let meal_lines =
    meals
    |> list.map(format_meal_entry)
    |> string.join("\n")

  date <> "\n" <> meal_lines
}

/// Format a single meal entry
///
/// # Example
/// "  Breakfast: Oatmeal (1 serving)"
fn format_meal_entry(meal: MealPlanEntry) -> String {
  let servings_str = case float.floor(meal.servings) == meal.servings {
    True -> int.to_string(float.round(meal.servings))
    False -> float.to_string(meal.servings)
  }

  let serving_text = case servings_str {
    "1" -> "1 serving"
    _ -> servings_str <> " servings"
  }

  "  "
  <> meal.meal_type_name
  <> ": "
  <> meal.recipe_name
  <> " ("
  <> serving_text
  <> ")"
}

// ============================================================================
// Show Single Meal Plan
// ============================================================================

/// Show meal plan for a specific date
///
/// Displays all meals for the given date, grouped by meal type and ordered
/// by meal type order (Breakfast, Lunch, Dinner, Snack, etc.)
///
/// # Arguments
/// * `config` - Application configuration
/// * `date` - Date in YYYY-MM-DD format
///
/// # Returns
/// Ok(Nil) on success with meal plan printed, Error(Nil) on failure
///
/// # Example
/// ```gleam
/// show_plan(config, "2025-12-19")
/// // Output:
/// // Meal Plan for 2025-12-19
/// //
/// // Breakfast
/// //   Scrambled Eggs (2 servings)
/// //
/// // Lunch
/// //   Chicken Salad (1 serving)
/// // ...
/// ```
pub fn show_plan(config: Config, date: String) -> Result(Nil, Nil) {
  // Validate date format
  case parse_date(date) {
    Error(err) -> {
      io.println(err)
      Error(Nil)
    }
    Ok(_) -> {
      // Create Tandoor config
      let tandoor_config = create_tandoor_config(config)

      // Query meal plans for the specific date
      case
        mealplan.list_meal_plans(
          tandoor_config,
          from_date: Some(date),
          to_date: Some(date),
        )
      {
        Error(err) -> {
          io.println("Failed to fetch meal plans: " <> string.inspect(err))
          Error(Nil)
        }
        Ok(response) -> {
          // Display the meal plan
          display_meal_plan(date, response)
          Ok(Nil)
        }
      }
    }
  }
}

/// Display a meal plan for a specific date
///
/// Groups meals by meal type and displays them in order
fn display_meal_plan(date: String, response: MealPlanListResponse) -> Nil {
  io.println("Meal Plan for " <> date)
  io.println("")

  case response.results {
    [] -> {
      io.println("No meals planned for this date")
      Nil
    }
    meals -> {
      // Group meals by meal type name
      let grouped = group_by_meal_type(meals)

      // Get all unique meal types and sort by meal type order
      let sorted_meal_types = get_sorted_meal_types(meals)

      // Display each meal type group
      list.each(sorted_meal_types, fn(meal_type_name) {
        case dict.get(grouped, meal_type_name) {
          Ok(meals_in_type) -> {
            io.println(meal_type_name)
            list.each(meals_in_type, fn(meal) {
              io.println(
                "  "
                <> meal.recipe_name
                <> " ("
                <> format_servings(meal.servings)
                <> ")",
              )
            })
            io.println("")
          }
          Error(_) -> Nil
        }
      })

      // TODO: Display nutrition totals (requires fetching recipe details)
      Nil
    }
  }
}

/// Group meal plans by meal type name
fn group_by_meal_type(
  meals: List(mealplan.MealPlan),
) -> Dict(String, List(mealplan.MealPlan)) {
  list.fold(meals, dict.new(), fn(acc, meal) {
    dict.upsert(acc, meal.meal_type_name, fn(existing) {
      case existing {
        Some(meal_list) -> [meal, ..meal_list]
        None -> [meal]
      }
    })
  })
}

/// Get sorted list of meal type names based on meal type order
fn get_sorted_meal_types(meals: List(mealplan.MealPlan)) -> List(String) {
  meals
  |> list.map(fn(meal) { #(meal.meal_type_name, meal.meal_type.order) })
  |> list.unique
  |> list.sort(fn(a, b) {
    let #(_name_a, order_a) = a
    let #(_name_b, order_b) = b
    int.compare(order_a, order_b)
  })
  |> list.map(fn(tuple) {
    let #(name, _order) = tuple
    name
  })
}

/// Format servings for display
fn format_servings(servings: Float) -> String {
  let servings_str = case float.floor(servings) == servings {
    True -> int.to_string(float.round(servings))
    False -> float.to_string(servings)
  }

  case servings_str {
    "1" -> "1 serving"
    _ -> servings_str <> " servings"
  }
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
  use start_date <- glint.flag(
    glint.string_flag("start-date")
    |> glint.flag_help("Start date for filtering (YYYY-MM-DD)"),
  )
  use end_date <- glint.flag(
    glint.string_flag("end-date")
    |> glint.flag_help("End date for filtering (YYYY-MM-DD)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["list"] -> {
      let start = start_date(flags) |> option.from_result
      let end = end_date(flags) |> option.from_result

      case
        list_meal_plans_with_filters(config, start_date: start, end_date: end)
      {
        Ok(output) -> {
          io.println(output)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error listing meal plans: " <> err)
          Error(Nil)
        }
      }
    }
    ["show", date_arg] -> {
      // Show meal plan for a specific date
      show_plan(config, date_arg)
    }
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
      let start_date_val = date(flags) |> result.unwrap("2025-12-19")

      // Call regenerate_meals helper
      case regenerate_meals(config, start_date_val, days_val) {
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
      io.println(
        "  mp plan list [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]",
      )
      io.println("  mp plan show <YYYY-MM-DD>")
      io.println("  mp plan generate --days 7")
      io.println("  mp plan regenerate --date 2025-12-19 --days 7")
      io.println("  mp plan sync")
      Ok(Nil)
    }
  }
}
