# FatSecret API Test Fixtures

This directory contains comprehensive test fixtures for mocking FatSecret Platform API responses. These fixtures support unit testing, integration testing, and local development without requiring live API calls.

## Directory Structure

```
tests/fixtures/
├── README.md                 # This file
├── diary/                    # Food diary entries and summaries
│   ├── food_entry_create_response.json
│   ├── food_entries_get_response.json
│   ├── food_entries_get_empty.json
│   ├── day_summary.json
│   └── month_summary.json
├── exercise/                 # Exercise entries and summaries
│   ├── exercise_entry_create_response.json
│   ├── exercise_entries_get_response.json
│   └── exercise_month_summary.json
├── favorites/                # Favorite foods and recipes
│   ├── favorite_foods_response.json
│   ├── most_eaten_response.json
│   └── recently_eaten_response.json
├── foods/                    # Food search and details
│   ├── food_complete.json
│   ├── food_branded.json
│   ├── food_minimal.json
│   ├── search_response.json
│   └── search_response_empty.json
├── oauth/                    # OAuth authentication
│   ├── request_token_response.json
│   └── access_token_response.json
├── profile/                  # User profile data
│   ├── profile_response.json
│   └── profile_auth_response.json
├── recipes/                  # Recipe search and details
│   ├── recipe_search_response.json
│   ├── recipe_get_response.json
│   └── recipe_types_response.json
├── saved_meals/              # Saved meal templates
│   ├── saved_meals_response.json
│   └── saved_meal_items_response.json
├── weight/                   # Weight tracking
│   ├── weight_entry_response.json
│   └── weight_month_summary.json
└── errors/                   # API error responses
    ├── unauthorized_error.json
    ├── not_found_error.json
    ├── invalid_parameter_error.json
    ├── rate_limit_error.json
    └── server_error.json
```

## Usage Patterns

### 1. Loading Fixtures in Tests

Use Rust's `include_str!` macro for compile-time fixture loading:

```rust
#[cfg(test)]
mod tests {
    use serde_json;
    use meal_planner::fatsecret::foods::Food;

    #[test]
    fn test_parse_food_response() {
        let json = include_str!("../fixtures/foods/food_complete.json");
        let response: serde_json::Value = serde_json::from_str(json).unwrap();
        
        // Assert structure
        assert!(response["food"].is_object());
        assert_eq!(response["food"]["food_id"], "12345");
    }

    #[test]
    fn test_deserialize_food() {
        let json = include_str!("../fixtures/foods/food_complete.json");
        let food: Food = serde_json::from_str(json).unwrap();
        
        assert_eq!(food.food_id.value, "12345");
        assert_eq!(food.food_name, "Chicken Breast");
    }
}
```

### 2. Mocking HTTP Responses

Use with `mockito` or `wiremock` for HTTP mocking:

```rust
#[cfg(test)]
mod tests {
    use mockito::{mock, server_url};
    use meal_planner::fatsecret::foods::search_foods;
    use meal_planner::fatsecret::core::FatSecretConfig;

    #[tokio::test]
    async fn test_search_foods_with_mock() {
        let fixture = include_str!("../fixtures/foods/search_response.json");
        
        let _m = mock("GET", "/foods.search.v1")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(fixture)
            .create();

        let config = FatSecretConfig {
            consumer_key: "test_key".to_string(),
            consumer_secret: "test_secret".to_string(),
            base_url: server_url(), // Use mockito server
        };

        let result = search_foods(&config, "chicken", None, None).await;
        assert!(result.is_ok());
    }
}
```

### 3. Testing Error Handling

Use error fixtures to test error scenarios:

```rust
#[cfg(test)]
mod tests {
    use meal_planner::fatsecret::core::FatSecretError;

    #[test]
    fn test_parse_unauthorized_error() {
        let json = include_str!("../fixtures/errors/unauthorized_error.json");
        let error: serde_json::Value = serde_json::from_str(json).unwrap();
        
        assert_eq!(error["error"]["code"], "2");
        assert_eq!(error["error"]["message"], "Invalid authentication credentials");
    }

    #[tokio::test]
    async fn test_handle_rate_limit() {
        let fixture = include_str!("../fixtures/errors/rate_limit_error.json");
        
        // Mock HTTP response with rate limit error
        let _m = mock("GET", "/food.get.v3")
            .with_status(429)
            .with_body(fixture)
            .create();

        // Test that your code handles rate limiting gracefully
        let result = get_food(&config, "12345").await;
        assert!(matches!(result, Err(FatSecretError::RateLimit)));
    }
}
```

### 4. Testing Empty/Edge Cases

Use empty response fixtures for boundary testing:

```rust
#[test]
fn test_empty_food_entries() {
    let json = include_str!("../fixtures/diary/food_entries_get_empty.json");
    let response: serde_json::Value = serde_json::from_str(json).unwrap();
    
    // FatSecret returns empty string for no entries
    assert_eq!(response["food_entries"], "");
}

#[test]
fn test_empty_search_results() {
    let json = include_str!("../fixtures/foods/search_response_empty.json");
    let response: FoodSearchResponse = serde_json::from_str(json).unwrap();
    
    assert_eq!(response.foods.total_results, "0");
    assert!(response.foods.food.is_empty());
}
```

## Fixture Conventions

### Naming Conventions

- **Response fixtures**: Named after the operation they represent (e.g., `food_entry_create_response.json`)
- **Entity fixtures**: Named after the entity type and variant (e.g., `food_complete.json`, `food_minimal.json`)
- **Error fixtures**: Named after the error type (e.g., `unauthorized_error.json`, `rate_limit_error.json`)
- **Empty fixtures**: Suffixed with `_empty` (e.g., `search_response_empty.json`)

### Data Consistency

All fixtures use consistent test data for easier debugging:

- **User ID**: `123456`
- **Food IDs**: `12345`, `67890`, `98765`, `11111`
- **Serving IDs**: `67890`, `12345`, `22222`
- **Date Int**: `20088` (example date for consistent testing)
- **Entry IDs**: `987654321`, `987654322`, `456789123`, etc.

### Realistic Data

Fixtures contain realistic nutritional values based on actual foods:

- **Chicken Breast**: High protein, low carb
- **Oatmeal**: High carb, moderate protein, high fiber
- **Salad Greens**: Low calorie, high fiber

This helps catch validation bugs and ensures tests reflect real-world usage.

## Common FatSecret API Patterns

### Date Integer Format

FatSecret uses `date_int` format (days since Unix epoch):

```json
{
  "date_int": "20088"  // String format, represents a specific date
}
```

To convert:
- Use `meal_planner::fatsecret::diary::date_to_int()` to convert `chrono::NaiveDate` → `i32`
- Use `meal_planner::fatsecret::diary::int_to_date()` to convert `i32` → `chrono::NaiveDate`

### Empty vs. Missing Fields

FatSecret API returns:
- **Empty string** `""` for empty collections (e.g., no food entries)
- **Missing fields** for optional data (e.g., `brand_name` on generic foods)

Your deserialization logic should handle both cases.

### Serving Descriptions

Foods can have multiple servings with different formats:

```json
{
  "servings": {
    "serving": [
      {"serving_description": "1 cup, chopped or diced", "is_default": "1"},
      {"serving_description": "100g"},
      {"serving_description": "1 breast"}
    ]
  }
}
```

The `is_default` field indicates the primary serving size.

## Error Code Reference

Common FatSecret API error codes (see `errors/` directory):

| Code | Description | HTTP Status | Fixture |
|------|-------------|-------------|---------|
| `2` | Invalid authentication credentials | 401 | `unauthorized_error.json` |
| `3` | Resource not found | 404 | `not_found_error.json` |
| `4` | Invalid parameter | 400 | `invalid_parameter_error.json` |
| `6` | Rate limit exceeded | 429 | `rate_limit_error.json` |
| `10` | Internal server error | 500 | `server_error.json` |

## Extending Fixtures

When adding new fixtures:

1. **Follow the naming convention**: `{operation}_{type}.json`
2. **Use consistent test data**: Follow the IDs/values listed above
3. **Include all required fields**: Match FatSecret API structure exactly
4. **Add documentation**: Update this README with new fixtures
5. **Create variants**: Add `_minimal`, `_complete`, `_empty` variants as needed

### Example: Adding a New Fixture

```bash
# 1. Create the fixture file
cat > tests/fixtures/diary/food_entry_edit_response.json <<EOF
{
  "success": true
}
EOF

# 2. Test it works
cargo test --test fatsecret_foods_tests -- test_edit_food_entry

# 3. Update this README
# (Add to directory structure and usage examples)
```

## Maintenance

### Updating Fixtures for API Changes

When the FatSecret API changes:

1. Capture real API response (sanitize any personal data)
2. Update affected fixture files
3. Run full test suite: `cargo test`
4. Update README if structure changed

### Validation

Fixtures are validated in CI:

```bash
# Validate all JSON fixtures parse correctly
for file in tests/fixtures/**/*.json; do
  echo "Validating $file"
  jq empty "$file" || echo "Invalid JSON: $file"
done
```

## Reference

- [FatSecret Platform API Documentation](https://platform.fatsecret.com/api/)
- [FatSecret OAuth 1.0a Guide](https://platform.fatsecret.com/api/Default.aspx?screen=rapiauth)
- [FatSecret Error Codes](https://platform.fatsecret.com/api/Default.aspx?screen=rapiref)

## Questions?

For questions about fixtures or testing patterns, see:
- Main project README: `../../README.md`
- FatSecret module docs: `../../src/fatsecret/mod.rs`
- Test examples: `../../tests/fatsecret_foods_tests.rs`
