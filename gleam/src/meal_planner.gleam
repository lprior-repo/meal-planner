/// Meal Planner - Weekly meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner application.
/// It handles CLI argument parsing and dispatches to the appropriate commands.
import gleam/io
import gleam/list
import gleam/result
import glint
import meal_planner/application
import meal_planner/env
import meal_planner/meal_plan
import meal_planner/ncp
import meal_planner/output
import meal_planner/recipe_loader
import meal_planner/user_profile

/// Application entry point
pub fn main() {
  // Start OTP application (initializes database, supervisor tree)
  case application.start() {
    Error(err) -> {
      io.println(
        "Failed to start application: " <> application.format_error(err),
      )
    }
    Ok(_app_state) -> {
      // Application started successfully, run CLI
      glint.new()
      |> glint.with_name("meal-planner")
      |> glint.pretty_help(glint.default_pretty_help())
      |> glint.add(at: [], do: default_command())
      |> glint.add(at: ["plan"], do: plan_command())
      |> glint.add(at: ["audit"], do: audit_command())
      |> glint.add(at: ["profile"], do: profile_command())
      |> glint.add(at: ["ncp-status"], do: ncp_status_command())
      |> glint.add(at: ["ncp-reconcile"], do: ncp_reconcile_command())
      |> glint.run(start_arguments())
    }
  }
}

/// Get command line arguments (Erlang specific)
@external(erlang, "init", "get_plain_arguments")
fn start_arguments() -> List(String)

/// Default command - interactive mode selection
fn default_command() -> glint.Command(Nil) {
  use <- glint.command_help("Interactive mode selection")
  use _named, _args, _flags <- glint.command()

  io.println("Meal Planner v1.0.0")
  io.println("")

  case select_mode() {
    Ok(mode) -> handle_mode(mode)
    Error(err) -> {
      io.println("Error: " <> err)
      Nil
    }
  }
}

/// Plan command - generate weekly meal plan
fn plan_command() -> glint.Command(Nil) {
  use <- glint.command_help("Generate weekly meal plan")
  use _named, _args, _flags <- glint.command()

  case generate_and_display_plan() {
    Ok(_) -> Nil
    Error(err) -> io.println("Error generating plan: " <> err)
  }
}

/// Audit command - audit recipes for Vertical Diet compliance
fn audit_command() -> glint.Command(Nil) {
  use <- glint.command_help("Audit recipes for Vertical Diet compliance")
  use _named, _args, _flags <- glint.command()

  case audit_recipes() {
    Ok(_) -> Nil
    Error(err) -> io.println("Error auditing recipes: " <> err)
  }
}

/// Profile command - collect and display user profile
fn profile_command() -> glint.Command(Nil) {
  use <- glint.command_help("Set up and display user profile")
  use _named, _args, _flags <- glint.command()

  case setup_profile() {
    Ok(_) -> Nil
    Error(err) -> io.println("Error setting up profile: " <> err)
  }
}

/// Days flag for NCP commands
fn days_flag() -> glint.Flag(Int) {
  glint.int_flag("days")
  |> glint.flag_default(7)
  |> glint.flag_help("Number of days to analyze")
}

/// NCP status command - show nutrition status vs goals
fn ncp_status_command() -> glint.Command(Nil) {
  use <- glint.command_help("Show nutrition status vs goals")
  use days_getter <- glint.flag(days_flag())
  use _named, _args, flags <- glint.command()

  let day_count = case days_getter(flags) {
    Ok(d) -> d
    Error(_) -> 7
  }

  case show_ncp_status(day_count) {
    Ok(_) -> Nil
    Error(err) -> io.println("Error showing NCP status: " <> err)
  }
}

/// NCP reconcile command - run nutrition reconciliation
fn ncp_reconcile_command() -> glint.Command(Nil) {
  use <- glint.command_help(
    "Run nutrition reconciliation and suggest adjustments",
  )
  use days_getter <- glint.flag(days_flag())
  use _named, _args, flags <- glint.command()

  let day_count = case days_getter(flags) {
    Ok(d) -> d
    Error(_) -> 7
  }

  case run_ncp_reconciliation(day_count) {
    Ok(_) -> Nil
    Error(err) -> io.println("Error running NCP reconciliation: " <> err)
  }
}

/// Application modes
pub type Mode {
  Terminal
  Email
  Audit
  Profile
}

/// Interactive mode selection
fn select_mode() -> Result(String, String) {
  io.println("Select mode:")
  io.println("  (t)erminal - Display meal plan in terminal")
  io.println("  (e)mail    - Send meal plan via email")
  io.println("  (a)udit    - Audit recipes for Vertical Diet compliance")
  io.println("  (p)rofile  - Set up user profile")
  io.print("Your choice: ")

  // This would need to be implemented with proper stdin reading
  // For now, default to terminal mode
  Ok("t")
}

/// Handle selected mode
fn handle_mode(mode: String) {
  case mode {
    "t" ->
      case generate_and_display_plan() {
        Ok(_) -> Nil
        Error(err) -> io.println("Error: " <> err)
      }
    "e" ->
      case generate_and_email_plan() {
        Ok(_) -> Nil
        Error(err) -> io.println("Error: " <> err)
      }
    "a" ->
      case audit_recipes() {
        Ok(_) -> Nil
        Error(err) -> io.println("Error: " <> err)
      }
    "p" ->
      case setup_profile() {
        Ok(_) -> Nil
        Error(err) -> io.println("Error: " <> err)
      }
    _ -> io.println("Invalid mode. Please choose t, e, a, or p.")
  }
}

/// Generate and display meal plan in terminal
fn generate_and_display_plan() -> Result(Nil, String) {
  // Database is already initialized by application.start()
  case user_profile.load_or_collect_profile() {
    Ok(profile) -> {
      case recipe_loader.load_all_recipes("recipes", "") {
        Ok(recipes) -> {
          case meal_plan.generate_weekly_plan(profile, recipes) {
            Ok(plan) -> {
              output.print_weekly_plan(plan)
              Ok(Nil)
            }
            Error(err) -> Error("Failed to generate meal plan: " <> err)
          }
        }
        Error(err) -> Error("Failed to load recipes: " <> err)
      }
    }
    Error(err) -> Error("Failed to load profile: " <> err)
  }
}

/// Generate and email meal plan
fn generate_and_email_plan() -> Result(Nil, String) {
  // Database is already initialized by application.start()
  case user_profile.load_or_collect_profile() {
    Ok(profile) -> {
      case recipe_loader.load_all_recipes("recipes", "") {
        Ok(recipes) -> {
          case meal_plan.generate_weekly_plan(profile, recipes) {
            Ok(plan) -> {
              case env.load_email_config() {
                Ok(config) -> {
                  case output.send_weekly_plan_email(plan, config) {
                    Ok(_) -> Ok(Nil)
                    Error(err) -> Error("Failed to send email: " <> err)
                  }
                }
                Error(env_err) ->
                  Error(
                    "Failed to load email config: " <> env.format_error(env_err),
                  )
              }
            }
            Error(err) -> Error("Failed to generate meal plan: " <> err)
          }
        }
        Error(err) -> Error("Failed to load recipes: " <> err)
      }
    }
    Error(err) -> Error("Failed to load profile: " <> err)
  }
}

/// Audit recipes for Vertical Diet compliance
fn audit_recipes() -> Result(Nil, String) {
  use recipes <- result.try(recipe_loader.load_all_recipes("recipes", ""))

  output.print_audit_report(recipes)
  Ok(Nil)
}

/// Set up user profile
fn setup_profile() -> Result(Nil, String) {
  case user_profile.collect_interactive_profile() {
    Ok(profile) -> {
      user_profile.print_profile(profile)
      Ok(Nil)
    }
    Error(profile_err) ->
      Error(user_profile.profile_error_to_string(profile_err))
  }
}

/// Show NCP status
fn show_ncp_status(days: Int) -> Result(Nil, String) {
  io.println("Fetching nutrition status...")

  // Get history
  case ncp.get_nutrition_history(days) {
    Ok(history) -> {
      case list.is_empty(history) {
        True -> {
          io.println("No nutrition data found.")
          Ok(Nil)
        }
        False -> {
          // Get goals
          let goals = get_ncp_goals()

          // Get recipes for suggestions
          let recipes = get_ncp_recipes()

          // Get current date as string
          let date = get_current_date()

          // Run reconciliation
          let result =
            ncp.run_reconciliation(history, goals, recipes, 25.0, 3, date)

          // Output status
          io.println(ncp.format_status_output(result))
          Ok(Nil)
        }
      }
    }
    Error(err) -> Error("Failed to get nutrition history: " <> err)
  }
}

/// Run NCP reconciliation
fn run_ncp_reconciliation(days: Int) -> Result(Nil, String) {
  io.println("Running nutrition reconciliation...")

  // Get history
  case ncp.get_nutrition_history(days) {
    Ok(history) -> {
      case list.is_empty(history) {
        True -> {
          io.println("No nutrition data found.")
          Ok(Nil)
        }
        False -> {
          // Get goals
          let goals = get_ncp_goals()

          // Get recipes for suggestions
          let recipes = get_ncp_recipes()

          // Get current date as string
          let date = get_current_date()

          // Run reconciliation
          let result =
            ncp.run_reconciliation(history, goals, recipes, 25.0, 5, date)

          // Output reconciliation result
          io.println(ncp.format_reconcile_output(result))
          Ok(Nil)
        }
      }
    }
    Error(err) -> Error("Failed to get nutrition history: " <> err)
  }
}

/// Get NCP goals from environment or defaults
fn get_ncp_goals() -> ncp.NutritionGoals {
  // Use defaults for now - could be enhanced to read from env
  ncp.get_default_goals()
}

/// Get recipes for NCP suggestions
fn get_ncp_recipes() -> List(ncp.ScoredRecipe) {
  // Load recipes and convert to ScoredRecipe format
  case recipe_loader.load_all_recipes("recipes", "") {
    Ok(recipes) -> {
      list.map(recipes, fn(r) {
        ncp.ScoredRecipe(name: r.name, macros: r.macros)
      })
    }
    Error(_) -> []
  }
}

/// Get current date as string
@external(erlang, "meal_planner_ffi", "get_current_date")
fn get_current_date() -> String
