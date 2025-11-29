# Meal Planner - Gleam/BEAM Port

This directory contains the Gleam port of the Go meal planner application.

## Directory Structure

```
gleam/
├── gleam.toml              # Project config and dependencies
├── manifest.toml           # Lock file (auto-generated)
├── src/
│   ├── meal_planner.gleam  # Main entry point
│   │
│   ├── types/              # Core domain types
│   │   ├── macros.gleam    # Macros type (protein, fat, carbs, calories)
│   │   ├── ingredient.gleam # Ingredient type
│   │   ├── recipe.gleam    # Recipe type
│   │   └── user_profile.gleam # UserProfile type
│   │
│   ├── ncp/                # Nutritional Control Plane
│   │   ├── types.gleam     # NutritionData, NutritionState, NutritionGoals
│   │   ├── deviation.gleam # Deviation calculation
│   │   ├── scoring.gleam   # Recipe scoring for deviation
│   │   ├── adjustment.gleam # Adjustment plan generation
│   │   ├── reconcile.gleam # Reconciliation engine
│   │   ├── history.gleam   # Nutrition history averaging
│   │   └── cli.gleam       # Status/reconcile output formatting
│   │
│   ├── db/                 # Database layer
│   │   ├── database.gleam  # Database behavior/trait
│   │   ├── sqlite.gleam    # SQLite implementation
│   │   ├── nutrition.gleam # Nutrition state persistence
│   │   ├── profile.gleam   # User profile persistence
│   │   └── recipe.gleam    # Recipe storage/lookup
│   │
│   ├── io/                 # External I/O
│   │   ├── yaml.gleam      # YAML recipe loading
│   │   ├── email.gleam     # Email formatting
│   │   ├── mailtrap.gleam  # Mailtrap HTTP client
│   │   └── env.gleam       # Environment variable loading
│   │
│   ├── core/               # Business logic
│   │   ├── filter.gleam    # Recipe filtering
│   │   ├── shuffle.gleam   # Recipe shuffling/selection
│   │   ├── pairing.gleam   # Side dish pairing
│   │   ├── plan.gleam      # Weekly meal plan generation
│   │   └── macros.gleam    # Macro calculation
│   │
│   └── app/                # OTP application
│       ├── supervisor.gleam # Supervisor tree
│       ├── state.gleam     # GenServer for state management
│       └── errors.gleam    # Error handling patterns
│
├── test/
│   ├── types/              # Type tests
│   │   ├── macros_test.gleam
│   │   ├── ingredient_test.gleam
│   │   └── recipe_test.gleam
│   │
│   ├── ncp/                # NCP tests
│   │   ├── deviation_test.gleam
│   │   ├── scoring_test.gleam
│   │   ├── adjustment_test.gleam
│   │   └── reconcile_test.gleam
│   │
│   ├── db/                 # Database tests
│   │   └── sqlite_test.gleam
│   │
│   ├── core/               # Core logic tests
│   │   ├── filter_test.gleam
│   │   ├── shuffle_test.gleam
│   │   └── plan_test.gleam
│   │
│   └── integration/        # Integration tests
│       └── full_flow_test.gleam
│
├── recipes/                # Recipe YAML files (symlink to ../recipes)
│
└── build/                  # Build artifacts (auto-generated)
```

## Module Mapping: Go → Gleam

| Go File | Gleam Module |
|---------|--------------|
| `main.go` | `src/meal_planner.gleam` |
| `database.go` | `src/db/database.gleam` |
| `badger_db.go` | `src/db/sqlite.gleam` |
| `init.go` | `src/io/yaml.gleam` |
| `ncp/state.go` | `src/ncp/types.gleam` |
| `ncp/goals.go` | `src/ncp/types.gleam` |
| `ncp/scoring.go` | `src/ncp/scoring.gleam` |
| `ncp/adjustment.go` | `src/ncp/adjustment.gleam` |
| `ncp/reconcile.go` | `src/ncp/reconcile.gleam` |
| `ncp/reconciler.go` | `src/ncp/reconcile.gleam` |
| `ncp/history.go` | `src/ncp/history.gleam` |
| `ncp/cli.go` | `src/ncp/cli.gleam` |
| `ncp/storage.go` | `src/db/nutrition.gleam` |
| `ncp/generate.go` | `src/ncp/adjustment.gleam` |
| `ncp/result.go` | `src/ncp/types.gleam` |

## Build Commands

```bash
# Install dependencies
gleam deps download

# Build
gleam build

# Test
gleam test

# Run
gleam run

# Format
gleam format
```

## Architecture Notes

### OTP Application Structure
- Main supervisor starts database and state GenServers
- Database GenServer wraps SQLite connection
- State GenServer holds nutrition/profile state
- CLI commands are synchronous handlers

### Error Handling
- Use `Result(T, Error)` throughout
- Custom error types per module
- Pattern match on errors, don't panic

### Testing
- Unit tests with gleeunit
- Property tests with qcheck (future)
- Integration tests use in-memory SQLite
