/// Shore TUI Application - Elm Architecture Setup
///
/// This module wires up the Shore framework with the Elm Architecture pattern:
/// - Model: Application state
/// - Msg: Messages/events
/// - Update: State transitions
/// - View: Rendering
import gleam/io
import meal_planner/cli/model
import meal_planner/cli/types
import meal_planner/cli/update
import meal_planner/cli/view
import meal_planner/config

/// Launch the interactive TUI application
pub fn start(config: config.Config) -> Nil {
  io.println("🚀 Launching Meal Planner TUI...")
  io.println("")

  // Initialize the model with config
  let initial_model = model.init(config)

  // Create Shore application with Elm Architecture
  // Note: Shore framework handles the event loop and rendering
  // For now, we'll display a placeholder message since full Shore integration
  // requires the Shore library to be fully configured
  display_tui_placeholder(initial_model)
}

/// Placeholder TUI display while awaiting full Shore integration
fn display_tui_placeholder(model: types.Model) -> Nil {
  io.println("╔════════════════════════════════════════════════╗")
  io.println("║        Meal Planner - Interactive TUI          ║")
  io.println("╠════════════════════════════════════════════════╣")
  io.println("║                                                ║")
  io.println("║  🍽️  Meal Planner Interactive Interface       ║")
  io.println("║                                                ║")
  io.println("║  Select Domain:                                ║")
  io.println("║    1. FatSecret API                            ║")
  io.println("║    2. Tandoor Recipes                          ║")
  io.println("║    3. Database                                 ║")
  io.println("║    4. Meal Planning                            ║")
  io.println("║    5. Nutrition Analysis                       ║")
  io.println("║    6. Scheduler                                ║")
  io.println("║                                                ║")
  io.println("║  [q]uit                                        ║")
  io.println("║  [?] Help                                      ║")
  io.println("║                                                ║")
  io.println("╚════════════════════════════════════════════════╝")
  io.println("")
  io.println("ℹ️  TUI mode initializing with:")
  io.println("   - Database: " <> model.config.database.host)
  io.println("")
  io.println("💡 Shore TUI framework integration in progress...")
  io.println(
    "   Use CLI mode for immediate access: gleam run -- fatsecret foods search --query chicken",
  )
}
