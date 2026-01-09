//  Command Line Interface
//  Provides CLI commands for the meal-planner automation
//  Supports recipe management, meal planning, and nutrition tracking

import gleam/list
import gleam/string

pub type Command {
  Help
  Version
  RecipeList
  RecipeSearch(String)
  RecipeImport(String)
  MealPlanCreate(String, String)
  MealPlanShow(String)
  GroceryListGenerate(String)
  Unknown(String)
}

pub type CommandResult {
  Success(String)
  Error(String)
  Help(String)
}

/// Parse command line arguments
pub fn parse_args(args: list.List(String)) -> Command {
  case args {
    [] -> RecipeList
    ["help"] -> Help
    ["--help"] -> Help
    ["-h"] -> Help
    ["version"] -> Version
    ["--version"] -> Version
    ["-v"] -> Version
    ["recipe", "list"] -> RecipeList
    ["recipe", "search", query] -> RecipeSearch(query)
    ["recipe", "import", recipe_id] -> RecipeImport(recipe_id)
    ["meal-plan", "create", start, end] -> MealPlanCreate(start, end)
    ["meal-plan", "show", date] -> MealPlanShow(date)
    ["grocery-list", "generate", date] -> GroceryListGenerate(date)
    [cmd] -> Unknown(cmd)
    [cmd, ..rest] -> {
      let args_str = string.join(rest, " ")
      Unknown(cmd <> " " <> args_str)
    }
  }
}

/// Format help text
pub fn help_text() -> String {
  "Meal Planner Automation - CLI Commands

USAGE:
    mp <COMMAND> [OPTIONS]

COMMANDS:
    recipe list              List all recipes
    recipe search <QUERY>    Search recipes by name
    recipe import <ID>       Import recipe from Tandoor

    meal-plan create <S> <E> Create meal plan (start_date end_date)
    meal-plan show <DATE>    Show meal plan for date

    grocery-list generate    Generate grocery list

    help                     Show this help message
    version                  Show version

OPTIONS:
    -h, --help              Show help message
    -v, --version           Show version

EXAMPLES:
    mp recipe list
    mp recipe search pasta
    mp meal-plan create 20088 20094
    mp grocery-list generate
"
}

/// Execute a parsed command
pub fn execute(cmd: Command) -> CommandResult {
  case cmd {
    Help -> Help(help_text())
    Version -> Success("meal-planner v0.1.0")
    RecipeList -> Success("Listing recipes... (not yet implemented)")
    RecipeSearch(query) -> Success("Searching for: " <> query <> " (not yet implemented)")
    RecipeImport(recipe_id) -> Success("Importing recipe " <> recipe_id <> " (not yet implemented)")
    MealPlanCreate(start, end) -> Success("Creating meal plan from " <> start <> " to " <> end <> " (not yet implemented)")
    MealPlanShow(date) -> Success("Showing meal plan for " <> date <> " (not yet implemented)")
    GroceryListGenerate(date) -> Success("Generating grocery list for " <> date <> " (not yet implemented)")
    Unknown(cmd) -> Error("Unknown command: " <> cmd <> "\nUse 'mp help' for usage information")
  }
}

/// Format command result for display
pub fn format_result(result: CommandResult) -> String {
  case result {
    Success(msg) -> msg
    Error(msg) -> "Error: " <> msg
    Help(msg) -> msg
  }
}
