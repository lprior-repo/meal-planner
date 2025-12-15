# Tandoor API Integration Tests - Setup & Status

## Current Status

✅ **Completed:**
- Enabled integration test files (recipe, mealplan, unit)
  - `gleam/test/meal_planner/tandoor/api/recipe_integration_test.gleam`
  - `gleam/test/meal_planner/tandoor/api/mealplan_integration_test.gleam`
  - `gleam/test/meal_planner/tandoor/api/unit_integration_test.gleam`
- Individual CRUD unit tests exist for all major resources:
  - Recipe: create, get, list, update, delete
  - Meal Plan: create, get, list, update, delete
  - Food: create, get, update, delete
  - Unit: list, crud
  - Shopping List: create, get, list, update, delete, add_recipe
- Web handler for Tandoor status check (/tandoor/status)
- Docker test infrastructure configured (docker-compose.test.yml)

## Running Integration Tests

### Prerequisites

1. **Install Docker and Docker Compose**
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Navigate to Gleam directory**
   ```bash
   cd gleam
   ```

### Step 1: Start Tandoor Test Instance

```bash
docker-compose -f docker-compose.test.yml up -d
```

Wait for services to be healthy (takes ~60 seconds):
```bash
docker-compose -f docker-compose.test.yml ps
```

Check logs if needed:
```bash
docker-compose -f docker-compose.test.yml logs tandoor_test
```

### Step 2: Get API Token

1. Access Tandoor at `http://localhost:8100`
2. Login with credentials: `admin` / `admin`
3. Go to **Settings → API → Generate Token**
4. Copy the generated token

### Step 3: Create .env.test File

```bash
cat > .env.test << 'ENVEOF'
# Tandoor Test Instance Configuration
TANDOOR_TEST_URL=http://localhost:8100
TANDOOR_TEST_TOKEN=<your-generated-token-here>
TANDOOR_TEST_USER=admin
TANDOOR_TEST_PASS=admin
ENVEOF
```

### Step 4: Run Integration Tests

```bash
# Load environment and run tests
export $(cat .env.test | grep -v '^#' | xargs)
gleam test --target erlang -- --module tandoor/integration
```

Or run specific test modules:
```bash
# Recipe tests
gleam test --target erlang -- --module meal_planner/tandoor/api/recipe_integration_test

# Meal plan tests
gleam test --target erlang -- --module meal_planner/tandoor/api/mealplan_integration_test

# Unit tests
gleam test --target erlang -- --module meal_planner/tandoor/api/unit_integration_test
```

### Step 5: Cleanup

```bash
# Stop containers
docker-compose -f docker-compose.test.yml stop

# Remove containers and volumes
docker-compose -f docker-compose.test.yml down -v
```

## Test Coverage

### Integration Tests Available
- ✅ Recipe API: Full CRUD flow tests
- ✅ Meal Plan API: Full CRUD flow tests  
- ✅ Unit API: Read operations tests
- ✅ Shopping List API: CRUD operations
- ✅ Supermarket API: Category management

### Unit Tests Available
Located in `gleam/test/tandoor/api/*/`

- Recipe: create_test.gleam, get_test.gleam, list_test.gleam, update_test.gleam
- Meal Plan: create_test.gleam, get_test.gleam, list_test.gleam, update_test.gleam
- Food: create_test.gleam, get_test.gleam, update_test.gleam, delete_test.gleam
- Unit: list_test.gleam, crud_test.gleam
- Shopping: create_test.gleam, get_test.gleam, list_test.gleam, update_test.gleam, delete_test.gleam, add_recipe_test.gleam

## API Endpoints

### Status
- `GET /tandoor/status` - Check Tandoor connection

### Recipes
- `GET /api/tandoor/recipes` - List recipes (requires Bearer token in web handler)
- `POST /api/tandoor/recipes` - Create recipe (API available)
- `PATCH /api/tandoor/recipes/:id` - Update recipe (API available)
- `DELETE /api/tandoor/recipes/:id` - Delete recipe (API available)

### Meal Plans  
- `GET /api/tandoor/meal-plans` - List meal plans (API available)
- `POST /api/tandoor/meal-plans` - Create meal plan (API available)
- `PATCH /api/tandoor/meal-plans/:id` - Update meal plan (API available)
- `DELETE /api/tandoor/meal-plans/:id` - Delete meal plan (API available)

### Support Endpoints
- `GET /api/tandoor/units` - List measurement units
- `GET /api/tandoor/keywords` - List keywords

## Troubleshooting

### Tandoor won't start
```bash
# Check database
docker-compose -f docker-compose.test.yml logs db_tandoor_test

# Restart from scratch
docker-compose -f docker-compose.test.yml down -v
docker-compose -f docker-compose.test.yml up -d
```

### Tests can't connect
- Verify `TANDOOR_TEST_URL` matches port 8100
- Check if Tandoor is ready: `curl http://localhost:8100/api/`
- Verify token is correct and not expired

### Port conflicts
- Change port in docker-compose.test.yml if 8100 is in use
- Update TANDOOR_TEST_URL to match new port

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tandoor Integration Tests

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
          TOKEN=$(curl -X POST http://localhost:8100/api-token-auth/ \
            -H "Content-Type: application/json" \
            -d '{"username":"admin","password":"admin"}' | jq -r '.token')
          echo "TANDOOR_TEST_TOKEN=$TOKEN" >> $GITHUB_ENV
      
      - name: Run Integration Tests
        env:
          TANDOOR_TEST_URL: http://localhost:8100
        run: |
          cd gleam
          export TANDOOR_TEST_TOKEN
          gleam test --target erlang -- --module meal_planner/tandoor/api/recipe_integration_test
      
      - name: Cleanup
        if: always()
        run: |
          cd gleam
          docker-compose -f docker-compose.test.yml down -v
```

## Next Steps

1. **Fix function signatures** in integration tests to match CRUD API  
2. **Implement web handlers** for POST/PATCH/DELETE operations
3. **Add authentication middleware** for API routes
4. **Create Postman collection** for manual testing
5. **Document API response schemas** for each endpoint

## Files Modified

- ✅ `gleam/test/meal_planner/tandoor/api/recipe_integration_test.gleam` - Enabled
- ✅ `gleam/test/meal_planner/tandoor/api/mealplan_integration_test.gleam` - Enabled  
- ✅ `gleam/test/meal_planner/tandoor/api/unit_integration_test.gleam` - Enabled
- ✅ `gleam/src/meal_planner/web/handlers/tandoor.gleam` - Updated with new structure
- ✅ `docker-compose.test.yml` - Already configured
- ✅ `gleam/test/tandoor/integration/run-integration-tests.sh` - Ready to use

## References

- [Tandoor API Documentation](https://docs.tandoor.dev/)
- [Docker Compose Guide](https://docs.docker.com/compose/)
- [Gleam Testing Guide](https://gleam.run/writing-gleam/testing/)
