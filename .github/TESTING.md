# Testing Strategy & Configuration

This document describes the testing approach, coverage requirements, and best practices for the Meal Planner project.

## Test Categories

### 1. Unit Tests (Fast, ~0.8s)

Located in `test/` with `*_test.gleam` suffix.

**Purpose**: Test individual functions and modules in isolation.

**Target**: Core business logic, type safety, error handling.

**Example**:
```gleam
import gleeunit/should
import meal_planner/constraint

pub fn validate_calories_test() {
  constraint.validate_calories(1500)
  |> should.equal(Ok(Nil))
}
```

**Run**: `make test`

### 2. Integration Tests

Test interaction between modules and external services.

**Types**:
- **API Integration**: Test against real external APIs (FatSecret, Tandoor)
- **Database Integration**: Test database operations with test database
- **End-to-End**: Full request/response cycles

**Example**:
```gleam
pub fn fatsecret_oauth_test() {
  use token <- gleeunit.promise_each([test_oauth_token])
  fatsecret.validate_token(token)
  |> promise.await(fn(result) {
    result |> should.be_ok()
  })
}
```

**Run**: `make test-all` or `make test-live`

### 3. Property-Based Tests

Use `qcheck` for randomized testing across input space.

**Purpose**: Find edge cases and invariants.

**Example**:
```gleam
import qcheck

pub fn list_length_prop_test() {
  qcheck.run(100, fn() {
    let list = qcheck.list(qcheck.int(), int_range: 0..10)
    let length = list.length(list)
    length >= 0 && length <= 10
  })
}
```

**Run**: `make test-properties`

## Test Structure

### Directory Layout

```
test/
├── fatsecret/              # FatSecret API tests
│   ├── core/
│   │   ├── error_decoder_test.gleam
│   │   └── http_integration_test.gleam
│   ├── diary/
│   │   └── decoders_test.gleam
│   ├── exercise/
│   │   ├── exercise_test.gleam
│   │   └── handlers_test.gleam
│   └── ...
├── tandoor/                # Tandoor API tests
├── meal_plan/              # Core logic tests
├── fixtures/               # Test data files
│   ├── valid_input.json
│   ├── error_responses.json
│   └── ...
└── test_runner/            # Custom test runners
    ├── fast.gleam          # Fast unit tests only
    └── properties.gleam    # Property-based tests
```

### Test File Naming

- **Unit Tests**: `module_test.gleam`
- **Integration Tests**: `module_integration_test.gleam`
- **Property Tests**: `module_prop_test.gleam`

## Running Tests

### Quick Reference

```bash
# Fast unit tests (recommended for development)
make test

# All tests (including integration)
make test-all

# Property-based tests
make test-properties

# Specific test file
gleam test test/meal_plan/meal_plan_test.gleam

# With verbose output
gleam test --verbose

# With pattern matching
gleam test --filter "pattern_name"
```

### Environment Variables

For integration tests, set these in `.env`:

```bash
# FatSecret API (optional, tests skip if not set)
FATSECRET_CONSUMER_KEY=...
FATSECRET_CONSUMER_SECRET=...

# Tandoor API (optional)
TANDOOR_BASE_URL=http://localhost:8000
TANDOOR_API_TOKEN=...

# Database
TEST_DATABASE_URL=postgresql://...

# Skip slow tests
SKIP_INTEGRATION_TESTS=true
```

## Writing Tests

### Best Practices

1. **One assertion per test** (preferred)
   ```gleam
   pub fn test_single_assertion() {
     result |> should.equal(expected)
   }
   ```

2. **Descriptive names** - indicate what is being tested
   ```gleam
   pub fn validate_email_rejects_invalid_format_test() { ... }
   ```

3. **Use Arrange-Act-Assert pattern**
   ```gleam
   pub fn example_test() {
     // Arrange
     let input = TestData(value: 42)

     // Act
     let result = process(input)

     // Assert
     result |> should.equal(Ok(expected))
   }
   ```

4. **Test error paths explicitly**
   ```gleam
   pub fn handles_invalid_input_test() {
     invalid_input()
     |> should.be_error()
   }
   ```

5. **Use fixtures for complex data**
   ```gleam
   pub fn test_with_fixture() {
     let json = load_fixture("valid_response.json")
     json
     |> decode_response()
     |> should.be_ok()
   }
   ```

### Testing Patterns

#### Result Handling
```gleam
pub fn result_test() {
  some_function()
  |> should.be_ok()

  another_function()
  |> should.be_error()
}
```

#### Option Handling
```gleam
pub fn option_test() {
  Some(42)
  |> should.equal(Some(42))

  None
  |> should.equal(None)
}
```

#### List Operations
```gleam
pub fn list_test() {
  [1, 2, 3]
  |> should.equal([1, 2, 3])

  []
  |> list.length()
  |> should.equal(0)
}
```

#### Async/Promise
```gleam
import gleeunit/promise

pub fn async_test() {
  use _ <- promise.test
  perform_async_operation()
  |> promise.map(fn(result) {
    result |> should.be_ok()
  })
}
```

## Test Fixtures

### Location
`test/fixtures/` - Store test data here

### Examples

**JSON Fixture** (`test/fixtures/valid_response.json`):
```json
{
  "status": "ok",
  "data": {
    "id": 123,
    "name": "Test Item"
  }
}
```

**Loading Fixtures**:
```gleam
import simplifile

pub fn load_fixture(name: String) -> Result(String, Nil) {
  simplifile.read("test/fixtures/" <> name)
  |> result.map_error(fn(_) { Nil })
}
```

## Coverage Expectations

### Minimum Coverage Targets

- **Core Logic**: 90%+ coverage
- **API Handlers**: 80%+ coverage
- **Error Cases**: 100% (all error paths must be tested)
- **Database**: 75%+ coverage

### Coverage Reporting

```bash
# Generate coverage (if using gleam/coverage)
gleam test --coverage

# View HTML report
open coverage/index.html
```

## CI/CD Integration

### Automated Testing

GitHub Actions runs tests on:
1. **Every PR** - must pass all checks
2. **Push to main** - triggers full test suite
3. **Schedule** - nightly full test run (optional)

### Required Checks

- `gleam build` - type checking
- `gleam format --check` - code formatting
- `gleam test` - unit tests
- Custom CLI smoke tests

### Handling Flaky Tests

If a test is intermittently failing:

1. **Local Reproduction**
   ```bash
   for i in {1..10}; do gleam test; done
   ```

2. **Isolate the Test**
   ```bash
   gleam test --filter "flaky_test"
   ```

3. **Fix Root Cause**
   - Add proper async handling
   - Fix race conditions
   - Handle timeout issues

4. **Mark as Known Flaky**
   ```gleam
   @skip("Known flaky: Issue #123")
   pub fn flaky_test() { ... }
   ```

## Test Data Management

### Creating Test Data

1. **Fixtures** - Static JSON/YAML files for complex data
2. **Factories** - Functions that generate test objects
3. **Builders** - Fluent API for constructing test data

Example Factory:
```gleam
pub fn create_user_for_test(
  id: Int,
  name: String,
) -> User {
  User(
    id: id,
    name: name,
    email: name <> "@test.local",
  )
}
```

### Database Test Isolation

```gleam
pub fn setup_test_database() {
  // Create fresh schema per test
  db.execute("DROP TABLE IF EXISTS users CASCADE")
  db.execute("CREATE TABLE users (...)")
}

pub fn teardown_test_database() {
  db.execute("DROP TABLE IF EXISTS users CASCADE")
}
```

## Debugging Tests

### Verbose Output

```bash
gleam test --verbose
```

### Print Debugging

```gleam
pub fn debug_test() {
  let result = some_function()
  let _ = io.println("Debug: " <> string.inspect(result))
  result |> should.equal(expected)
}
```

### Interactive Debugging

```bash
# Start REPL
gleam shell

# Load test module
:c(test_file)

# Call functions interactively
some_test_function()
```

## Performance Testing

### Benchmarking

```gleam
pub fn performance_test() {
  let iterations = 1000
  let start = birl.now()

  list.range(0, iterations)
  |> list.each(fn(_) { expensive_operation() })

  let end = birl.now()
  let duration = birl.difference(start, end)

  duration.milliseconds
  |> should.be_less_than(100)  // Should complete in < 100ms
}
```

## Continuous Improvement

### Metrics to Track

1. **Test Coverage**: Trend towards 85%+
2. **Test Execution Time**: Keep under 5 seconds
3. **Flakiness Rate**: Goal < 1%
4. **New Test Velocity**: >1 test per feature

### Review Checklist

- [ ] Tests exist for all public functions
- [ ] Error cases are tested
- [ ] Edge cases are covered
- [ ] Tests pass locally before commit
- [ ] Tests pass in CI/CD pipeline
- [ ] Documentation is updated

---

Last Updated: 2025-12-19
Gleam Version: 1.4.0+
