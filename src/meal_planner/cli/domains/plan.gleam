/// Plan CLI domain - meal plan management and synchronization
///
/// This module provides CLI commands for:
/// - Listing meal plans
/// - Viewing meal plan details
/// - Generating new meal plans
/// - Syncing with FatSecret diary
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/id
import meal_planner/scheduler/sync_scheduler
import meal_planner/tandoor/client
import meal_planner/tandoor/mealplan

pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Manage meal plans and sync with FatSecret diary")
  use from_date <- glint.flag(
    glint.string_flag("from")
    |> glint.flag_help("Start date for listing (YYYY-MM-DD)"),
  )
  use to_date <- glint.flag(
    glint.string_flag("to")
    |> glint.flag_help("End date for listing (YYYY-MM-DD)"),
  )
  use plan_id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Meal plan ID for view/delete operations"),
  )
  use meal_type <- glint.flag(
    glint.int_flag("meal-type")
    |> glint.flag_help("Filter by meal type ID"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["list"] -> {
      let from = result_to_option(from_date(flags))
      let to = result_to_option(to_date(flags))
      let meal_type_filter = result_to_option(meal_type(flags))

      case
        list_meal_plans(config, from: from, to: to, meal_type: meal_type_filter)
      {
        Ok(output) -> {
          io.println(output)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
      }
    }
    ["view"] -> {
      case result_to_option(plan_id(flags)) {
        Some(id) -> {
          case view_meal_plan(config, plan_id: id) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
        None -> {
          io.println("Error: --id flag is required")
          io.println("Usage: mp plan view --id <meal_plan_id>")
          Error(Nil)
        }
      }
    }
    ["sync"] -> {
      io.println("Syncing FatSecret diary with meal plans...")

      // Create a dummy user ID for now (would come from auth in production)
      let user_id = id.user_id("default_user")

      // Trigger the sync
      case sync_scheduler.trigger_auto_sync(user_id) {
        Ok(result) -> {
          io.println("")
          io.println("Sync Complete!")
          io.println(string.repeat("=", 40))
          io.println("  Synced:  " <> int.to_string(result.synced))
          io.println("  Skipped: " <> int.to_string(result.skipped))
          io.println("  Failed:  " <> int.to_string(result.failed))
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: Sync failed")
          Error(Nil)
        }
      }
    }
    ["types"] -> {
      // List available meal types
      case list_meal_types(config) {
        Ok(output) -> {
          io.println(output)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Plan commands:")
      io.println("")
      io.println("  mp plan list                     - List all meal plans")
      io.println("  mp plan list --from 2025-12-01   - List from date")
      io.println("  mp plan list --to 2025-12-31     - List until date")
      io.println("  mp plan list --meal-type 1       - Filter by meal type")
      io.println("  mp plan view --id <id>           - View meal plan details")
      io.println(
        "  mp plan types                    - List available meal types",
      )
      io.println(
        "  mp plan sync                     - Sync with FatSecret diary",
      )
      Ok(Nil)
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert Result to Option for CLI flag handling
pub fn result_to_option(res: Result(a, b)) -> Option(a) {
  case res {
    Ok(val) -> Some(val)
    Error(_) -> None
  }
}

// ============================================================================
// List Meal Plans
// ============================================================================

fn list_meal_plans(
  config: Config,
  from from_date: Option(String),
  to to_date: Option(String),
  meal_type meal_type_filter: Option(Int),
) -> Result(String, String) {
  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case
    mealplan.list_meal_plans(
      tandoor_config,
      from_date: from_date,
      to_date: to_date,
      meal_type: meal_type_filter,
    )
  {
    Ok(response) -> {
      let header =
        "Meal Plans\n"
        <> string.repeat("=", 60)
        <> "\n"
        <> "Total: "
        <> int.to_string(response.count)
        <> " meal plans\n\n"

      let body = case response.results {
        [] -> "No meal plans found.\n"
        plans -> {
          plans
          |> list.map(format_meal_plan_entry)
          |> string.join("\n")
        }
      }

      Ok(header <> body)
    }
    Error(err) -> {
      Error("Failed to list meal plans: " <> client.error_to_string(err))
    }
  }
}

/// Format a single meal plan entry for display
pub fn format_meal_plan_entry(plan: mealplan.MealPlan) -> String {
  let recipe_info = case plan.recipe {
    Some(r) -> r.name
    None -> plan.title
  }

  let date_range = string.slice(plan.from_date, 0, 10)

  "┌─────────────────────────────────────────────────────────┐\n"
  <> "│ ID: "
  <> pad_right(int.to_string(plan.id), 8)
  <> " │ "
  <> pad_right(plan.meal_type_name, 12)
  <> " │ "
  <> date_range
  <> " │\n"
  <> "├─────────────────────────────────────────────────────────┤\n"
  <> "│ "
  <> pad_right(recipe_info, 55)
  <> " │\n"
  <> "│ Servings: "
  <> pad_right(float.to_string(plan.servings), 44)
  <> " │\n"
  <> "└─────────────────────────────────────────────────────────┘\n"
}

// ============================================================================
// View Meal Plan
// ============================================================================

fn view_meal_plan(
  config: Config,
  plan_id plan_id: Int,
) -> Result(String, String) {
  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case mealplan.get_meal_plan(tandoor_config, meal_plan_id: plan_id) {
    Ok(plan) -> {
      let header =
        string.repeat("=", 60)
        <> "\n"
        <> "                    MEAL PLAN DETAILS\n"
        <> string.repeat("=", 60)
        <> "\n\n"

      let basic_info =
        "ID:           "
        <> int.to_string(plan.id)
        <> "\n"
        <> "Title:        "
        <> plan.title
        <> "\n"
        <> "Meal Type:    "
        <> plan.meal_type_name
        <> "\n"
        <> "From:         "
        <> plan.from_date
        <> "\n"
        <> "To:           "
        <> plan.to_date
        <> "\n"
        <> "Servings:     "
        <> float.to_string(plan.servings)
        <> "\n"

      let recipe_info = case plan.recipe {
        Some(r) ->
          "\nRecipe\n"
          <> string.repeat("-", 40)
          <> "\n"
          <> "  Name: "
          <> r.name
          <> "\n"
          <> "  ID:   "
          <> int.to_string(r.id)
          <> "\n"
        None -> ""
      }

      let note_info = case plan.note {
        "" -> ""
        note -> "\nNote\n" <> string.repeat("-", 40) <> "\n" <> note <> "\n"
      }

      let shopping_info =
        "\nShopping List: "
        <> case plan.shopping {
          True -> "Yes"
          False -> "No"
        }
        <> "\n"

      let footer = "\n" <> string.repeat("=", 60)

      Ok(
        header
        <> basic_info
        <> recipe_info
        <> note_info
        <> shopping_info
        <> footer,
      )
    }
    Error(err) -> {
      Error("Failed to get meal plan: " <> client.error_to_string(err))
    }
  }
}

// ============================================================================
// List Meal Types
// ============================================================================

fn list_meal_types(config: Config) -> Result(String, String) {
  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case mealplan.list_meal_types(tandoor_config) {
    Ok(meal_types) -> {
      let header = "Available Meal Types\n" <> string.repeat("=", 40) <> "\n\n"

      let body = case meal_types {
        [] -> "No meal types configured.\n"
        types -> {
          types
          |> list.map(fn(mt) {
            "  "
            <> int.to_string(mt.id)
            <> ". "
            <> mt.name
            <> case mt.order {
              0 -> ""
              order -> " (order: " <> int.to_string(order) <> ")"
            }
          })
          |> string.join("\n")
        }
      }

      Ok(header <> body)
    }
    Error(err) -> {
      Error("Failed to list meal types: " <> client.error_to_string(err))
    }
  }
}

// ============================================================================
// Formatting Helpers
// ============================================================================

fn pad_right(s: String, width: Int) -> String {
  let len = string.length(s)
  case width > len {
    True -> s <> string.repeat(" ", width - len)
    False -> string.slice(s, 0, width)
  }
}
