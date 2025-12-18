# Tandoor SDK Testing Infrastructure

This package provides comprehensive testing utilities for the Tandoor SDK, enabling effective unit and integration testing without making real HTTP calls.

## Components

### 1. Mock HTTP Transport (`mock_transport.gleam`)

Injectable mock for unit testing API calls without network requests.

**Features:**
- Static responses
- Response queues for sequential calls
- Conditional responses based on request
- Request matchers for validation
- Call history tracking

**Example:**
```gleam
import meal_planner/tandoor/testing/mock_transport
import meal_planner/tandoor/testing/builders

let mock =
  mock_transport.new()
  |> mock_transport.with_response(
    builders.success() |> builders.with_body("{\"id\": 1}")
  )

let sdk = sdk.new(...) |> sdk.with_transport(mock_transport.as_transport(mock))
```

### 2. Request Matchers (`matchers.gleam`)

Helpers to assert HTTP request structure in tests.

**Features:**
- Method matching
- URL pattern matching (with wildcards)
- Header assertions
- Body content assertions
- JSON field matching
- Combinators (AND, OR, NOT)

**Example:**
```gleam
import meal_planner/tandoor/testing/matchers

// Simple assertions
matchers.assert_method(request, http.Post)
matchers.assert_url_matches(request, "/api/recipe/*")
matchers.assert_header(request, "Authorization", "Bearer token")

// Combinators
matchers.all([
  matchers.method_is(http.Post),
  matchers.url_is("/api/recipe"),
  matchers.has_header("Content-Type"),
])
|> matchers.assert_matches(request, _)
```

### 3. Response Builders (`builders.gleam`)

Create mock HTTP responses with fluent API.

**Features:**
- Status code builders (200, 201, 404, 500, etc.)
- Header management
- JSON response helpers
- Paginated response builders
- Domain-specific builders (recipe, food, etc.)

**Example:**
```gleam
import meal_planner/tandoor/testing/builders

// Basic response
let response =
  builders.success()
  |> builders.with_header("Content-Type", "application/json")
  |> builders.with_body("{\"id\": 1}")

// Domain-specific
let recipe_response =
  builders.recipe_response(id: 1, name: "Pasta", servings: 4)

// Paginated
let paginated =
  builders.paginated(
    count: 100,
    next: "http://api/recipes?page=2",
    previous: "",
    results: "[...]"
  )
```

### 4. Test Fixtures (`fixtures.gleam`)

Pre-configured JSON fixtures for all Tandoor domain types.

**Features:**
- Default fixtures for all types
- Custom ID/name builders
- Paginated response fixtures
- Error response fixtures
- JSON string output (ready for HTTP responses)

**Example:**
```gleam
import meal_planner/tandoor/testing/fixtures

// Default fixtures
let recipe_json = fixtures.recipe_json()
let food_json = fixtures.food_json()

// Custom fixtures
let custom_recipe = fixtures.recipe_with_name_json(id: 42, name: "Custom")

// Paginated
let paginated = fixtures.paginated_recipes_json(count: 50, page_size: 10)

// Errors
let not_found = fixtures.not_found_error_json("Recipe")
```

## Usage Patterns

### Unit Testing API Module

```gleam
import gleeunit/should
import meal_planner/tandoor/testing/mock_transport
import meal_planner/tandoor/testing/builders
import meal_planner/tandoor/api/recipe/get

pub fn get_recipe_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.expect_request(fn(req) {
      req.method == http.Get && req.url == "/api/recipe/1"
    })
    |> mock_transport.with_response(
      builders.recipe_response(id: 1, name: "Test", servings: 4)
    )

  let config = // ... create config with mock transport

  let assert Ok(recipe) = get.get_recipe(config, recipe_id: 1)
  recipe.name |> should.equal("Test")
}
```

### Integration Testing with SDK

```gleam
import meal_planner/tandoor/sdk
import meal_planner/tandoor/testing/mock_transport
import meal_planner/tandoor/testing/fixtures

pub fn recipe_crud_workflow_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.queue_response(
      builders.created() |> builders.with_body(fixtures.recipe_json())
    )
    |> mock_transport.queue_response(
      builders.success() |> builders.with_body(fixtures.recipe_json())
    )

  let sdk =
    sdk.new(base_url: "http://test", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test complete workflow
  let assert Ok(created) = sdk.recipes.create(...)
  let assert Ok(fetched) = sdk.recipes.get(recipe_id: created.id)
}
```

## Testing Best Practices

1. **Use Mock Transport for Unit Tests**: Never make real HTTP calls in tests
2. **Verify Request Structure**: Use matchers to ensure requests are correct
3. **Test Error Cases**: Use error response builders to test error handling
4. **Test Workflows**: Use response queues for multi-step integration tests
5. **Keep Fixtures Simple**: Use JSON strings instead of complex type construction

## File Structure

```
src/meal_planner/tandoor/testing/
├── README.md                    # This file
├── mock_transport.gleam         # Mock HTTP transport
├── matchers.gleam               # Request matchers
├── builders.gleam               # Response builders
├── fixtures.gleam               # Test fixtures
└── fixtures/                    # JSON fixture files (future)

test/tandoor/testing/
├── mock_transport_test.gleam    # Mock transport tests
├── matchers_test.gleam          # Matcher tests
├── builders_test.gleam          # Builder tests
└── fixtures_test.gleam          # Fixture tests

test/tandoor/integration/
└── sdk_integration_test.gleam   # SDK integration tests
```

## Related Beads

- `meal-planner-gt1.1`: Mock HttpTransport
- `meal-planner-gt1.2`: Request matchers
- `meal-planner-gt1.3`: Response builders
- `meal-planner-gt1.4`: Test fixtures
- `meal-planner-xs9.1`: TandoorSDK facade
- `meal-planner-xs9.2`: Migration path
- `meal-planner-xs9.3`: Integration tests

## Future Enhancements

1. **Fixture Files**: Move to separate JSON files in `fixtures/` directory
2. **SDK API Modules**: Implement full API module namespaces (recipes, foods, etc.)
3. **Request Recording**: Add ability to record real requests for replay
4. **Snapshot Testing**: Add snapshot comparison for responses
5. **Property Testing**: Add property-based tests for API contracts
