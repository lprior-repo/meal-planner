# FatSecret SDK Test Infrastructure - Quick Start

## Installation

The test infrastructure is located in `test/fatsecret/support/`:
- `http_mock.gleam` - Mock HTTP client
- `fixtures.gleam` - API response fixtures
- `test_helpers.gleam` - Test utilities
- `integration_example_test.gleam` - Working examples

## 5-Minute Quick Start

### 1. Import the modules

```gleam
import fatsecret/support/fixtures
import fatsecret/support/http_mock
import fatsecret/support/test_helpers
import gleam/dict
import gleeunit/should
```

### 2. Create a basic test

```gleam
pub fn my_first_test() {
  // Setup mock
  let client =
    http_mock.new()
    |> http_mock.expect(
      "foods.search",
      http_mock.json_response(200, fixtures.food_search_response()),
    )

  // Make request
  let assert Ok(#(_client, response)) =
    http_mock.make_request(
      client,
      "POST",
      "https://platform.fatsecret.com/rest/server.api?method=foods.search",
      dict.new(),
      "method=foods.search&search_expression=apple",
    )

  // Verify
  response.status |> should.equal(200)
}
```

### 3. Test with realistic fixtures

```gleam
import gleam/json

pub fn test_food_decoder() {
  let json_str = fixtures.food_response()

  case json.parse(json_str, using: my_decoder) {
    Ok(food) -> {
      food.food_name |> should.equal("Apple")
      food.servings |> should.have_length(1)
    }
    Error(_) -> should.fail()
  }
}
```

### 4. Use test helpers

```gleam
pub fn test_nutrition_validation() {
  let nutrition = test_helpers.test_nutrition(
    calories: 95.0,
    carbs: 25.13,
    protein: 0.47,
    fat: 0.31,
  )

  // Validate macros match calories
  nutrition
  |> test_helpers.macros_match_calories
  |> should.be_true()

  // Assert macro values
  nutrition
  |> test_helpers.assert_macros(
    calories: 95.0,
    carbs: 25.13,
    protein: 0.47,
    fat: 0.31,
  )
}
```

## Common Scenarios

### Test API client with mock

```gleam
pub fn test_search_foods() {
  let client =
    http_mock.new()
    |> http_mock.expect("foods.search",
       http_mock.json_response(200, fixtures.food_search_response()))

  let config = test_helpers.test_config()

  // Call your API client (would use the mock in tests)
  // let result = foods_client.search(config, "apple")

  // Verify the call was made
  client
  |> http_mock.assert_called("POST", "foods.search")
  |> should.be_true()
}
```

### Test error handling

```gleam
pub fn test_missing_parameter_error() {
  let client =
    http_mock.new()
    |> http_mock.expect("foods.search",
       http_mock.error_response(101, "Missing required parameter"))

  // Your code should handle this error
  // let result = foods_client.search(config, "")
  // result |> should.be_error()
}
```

### Test FatSecret quirks

```gleam
pub fn test_single_vs_array_results() {
  // Single result returns object
  let single = fixtures.food_search_single_response()

  // Multiple results return array
  let multiple = fixtures.food_search_response()

  // Your decoder should handle both
  json.parse(single, using: decode_search) |> should.be_ok()
  json.parse(multiple, using: decode_search) |> should.be_ok()
}
```

## Available Fixtures

| Fixture | Description |
|---------|-------------|
| `food_response()` | Single food with one serving |
| `food_multiple_servings_response()` | Food with 3 servings |
| `branded_food_response()` | Branded food with brand_name |
| `food_search_response()` | Search with 3 results (array) |
| `food_search_single_response()` | Search with 1 result (object!) |
| `empty_search_response()` | No results found |
| `recipe_response()` | Complete recipe |
| `profile_response()` | User profile |
| `food_entries_response()` | Food diary entries |
| `error_response(code, msg)` | Custom API error |
| `missing_parameter_error()` | 101 error |
| `oauth_error()` | 108 error |

## Useful Helpers

| Helper | Use Case |
|--------|----------|
| `test_config()` | Get test FatSecret config |
| `test_access_token()` | Get test OAuth token |
| `test_nutrition(...)` | Build nutrition object |
| `test_serving(...)` | Build serving object |
| `test_food(...)` | Build food object |
| `assert_macros(...)` | Check nutrition values |
| `assert_some(opt)` | Assert Option is Some |
| `assert_none(opt)` | Assert Option is None |
| `assert_length(list, n)` | Check list length |
| `assert_contains(str, sub)` | Check substring |
| `assert_float_equal(a, b)` | Compare floats with tolerance |
| `macros_match_calories(n)` | Validate nutrition math |

## Testing Checklist

When writing tests for FatSecret SDK:

- [ ] Test with realistic fixtures (not hand-crafted JSON)
- [ ] Test single vs array results (use both fixtures)
- [ ] Test with and without optional fields
- [ ] Test error responses (101, 102, 108, etc.)
- [ ] Test network errors (500, timeout)
- [ ] Verify HTTP calls were made correctly
- [ ] Validate nutrition math (macros → calories)
- [ ] Test branded and generic foods
- [ ] Test numeric strings ("95" vs 95)

## Next Steps

- Read `README.md` for full documentation
- See `integration_example_test.gleam` for working examples
- Check existing tests in `test/fatsecret/` for patterns

## Getting Help

- Check the README for detailed docs
- Look at integration_example_test.gleam for patterns
- Review existing tests in test/fatsecret/ directories
- See FatSecret API docs for expected response formats
