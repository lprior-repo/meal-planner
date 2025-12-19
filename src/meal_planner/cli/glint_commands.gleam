/// CLI commands module
///
/// Handles non-interactive command execution for the meal planner CLI
import gleam/io
import gleam/list
import gleam/string
import meal_planner/config.{type Config}

pub fn run(config: Config, args: List(String)) -> Nil {
  // Basic command handling for FatSecret foods search
  // More complete implementation would use Glint for full parsing
  case args {
    ["fatsecret", "foods", "search", ..rest] -> {
      handle_foods_search(config, rest)
    }
    ["help"] | ["--help"] | ["-h"] -> {
      show_help()
    }
    _ -> {
      io.println("Unknown command. Use 'help' for available commands.")
    }
  }
}

fn handle_foods_search(config: Config, args: List(String)) -> Nil {
  // Extract --query parameter
  let query = case
    list.find(args, fn(arg) { string.starts_with(arg, "--query=") })
  {
    Ok(arg) -> string.slice(arg, 8, string.length(arg))
    Error(_) -> ""
  }

  case query {
    "" -> {
      io.println("Error: --query parameter required")
      io.println("Usage: fatsecret foods search --query \"chicken\"")
    }
    _ -> {
      io.println("Searching for: " <> query)
      io.println("FatSecret API call would execute here")
      io.println("Config database: " <> config.database.host)
    }
  }
}

fn show_help() -> Nil {
  io.println("Meal Planner CLI - Available Commands:")
  io.println("")
  io.println("fatsecret foods search --query \"<search>\"")
  io.println("  Search for foods in FatSecret database")
  io.println("")
  io.println("help, --help, -h")
  io.println("  Show this help message")
}
