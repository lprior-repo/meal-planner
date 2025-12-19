# API Versioning Strategy

## Overview

The Meal Planner API follows semantic versioning principles with a focus on backward compatibility and contract-driven development.

## Versioning Scheme

### URL-Based Versioning

All API endpoints include version in the path:

```
/api/v1/fatsecret/foods/search
/api/v2/fatsecret/foods/search
```

### Version Format

- **Major version (v1, v2)**: Breaking changes
- **Minor version (v1.1, v1.2)**: Backward-compatible additions
- **Patch version (v1.1.1, v1.1.2)**: Bug fixes

Major version is included in URL path. Minor/patch versions are tracked internally but don't affect routing.

## Breaking vs Non-Breaking Changes

### Breaking Changes (Require Major Version Bump)

1. **Removed fields** from response
   ```json
   // v1 - BEFORE
   {"food_id": "123", "deprecated_field": "value"}

   // v2 - AFTER (BREAKING)
   {"food_id": "123"}  // deprecated_field removed
   ```

2. **Required field additions** to request
   ```json
   // v1 - BEFORE
   {"food_id": "123"}

   // v2 - AFTER (BREAKING)
   {"food_id": "123", "required_new_field": "value"}
   ```

3. **Type changes**
   ```json
   // v1 - BEFORE
   {"calories": "100"}  // string

   // v2 - AFTER (BREAKING)
   {"calories": 100}  // number
   ```

4. **Enum value removals**
   ```json
   // v1 - BEFORE
   {"meal": "breakfast|lunch|dinner|snack"}

   // v2 - AFTER (BREAKING)
   {"meal": "breakfast|lunch|dinner"}  // snack removed
   ```

5. **Endpoint URL changes**
   ```
   v1: POST /api/v1/diary/entries
   v2: POST /api/v2/food-entries  // BREAKING - URL changed
   ```

### Non-Breaking Changes (Minor/Patch Version)

1. **Optional field additions** to response
   ```json
   // v1.0
   {"food_id": "123"}

   // v1.1 (NON-BREAKING)
   {"food_id": "123", "new_optional_field": "value"}
   ```

2. **Optional parameter additions** to request
   ```json
   // v1.0
   POST /api/v1/foods/search?q=apple

   // v1.1 (NON-BREAKING)
   POST /api/v1/foods/search?q=apple&filter=organic
   ```

3. **Enum value additions**
   ```json
   // v1.0
   {"meal": "breakfast|lunch|dinner"}

   // v1.1 (NON-BREAKING)
   {"meal": "breakfast|lunch|dinner|snack"}  // snack added
   ```

4. **Bug fixes** that don't change contract
   - Performance improvements
   - Error message improvements
   - Internal logic fixes

## Deprecation Policy

### Timeline

1. **Deprecation Announcement**: Minimum 6 months notice
2. **Deprecation Headers**: Response includes deprecation warning
   ```http
   Deprecated: true
   Sunset: 2025-12-31
   Link: </api/v2/foods/search>; rel="successor-version"
   ```
3. **Grace Period**: Old version supported for 12 months minimum
4. **Sunset**: Old version removed after grace period

### Example Deprecation Flow

```
Month 0:  v2 released, v1 marked deprecated
Month 6:  Warning logs for v1 usage
Month 12: v1 sunset announced (3 months notice)
Month 15: v1 removed
```

## Migration Support

### Parallel Version Support

During migration periods, both versions run simultaneously:

```gleam
// src/meal_planner/web/routes.gleam
pub fn router(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    // v1 endpoints (deprecated)
    ["api", "v1", "foods", "search"] -> v1.handle_food_search(req, conn)

    // v2 endpoints (current)
    ["api", "v2", "foods", "search"] -> v2.handle_food_search(req, conn)

    // Latest (redirects to current major version)
    ["api", "foods", "search"] -> v2.handle_food_search(req, conn)

    _ -> wisp.not_found()
  }
}
```

### Automated Migration Tools

Clients can use migration tools:

```bash
# Check what would break
curl -X POST /api/v1/foods/search \
  -H "X-Check-Migration: v2" \
  -d '{"q": "apple"}'

# Response includes migration warnings
{
  "data": {...},
  "migration_warnings": [
    "Field 'deprecated_field' will be removed in v2",
    "New required field 'source' will be added in v2"
  ]
}
```

## Contract Testing

### Pre-Deployment Validation

Before deploying any API changes:

1. **Schema validation** - All responses validated against OpenAPI spec
2. **Backward compatibility tests** - Automated tests detect breaking changes
3. **Contract tests** - Consumer-driven contract tests run

```gleam
// test/meal_planner/web/contract_validation_test.gleam
pub fn test_food_search_backward_compatible() {
  let v1_response = get_v1_food_search_response()
  let v2_response = get_v2_food_search_response()

  contract_validator.check_backward_compatibility(
    schema_name: "FoodSearchResponse",
    old_version: "1.0",
    new_version: "2.0",
    old_json: v1_response,
    new_json: v2_response,
  )
  |> should.be_ok  // Fails if breaking change detected
}
```

### OpenAPI Spec Validation

Every response is validated:

```gleam
pub fn handle_food_search(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.require_method(req, Get)

  case service.search_foods(conn, query) {
    Ok(results) -> {
      let response_json = contract_validator.food_search_response_to_json(results)

      // Validate against schema before sending
      case contract_validator.validate_food_search_response_schema(response_json) {
        Ok(_) -> wisp.json_response(json.to_string(response_json), 200)
        Error(msg) -> {
          // Schema violation - log error and return 500
          logger.error("Schema violation: " <> msg)
          wisp.internal_server_error()
        }
      }
    }
    Error(e) -> error_response(e)
  }
}
```

## Version Detection

### Request Headers

Clients can specify version preference:

```http
GET /api/foods/search?q=apple
Accept: application/vnd.mealplanner.v2+json
```

If no version specified, defaults to latest stable.

### Response Headers

All responses include version information:

```http
HTTP/1.1 200 OK
API-Version: 2.1.0
Deprecated: false
Content-Type: application/json
```

## Current API Status

### v1 (Current Stable)

- **Status**: Production
- **Endpoints**: All FatSecret and Tandoor integrations
- **Sunset**: No sunset planned
- **OpenAPI**: `/openapi.yaml`

### v2 (Planning)

- **Status**: Not yet implemented
- **Planned Changes**:
  - Consolidated error responses
  - Improved pagination metadata
  - Enhanced nutrition data structures
- **Target Release**: Q2 2025

## Tooling

### Schema Validation

```bash
# Validate OpenAPI spec
make validate-openapi

# Run contract tests
make test-contracts

# Check for breaking changes
make check-compatibility
```

### Code Generation

OpenAPI spec used for:
- TypeScript client generation
- API documentation
- Mock server generation
- Contract test generation

## Best Practices

### For API Developers

1. **Never remove fields** from responses
2. **Always make new fields optional** initially
3. **Add deprecation warnings** before removing features
4. **Run contract tests** before merging
5. **Update OpenAPI spec** first, then implement

### For API Consumers

1. **Don't rely on field order**
2. **Ignore unknown fields** (forward compatibility)
3. **Handle optional fields** gracefully
4. **Pin to major version** in production
5. **Test against latest** in staging

## References

- OpenAPI Specification: `/openapi.yaml`
- Contract Validator: `src/meal_planner/web/contract_validator.gleam`
- Contract Tests: `test/meal_planner/web/contract_validation_test.gleam`
- Semantic Versioning: https://semver.org/
