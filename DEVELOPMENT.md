# Development Guide - Meal Planner

This guide covers local development setup, testing, and CI/CD workflows for the Meal Planner Gleam application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Setup](#local-setup)
3. [Make Commands](#make-commands)
4. [Testing](#testing)
5. [Code Formatting](#code-formatting)
6. [Pre-commit Hooks](#pre-commit-hooks)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- **Gleam** >= 1.4.0
  - Install: https://gleam.run/getting-started/
  - Verify: `gleam --version`

- **Erlang/OTP** >= 24
  - Install: `brew install erlang` (macOS) or `apt-get install erlang` (Linux)
  - Verify: `erl -eval 'erlang:halt()'`

- **Elixir** >= 1.14 (optional, for optional dependencies)
  - Install: `brew install elixir` (macOS)

- **PostgreSQL** >= 13
  - Install: `brew install postgresql` (macOS) or `apt-get install postgresql` (Linux)
  - Verify: `psql --version`

### Optional

- **Docker & Docker Compose** (for containerized Tandoor)
  - Install: https://docs.docker.com/get-docker/
  - Verify: `docker --version`

- **entr** (for watch mode)
  - Install: `brew install entr` (macOS) or `apt-get install entr` (Linux)

- **pre-commit** (for git hooks)
  - Install: `pip install pre-commit`

---

## Local Setup

### 1. Clone and Dependencies

```bash
git clone https://github.com/lprior-repo/meal-planner.git
cd meal-planner

# Download Gleam dependencies
gleam deps download
```

### 2. Environment Configuration

```bash
# Copy example to .env for local development
cp .env.example .env

# Edit .env with your configuration
# See .env.example for detailed instructions on each variable
```

### 3. Database Setup

```bash
# Create development database
createdb meal_planner

# Create test database
createdb meal_planner_test

# (Optional) Run migrations if available
# gleam run -m migration
```

### 4. Optional: Start Tandoor (Recipe API)

```bash
# Start Tandoor in Docker
docker-compose up -d tandoor

# Get API token from http://localhost:8000
# Settings > API Tokens > Create
# Copy token to TANDOOR_API_TOKEN in .env
```

### 5. Verify Installation

```bash
# Build the project
gleam build

# Run fast tests (should all pass)
make test

# Start the development server
make run
```

---

## Make Commands

Quick reference for common development tasks:

### Building

```bash
make build           # Build the project
make cli-build       # Clean build for CLI binary
make clean           # Remove all build artifacts
```

### Testing

```bash
make test            # Fast tests only (0.8s)
make test-all        # All tests including integration tests
make test-live       # Live FatSecret integration tests
make test-properties # Property-based tests only
make cli-test        # Run all CLI tests (fast + properties)
```

### Code Quality

```bash
make fmt             # Format all Gleam code
make check           # Check formatting without changing
make cli-format      # Format and validate code
make lint            # Lint check (format + build)
make dev-check       # Full development check (format + lint + test)
```

### Running

```bash
make run             # Start development server (port 8080)
make cli-run         # Run CLI application
make watch           # Watch mode with auto-test (requires entr)
```

### CI/CD

```bash
make ci-all          # Run complete CI pipeline
make pre-commit-run  # Run pre-commit checks manually
make pre-commit-install  # Install git pre-commit hooks
```

---

## Testing

### Test Structure

Tests are organized by module under `/test`:

```
test/
├── fatsecret/          # FatSecret API integration tests
│   ├── core/
│   ├── diary/
│   ├── exercise/
│   └── ...
├── tandoor/            # Tandoor API integration tests
├── meal_plan/          # Core meal planning logic tests
└── error_test.gleam    # Error handling tests
```

### Running Tests

```bash
# Fast tests (unit tests, ~0.8s)
make test

# All tests (includes integration tests, slower)
make test-all

# Specific test file
gleam test test/meal_plan/meal_plan_test.gleam

# Property-based tests
make test-properties

# With output
gleam test --verbose
```

### Test Patterns

#### Unit Tests

```gleam
import gleeunit
import gleeunit/should

pub fn example_test() {
  let result = some_function()
  result
  |> should.equal(expected_value)
}
```

#### Integration Tests

```gleam
pub fn integration_test() {
  use _ <- gleeunit.each_promise(list_of_test_cases)
  // Async test that returns Promise
  promise.Ok(Nil)
}
```

#### Property-Based Tests

```gleam
import qcheck

pub fn prop_test() {
  qcheck.run(100, fn() {
    let value = qcheck.int_range(0, 100)
    value >= 0 && value < 100
  })
}
```

### Fixtures

Test fixtures are stored in `test/fixtures/`:

```gleam
import simplifile
import json

pub fn load_fixture(filename: String) -> String {
  let assert Ok(content) = simplifile.read(
    "test/fixtures/" <> filename
  )
  content
}
```

---

## Code Formatting

### Automatic Formatting

Gleam has strict, automatic formatting via `gleam format`:

```bash
# Format all code
make fmt

# Check formatting without changing
make check

# Format specific directory
gleam format src/meal_planner
```

### Formatting Rules

- 2-space indentation
- Lines broken at 100 characters
- Imports sorted alphabetically
- Single trailing newline
- **No manual formatting** - the tool is authoritative

### CI Enforcement

The GitHub Actions pipeline enforces `gleam format --check`. All PRs must pass formatting checks.

---

## Pre-commit Hooks

Automatically run checks before each commit.

### Installation

```bash
# Option 1: Via Make
make pre-commit-install

# Option 2: Manual with pre-commit framework
pip install pre-commit
pre-commit install

# Option 3: Manual script
# Creates .git/hooks/pre-commit automatically via make
```

### What Runs

Each commit will run:

1. **Format Check** - `gleam format --check`
2. **Build Check** - `gleam build`
3. **Fast Tests** - `gleam run -m test_runner/fast`
4. **YAML/JSON Validation**
5. **Whitespace & Key Detection**

### Bypass Hooks (Emergency Only)

```bash
git commit --no-verify
```

### Manual Hook Run

```bash
make pre-commit-run
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

Defined in `.github/workflows/cli-test.yml`:

Triggers on:
- Push to `main` and `develop` branches
- Pull requests to `main` and `develop`

### Pipeline Stages

1. **Setup** (~10s)
   - Gleam 1.4.0
   - Erlang/OTP 27
   - PostgreSQL 15 test database

2. **Build** (~15s)
   - `gleam deps download`
   - `gleam build`

3. **Code Quality** (~5s)
   - `gleam format --check`
   - Type checking

4. **Tests** (~10s)
   - Unit tests
   - Property-based tests
   - CLI smoke tests

5. **Result**
   - Pass: Merge allowed
   - Fail: Requires fixes and re-push

### View Results

```bash
# Local (dry run)
make ci-all

# GitHub Actions
# Go to: https://github.com/lprior-repo/meal-planner/actions
```

### Pipeline Logs

```bash
# View GitHub Actions logs
# 1. Go to Actions tab
# 2. Select workflow run
# 3. Click "Details"
```

---

## Troubleshooting

### Build Fails

```bash
# Clean and rebuild
make cli-clean
make build

# Check Gleam version
gleam --version  # Should be >= 1.4.0

# Verify dependencies
gleam deps download
gleam deps list
```

### Tests Fail

```bash
# Run with verbose output
gleam test --verbose

# Run specific test
gleam test test/path/to/test_test.gleam --verbose

# Check database connection
psql meal_planner_test -c "SELECT 1"

# FatSecret integration test failures
# These skip gracefully if credentials missing
# Add credentials to .env to enable
```

### Formatting Issues

```bash
# Check what would change
gleam format --check

# Auto-fix
gleam format

# If still fails
gleam format --check src/
```

### Pre-commit Hook Issues

```bash
# Reinstall hooks
make pre-commit-install

# Check hook file
cat .git/hooks/pre-commit

# Run manually to debug
bash .git/hooks/pre-commit
```

### PostgreSQL Issues

```bash
# Test connection
psql -h localhost -U postgres -c "SELECT 1"

# Start PostgreSQL
brew services start postgresql  # macOS
sudo systemctl start postgresql  # Linux

# Create test database
createdb meal_planner_test
```

### Tandoor Connection Issues

```bash
# Check if Tandoor is running
curl http://localhost:8000/api/

# Restart Tandoor
docker-compose restart tandoor

# View logs
docker-compose logs -f tandoor
```

### Watch Mode Not Working

```bash
# Install entr
brew install entr  # macOS
apt-get install entr  # Linux

# Try again
make watch
```

---

## Development Workflow

### Daily Development

1. **Start of day**
   ```bash
   git pull origin main
   gleam deps download
   ```

2. **Make changes**
   ```bash
   # Edit src/ files
   # Write tests first (TDD)
   ```

3. **Test locally**
   ```bash
   make dev-check  # Runs format + lint + test
   ```

4. **Commit**
   ```bash
   git add .
   git commit -m "FEAT: your feature description"
   # Pre-commit hooks run automatically
   ```

5. **Push**
   ```bash
   git push origin feature-branch
   # GitHub Actions runs CI pipeline
   ```

### Feature Branch Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and test
make dev-check

# Commit with conventional message
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/my-feature

# GitHub Actions will validate
# Once approved, merge to main
```

---

## Performance Tips

### Faster Testing

```bash
# Use fast tests during development
make test  # 0.8s

# Only run integration tests when needed
make test-all  # 5-10s
```

### Faster Builds

```bash
# Gleam caches builds, but force clean if needed
make clean
make build

# Use watch mode to avoid rebuilding
make watch
```

### Faster Formatting

```bash
# Format just your changes
gleam format src/my_module.gleam

# Format directory
gleam format src/meal_planner
```

---

## Additional Resources

- **Gleam Documentation**: https://gleam.run/documentation/
- **Gleam Community**: https://gleam.run/news/
- **Project Issues**: https://github.com/lprior-repo/meal-planner/issues
- **Contributing Guide**: CONTRIBUTING.md (if available)

---

Last Updated: 2025-12-19
Gleam Version: 1.4.0+
