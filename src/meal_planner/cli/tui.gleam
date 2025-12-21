/// Interactive TUI Menu System using Shore Framework
///
/// Provides an interactive terminal UI with:
/// - Menu navigation with arrow keys and numeric shortcuts
/// - Domain-based command organization
/// - Keyboard shortcuts for all operations
/// - Visual feedback and styling
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import meal_planner/cli/model
import meal_planner/cli/types
import meal_planner/config.{type Config}
import shore
import shore/internal
import shore/key
import shore/style
import shore/ui

// ============================================================================
// Shore Application Setup
// ============================================================================

/// Initialize and start the interactive TUI
pub fn start(config: Config) -> Nil {
  let exit = process.new_subject()

  let assert Ok(_actor) =
    shore.spec(
      init: fn() { init(config) },
      update: update,
      view: view,
      exit: exit,
      keybinds: custom_keybinds(),
      redraw: shore.on_update(),
    )
    |> shore.start

  // Wait for exit signal
  exit
  |> process.receive_forever
}

/// Initialize model with effects
fn init(config: Config) -> #(types.Model, List(fn() -> types.Msg)) {
  let model = model.init(config)
  #(model, [])
}

/// Custom keybindings for TUI navigation
fn custom_keybinds() -> internal.Keybinds {
  shore.keybinds(
    exit: key.Char("q"),
    submit: key.Enter,
    focus_clear: key.Esc,
    focus_next: key.Tab,
    focus_prev: key.BackTab,
  )
}

// ============================================================================
// Update - Message Handler
// ============================================================================

/// Process messages and return updated model with effects
pub fn update(
  model: types.Model,
  msg: types.Msg,
) -> #(types.Model, List(fn() -> types.Msg)) {
  case msg {
    types.SelectDomain(domain) -> {
      let updated = model.select_domain(model, domain)
      #(updated, [])
    }

    types.SelectScreen(screen) -> {
      let updated = model.navigate_to(model, screen)
      #(updated, [])
    }

    types.SelectCommand(command) -> {
      handle_command_selection(model, command)
    }

    types.GoBack -> {
      let updated = model.go_back(model)
      #(updated, [])
    }

    types.Quit -> {
      #(model, [])
    }

    types.Refresh -> {
      #(model, [])
    }

    types.UpdateSearchQuery(query) -> {
      let updated = model.update_search_query(model, query)
      #(updated, [])
    }

    types.UpdateDate(_date) -> {
      #(model, [])
    }

    types.UpdateQuantity(_qty) -> {
      #(model, [])
    }

    types.ClearInput -> {
      let updated = model.update_search_query(model, "")
      #(updated, [])
    }

    types.KeyPress(key) -> handle_key_press(model, key)

    types.SearchFoods -> {
      let loading_model = model.set_loading(model, True)
      #(loading_model, [])
    }

    types.GotSearchResults(result) -> {
      case result {
        Ok(foods) -> {
          let updated = model.set_results(model, types.FoodResults(foods))
          #(updated, [])
        }
        Error(err) -> {
          let updated = model.set_error(model, err)
          #(updated, [])
        }
      }
    }

    types.GetFoodDetails(food_id) -> {
      let loading_model = model.set_loading(model, True)
      let _ = food_id
      #(loading_model, [])
    }

    types.GotFoodDetails(result) -> {
      case result {
        Ok(_details) -> {
          #(model, [])
        }
        Error(err) -> {
          let updated = model.set_error(model, err)
          #(updated, [])
        }
      }
    }

    types.NoOp -> {
      #(model, [])
    }
  }
}

/// Handle command selection and navigate to appropriate screen
fn handle_command_selection(
  model: types.Model,
  command: types.DomainCommand,
) -> #(types.Model, List(fn() -> types.Msg)) {
  let screen = command_to_screen(command)
  let updated = model.navigate_to(model, screen)
  #(updated, [])
}

/// Map domain commands to their target screens
fn command_to_screen(command: types.DomainCommand) -> types.Screen {
  case command {
    // FatSecret commands
    types.FatSecretFoodsSearch -> types.FoodSearch
    types.FatSecretFoodsDetail -> types.FoodSearch
    types.FatSecretDiaryGet -> types.DiaryView
    types.FatSecretExerciseList -> types.ExerciseView
    types.FatSecretFavoritesList -> types.FavoritesView
    types.FatSecretRecipesSearch -> types.RecipeView
    types.FatSecretProfileGet -> types.ProfileView
    types.FatSecretWeightLog -> types.WeightView
    // Tandoor commands
    types.TandoorSync -> types.TandoorRecipes
    types.TandoorCategories -> types.TandoorRecipes
    types.TandoorUpdate -> types.TandoorRecipes
    types.TandoorDelete -> types.TandoorRecipes
    // Database commands
    types.DatabaseFoodsSearch -> types.DatabaseFoods
    types.DatabaseFoodsDetail -> types.DatabaseFoods
    types.DatabaseSync -> types.DatabaseFoods
    // Meal Planning commands
    types.MealPlanGenerate -> types.MealPlanGenerator
    types.MealPlanShow -> types.MealPlanGenerator
    types.MealPlanRegenerate -> types.MealPlanGenerator
    // Nutrition commands
    types.NutritionGoalsShow -> types.NutritionAnalysis
    types.NutritionGoalsSet -> types.NutritionAnalysis
    types.NutritionAnalyze -> types.NutritionAnalysis
    // Scheduler commands
    types.SchedulerList -> types.SchedulerView
    types.SchedulerEnable -> types.SchedulerView
    types.SchedulerDisable -> types.SchedulerView
    types.SchedulerRun -> types.SchedulerView
  }
}

/// Handle keyboard input for menu navigation
pub fn handle_key_press(
  model: types.Model,
  key: String,
) -> #(types.Model, List(fn() -> types.Msg)) {
  case model.current_screen {
    types.MainMenu -> handle_main_menu_key(model, key)
    types.DomainMenu(domain) -> handle_domain_menu_key(model, domain, key)
    _ -> {
      case key {
        "\u{001B}" -> {
          let updated = model.go_back(model)
          #(updated, [])
        }
        _ -> #(model, [])
      }
    }
  }
}

/// Handle key press on main menu
fn handle_main_menu_key(
  model: types.Model,
  key: String,
) -> #(types.Model, List(fn() -> types.Msg)) {
  case key {
    "1" -> {
      let updated = model.select_domain(model, types.FatSecretDomain)
      #(updated, [])
    }
    "2" -> {
      let updated = model.select_domain(model, types.TandoorDomain)
      #(updated, [])
    }
    "3" -> {
      let updated = model.select_domain(model, types.DatabaseDomain)
      #(updated, [])
    }
    "4" -> {
      let updated = model.select_domain(model, types.MealPlanningDomain)
      #(updated, [])
    }
    "5" -> {
      let updated = model.select_domain(model, types.NutritionDomain)
      #(updated, [])
    }
    "6" -> {
      let updated = model.select_domain(model, types.SchedulerDomain)
      #(updated, [])
    }
    _ -> #(model, [])
  }
}

/// Handle key press on domain menu
fn handle_domain_menu_key(
  model: types.Model,
  domain: types.Domain,
  key: String,
) -> #(types.Model, List(fn() -> types.Msg)) {
  case key {
    "\u{001B}" -> {
      let updated = model.go_back(model)
      #(updated, [])
    }
    // Number key navigation for domain commands
    _ -> {
      case get_command_for_key(domain, key) {
        Some(command) -> handle_command_selection(model, command)
        None -> #(model, [])
      }
    }
  }
}

/// Get the domain command for a given key press
fn get_command_for_key(
  domain: types.Domain,
  key: String,
) -> option.Option(types.DomainCommand) {
  case domain {
    types.FatSecretDomain ->
      case key {
        "1" -> Some(types.FatSecretFoodsSearch)
        "2" -> Some(types.FatSecretFoodsDetail)
        "3" -> Some(types.FatSecretDiaryGet)
        "4" -> Some(types.FatSecretExerciseList)
        "5" -> Some(types.FatSecretFavoritesList)
        "6" -> Some(types.FatSecretRecipesSearch)
        "7" -> Some(types.FatSecretProfileGet)
        "8" -> Some(types.FatSecretWeightLog)
        _ -> None
      }
    types.TandoorDomain ->
      case key {
        "1" -> Some(types.TandoorSync)
        "2" -> Some(types.TandoorCategories)
        "3" -> Some(types.TandoorUpdate)
        "4" -> Some(types.TandoorDelete)
        _ -> None
      }
    types.DatabaseDomain ->
      case key {
        "1" -> Some(types.DatabaseFoodsSearch)
        "2" -> Some(types.DatabaseFoodsDetail)
        "3" -> Some(types.DatabaseSync)
        _ -> None
      }
    types.MealPlanningDomain ->
      case key {
        "1" -> Some(types.MealPlanGenerate)
        "2" -> Some(types.MealPlanShow)
        "3" -> Some(types.MealPlanRegenerate)
        _ -> None
      }
    types.NutritionDomain ->
      case key {
        "1" -> Some(types.NutritionGoalsShow)
        "2" -> Some(types.NutritionGoalsSet)
        "3" -> Some(types.NutritionAnalyze)
        _ -> None
      }
    types.SchedulerDomain ->
      case key {
        "1" -> Some(types.SchedulerList)
        "2" -> Some(types.SchedulerEnable)
        "3" -> Some(types.SchedulerDisable)
        "4" -> Some(types.SchedulerRun)
        _ -> None
      }
  }
}

// ============================================================================
// View - Screen Rendering
// ============================================================================

/// Render the current screen as Shore UI nodes
fn view(model: types.Model) -> shore.Node(types.Msg) {
  case model.current_screen {
    types.MainMenu -> view_main_menu(model)
    types.DomainMenu(domain) -> view_domain_menu(model, domain)
    types.FoodSearch -> view_food_search(model)
    types.ErrorScreen(err) -> view_error(err)
    types.LoadingScreen(msg) -> view_loading(msg)
    _ -> view_placeholder(model)
  }
}

/// Render main menu with domain options
fn view_main_menu(_model: types.Model) -> shore.Node(types.Msg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("Meal Planner - Interactive TUI", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Select a domain:"),
    ui.br(),
    ui.button(
      "1. FatSecret API",
      key.Char("1"),
      types.SelectDomain(types.FatSecretDomain),
    ),
    ui.br(),
    ui.button(
      "2. Tandoor Recipes",
      key.Char("2"),
      types.SelectDomain(types.TandoorDomain),
    ),
    ui.br(),
    ui.button(
      "3. Database",
      key.Char("3"),
      types.SelectDomain(types.DatabaseDomain),
    ),
    ui.br(),
    ui.button(
      "4. Meal Planning",
      key.Char("4"),
      types.SelectDomain(types.MealPlanningDomain),
    ),
    ui.br(),
    ui.button(
      "5. Nutrition Analysis",
      key.Char("5"),
      types.SelectDomain(types.NutritionDomain),
    ),
    ui.br(),
    ui.button(
      "6. Scheduler",
      key.Char("6"),
      types.SelectDomain(types.SchedulerDomain),
    ),
    ui.br(),
    ui.hr(),
    ui.br(),
    ui.text_styled("Press [q] to quit, [1-6] to select", Some(style.Cyan), None),
  ])
}

/// Render domain menu with command options
fn view_domain_menu(
  _model: types.Model,
  domain: types.Domain,
) -> shore.Node(types.Msg) {
  let domain_name = domain_to_string(domain)
  let commands = get_domain_commands(domain)

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled(domain_name <> " Domain", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Available commands:"),
    ui.br(),
    ..list.append(render_command_list(commands), [
      ui.br(),
      ui.hr(),
      ui.br(),
      ui.text_styled(
        "Press [ESC] to go back, [q] to quit",
        Some(style.Cyan),
        None,
      ),
    ])
  ])
}

/// Render food search screen
fn view_food_search(model: types.Model) -> shore.Node(types.Msg) {
  ui.col([
    ui.br(),
    ui.text_styled("Food Search", Some(style.Green), None),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.input(
      "Search query:",
      model.search_query,
      style.Pct(80),
      types.UpdateSearchQuery,
    ),
    ui.br(),
    ui.button("Search", key.Enter, types.SearchFoods),
    ui.br(),
    case model.loading {
      True -> ui.text("Loading...")
      False -> ui.text("")
    },
  ])
}

/// Render error screen
fn view_error(err: String) -> shore.Node(types.Msg) {
  ui.col([
    ui.br(),
    ui.text_styled("Error", Some(style.Red), None),
    ui.hr_styled(style.Red),
    ui.br(),
    ui.text_wrapped(err),
    ui.br(),
    ui.text_styled("Press [ESC] to go back", Some(style.Cyan), None),
  ])
}

/// Render loading screen
fn view_loading(msg: String) -> shore.Node(types.Msg) {
  ui.col([
    ui.br(),
    ui.text_styled("Loading...", Some(style.Yellow), None),
    ui.hr(),
    ui.br(),
    ui.text(msg),
  ])
}

/// Render placeholder for unimplemented screens
fn view_placeholder(_model: types.Model) -> shore.Node(types.Msg) {
  ui.col([
    ui.br(),
    ui.text_styled("Screen not yet implemented", Some(style.Yellow), None),
    ui.br(),
    ui.text_styled("Press [ESC] to go back", Some(style.Cyan), None),
  ])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert domain to display string
fn domain_to_string(domain: types.Domain) -> String {
  case domain {
    types.FatSecretDomain -> "FatSecret API"
    types.TandoorDomain -> "Tandoor Recipes"
    types.DatabaseDomain -> "Database"
    types.MealPlanningDomain -> "Meal Planning"
    types.NutritionDomain -> "Nutrition Analysis"
    types.SchedulerDomain -> "Scheduler"
  }
}

/// Get available commands for a domain
fn get_domain_commands(domain: types.Domain) -> List(String) {
  case domain {
    types.FatSecretDomain -> [
      "foods search - Search for foods",
      "foods detail - Get food details",
      "diary get - View diary entries",
      "exercise list - List exercise entries",
      "favorites list - View favorite foods",
      "recipes search - Search recipes",
      "profile get - Get user profile",
      "weight log - Log weight entry",
    ]
    types.TandoorDomain -> [
      "sync - Sync recipes from Tandoor",
      "categories - List recipe categories",
      "update - Update recipe metadata",
      "delete - Delete a recipe",
    ]
    types.DatabaseDomain -> [
      "foods search - Search database foods",
      "foods detail - Get food details",
      "sync - Sync USDA data",
    ]
    types.MealPlanningDomain -> [
      "generate - Generate meal plan",
      "show - Display current plan",
      "regenerate - Regenerate specific day",
    ]
    types.NutritionDomain -> [
      "goals show - Display nutrition goals",
      "goals set - Set nutrition targets",
      "analyze - Analyze meal nutrition",
    ]
    types.SchedulerDomain -> [
      "list - List scheduled tasks",
      "enable - Enable a task",
      "disable - Disable a task",
      "run - Run task immediately",
    ]
  }
}

/// Render list of commands
fn render_command_list(commands: List(String)) -> List(shore.Node(types.Msg)) {
  commands
  |> list.map(fn(cmd) { ui.text("  - " <> cmd) })
  |> list.intersperse(ui.br())
}

/// Render the view as a string (for testing)
pub fn render_view(model: types.Model) -> String {
  case model.current_screen {
    types.MainMenu ->
      "Meal Planner - Main Menu\n\nFatSecret API\nTandoor Recipes\nDatabase\nMeal Planning\nNutrition Analysis\nScheduler"
    types.DomainMenu(domain) -> {
      let name = domain_to_string(domain)
      name <> " Domain\n\nAvailable commands"
    }
    types.FoodSearch ->
      "Food Search\nQuery: "
      <> model.search_query
      <> "\nLoading: "
      <> case model.loading {
        True -> "Yes"
        False -> "No"
      }
    types.ErrorScreen(err) -> "Error: " <> err
    types.LoadingScreen(msg) -> "Loading: " <> msg
    _ -> "Screen not implemented"
  }
}
