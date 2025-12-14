# FatSecret SDK Test Infrastructure - Architecture

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Test File                         │
│                                                              │
│  import fatsecret/support/{http_mock, fixtures, helpers}    │
└──────────┬────────────────┬────────────────┬────────────────┘
           │                │                │
           ▼                ▼                ▼
┌──────────────────┐ ┌─────────────┐ ┌──────────────────┐
│   http_mock      │ │  fixtures   │ │  test_helpers    │
│                  │ │             │ │                  │
│ • Mock HTTP      │ │ • Food API  │ │ • Builders       │
│ • Call recording │ │ • Search    │ │ • Assertions     │
│ • Verification   │ │ • Recipes   │ │ • Validators     │
│ • Error sim      │ │ • OAuth     │ │ • Parameters     │
└──────────────────┘ └─────────────┘ └──────────────────┘
```

## Data Flow

```
1. Setup Phase
   ┌──────────────┐
   │ Create Mock  │
   │   Client     │──┐
   └──────────────┘  │
                     │
   ┌──────────────┐  │
   │ Configure    │  │
   │  Expected    │◄─┘
   │  Responses   │
   └──────────────┘
         │
         │ uses
         ▼
   ┌──────────────┐
   │  Fixtures    │
   │ (realistic   │
   │  responses)  │
   └──────────────┘

2. Execution Phase
   ┌──────────────┐
   │ Make Request │
   │  via Mock    │
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │ Mock Client  │
   │  - Records   │
   │  - Returns   │
   └──────────────┘

3. Verification Phase
   ┌──────────────┐
   │ Assert on    │
   │  Response    │
   └──────┬───────┘
          │ uses
          ▼
   ┌──────────────┐
   │Test Helpers  │
   │ - Assertions │
   │ - Validators │
   └──────────────┘
```

## Module Responsibilities

### http_mock.gleam
**Purpose**: Simulate HTTP requests/responses without network calls

**Responsibilities**:
- Match URL patterns to responses
- Record all calls made
- Provide response helpers (JSON, error, network error)
- Verify calls were made

**Used by**: All tests that need to mock API calls

### fixtures.gleam
**Purpose**: Provide realistic API response data

**Responsibilities**:
- Store actual FatSecret API responses
- Cover all API endpoints
- Include edge cases (single vs array, etc.)
- Document response formats

**Used by**: Tests and http_mock expectations

### test_helpers.gleam
**Purpose**: Common test utilities and assertions

**Responsibilities**:
- Build test data (config, tokens, nutrition, etc.)
- Assert on complex types (food, serving, nutrition)
- Validate business logic (macros → calories)
- Create parameter dictionaries

**Used by**: All tests for building data and assertions

## Typical Test Flow

```gleam
pub fn test_food_search() {
  // 1. Setup: Create mock with fixture
  let client = http_mock.new()                           // http_mock
    |> http_mock.expect("foods.search",                  // http_mock
       http_mock.json_response(200,                      // http_mock
         fixtures.food_search_response()))               // fixtures

  // 2. Setup: Create test config
  let config = test_helpers.test_config()                // test_helpers

  // 3. Execute: Make API call (would use mock internally)
  let result = foods_client.search(config, "apple")

  // 4. Verify: Check response
  case result {
    Ok(response) -> {
      response.foods
      |> test_helpers.assert_length(3)                   // test_helpers

      let assert [first, ..] = response.foods
      first
      |> test_helpers.assert_food(                       // test_helpers
        id: "33691",
        name: "Apple",
        food_type: "Generic",
        serving_count: 1
      )
    }
    Error(_) -> should.fail()
  }

  // 5. Verify: Check HTTP calls
  client
  |> http_mock.assert_called("POST", "foods.search")     // http_mock
  |> should.be_true()
}
```

## Component Interactions

```
┌─────────────────────────────────────────────────────────┐
│ Test Case                                               │
│                                                         │
│  ┌────────┐   creates    ┌────────┐                    │
│  │ Test   │─────────────▶│ Mock   │                    │
│  │ Config │              │ Client │                    │
│  └────────┘              └───┬────┘                    │
│      ▲                       │                         │
│      │                       │ expects                 │
│      │                       ▼                         │
│      │                  ┌─────────┐                    │
│      │                  │Fixture  │                    │
│      │                  │Response │                    │
│      │                  └─────────┘                    │
│      │                       │                         │
│      │                       │ returns                 │
│      │                       ▼                         │
│  ┌────────┐              ┌─────────┐                  │
│  │API Call│─────────────▶│ Mock    │                  │
│  │        │   executes   │ Response│                  │
│  └────────┘              └───┬─────┘                  │
│      │                       │                         │
│      │                       │                         │
│      ▼                       ▼                         │
│  ┌────────────────────────────────┐                   │
│  │ Assertions & Validation        │                   │
│  │ (using test_helpers)           │                   │
│  └────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

## Design Principles

### 1. Separation of Concerns
- **http_mock**: HTTP mechanics only
- **fixtures**: Data only
- **test_helpers**: Utilities only

### 2. Realistic Fixtures
- Based on actual API responses
- Include all edge cases
- Document quirks

### 3. Type Safety
- Full Gleam type checking
- No dynamic typing
- Compile-time safety

### 4. Easy to Use
- Simple, intuitive API
- Good defaults
- Clear naming

### 5. Easy to Extend
- Add new fixtures easily
- Add new helpers as needed
- Pattern-based matching

## Extension Points

### Adding New Fixtures

```gleam
// In fixtures.gleam
pub fn new_endpoint_response() -> String {
  "{
    \"new_field\": \"value\",
    ...
  }"
}
```

### Adding New Helpers

```gleam
// In test_helpers.gleam
pub fn test_new_type(...) -> NewType {
  NewType(...)
}

pub fn assert_new_type(value: NewType, ...) -> Nil {
  value.field |> should.equal(expected)
}
```

### Adding New Mock Patterns

```gleam
// In your test
let client = http_mock.new()
  |> http_mock.expect("new.endpoint",
     http_mock.json_response(200, fixtures.new_endpoint_response()))
```

## Dependencies

```
test_helpers
    ├── gleam/dict
    ├── gleam/int
    ├── gleam/list
    ├── gleam/option
    ├── gleam/string
    ├── gleeunit/should
    ├── meal_planner/fatsecret/core/config
    ├── meal_planner/fatsecret/core/oauth
    └── meal_planner/fatsecret/foods/types

http_mock
    ├── gleam/dict
    ├── gleam/list
    ├── gleam/option
    └── gleam/string

fixtures
    └── gleam/string

integration_example_test
    ├── gleam/dict
    ├── gleeunit/should
    ├── fatsecret/support/fixtures
    ├── fatsecret/support/http_mock
    └── fatsecret/support/test_helpers
```

## File Sizes

| File | Lines | Purpose |
|------|-------|---------|
| http_mock.gleam | 269 | Mock HTTP client |
| fixtures.gleam | 457 | API response fixtures |
| test_helpers.gleam | 543 | Test utilities |
| integration_example_test.gleam | 312 | Working examples |
| README.md | 511 | Full documentation |
| QUICK_START.md | 208 | Quick start guide |
| **Total** | **2,300** | Complete infrastructure |

## Usage Statistics

- **Mock Patterns**: Pattern-based URL matching (flexible)
- **Fixtures**: 15+ realistic API responses
- **Test Helpers**: 30+ utility functions
- **Examples**: 12+ complete test examples
- **Edge Cases**: Single vs array, numeric strings, optional fields
- **API Coverage**: Food, Search, Recipe, OAuth, Profile, Diary

## Performance Characteristics

- **No Network Calls**: Instant test execution
- **In-Memory**: All data in memory
- **Type Safe**: No runtime type errors
- **Fast**: Tests run in milliseconds
- **Deterministic**: Same inputs → same outputs

## Best Practices

1. **Use fixtures**: Don't hand-craft JSON
2. **Test edge cases**: Single vs array, optional fields
3. **Verify calls**: Use `assert_called` to check HTTP calls
4. **Use helpers**: Don't repeat assertion patterns
5. **Document**: Add comments explaining what you're testing

## Quick Reference

### Common Imports
```gleam
import fatsecret/support/fixtures
import fatsecret/support/http_mock
import fatsecret/support/test_helpers
import gleam/dict
import gleeunit/should
```

### Basic Test Structure
```gleam
pub fn my_test() {
  // 1. Setup mock
  let client = http_mock.new()
    |> http_mock.expect("endpoint", 
       http_mock.json_response(200, fixtures.response()))

  // 2. Setup config
  let config = test_helpers.test_config()

  // 3. Execute
  let result = api_call(config, params)

  // 4. Verify response
  result |> should.be_ok()

  // 5. Verify HTTP calls
  client |> http_mock.assert_called("POST", "endpoint")
    |> should.be_true()
}
```
