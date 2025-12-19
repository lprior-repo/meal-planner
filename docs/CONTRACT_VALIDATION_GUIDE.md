# Contract Validation Integration Guide

## Overview

This guide shows how to integrate contract validation into API handlers to ensure all responses conform to the OpenAPI specification.

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP Request
       ▼
┌─────────────────────────────────────┐
│  Validation Middleware              │
│  ├─ Validate request body           │
│  ├─ Validate query parameters       │
│  └─ Check authentication            │
└──────┬──────────────────────────────┘
       │ Validated Request
       ▼
┌─────────────────────────────────────┐
│  Handler                            │
│  ├─ Business logic                  │
│  └─ Service calls                   │
└──────┬──────────────────────────────┘
       │ Response Data
       ▼
┌─────────────────────────────────────┐
│  Contract Validator                 │
│  ├─ Encode to JSON                  │
│  ├─ Validate against schema         │
│  └─ Add version headers             │
└──────┬──────────────────────────────┘
       │ HTTP Response
       ▼
┌─────────────┐
│   Client    │
└─────────────┘
```

## Basic Integration

### Step 1: Import Modules

```gleam
import meal_planner/web/contract_validator
import meal_planner/web/validation_middleware as middleware
import wisp.{type Request, type Response}
```

### Step 2: Add Request Validation

```gleam
pub fn create_food_entry(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- wisp.require_method(req, http.Post)

  // Validate request body
  use validated_req <- middleware.validate_request(
    req,
    schema: "FoodEntryInput",
    required_fields: [
      "food_id",
      "serving_id",
      "number_of_units",
      "meal",
      "date"
    ],
  )

  // Business logic
  case parse_food_entry_input(validated_req.body) {
    Ok(input) -> {
      case service.create_food_entry(conn, input) {
        Ok(entry) -> {
          // Encode and validate response
          let response_json = contract_validator.food_entry_to_json(entry)

          middleware.validate_response(
            response_json,
            schema: "FoodEntry",
            status: 201,
          )
          |> middleware.add_version_headers(
            version: "1.0.0",
            deprecated: False,
            sunset: "",
          )
          |> middleware.add_cors_headers
        }
        Error(e) -> error_response(e)
      }
    }
    Error(msg) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("invalid_input")),
            #("message", json.string(msg)),
          ])
        ),
        400,
      )
  }
}
```

## Advanced Patterns

### Query Parameter Validation

```gleam
pub fn search_foods(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.require_method(req, http.Get)

  // Validate query parameters
  use query <- middleware.validate_query_params(req)

  // Use validated parameters
  case service.search_foods(conn, query.search, query.limit, query.offset) {
    Ok(results) -> {
      let response_json =
        contract_validator.food_search_response_to_json(results)

      middleware.validate_response(
        response_json,
        schema: "FoodSearchResponse",
        status: 200,
      )
    }
    Error(e) -> error_response(e)
  }
}
```

### Authentication Requirement

```gleam
pub fn get_user_diary(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.require_method(req, http.Get)

  // Require authentication
  use authed_req <- middleware.require_auth(req)

  // Extract user from auth token
  let user_id = extract_user_id(authed_req)

  case service.get_diary_entries(conn, user_id) {
    Ok(entries) -> {
      let response_json = json.array(entries, contract_validator.food_entry_to_json)

      middleware.validate_response(
        response_json,
        schema: "FoodEntriesArray",
        status: 200,
      )
    }
    Error(e) -> error_response(e)
  }
}
```

### Deprecated Endpoint Handling

```gleam
pub fn legacy_food_search(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_warning("Using deprecated endpoint: /api/foods/search")
  use <- wisp.require_method(req, http.Get)

  // Forward to new implementation
  let result = search_foods_v2(req, conn)

  // Add deprecation headers
  result
  |> middleware.add_version_headers(
    version: "1.0.0",
    deprecated: True,
    sunset: "2025-12-31",
  )
}
```

## Error Response Validation

All error responses should conform to the ErrorResponse schema:

```gleam
fn error_response(error: ServiceError) -> Response {
  let error_json = json.object([
    #("error", json.object([
      #("code", json.int(error_code(error))),
      #("message", json.string(error_message(error))),
    ])),
  ])

  // Validate error response
  case contract_validator.validate_error_response_schema(error_json) {
    Ok(_) -> wisp.json_response(json.to_string(error_json), status_code(error))
    Error(msg) -> {
      // Schema violation in error response - log and return generic 500
      wisp.log_error("Error response schema violation: " <> msg)
      wisp.internal_server_error()
    }
  }
}

fn error_code(error: ServiceError) -> Int {
  case error {
    NotAuthenticated -> 401
    NotAuthorized -> 403
    NotFound -> 404
    InvalidInput(_) -> 400
    ServerError(_) -> 500
  }
}
```

## Testing Contract Compliance

### Unit Test Example

```gleam
import gleeunit/should

pub fn food_entry_response_contract_test() {
  // GIVEN: A FoodEntry from the service
  let entry = create_test_food_entry()

  // WHEN: Converting to JSON
  let json_obj = contract_validator.food_entry_to_json(entry)

  // THEN: Should validate against schema
  contract_validator.validate_food_entry_schema(json_obj)
  |> should.be_ok
}
```

### Integration Test Example

```gleam
import gleam/http
import gleam/http/request
import gleam/http/response
import gleeunit/should

pub fn create_food_entry_integration_test() {
  // GIVEN: A valid create entry request
  let request_body = json.object([
    #("food_id", json.string("4142")),
    #("serving_id", json.string("12345")),
    #("number_of_units", json.float(1.0)),
    #("meal", json.string("lunch")),
    #("date", json.string("2024-01-15")),
  ])

  // WHEN: Making request to handler
  let req = test_request(http.Post, "/api/fatsecret/diary/entries", request_body)
  let resp = create_food_entry(req, test_db_conn)

  // THEN: Response should be 201
  resp.status
  |> should.equal(201)

  // AND: Response body should conform to schema
  let response_json = json.decode(resp.body)
  contract_validator.validate_food_entry_schema(response_json)
  |> should.be_ok
}
```

## Contract Testing in CI/CD

### Pre-Deployment Checks

```bash
#!/bin/bash
# scripts/validate-contracts.sh

echo "Running contract validation tests..."

# Run contract test suite
gleam test --module contract_validation_test

# Validate OpenAPI spec
npx @openapitools/openapi-generator-cli validate -i openapi.yaml

# Check for breaking changes
gleam run -m contract_validator check_compatibility \
  --old-spec openapi-v1.0.0.yaml \
  --new-spec openapi.yaml

echo "Contract validation complete!"
```

### GitHub Actions Workflow

```yaml
# .github/workflows/contract-tests.yml
name: API Contract Tests

on: [pull_request]

jobs:
  contract-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Gleam
        uses: erlef/setup-beam@v1
        with:
          gleam-version: 1.0.0

      - name: Run Contract Tests
        run: |
          gleam deps download
          gleam test --module contract_validation_test

      - name: Validate OpenAPI Spec
        run: |
          npm install -g @openapitools/openapi-generator-cli
          openapi-generator-cli validate -i openapi.yaml

      - name: Check Backward Compatibility
        run: ./scripts/validate-contracts.sh
```

## Best Practices

### 1. Always Validate Responses

Even if the handler logic is correct, validation catches:
- Type system edge cases
- Missing optional fields
- Incorrect enum values

```gleam
// ❌ BAD: No validation
pub fn get_food(req: Request, conn: pog.Connection) -> Response {
  case service.get_food(conn, food_id) {
    Ok(food) -> wisp.json_response(encode_food(food), 200)
    Error(e) -> error_response(e)
  }
}

// ✅ GOOD: Validated response
pub fn get_food(req: Request, conn: pog.Connection) -> Response {
  case service.get_food(conn, food_id) {
    Ok(food) -> {
      let json_obj = contract_validator.food_to_json(food)
      middleware.validate_response(json_obj, schema: "Food", status: 200)
    }
    Error(e) -> error_response(e)
  }
}
```

### 2. Fail Fast on Schema Violations

Schema violations are bugs, not runtime errors:

```gleam
case contract_validator.validate_food_entry_schema(json_obj) {
  Ok(_) -> wisp.json_response(json.to_string(json_obj), 200)
  Error(msg) -> {
    // Log as error (this should never happen in production)
    wisp.log_error("CRITICAL: Response schema violation - " <> msg)
    wisp.internal_server_error()
  }
}
```

### 3. Test Negative Cases

Don't just test happy paths:

```gleam
pub fn missing_required_field_test() {
  let invalid_json = json.object([
    #("food_entry_id", json.string("123")),
    // Missing food_id - REQUIRED field
    #("meal", json.string("lunch")),
  ])

  contract_validator.validate_food_entry_schema(invalid_json)
  |> should.be_error
  |> should.equal("Missing required field: food_id")
}
```

### 4. Document Breaking Changes

When making breaking changes, update:
- OpenAPI spec version
- CHANGELOG.md
- Migration guide
- Deprecation notices

```gleam
// Before deprecation
pub fn legacy_endpoint(req: Request, conn: pog.Connection) -> Response {
  handle_request(req, conn)
}

// After deprecation
pub fn legacy_endpoint(req: Request, conn: pog.Connection) -> Response {
  wisp.log_warning("DEPRECATED: Use /api/v2/endpoint instead")

  handle_request(req, conn)
  |> middleware.add_version_headers(
    version: "1.0.0",
    deprecated: True,
    sunset: "2025-06-30",
  )
}
```

## Troubleshooting

### Common Issues

#### 1. Schema Validation Fails in Production

**Symptom**: Tests pass, but production logs schema violations

**Cause**: Optional fields handled differently in test vs production data

**Fix**: Add property-based tests to catch edge cases

```gleam
import gleam/property_test

pub fn food_entry_property_test() {
  property_test.run(
    property_test.int(),
    fn(random_calories) {
      let entry = FoodEntry(
        ...
        calories: int.to_float(random_calories),
        ...
      )

      let json_obj = contract_validator.food_entry_to_json(entry)
      contract_validator.validate_food_entry_schema(json_obj)
      |> should.be_ok
    }
  )
}
```

#### 2. Performance Impact

**Symptom**: Response times increase after adding validation

**Cause**: JSON serialization/deserialization overhead

**Fix**: Cache schema validators, use streaming validation for large responses

```gleam
// Cache validators at module level
const food_entry_validator = compile_validator("FoodEntry")

pub fn validate_food_entry_schema(json_obj: Json) -> Result(Nil, String) {
  food_entry_validator.validate(json_obj)
}
```

#### 3. Backward Compatibility False Positives

**Symptom**: Compatibility check fails on valid changes

**Cause**: Field reordering or formatting changes

**Fix**: Use semantic comparison, not string comparison

```gleam
pub fn check_backward_compatibility(...) -> Result(Nil, String) {
  // Compare field sets, not JSON strings
  let old_fields = extract_field_names(old_json)
  let new_fields = extract_field_names(new_json)

  // OK if new has all old fields (additions are fine)
  case list.all(old_fields, fn(f) { list.contains(new_fields, f) }) {
    True -> Ok(Nil)
    False -> Error("Breaking change detected")
  }
}
```

## References

- [API Versioning Strategy](/docs/API_VERSIONING_STRATEGY.md)
- [OpenAPI Specification](/openapi.yaml)
- [Contract Validator Source](/src/meal_planner/web/contract_validator.gleam)
- [Validation Middleware Source](/src/meal_planner/web/validation_middleware.gleam)
- [Contract Tests](/test/meal_planner/web/contract_validation_test.gleam)
