# Tandoor SDK Integration Tests

This directory contains comprehensive integration tests for the Tandoor SDK.

## Overview

The integration tests cover the full CRUD lifecycle for all major Tandoor API domains:

- **Recipe API** (`recipe_integration_test.gleam`)
  - Full CRUD flow (Create, Read, Update, Delete)
  - Pagination
  - Complex recipes with ingredients
  - Authentication (Bearer + Session)
  - Error handling (404, 401, network errors)

- **Food API** (`food_integration_test.gleam`)
  - Full CRUD flow
  - Pagination
  - Bulk operations
  - Error handling

- **Unit API** (`unit_integration_test.gleam`)
  - Read operations (units are system-managed)
  - Pagination
  - Data validation
  - Error handling

- **Shopping List API** (`shopping_integration_test.gleam`)
  - CRUD operations for shopping list entries
  - Pagination
  - Bulk operations
  - Shopping workflow tests

- **Supermarket API** (`supermarket_integration_test.gleam`)
  - Supermarket CRUD
  - Supermarket Category CRUD
  - Hierarchical relationships
  - Error handling

## Prerequisites

### Running Tandoor Test Instance

These tests require a running Tandoor instance. We provide a Docker Compose setup for easy testing:

```bash
# Start Tandoor test instance
cd gleam
docker-compose -f docker-compose.test.yml up -d

# Wait for services to be healthy (takes ~60 seconds)
docker-compose -f docker-compose.test.yml ps

# Check logs
docker-compose -f docker-compose.test.yml logs -f tandoor_test
```

The test instance will be available at:
- **URL**: `http://localhost:8100`
- **Default credentials**: admin / admin

### Getting API Token

1. Access Tandoor at `http://localhost:8100`
2. Login with admin/admin
3. Go to Settings → API → Generate Token
4. Copy the token

### Setting Environment Variables

Create a `.env.test` file in the gleam directory:

```bash
# Tandoor Test Instance
TANDOOR_TEST_URL=http://localhost:8100
TANDOOR_TEST_TOKEN=your-api-token-here

# Optional: Session auth credentials
TANDOOR_TEST_USER=admin
TANDOOR_TEST_PASS=admin
```

## Running Integration Tests

### Run All Integration Tests

```bash
cd gleam
gleam test --target erlang -- --module tandoor/integration
```

### Run Specific Test Suite

```bash
# Recipe tests
gleam test --target erlang -- --module tandoor/integration/recipe_integration_test

# Food tests
gleam test --target erlang -- --module tandoor/integration/food_integration_test

# Unit tests
gleam test --target erlang -- --module tandoor/integration/unit_integration_test

# Shopping tests
gleam test --target erlang -- --module tandoor/integration/shopping_integration_test

# Supermarket tests
gleam test --target erlang -- --module tandoor/integration/supermarket_integration_test
```

### Run Individual Test

```bash
gleam test --target erlang -- --module tandoor/integration/recipe_integration_test --function recipe_crud_flow_bearer_test
```

## Test Structure

Each integration test follows this pattern:

1. **Setup**: Create test client configuration
2. **Create**: Create test data via API
3. **Verify**: Fetch and verify the created data
4. **Update**: Modify data via API (if applicable)
5. **Delete**: Clean up test data
6. **Assert**: Verify deletion succeeded

### Example Test Flow

```gleam
pub fn recipe_crud_flow_bearer_test() {
  let config = bearer_test_config()
  
  // Create
  let assert Ok(created_recipe) = create.create_recipe(config, recipe_data)
  
  // Read
  let assert Ok(fetched_recipe) = get.get_recipe(config, created_recipe.id)
  
  // Update
  let assert Ok(updated_recipe) = update.update_recipe(config, created_recipe.id, updated_data)
  
  // Delete
  let assert Ok(_) = delete.delete_recipe(config, created_recipe.id)
  
  // Verify deletion
  let delete_result = get.get_recipe(config, created_recipe.id)
  delete_result |> should.be_error
}
```

## Error Handling Tests

Each test suite includes error handling tests:

- **404 Not Found**: Test with non-existent resource IDs
- **401 Unauthorized**: Test with invalid authentication
- **Network Errors**: Test with unreachable server

## Authentication Tests

Tests verify both authentication methods:

- **Bearer Token**: Standard API token authentication
- **Session Auth**: Username/password authentication with session cookies

## Cleanup

The tests include cleanup helpers to ensure test data doesn't accumulate:

```gleam
fn cleanup_recipe(config: ClientConfig, recipe_id: Int) -> Nil {
  let _result = delete.delete_recipe(config, recipe_id)
  Nil
}
```

Even if tests fail, cleanup is attempted to maintain test isolation.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start Tandoor Test Instance
        run: |
          cd gleam
          docker-compose -f docker-compose.test.yml up -d
          
      - name: Wait for Tandoor
        run: |
          timeout 120 bash -c 'until curl -f http://localhost:8100/api/; do sleep 5; done'
      
      - name: Get API Token
        run: |
          # Use Tandoor API to create token
          TOKEN=$(curl -X POST http://localhost:8100/api-token-auth/ \
            -H "Content-Type: application/json" \
            -d '{"username":"admin","password":"admin"}' | jq -r '.token')
          echo "TANDOOR_TEST_TOKEN=$TOKEN" >> $GITHUB_ENV
      
      - name: Run Integration Tests
        env:
          TANDOOR_TEST_URL: http://localhost:8100
        run: |
          cd gleam
          gleam test --target erlang -- --module tandoor/integration
      
      - name: Cleanup
        if: always()
        run: |
          cd gleam
          docker-compose -f docker-compose.test.yml down -v
```

## Troubleshooting

### Tests Fail with Connection Error

**Problem**: Cannot connect to Tandoor instance

**Solutions**:
1. Check Tandoor is running: `docker-compose -f docker-compose.test.yml ps`
2. Check logs: `docker-compose -f docker-compose.test.yml logs tandoor_test`
3. Verify URL in `.env.test` matches Docker port (default: `http://localhost:8100`)

### Tests Fail with 401 Unauthorized

**Problem**: API token is invalid

**Solutions**:
1. Generate new token in Tandoor UI
2. Update `TANDOOR_TEST_TOKEN` in `.env.test`
3. Verify token format (should be a long alphanumeric string)

### Tests Fail with 404 Not Found

**Problem**: API endpoint not found

**Solutions**:
1. Verify Tandoor version matches SDK expectations
2. Check API endpoint paths in test code
3. Ensure Tandoor has completed initialization

### Docker Container Won't Start

**Problem**: Tandoor container exits or won't start

**Solutions**:
1. Check database health: `docker-compose -f docker-compose.test.yml logs db_tandoor_test`
2. Verify ports 8100 and 5433 are not in use
3. Remove volumes and restart: `docker-compose -f docker-compose.test.yml down -v && docker-compose -f docker-compose.test.yml up -d`

## Test Coverage

Current test coverage:

- ✅ Recipe API: Full CRUD + Pagination + Error Handling
- ✅ Food API: Full CRUD + Pagination + Error Handling
- ✅ Unit API: Read operations + Pagination + Error Handling
- ✅ Shopping List API: Full CRUD + Pagination + Workflow
- ✅ Supermarket API: Full CRUD + Pagination + Relationships
- ⏳ Meal Plan API: Planned
- ⏳ Keyword API: Planned
- ⏳ Import/Export API: Planned

## Contributing

When adding new integration tests:

1. Follow the existing test structure (Setup, Create, Verify, Update, Delete, Assert)
2. Include cleanup helpers to prevent test data accumulation
3. Add error handling tests (404, 401, network errors)
4. Test pagination if the API supports it
5. Update this README with test coverage information

## Resources

- [Tandoor API Documentation](https://docs.tandoor.dev/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Gleam Testing Documentation](https://gleam.run/writing-gleam/testing/)
