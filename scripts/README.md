# Test Runner Scripts

This directory contains scripts for running tests in the Meal Planner project.

## Main Test Runner

**`run-all-tests.sh`** - Unified test runner that executes all tests in sequence

### Usage

```bash
# Run all tests (with infrastructure setup)
./scripts/run-all-tests.sh

# Run only unit tests
./scripts/run-all-tests.sh unit

# Run only integration tests
./scripts/run-all-tests.sh integration

# Run tests for specific category
./scripts/run-all-tests.sh category tandoor
./scripts/run-all-tests.sh category fatsecret
./scripts/run-all-tests.sh category meal_planner

# Quick run (skip infrastructure setup)
./scripts/run-all-tests.sh quick

# Show infrastructure status
./scripts/run-all-tests.sh status

# Cleanup infrastructure
./scripts/run-all-tests.sh clean

# Show help
./scripts/run-all-tests.sh help
```

### Features

- ✅ **Sequential Execution**: Runs tests in proper sequence
- ✅ **Infrastructure Management**: Automatic setup/teardown of test infrastructure
- ✅ **Colored Output**: Easy-to-read test results
- ✅ **Summary Reports**: Shows passed/failed counts and duration
- ✅ **Flexible Options**: Run all tests or specific categories
- ✅ **Error Handling**: Proper cleanup on failure
- ✅ **Prerequisites Check**: Validates environment before running

### Test Categories

1. **Unit Tests** - Fast, isolated tests
2. **Integration Tests** - Tests with external services
3. **Category Tests** - Tests for specific modules (tandoor, fatsecret, meal_planner)

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed or error occurred

### Integration with Makefile

The test runner integrates with the Makefile in `gleam/Makefile`:

```bash
cd gleam
make test              # Run all tests
make test-unit         # Run unit tests only
make test-integration  # Run integration tests only
```

## Infrastructure Management

**`setup-integration-tests.sh`** - Manages test infrastructure (PostgreSQL, etc.)

This script is called automatically by the main test runner but can be used independently:

```bash
# Setup infrastructure
./scripts/setup-integration-tests.sh setup

# Check status
./scripts/setup-integration-tests.sh status

# Stop infrastructure
./scripts/setup-integration-tests.sh stop

# Full cleanup (including volumes)
./scripts/setup-integration-tests.sh cleanup

# View logs
./scripts/setup-integration-tests.sh logs
```

## Hooks Integration

The test runner supports Claude Flow hooks for coordination:

```bash
# Pre-task hook (before running tests)
npx claude-flow@alpha hooks pre-task --description "Running test suite"

# Post-edit hook (after test creation/modification)
npx claude-flow@alpha hooks post-edit --file "scripts/run-all-tests.sh" --memory-key "swarm/test-runner/created"

# Post-task hook (after test completion)
npx claude-flow@alpha hooks post-task --task-id "test-runner"
```

## Example Workflow

```bash
# 1. Run all tests with infrastructure
./scripts/run-all-tests.sh

# 2. If integration tests fail, check infrastructure
./scripts/run-all-tests.sh status

# 3. Run only unit tests for quick iteration
./scripts/run-all-tests.sh unit

# 4. Run specific category to debug
./scripts/run-all-tests.sh category tandoor

# 5. Cleanup when done
./scripts/run-all-tests.sh clean
```

## Development Tips

1. **Quick Iteration**: Use `./scripts/run-all-tests.sh unit` for fast feedback
2. **Debugging**: Use `status` command to check infrastructure state
3. **CI/CD**: Use `./scripts/run-all-tests.sh all` in pipelines
4. **Cleanup**: Always run `clean` to free resources after testing

## Troubleshooting

**Tests fail to connect to database:**
```bash
./scripts/run-all-tests.sh status  # Check infrastructure
./scripts/setup-integration-tests.sh stop
./scripts/setup-integration-tests.sh setup
```

**Infrastructure won't start:**
```bash
./scripts/setup-integration-tests.sh cleanup  # Remove old volumes
./scripts/setup-integration-tests.sh setup    # Fresh start
```

**Permission denied:**
```bash
chmod +x ./scripts/run-all-tests.sh
chmod +x ./scripts/setup-integration-tests.sh
```
