# Gleam Automation Framework

A comprehensive Gleam-based automation layer for the meal-planner project, providing type-safe bindings for FatSecret nutrition tracking and Tandoor recipe management APIs.

## Overview

The Gleam automation framework provides:

- **FatSecret Integration**: Complete OAuth 1.0a (2-legged and 3-legged) implementation for nutrition data
- **Tandoor Integration**: Type-safe API client for recipe management
- **Workflow Orchestration**: Composable workflow abstractions for complex operations
- **CLI Interface**: Command-line tools for meal planning and recipe management
- **Type Safety**: Leveraging Gleam's static type system to prevent runtime errors

## Project Structure

```
gleam/
├── src/
│   ├── meal_planner.gleam      # Main entry point
│   ├── cli.gleam               # Command-line interface
│   ├── fatsecret.gleam         # FatSecret API client
│   ├── tandoor.gleam           # Tandoor API client
│   └── workflow.gleam          # Workflow orchestration
├── tests/
│   ├── cli_test.gleam          # CLI tests
│   ├── fatsecret_test.gleam    # FatSecret API tests
│   ├── tandoor_test.gleam      # Tandoor API tests
│   └── workflow_test.gleam     # Workflow tests
├── gleam.toml                  # Project manifest
├── manifest.toml               # Dependency lock file
└── README.md                   # This file
```

## Core Modules

### `meal_planner.gleam`
Main entry point for the automation framework. Parses CLI arguments and routes commands to appropriate handlers.

### `cli.gleam`
Command-line interface with support for:
- Recipe listing and searching
- Recipe import from Tandoor
- Meal plan creation and management
- Grocery list generation

### `fatsecret.gleam`
FatSecret API client providing:
- OAuth 1.0a authentication (both 2-legged and 3-legged)
- Food search and retrieval
- Diary entry management
- Weight tracking
- Exercise logging
- Saved meal templates
- Recipe management

### `tandoor.gleam`
Tandoor recipe management API client providing:
- Recipe CRUD operations
- Ingredient management
- Recipe listing with pagination
- Connection testing

### `workflow.gleam`
Workflow orchestration engine supporting:
- Step-based workflow composition
- Error handling and recovery
- Common workflows (recipe import, meal planning, grocery list generation)
- Extensible execution model

## CLI Usage

```bash
# Build the Gleam project
gleam build

# Run CLI commands
gleam run -- recipe list
gleam run -- recipe search "pasta"
gleam run -- recipe import 123
gleam run -- meal-plan create 20088 20094
gleam run -- grocery-list generate
gleam run -- help
gleam run -- version
```

## Development

### Building

```bash
# Build the project
gleam build

# Run tests
gleam test

# Format code
gleam format src tests
```

### Integration with Moon

The Gleam project is integrated into the Moon CI/CD pipeline:

```bash
# Format and build
moon run :gleam-fmt
moon run :gleam-build

# Run tests
moon run :gleam-test

# Full CI pipeline (includes Gleam)
moon run :ci

# Quick checks (for pre-commit)
moon run :quick
```

### Git Hooks

Gleam formatting is checked in the pre-commit hook. To auto-format before committing:

```bash
gleam format src tests
git add .
git commit -m "format: auto-format Gleam code"
```

## Testing

The project includes comprehensive test coverage:

- **CLI Tests** (`cli_test.gleam`): Command parsing and execution
- **FatSecret Tests** (`fatsecret_test.gleam`): OAuth and API operations
- **Tandoor Tests** (`tandoor_test.gleam`): Recipe management
- **Workflow Tests** (`workflow_test.gleam`): Workflow composition and execution

Run tests with:

```bash
gleam test
moon run :gleam-test
```

## Automation Beads

The project uses **Beads** for task tracking. 50 automation tasks have been created to guide implementation:

### Core Implementation (Beads 001-025)
- FatSecret API integration (HTTP client, OAuth, all endpoints)
- Tandoor API integration (HTTP client, recipe and ingredient endpoints)

### Workflow & Utilities (Beads 026-037)
- Workflow execution engine with error recovery
- Common workflows (recipe import, meal planning, grocery lists)
- Supporting utilities (nutrition calc, dates, JSON, config, logging, error handling)

### Testing & Documentation (Beads 038-050)
- Comprehensive test suites for each module
- Documentation and examples
- Integration with Moon CI/CD
- Pre-commit hook setup
- CLI binary deployment

## Next Steps

1. **Implement HTTP Client**: Foundation for both FatSecret and Tandoor APIs
2. **Add OAuth Support**: Secure authentication for FatSecret
3. **Build API Bindings**: Implement all required endpoints
4. **Create Workflows**: Compose complex operations from API calls
5. **Comprehensive Testing**: Unit and integration tests
6. **Documentation**: Examples and usage guides
7. **Production Deployment**: Build CLI binary and integrate with Windmill

## Dependencies

- `gleam_stdlib >= 0.34.0` - Gleam standard library
- `gleam_http >= 4.0.0` - HTTP client library
- `gleeunit >= 1.0.0` - Testing framework (dev dependency)

## Motivation

This Gleam automation layer demonstrates:

- **Type Safety**: Static typing prevents entire classes of runtime errors
- **Functional Programming**: Pure functions and immutable data structures
- **Composability**: Small, focused modules that combine well
- **Production Quality**: Comprehensive testing and error handling
- **Maintainability**: Clear types and explicit data flow

It complements the existing Rust binaries by providing a higher-level automation interface while maintaining strong guarantees through type safety.

## References

- [Gleam Language Documentation](https://gleam.run/)
- [FatSecret API Documentation](https://platform.fatsecret.com/api/)
- [Tandoor API Documentation](https://docs.tandoor.dev/api/)
- [Moon CI/CD Documentation](https://moonrepo.dev/)
