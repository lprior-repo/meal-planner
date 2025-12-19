# Meal Planner CLI Architecture

This document explains the design and architecture of the Meal Planner CLI system, how it works internally, and how to extend it with new commands.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Design Patterns](#design-patterns)
4. [Message Flow](#message-flow)
5. [Adding New Commands](#adding-new-commands)
6. [Adding New Screens](#adding-new-screens)
7. [Adding New Domains](#adding-new-domains)
8. [Error Handling](#error-handling)
9. [Gleam Patterns Used](#gleam-patterns-used)

## Architecture Overview

The CLI uses a **dual-mode architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Meal Planner CLI                         │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴────────────┐
         │                        │
    ┌────▼──────┐         ┌──────▼────┐
    │ Glint      │         │ Shore      │
    │ (Commands) │         │ (TUI)      │
    └────┬──────┘         └──────┬────┘
         │                       │
         │   ┌───────────────────┘
         │   │
    ┌────▼───▼──────────────────────┐
    │   Configuration + Services     │
    │   (FatSecret, Tandoor, etc.)   │
    └─────────────────────────────────┘
```

### Two Modes Explained

**Mode 1: Command-Line (Glint)**
- Direct command execution
- Used for scripting and automation
- Example: `gleam run -- fatsecret foods search --query "apple"`
- Powers: automation, CI/CD, batch operations

**Mode 2: Interactive TUI (Shore)**
- Full terminal user interface
- Menu-driven navigation
- Used for interactive exploration
- Example: `gleam run` (launches full TUI)
- Powers: exploratory analysis, data entry, browsing

Both modes share:
- Same underlying services and APIs
- Identical business logic
- Configuration system
- Error handling strategies

## Core Components

### 1. CLI Module Structure

```
src/meal_planner/cli/
├── types.gleam          # Type definitions for CLI
├── model.gleam          # Model initialization and state management
├── update.gleam         # Message handlers (Elm-style update function)
├── view.gleam           # View rendering (screen-specific output)
├── commands.gleam       # Shore async commands (for API calls)
├── formatters.gleam     # Output formatting (JSON, table, CSV)
├── glint_commands.gleam # Glint command handlers (CLI mode)
└── shore_app.gleam      # Shore application wiring
```

### 2. Type System

**Model** - Application state:

```gleam
pub type Model {
  Model(
    config: Config,              // App configuration
    current_screen: Screen,      // Active screen (MainMenu, FoodSearch, etc.)
    navigation_stack: List(Screen), // History for "back" button
    selected_domain: Option(Domain), // Currently selected domain
    search_query: String,        // User search input
    results: Option(Results),    // Search/API results
    loading: Bool,              // Loading indicator
    error: Option(String),      // Error message, if any
    pagination_offset: Int,     // Pagination state
    pagination_limit: Int,      // Results per page
  )
}
```

**Screens** - UI destinations:

```gleam
pub type Screen {
  MainMenu
  DomainMenu(Domain)    // FatSecret, Tandoor, Database, etc.
  FoodSearch
  DiaryView
  ExerciseView
  FavoritesView
  // ... 12+ more screens
}
```

**Domains** - API/Module groups:

```gleam
pub type Domain {
  FatSecretDomain     // Food, exercise, diary
  TandoorDomain       // Recipes
  DatabaseDomain      // USDA foods
  MealPlanningDomain  // Weekly plans
  NutritionDomain     // Analysis, trends
  SchedulerDomain     // Scheduled tasks
}
```

**Messages** - User interactions:

```gleam
pub type Msg {
  // Navigation
  SelectDomain(Domain)
  SelectScreen(Screen)
  GoBack
  Quit

  // Input
  UpdateSearchQuery(String)
  ClearInput

  // Async results
  SearchFoods
  GotSearchResults(Result(List(Food), String))

  // System
  KeyPress(String)
  NoOp
}
```

### 3. Shore TUI Framework

Shore implements the **Elm Architecture**:

```gleam
// Initialization
model.init(config) → Model

// Update - Pure function that processes messages
update(model, msg) → #(Model, Command(Msg))

// View - Renders current model state
view(model) → Element(Msg)

// Command - Async side effects (API calls)
commands.search_foods(query, callback) → Command(Msg)
```

This ensures:
- **Separation of concerns**: Pure state management, rendering, side effects
- **Testability**: Model and update logic can be tested without UI
- **Composability**: Commands can be chained and combined
- **Referential transparency**: Pure functions throughout

### 4. Glint Command System

Glint provides CLI argument parsing and command routing:

```gleam
pub fn run(config: Config, args: List(String)) -> Nil {
  let app = glint.new()
  |> add_fatsecret_commands(config)
  |> glint.default(unknown_command_handler)

  glint.run(app, args)
}
```

Commands are registered as:

```gleam
glint.add(
  ["fatsecret", "foods", "search"],  // Command path
  glint.command(handler)              // Handler function
  |> glint.description("Search foods")
  |> glint.flag("query", glint.string_flag())
)
```

## Design Patterns

### 1. Elm Architecture (Model-Update-View)

All state changes flow through a single update function:

```
User Input/Event → Message → Update Function → New Model → View Render
```

Benefits:
- **Predictable state**: All state transitions are visible
- **Time-travel debugging**: Can replay message sequences
- **Concurrent safety**: No race conditions (single update function)

### 2. Railway-Oriented Programming

Error handling using Result types:

```gleam
case api_call() {
  Ok(data) -> handle_success(data)
  Error(err) -> handle_error(err)
}

// Chaining operations
result.try(api1(), fn(data) {
  api2(data)
})
```

No exceptions or panics - all errors are values.

### 3. Command Pattern (Async Operations)

Side effects are represented as commands:

```gleam
pub fn search_foods(query: String, callback: fn(Result) -> Msg) -> shore.Command(Msg) {
  shore.command(fn() {
    foods_service.search(query)
    |> callback  // Result wrapped as Message
  })
}
```

Async operations don't block the UI, results are handled via messages.

### 4. Dependency Injection

Services are injected through the Config object:

```gleam
let model = Model(
  config: config,  // Contains all API clients and settings
  // ...
)

// In commands:
commands.search_foods(model.config.fatsecret_client, query, callback)
```

Makes testing easy - provide mock services in tests.

### 5. Opaque Types for Domain Models

Hide implementation details:

```gleam
pub opaque type Food {
  Food(id: String, name: String, calories: Float)
}

pub fn new(id: String, name: String, calories: Float) -> Result(Food, Nil) {
  // Validation
  Ok(Food(id, name, calories))
}

pub fn name(food: Food) -> String {
  food.name
}
```

Enforces valid states - can't construct Food without validation.

## Message Flow

### Interactive Mode (Shore TUI)

Complete flow for searching foods:

```
1. User presses "/" in FoodSearch screen
   └─> KeyPress("/") Message → View shows search prompt

2. User types "apple" and presses Enter
   └─> UpdateSearchQuery("apple") Message
   └─> KeyPress("Enter") Message → triggers SearchFoods

3. Update handler processes SearchFoods
   └─> Calls model.set_loading(model, True)
   └─> Returns Command: commands.search_foods(query, GotSearchResults)

4. Command executes async (doesn't block UI)
   └─> Calls foods_service.search("apple")
   └─> API request sent
   └─> Response received → Results wrapped as Message

5. Update handler processes GotSearchResults
   └─> Case Ok(foods):
       └─> model.set_results(model, FoodResults(foods))
       └─> View re-renders with results
   └─> Case Error(err):
       └─> model.set_error(model, err)
       └─> View shows error screen

6. View renders results
   └─> Shows food list: "Apple", "Apple juice", "Apple sauce", ...
   └─> User can select item or search again
```

### Command Mode (Glint)

Direct command execution:

```
1. User runs:
   gleam run -- fatsecret foods search --query "apple"

2. Main entry point routes to glint.run()

3. Glint parses arguments:
   - domain: "fatsecret"
   - action: "foods"
   - sub_action: "search"
   - flag "query": "apple"

4. Glint invokes registered handler:
   fatsecret_foods_search_handler(input)

5. Handler extracts flags:
   query = glint.get_flag(input, "query") → "apple"

6. Handler calls service synchronously:
   foods_service.search("apple")
   └─> Returns Result(List(Food), Error)

7. Handler formats output:
   format_json(results) or format_table(results)

8. Output printed to stdout

9. Process exits with code 0 (success) or 1+ (error)
```

## Adding New Commands

### Step 1: Define Types

Add to `src/meal_planner/cli/types.gleam`:

```gleam
pub type Screen {
  // ... existing screens
  NewFeatureScreen      // Add new screen variant
}

pub type Msg {
  // ... existing messages
  NewFeatureAction      // Add new message variant
  GotNewFeatureResult(Result(Data, String))
}
```

### Step 2: Add Model Helpers

Add to `src/meal_planner/cli/model.gleam`:

```gleam
pub fn navigate_to_new_feature(model: Model) -> Model {
  Model(
    ..model,
    current_screen: NewFeatureScreen,
    navigation_stack: [model.current_screen, ..model.navigation_stack],
  )
}
```

### Step 3: Add Update Handler

Add to `src/meal_planner/cli/update.gleam`:

```gleam
types.NewFeatureAction -> {
  let updated_model = model.set_loading(model, True)
  let cmd = commands.fetch_new_feature_data(callback)
  #(updated_model, cmd)
}

types.GotNewFeatureResult(Ok(data)) -> {
  let results = types.TextResults(format_data(data))
  let updated_model = model.set_results(model, results)
  #(updated_model, shore.none())
}

types.GotNewFeatureResult(Error(err)) -> {
  let updated_model = model.set_error(model, err)
  #(updated_model, shore.none())
}
```

### Step 4: Add Command Handler

Add to `src/meal_planner/cli/commands.gleam`:

```gleam
pub fn fetch_new_feature_data(
  on_result: fn(Result(Data, String)) -> Msg,
) -> shore.Command(Msg) {
  shore.command(fn() {
    // Call your service
    new_feature_service.fetch()
    |> on_result
  })
}
```

### Step 5: Add View

Add to `src/meal_planner/cli/view.gleam`:

```gleam
Screen.NewFeatureScreen -> view_new_feature(model)

fn view_new_feature(model: Model) -> shore.Element(Msg) {
  shore.column([
    shore.text("New Feature"),
    case model.results {
      option.Some(results) -> render_results(results)
      option.None -> shore.text("No data")
    }
  ])
  |> shore.element
}
```

### Step 6: Add Glint Command (for CLI mode)

Add to `src/meal_planner/cli/glint_commands.gleam`:

```gleam
fn add_new_feature_commands(
  app: glint.App(Nil),
  config: Config,
) -> glint.App(Nil) {
  app
  |> glint.add(
    ["domain", "action"],
    glint.command(new_feature_handler(config))
    |> glint.description("Do something new")
    |> glint.flag("option", glint.string_flag() |> glint.help("Option description")),
  )
}

fn new_feature_handler(config: Config) -> fn(glint.CommandInput) -> Nil {
  fn(input: glint.CommandInput) -> Nil {
    case glint.get_flag(input, "option") {
      Ok(option) -> {
        let result = new_feature_service.do_something(option)
        io.println(format_output(result))
      }
      Error(_) -> io.println("Error: --option flag is required")
    }
  }
}
```

## Adding New Screens

Screens are UI destinations in the TUI. To add a new screen:

### 1. Add Screen Variant

```gleam
// types.gleam
pub type Screen {
  MyNewScreen
  MyNewScreen(SomeData)  // If you need to pass data
}
```

### 2. Add Navigation Message

```gleam
// types.gleam
pub type Msg {
  NavigateToMyScreen
  ScreenAction(ScreenMsg)
}
```

### 3. Handle in Update

```gleam
// update.gleam
types.NavigateToMyScreen -> {
  let updated = model.navigate_to(model, Screen.MyNewScreen)
  #(updated, shore.none())
}
```

### 4. Add View

```gleam
// view.gleam
Screen.MyNewScreen -> view_my_new_screen(model)

fn view_my_new_screen(model: Model) -> shore.Element(Msg) {
  // Render your screen
  shore.text("My New Screen")
  |> shore.element
}
```

## Adding New Domains

Domains group related API operations (FatSecret, Tandoor, Database, etc.).

### 1. Add Domain Type

```gleam
// types.gleam
pub type Domain {
  MyNewDomain
}
```

### 2. Add Domain Menu Handler

```gleam
// view.gleam
fn view_domain_menu(model: Model, domain: Domain) -> shore.Element(Msg) {
  case domain {
    Domain.MyNewDomain -> view_my_domain_menu(model)
    // ...
  }
}

fn view_my_domain_menu(_model: Model) -> shore.Element(Msg) {
  shore.column([
    shore.text("My Domain Menu"),
    shore.text("1. Option 1"),
    shore.text("2. Option 2"),
  ])
  |> shore.element
}
```

### 3. Add Domain Navigation

```gleam
// update.gleam
types.SelectDomain(Domain.MyNewDomain) -> {
  let updated = model.select_domain(model, Domain.MyNewDomain)
  #(updated, shore.none())
}
```

### 4. Create Service Module

```gleam
// src/meal_planner/my_domain/service.gleam
pub fn fetch_data(id: String) -> Result(Data, String) {
  // Implement API call or database query
  Ok(data)
}
```

### 5. Add Glint Commands

```gleam
// glint_commands.gleam
fn add_my_domain_commands(app: glint.App(Nil), config: Config) -> glint.App(Nil) {
  app
  |> glint.add(
    ["my_domain", "action"],
    glint.command(my_domain_handler(config)),
  )
}
```

## Error Handling

### 1. Result Types (Preferred)

```gleam
// Explicit error handling
case service.call() {
  Ok(data) -> render_success(data)
  Error(error) -> render_error(error)
}
```

### 2. Option Types

```gleam
// For values that may or may not exist
case optional_value {
  option.Some(value) -> process(value)
  option.None -> show_placeholder()
}
```

### 3. Error Messages in Model

```gleam
// Store error state in model
pub fn set_error(model: Model, message: String) -> Model {
  Model(..model, error: option.Some(message), loading: False)
}

// Display in view
case model.error {
  option.Some(err) -> view_error(err)
  option.None -> view_normal_content()
}
```

### 4. Error Recovery

```gleam
// Retry logic
case attempt_1() {
  Ok(data) -> Ok(data)
  Error(_) -> attempt_2()
}
```

## Gleam Patterns Used

### 1. Immutable Data Structures

All data is immutable - no mutations, only transformations:

```gleam
// Create new model, don't mutate
let updated_model = Model(
  ..model,
  search_query: new_query,
  error: option.None,
)
```

### 2. Pattern Matching

Exhaustive pattern matching replaces conditionals:

```gleam
case msg {
  Msg.SearchFoods -> handle_search()
  Msg.GoBack -> handle_back()
  Msg.Quit -> handle_quit()
}
```

### 3. Pipelines

Data flows through pipes (`|>`):

```gleam
query
|> string.trim()
|> string.lowercase()
|> foods_service.search()
|> result.map(format_results)
```

### 4. Higher-Order Functions

Callbacks passed as functions:

```gleam
pub fn search_foods(
  query: String,
  on_result: fn(Result(Data, Error)) -> Msg,
) -> Command(Msg) {
  // ...
}

// Called with a callback
commands.search_foods(query, GotResults)
```

### 5. Option and Result Chaining

```gleam
// Chaining multiple Result operations
result.try(api.call1(), fn(data1) {
  api.call2(data1)
})

// Chaining multiple Option operations
option.then(optional_value, fn(val) {
  option.Some(process(val))
})
```

## Testing CLI Components

### Unit Testing Update Logic

```gleam
#[test]
fn test_update_search_query() {
  let model = model.init(test_config)
  let updated = model.update_search_query(model, "apple")

  assert updated.search_query == "apple"
  assert updated.error == option.None
}
```

### Testing Commands

```gleam
#[test]
fn test_search_foods_command() {
  let cmd = commands.search_foods("apple", GotSearchResults)

  // Execute and verify callback is called
  // (requires mock service)
}
```

### Testing Views

```gleam
#[test]
fn test_main_menu_view() {
  let model = model.init(test_config)
  let view = view.view(model)

  // Verify rendered elements
}
```

## Performance Considerations

1. **Lazy Rendering**: Views are only re-rendered when model changes
2. **Async Commands**: Long operations (API calls) don't block UI
3. **Efficient State**: Only necessary state stored in model
4. **List Operations**: Use tail-recursive functions for lists
5. **Memoization**: Cache expensive computations in model if needed

## Extending the Architecture

### Adding a New Output Format

1. Add formatter function:

```gleam
// formatters.gleam
pub fn format_csv(results: Results) -> String {
  // CSV serialization
}
```

2. Update view or command handlers to use it

### Adding New Async Operations

1. Create command function in `commands.gleam`:

```gleam
pub fn long_operation(on_result) -> shore.Command(Msg) {
  shore.command(fn() {
    expensive_computation()
    |> on_result
  })
}
```

2. Wire up message in update handler

### Adding Persistence

1. Store model state to file/database
2. Load on initialization
3. Save after each model update

This keeps the architecture intact while adding persistence.

## Related Documentation

- [CLI.md](CLI.md) - User-facing CLI documentation
- [COMMANDS.md](COMMANDS.md) - Command reference
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development setup
- [GLEAM_PATTERNS.md](../docs/GLEAM_PATTERNS.md) - Gleam idioms and patterns
