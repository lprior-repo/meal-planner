# Meal Planner CLI Development Guide

This guide covers local development setup, building, testing, and contributing to the Meal Planner CLI.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Development Workflow](#development-workflow)
4. [Building](#building)
5. [Testing](#testing)
6. [Code Style and Formatting](#code-style-and-formatting)
7. [Debugging](#debugging)
8. [Common Development Tasks](#common-development-tasks)
9. [Contributing Guidelines](#contributing-guidelines)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Erlang/OTP**: 28 or later
  ```bash
  # Check version
  erl -version

  # Install (macOS with Homebrew)
  brew install erlang@28

  # Install (Ubuntu/Debian)
  sudo apt-get install erlang-base erlang-dev
  ```

- **Gleam**: 1.4.0 or later
  ```bash
  # Check version
  gleam --version

  # Install (see https://gleam.run/getting-started/)
  # macOS: brew install gleam
  # Or universal installer: curl https://get.gleam.run | sh
  ```

- **PostgreSQL**: 14 or later
  ```bash
  # Check version
  psql --version

  # Install (macOS)
  brew install postgresql@14

  # Install (Ubuntu/Debian)
  sudo apt-get install postgresql-14
  ```

- **Git**: 2.30 or later
  ```bash
  git --version
  ```

### Optional Tools

- **Just**: Command runner (alternative to Make)
  ```bash
  brew install just  # macOS
  sudo apt-get install just  # Ubuntu
  ```

- **Docker**: For isolated PostgreSQL
  ```bash
  docker --version
  ```

- **Make**: For running make targets
  ```bash
  make --version
  ```

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/lprior-repo/meal-planner
cd meal-planner
```

### 2. Install Dependencies

```bash
# Download Gleam dependencies
gleam deps download

# Verify installation
gleam --version
```

### 3. Setup PostgreSQL Database

#### Option A: Local PostgreSQL

```bash
# Create databases
createdb meal_planner
createdb meal_planner_test

# Run schema migrations (in order)
psql -d meal_planner -f schema/001_schema_migrations.sql
psql -d meal_planner -f schema/002_usda_tables.sql
psql -d meal_planner -f schema/003_app_tables.sql
psql -d meal_planner -f schema/005_add_micronutrients_to_food_logs.sql
psql -d meal_planner -f schema/006_add_source_tracking.sql
psql -d meal_planner -f schema/009_auto_meal_planner.sql
psql -d meal_planner -f schema/010_optimize_search_performance.sql

# Create test database
psql -d meal_planner_test -f schema/001_schema_migrations.sql
```

#### Option B: Docker PostgreSQL

```bash
# Start PostgreSQL container
docker run -d \
  --name meal-planner-db \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:14-alpine

# Wait for container to be ready
sleep 5

# Create databases and run migrations
docker exec meal-planner-db createdb -U postgres meal_planner
docker exec meal-planner-db psql -U postgres -d meal_planner -f /schema/001_schema_migrations.sql
```

### 4. Setup Environment Variables

```bash
# Copy example configuration
cp .env.example .env

# Edit with your settings
# Minimum required:
# DATABASE_HOST=localhost
# DATABASE_PORT=5432
# DATABASE_NAME=meal_planner
# DATABASE_USER=postgres
# DATABASE_PASSWORD=password
# SERVER_PORT=3000
# SERVER_ENV=development

nano .env  # or your preferred editor
```

### 5. Verify Setup

```bash
# Test database connection
psql -h localhost -U postgres -d meal_planner -c "SELECT 1"

# Build project
gleam build

# Run tests
gleam test
```

## Development Workflow

### Standard Development Loop

```bash
# 1. Create a feature branch
git checkout -b feature/my-feature

# 2. Make changes to source files
nano src/meal_planner/cli/types.gleam

# 3. Format code
gleam format

# 4. Run tests
make test

# 5. Build project
gleam build

# 6. Test CLI manually
gleam run -- --help

# 7. Commit changes
git add .
git commit -m "Add my feature"

# 8. Push and create PR
git push origin feature/my-feature
```

### Using TDD (Test-Driven Development)

This project follows strict TCR (Test-Commit-Revert) discipline:

```bash
# 1. Write failing test first
# Edit: test/meal_planner/cli/my_feature_test.gleam
# Add: #[test] fn test_my_feature() { ... }

# 2. Run test to confirm it fails
gleam test

# 3. Write minimal implementation to pass test
# Edit: src/meal_planner/cli/my_feature.gleam

# 4. Run test again
gleam test

# 5. If fails: revert both files, try different approach
git reset --hard

# 6. If passes: refactor for cleaner code
# No behavior change, just style improvements

# 7. Format and commit
gleam format
git add .
git commit -m "GREEN: Implement my feature"
```

## Building

### Quick Build

```bash
# Build to build/ directory
gleam build

# Verify compilation
ls -la build/
```

### Full Build with Dependencies

```bash
# Clean previous build
rm -rf build

# Download fresh dependencies
gleam deps download

# Build with all dependencies
gleam build

# Check for errors
echo $?  # Exit code 0 = success
```

### Build for Production

```bash
# Set production environment
export SERVER_ENV=production

# Build with optimizations
gleam build

# Verify binary size
du -h build/
```

## Testing

### Run All Tests

```bash
# Fast tests only (parallel, 0.8s)
make test

# Equivalent:
gleam run -m test_runner/fast
```

### Run Specific Test

```bash
# Run single test file
gleam test --module test_runner/fast

# Run with filter
gleam test -- --exact="test_update_search_query"
```

### Run Integration Tests

```bash
# All tests including slow integration tests
make test-all

# Equivalent:
gleam test
```

### Property-Based Testing

```bash
# Run qcheck property generators (100 iterations each)
make test-properties

# Equivalent:
gleam run -m test_runner/properties
```

### Test Coverage

```bash
# View test files
find test/ -name "*_test.gleam" | wc -l

# Example: 45 test files

# Check specific test file
cat test/meal_planner/cli/types_test.gleam
```

### Creating Tests

```gleam
// test/meal_planner/cli/my_feature_test.gleam
import gleeunit
import gleeunit/should
import meal_planner/cli/model
import meal_planner/config

pub fn run() {
  gleeunit.main()
}

pub fn test_my_feature() {
  let cfg = config.test_config()
  let model = model.init(cfg)

  assert model.search_query == ""
  should.equal(model.loading, False)
}
```

## Code Style and Formatting

### Automatic Formatting

```bash
# Format all files
gleam format

# Check formatting without changing
gleam format --check

# Format specific file
gleam format src/meal_planner/cli/types.gleam
```

### Gleam Code Style Rules

The project follows strict Gleam idioms (see [GLEAM_PATTERNS.md](../docs/GLEAM_PATTERNS.md)):

1. **Immutability**: No `var`, use recursion/folding
2. **No Nulls**: Use `Option(T)` or `Result(T, E)`
3. **Pipes**: Use `|>` for data transformations
4. **Exhaustive Matching**: Every `case` must cover all possibilities
5. **Labeled Arguments**: Functions with >2 args must use labels
6. **Type Safety**: Avoid `dynamic`, use custom types
7. **Format or Death**: `gleam format --check` must pass

### Pre-commit Hook

Setup automatic formatting before commits:

```bash
# Create git hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
gleam format --check
if [ $? -ne 0 ]; then
  echo "Code formatting check failed. Run: gleam format"
  exit 1
fi
EOF

# Make executable
chmod +x .git/hooks/pre-commit
```

## Debugging

### Enable Debug Logging

```bash
# Run with debug flag
gleam run -- --debug fatsecret foods search --query "apple"

# Set environment variable
export GLEAM_LOG_LEVEL=debug
gleam run
```

### Examine Model State

```gleam
// Print model state for debugging
pub fn debug_model(model: Model) -> String {
  "Model { "
  <> "screen: "
  <> string_of_screen(model.current_screen)
  <> ", error: "
  <> string_of_option(model.error)
  <> " }"
}

// Use in update function
types.SomeMessage -> {
  let _ = io.debug(debug_model(model))  // Print to console
  #(model, shore.none())
}
```

### Inspect Message Flow

```gleam
// In update function, print all messages
pub fn update(model: Model, msg: Msg) -> #(Model, shore.Command(Msg)) {
  let _ = case msg {
    types.SearchFoods -> io.println("→ SearchFoods message")
    types.GotSearchResults(_) -> io.println("→ GotSearchResults message")
    _ -> Nil
  }

  case msg {
    // ... rest of update logic
  }
}
```

### Test Specific Code Path

```bash
# Run single test with output
gleam test --module test_meal_planner/cli/update_test

# Capture output
gleam test 2>&1 | tee test_output.txt
```

### PostgreSQL Debugging

```bash
# Connect to database
psql -h localhost -U postgres -d meal_planner

# Check tables
\dt

# View table structure
\d food

# Run query
SELECT * FROM food LIMIT 5;

# Exit
\q
```

## Common Development Tasks

### Add a New CLI Command

See [CLI-ARCHITECTURE.md](CLI-ARCHITECTURE.md#adding-new-commands) for detailed guide.

Quick version:

1. Add message type to `types.gleam`
2. Add handler to `update.gleam`
3. Add view to `view.gleam`
4. Add command to `commands.gleam` (if async)
5. Add Glint handler to `glint_commands.gleam`
6. Add test in `test/meal_planner/cli/`
7. Run `make test` and `gleam format`

### Fix a Bug

```bash
# 1. Create bug fix branch
git checkout -b fix/issue-123

# 2. Write test that reproduces bug
# Edit: test/meal_planner/cli/bug_test.gleam
# Test should fail initially

gleam test

# 3. Fix the code
# Edit: src/meal_planner/cli/bug.gleam

# 4. Test should now pass
gleam test

# 5. Format and commit
gleam format
git add .
git commit -m "FIX: Issue 123 - description"

# 6. Push
git push origin fix/issue-123
```

### Update Dependencies

```bash
# Check for updates
gleam deps list

# Update specific dependency
# Edit: gleam.toml
# Change version constraint

# Download new version
gleam deps download

# Rebuild
gleam build

# Test
make test
```

### Add Database Migration

```bash
# 1. Create migration file
cat > schema/XXX_description.sql << 'EOF'
-- Description
ALTER TABLE table_name ADD COLUMN new_column TYPE;
EOF

# 2. Apply to local database
psql -d meal_planner -f schema/XXX_description.sql

# 3. Test with application
gleam run

# 4. Commit
git add schema/XXX_description.sql
git commit -m "DB: Add new_column to table_name"
```

## Contributing Guidelines

### Before Starting Work

1. Check issues and PRs to avoid duplication
2. Comment on issue you want to work on
3. Wait for approval before starting
4. Create feature branch from `main`

### Code Quality Standards

- Must pass `gleam format --check`
- Must pass all tests (`make test`)
- Must have tests for new functionality
- Must follow Gleam idioms (see GLEAM_PATTERNS.md)
- Comments for complex logic
- No TODO/FIXME comments (create issues instead)

### Commit Message Format

```
[TYPE]: [Description] - [Issue reference]

TYPES:
- GREEN: Test passes (implementation)
- BLUE: Refactoring (no behavior change)
- RED: Failing test
- REVERT: Undo previous commit
- CHORE: Build, dependencies, docs
- FIX: Bug fix
- FEAT: New feature
- TEST: Test additions
```

Examples:

```bash
git commit -m "GREEN: Implement food search via FatSecret API - #123"
git commit -m "BLUE: Extract pagination logic to module - #156"
git commit -m "FIX: Handle empty search query gracefully"
git commit -m "CHORE: Update dependencies"
```

### Pull Request Process

1. Fork repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Commit with proper messages
4. Push to your fork
5. Create PR with description:
   - What problem does this solve?
   - How does it solve it?
   - What testing was done?
   - Any breaking changes?

### PR Review Requirements

- At least 1 approval required
- All tests must pass
- Code must be formatted
- All conversations resolved

## Troubleshooting

### Compilation Errors

**Error: `Unknown type`**

```bash
# Check type is exported from module
grep "pub type MyType" src/meal_planner/cli/types.gleam

# If missing, add:
pub type MyType { ... }

# Rebuild
gleam build
```

**Error: `Cannot find module`**

```bash
# Verify import path matches file structure
# import meal_planner/cli/types  # imports src/meal_planner/cli/types.gleam

# Check file exists
ls src/meal_planner/cli/types.gleam

# Rebuild with clean
rm -rf build
gleam build
```

**Error: `Pattern does not cover all possibilities`**

```gleam
// Add missing case branch
case msg {
  Msg.SearchFoods -> handle_search()
  Msg.GoBack -> handle_back()
  Msg.Quit -> handle_quit()
  // Missing handler - add it:
  Msg.NoOp -> #(model, shore.none())
}
```

### Database Issues

**Error: `psql: could not translate host name`**

```bash
# PostgreSQL not running or wrong host
# Check if running
pg_isready

# Or verify configuration
echo $DATABASE_HOST
echo $DATABASE_PORT

# Start PostgreSQL if stopped
brew services start postgresql  # macOS
sudo systemctl start postgresql  # Linux
```

**Error: `FATAL: role "postgres" does not exist`**

```bash
# Re-initialize PostgreSQL
rm -rf /usr/local/var/postgres  # macOS
initdb /usr/local/var/postgres
brew services restart postgresql
```

### Test Failures

**Tests timeout**

```bash
# Run with longer timeout
gleam test --timeout 30000  # 30 seconds

# Or run specific fast tests
make test
```

**Test fails randomly (flaky)**

```bash
# Run test multiple times
for i in {1..10}; do gleam test; done

# If fails intermittently, likely concurrency issue
# Check test for shared state
# Add isolation between tests
```

### Performance Issues

**Build is slow**

```bash
# Use fast compilation
gleam build --no-codegen

# Check disk space
df -h

# Clean previous builds
rm -rf build gleam_packages

# Try parallel build
gleam build -j 4  # 4 jobs
```

**Tests are slow**

```bash
# Run fast tests only
make test

# Skip integration tests
make test

# Profile individual test
time gleam test --module test_meal_planner/cli/types_test
```

## See Also

- [CLI.md](CLI.md) - User CLI documentation
- [COMMANDS.md](COMMANDS.md) - Command reference
- [CLI-ARCHITECTURE.md](CLI-ARCHITECTURE.md) - Architecture details
- [GLEAM_PATTERNS.md](../docs/GLEAM_PATTERNS.md) - Gleam idioms
- [ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System architecture
