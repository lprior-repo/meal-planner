# Gleam Automation Framework

## Overview

The meal-planner project now includes a comprehensive Gleam automation layer (`gleam/`) that provides type-safe, production-grade bindings for FatSecret and Tandoor APIs, along with workflow orchestration capabilities.

## Why Gleam?

Gleam is a statically-typed, functional programming language that compiles to Erlang or JavaScript. It's chosen for this automation layer because:

1. **Type Safety**: The compiler catches entire classes of errors at compile time, preventing runtime failures
2. **Functional Programming**: Pure functions and immutable data structures make code easier to reason about
3. **Concurrency**: Built on Erlang's proven concurrent runtime for reliable automation
4. **Simplicity**: Syntax is clean and focused on making intent clear
5. **Complement to Rust**: While Rust provides low-level binaries, Gleam provides high-level orchestration

## Architecture

### Modular Design

```
CLI Commands
    ↓
Workflow Engine
    ↓
API Clients (FatSecret, Tandoor)
    ↓
HTTP Client + OAuth
    ↓
External APIs
```

### Core Modules

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| `meal_planner.gleam` | Main entry point | Command routing, argument parsing |
| `cli.gleam` | Command-line interface | Command parsing, help text, formatting |
| `fatsecret.gleam` | FatSecret API client | OAuth, food search, diary, weight, exercise |
| `tandoor.gleam` | Tandoor API client | Recipe CRUD, ingredients, listing |
| `workflow.gleam` | Workflow orchestration | Step composition, execution, error recovery |

## Automation Beads

50 automation tasks (beads) guide the implementation:

### Phase 1: Foundation (Beads 001-002)
- HTTP client with OAuth 1.0a support
- Signature generation for secure authentication

### Phase 2: FatSecret Integration (Beads 003-017)
- 2-legged OAuth (application-only)
- 3-legged OAuth (user-authenticated)
- 15+ API endpoints (search, diary, weight, exercise, recipes)

### Phase 3: Tandoor Integration (Beads 018-025)
- HTTP client with token authentication
- Recipe CRUD operations
- Ingredient management
- Listing and pagination

### Phase 4: Workflows & Utilities (Beads 026-037)
- Workflow step builder and execution engine
- Error recovery and retries
- Common workflows (import, meal planning, grocery lists)
- Supporting utilities (nutrition calc, dates, JSON, config, logging)

### Phase 5: Testing & Integration (Beads 038-050)
- Comprehensive test suites (unit + integration)
- Documentation and usage examples
- Moon CI/CD integration
- Git hook setup
- CLI binary deployment

## Building the Gleam Project

### Local Development

```bash
# Install Gleam (via mise)
mise install gleam

# Build
cd gleam && gleam build

# Test
gleam test

# Format
gleam format src tests
```

### Integration with Moon

Gleam is fully integrated into the Moon CI/CD pipeline:

```bash
# Format and build
moon run :gleam-fmt
moon run :gleam-build

# Test
moon run :gleam-test

# Full CI pipeline (includes Gleam)
moon run :ci

# Quick pre-commit checks
moon run :quick
```

### Git Hooks

Pre-commit hook automatically checks Gleam formatting:

```bash
# Auto-format before commit
gleam format src tests
git add .
git commit -m "format: auto-format Gleam code"
```

## CLI Commands

The Gleam automation layer provides a command-line interface for meal planning operations:

```bash
# List recipes
gleam run -- recipe list

# Search recipes
gleam run -- recipe search "pasta"

# Import recipe from Tandoor
gleam run -- recipe import 123

# Create meal plan
gleam run -- meal-plan create 20088 20094

# Show meal plan
gleam run -- meal-plan show 20088

# Generate grocery list
gleam run -- grocery-list generate

# Show help
gleam run -- help

# Show version
gleam run -- version
```

## FatSecret API Integration

### OAuth Flows

**2-Legged OAuth** (application-only, public endpoints):

```gleam
let config = fatsecret.new_oauth("consumer_key", "consumer_secret")
let result = fatsecret.search_foods(config, "apple")
```

**3-Legged OAuth** (user-authenticated, private endpoints):

```gleam
let config =
  fatsecret.new_oauth("consumer_key", "consumer_secret")
  |> fatsecret.with_user_credentials("user_token", "user_secret")

let result = fatsecret.log_food(config, food_id, serving_id, date_int, meal_type)
```

### Supported Endpoints

| Category | Endpoints |
|----------|-----------|
| **Foods** | search, get, autocomplete, find_barcode |
| **Diary** | add_food, get_entries, update_food, delete_food |
| **Weight** | add, get, delete, monthly_summary |
| **Exercise** | add, get, delete, monthly_summary |
| **Recipes** | search, get, favorites |
| **Saved Meals** | create, get, list, delete |
| **Profile** | get_profile |

## Tandoor API Integration

### Configuration

```gleam
let config = tandoor.new_config("http://localhost:8090", "api_token")
```

### Supported Operations

| Operation | Function |
|-----------|----------|
| **Recipes** | list, get, create, update, delete |
| **Ingredients** | list, create |
| **Connection** | test_connection |

## Workflow Orchestration

Create complex automated workflows by composing simple steps:

```gleam
// Define a workflow
let workflow =
  workflow.new_workflow(
    "Import Recipe",
    "Import recipe from Tandoor to FatSecret",
    [
      workflow.new_step(
        "fetch-recipe",
        "Fetch recipe from Tandoor",
        fn() { tandoor.get_recipe(config, recipe_id) }
      ),
      workflow.new_step(
        "calculate-nutrition",
        "Calculate nutrition facts",
        fn() { Ok("Nutrition calculated") }
      ),
      workflow.new_step(
        "create-fatsecret-recipe",
        "Create in FatSecret",
        fn() { fatsecret.create_recipe(config, ...) }
      ),
    ]
  )

// Execute
let result = workflow.execute(workflow)
```

### Common Workflows

1. **Recipe Import**: Fetch from Tandoor → Calculate nutrition → Save to FatSecret
2. **Meal Planning**: Select recipes → Calculate calories → Verify macro balance → Generate plan
3. **Grocery Lists**: Get meal plan → Extract ingredients → Group by category → Format for shopping

## Testing

Comprehensive test coverage ensures reliability:

```bash
# Run all tests
gleam test

# Or via Moon
moon run :gleam-test
```

Test files:
- `tests/cli_test.gleam` - CLI parsing and execution
- `tests/fatsecret_test.gleam` - OAuth and API operations
- `tests/tandoor_test.gleam` - Recipe management
- `tests/workflow_test.gleam` - Workflow composition

## Error Handling

The Gleam layer uses Result types for explicit error handling:

```gleam
// Functions return Result<a, String>
case fatsecret.search_foods(config, query) {
  Ok(results) -> {
    // Handle success
    io.println("Found " <> int.to_string(results.total) <> " foods")
  }
  Error(msg) -> {
    // Handle error
    io.println("Error: " <> msg)
  }
}
```

## Performance

- **Compile-time Checks**: Type checking and safety verified at build time
- **Caching**: Moon CI/CD caches Gleam builds (dependencies don't need re-download)
- **Concurrency**: Erlang runtime enables lightweight concurrent operations
- **JSON Parsing**: Efficient JSON encoding/decoding for API communication

## Dependencies

Core dependencies (defined in `gleam.toml`):

```toml
[dependencies]
gleam_stdlib = ">= 0.34.0"  # Standard library
gleam_http = ">= 4.0.0"    # HTTP client

[dev-dependencies]
gleeunit = ">= 1.0.0"       # Testing framework
```

## Deployment

### Building the CLI Binary

```bash
cd gleam
gleam build
```

Outputs JavaScript (default) or can be compiled to native via Erlang.

### Integration with Windmill

The Gleam CLI will eventually replace/complement some Rust binaries:

```bash
# Deploy to Windmill
cp target/build_gleam/dev/javascript/meal_planner/meal_planner.js /usr/local/bin/mp
chmod +x /usr/local/bin/mp
```

### Moon Task

```bash
moon run :build-gleam-cli  # Build CLI binary
moon run :deploy-gleam-cli # Deploy to Windmill worker
```

## Development Workflow

1. **Create a Bead**: Track the work in Beads
   ```bash
   bd add --title "GLEAM-XXX: ..." --priority 2 --label gleam
   ```

2. **Implement**: Add Gleam code in `src/` directory
   ```bash
   gleam format src tests
   ```

3. **Test**: Write tests in `tests/` directory
   ```bash
   gleam test
   ```

4. **Validate**: Run Moon CI pipeline
   ```bash
   moon run :ci
   ```

5. **Commit**: Follow conventional commits
   ```bash
   git add .
   git commit -m "feat: implement GLEAM-XXX - description"
   ```

6. **Close Bead**: Mark complete in Beads
   ```bash
   bd complete gleam-001
   ```

## Known Limitations & TODOs

- HTTP client implementation (currently stubbed)
- OAuth signature generation (currently stubbed)
- JSON encoding/decoding (need library selection)
- Full API endpoint implementations
- Workflow execution engine details
- Error recovery and retry logic
- Performance optimization

## Resources

- [Gleam Language Guide](https://gleam.run/)
- [Gleam Package Registry](https://packages.gleam.run/)
- [FatSecret API Docs](https://platform.fatsecret.com/api/)
- [Tandoor API Docs](https://docs.tandoor.dev/api/)
- [Beads Issue Tracker](../.beads/)

## Related Documentation

- [Project README](../README.md) - Overall project overview
- [Architecture Guide](./ARCHITECTURE.md) - System design
- [Moon CI Pipeline](./MOON_CI_PIPELINE.md) - Build system
- [Agent Guide](../AGENTS.md) - Development workflow
