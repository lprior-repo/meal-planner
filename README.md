# Meal Planner

A Gleam application for meal planning based on the Vertical Diet principles. Features include recipe management, FODMAP analysis, weekly meal plan generation, macro tracking, and a Nutrition Control Plane (NCP) for reconciling dietary goals.

## Features

- **Recipe Management**: Load recipes from YAML files, store in SQLite, query by category
- **FODMAP Analysis**: Analyze recipes for FODMAP content with exception handling (garlic-infused oil, etc.)
- **Weekly Meal Planning**: Generate weekly meal plans based on user profile and macro targets
- **Macro Calculations**: Calculate daily protein, fat, carb targets based on bodyweight, activity level, and goals
- **Portion Sizing**: Automatically calculate portion sizes to meet macro targets
- **Shopping List Generation**: Generate categorized shopping lists from meal plans
- **Nutrition Control Plane (NCP)**: Track nutrition state, set goals, reconcile deviations
- **Recipe Validation**: Validate recipes against Vertical Diet rules (no seed oils, proper grains)
- **User Profiles**: Persist user profiles with activity level, goals, and meal preferences

## Prerequisites

- **Erlang/OTP**: Version 26 or later
- **Gleam**: Version 1.5.1 or later
- **Git**: For version control

## Installation

1. **Clone the Repository**

```bash
git clone https://github.com/lprior-repo/meal-planner
cd meal-planner/gleam
```

2. **Install dependencies**
```bash
gleam deps download
```

3. **Build the project**
```bash
gleam build
```

4. **Run tests**
```bash
gleam test
```

## Usage

Run the CLI application:

```bash
gleam run
```

Available commands:
- `plan` - Generate a weekly meal plan
- `ncp status` - Show NCP status
- `ncp reconcile` - Reconcile nutrition state with goals
- `ncp goals` - Show nutrition goals
- `ncp recipes` - Suggest recipes based on current deviation

## Testing

The project has comprehensive test coverage (279+ tests):

```bash
# Run all tests
gleam test

# Run specific test files
gleam test --module fodmap_test
gleam test --module ncp_test
```

### Test Categories

- **Unit Tests**: Types, macros, FODMAP analysis, validation
- **Integration Tests**: Storage, migrations, recipe loading
- **NCP Tests**: Scoring, deviation calculation, reconciliation

## Project Structure

```
gleam/
├── src/
│   └── meal_planner/
│       ├── application.gleam   # OTP application lifecycle
│       ├── supervisor.gleam    # Supervision tree
│       ├── state.gleam         # GenServer for runtime state
│       ├── types.gleam         # Core types (Recipe, Macros, UserProfile)
│       ├── fodmap.gleam        # FODMAP analysis
│       ├── validation.gleam    # Recipe validation
│       ├── meal_plan.gleam     # Meal plan generation
│       ├── weekly_plan.gleam   # Weekly planning
│       ├── meal_selection.gleam # Meal selection logic
│       ├── portion.gleam       # Portion calculations
│       ├── shopping_list.gleam # Shopping list generation
│       ├── output.gleam        # Output formatting
│       ├── ncp.gleam           # Nutrition Control Plane
│       ├── storage.gleam       # SQLite persistence
│       ├── migrate.gleam       # Database migrations
│       └── recipe_loader.gleam # YAML recipe loading
├── test/
│   └── *.gleam                 # Test files
└── gleam.toml                  # Project configuration
```

## Architecture

The application follows functional programming principles with immutable data structures. Key design decisions:

- **OTP Supervision**: Application starts with OTP supervisor tree for fault tolerance
- **GenServer State**: Runtime state (user profile, goals) cached in GenServer
- **Pure Functions**: Core logic is pure, side effects isolated to storage/IO modules
- **Type Safety**: Gleam's type system prevents runtime errors
- **Pattern Matching**: Extensive use of pattern matching for control flow
- **Result Types**: Errors handled with Result types, no exceptions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests first (TDD)
4. Implement your changes
5. Ensure all tests pass: `gleam test`
6. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Legacy Go Code

The original Go implementation has been archived in `_archive/go/`. The project has been fully migrated to Gleam.
