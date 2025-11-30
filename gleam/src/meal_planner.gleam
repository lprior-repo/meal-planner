/// Meal Planner - Weekly meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner application.
/// It handles CLI argument parsing and dispatches to the appropriate commands.

import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glint
import meal_planner/env
import meal_planner/meal_plan
import meal_planner/recipe_loader
import meal_planner/storage
import meal_planner/output
import meal_planner/user_profile
// import meal_planner/ncp  // Temporarily disabled due to compilation errors
import shared/types

/// Application entry point
pub fn main() {
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

/// NCP status command - show nutrition status vs goals
fn ncp_status_command() -> glint.Command(Nil) {
  use <- glint.command_help("Show nutrition status vs goals")
  use named, _args, _flags <- glint.command()

  let days = case glint.get_flag(named, "days") {
    Ok(d) -> d
    Error(_) -> 7
  }
  
  case show_ncp_status(days) {
    Ok(_) -> Nil
    Error(err) -> io.println("Error showing NCP status: " <> err)
  }
}

/// NCP reconcile command - run nutrition reconciliation
fn ncp_reconcile_command() -> glint.Command(Nil) {
  use <- glint.command_help("Run nutrition reconciliation and suggest adjustments")
  use named, _args, _flags <- glint.command()

  let days = case glint.get_flag(named, "days") {
    Ok(d) -> d
    Error(_) -> 7
  }
  
  case run_ncp_reconciliation(days) {
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
    "t" -> case generate_and_display_plan() {
      Ok(_) -> Nil
      Error(err) -> io.println("Error: " <> err)
    }
    "e" -> case generate_and_email_plan() {
      Ok(_) -> Nil
      Error(err) -> io.println("Error: " <> err)
    }
    "a" -> case audit_recipes() {
      Ok(_) -> Nil
      Error(err) -> io.println("Error: " <> err)
    }
    "p" -> case setup_profile() {
      Ok(_) -> Nil
      Error(err) -> io.println("Error: " <> err)
    }
    _ -> io.println("Invalid mode. Please choose t, e, a, or p.")
  }
}

/// Generate and display meal plan in terminal
fn generate_and_display_plan() -> Result(Nil, String) {
  use <- result.try(storage.initialize_database())
  
  use profile <- result.try(user_profile.load_or_collect_profile())
  use recipes <- result.try(recipe_loader.load_all_recipes("recipes", ""))
  
  use plan <- result.try(meal_plan.generate_weekly_plan(profile, recipes))
  
  output.print_weekly_plan(plan)
  Ok(Nil)
}

/// Generate and email meal plan
fn generate_and_email_plan() -> Result(Nil, String) {
  use <- result.try(storage.initialize_database())
  
  use profile <- result.try(user_profile.load_or_collect_profile())
  use recipes <- result.try(recipe_loader.load_all_recipes("recipes", ""))
  
  use plan <- result.try(meal_plan.generate_weekly_plan(profile, recipes))
  
  case env.load_email_config() {
    Ok(config) -> output.send_weekly_plan_email(plan, config)
    Error(err) -> Error("Failed to load email config: " <> err)
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
  use profile <- result.try(user_profile.collect_interactive_profile())
  
  user_profile.print_profile(profile)
  Ok(Nil)
}

/// Show NCP status
fn show_ncp_status(days: Int) -> Result(Nil, String) {
  io.println("NCP status temporarily disabled due to module compilation issues")
  Ok(Nil)
}

/// Run NCP reconciliation
fn run_ncp_reconciliation(days: Int) -> Result(Nil, String) {
  io.println("NCP reconciliation temporarily disabled due to module compilation issues")
  Ok(Nil)
}
