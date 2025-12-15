# Endpoint Test Harness - Agent Test Scripts

## Setup Instructions

Before running tests, ensure:
```bash
# Services must be running
task start

# Or manually:
gleam build
gleam run  # Start API on port 8080
```

## Agent Test Templates

### Template: Health Check Test
```bash
# Agent 1: Health & Status
curl -s http://localhost:8080/
curl -s http://localhost:8080/health | jq .
```

### Template: OAuth Flow Test
```bash
# Agent 2: OAuth
# 1. Connect
curl -s "http://localhost:8080/fatsecret/connect" -H "Accept: application/json"

# 2. Check status (before callback)
curl -s "http://localhost:8080/fatsecret/status" -H "Accept: application/json"

# 3. Simulate callback (requires token from step 1)
curl -s "http://localhost:8080/fatsecret/callback?oauth_token=TEST&oauth_verifier=TEST"

# 4. Disconnect
curl -X POST "http://localhost:8080/fatsecret/disconnect" -H "Accept: application/json"
```

### Template: Foods API Test
```bash
# Agent 3: Foods
# 2-legged OAuth endpoint - no user auth needed

# Search foods
curl -s "http://localhost:8080/api/fatsecret/foods/search?search_expression=chicken" | jq .

# Get food by ID
curl -s "http://localhost:8080/api/fatsecret/foods/12345678" | jq .
```

### Template: Recipes API Test
```bash
# Agent 4: Recipes
# 2-legged OAuth endpoint - no user auth needed

# List recipe types
curl -s "http://localhost:8080/api/fatsecret/recipes/types" | jq .

# Search recipes
curl -s "http://localhost:8080/api/fatsecret/recipes/search?search_expression=pasta" | jq .

# Search by type
curl -s "http://localhost:8080/api/fatsecret/recipes/search/type/1" | jq .

# Get recipe by ID
curl -s "http://localhost:8080/api/fatsecret/recipes/999888" | jq .
```

### Template: Favorites Foods Test
```bash
# Agent 5: Favorites (Foods)
# 3-legged OAuth - requires user auth

# List favorites
curl -s "http://localhost:8080/api/fatsecret/favorites/foods" \
  -H "Authorization: Bearer TOKEN" | jq .

# Add favorite
curl -X POST "http://localhost:8080/api/fatsecret/favorites/foods/12345678" \
  -H "Authorization: Bearer TOKEN" | jq .

# Get most eaten
curl -s "http://localhost:8080/api/fatsecret/favorites/foods/most-eaten" \
  -H "Authorization: Bearer TOKEN" | jq .

# Get recently eaten
curl -s "http://localhost:8080/api/fatsecret/favorites/foods/recently-eaten" \
  -H "Authorization: Bearer TOKEN" | jq .

# Remove favorite
curl -X DELETE "http://localhost:8080/api/fatsecret/favorites/foods/12345678" \
  -H "Authorization: Bearer TOKEN" | jq .
```

### Template: Saved Meals Test
```bash
# Agent 6: Saved Meals
# 3-legged OAuth

# List saved meals
curl -s "http://localhost:8080/api/fatsecret/saved-meals" \
  -H "Authorization: Bearer TOKEN" | jq .

# Create saved meal
curl -X POST "http://localhost:8080/api/fatsecret/saved-meals" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Meal"}' | jq .

# Get meal items
curl -s "http://localhost:8080/api/fatsecret/saved-meals/123/items" \
  -H "Authorization: Bearer TOKEN" | jq .

# Add item to meal
curl -X POST "http://localhost:8080/api/fatsecret/saved-meals/123/items" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"food_id":12345678}' | jq .

# Edit saved meal
curl -X PUT "http://localhost:8080/api/fatsecret/saved-meals/123" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Meal"}' | jq .

# Delete saved meal
curl -X DELETE "http://localhost:8080/api/fatsecret/saved-meals/123" \
  -H "Authorization: Bearer TOKEN" | jq .
```

### Template: Diary API Test
```bash
# Agent 7: Diary
# 3-legged OAuth - requires user auth

# Create diary entry
curl -X POST "http://localhost:8080/api/fatsecret/diary/entries" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"food_id":"12345678","date":"2024-12-14","calories":500}' | jq .

# Get single entry
curl -s "http://localhost:8080/api/fatsecret/diary/entries/entry123" \
  -H "Authorization: Bearer TOKEN" | jq .

# Get all entries for date
curl -s "http://localhost:8080/api/fatsecret/diary/day/20241214" \
  -H "Authorization: Bearer TOKEN" | jq .

# Get month summary
curl -s "http://localhost:8080/api/fatsecret/diary/month/202412" \
  -H "Authorization: Bearer TOKEN" | jq .

# Edit entry
curl -X PATCH "http://localhost:8080/api/fatsecret/diary/entries/entry123" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"calories":600}' | jq .

# Delete entry
curl -X DELETE "http://localhost:8080/api/fatsecret/diary/entries/entry123" \
  -H "Authorization: Bearer TOKEN" | jq .
```

### Template: Profile Test
```bash
# Agent 8: Profile & Exercise
# 3-legged OAuth

# Get profile
curl -s "http://localhost:8080/api/fatsecret/profile" \
  -H "Authorization: Bearer TOKEN" | jq .

# Search exercises (TODO)
curl -s "http://localhost:8080/api/fatsecret/exercises?q=running" \
  -H "Authorization: Bearer TOKEN" | jq .
```

### Template: AI & Diet APIs Test
```bash
# Agent 12: AI & Diet & Tandoor

# Score recipe
curl -X POST "http://localhost:8080/api/ai/score-recipe" \
  -H "Content-Type: application/json" \
  -d '{"recipe":{"id":"999888","name":"Pasta"}}' | jq .

# Calculate macros
curl -X POST "http://localhost:8080/api/macros/calculate" \
  -H "Content-Type: application/json" \
  -d '{"ingredients":[...]}' | jq .

# Diet compliance check
curl -s "http://localhost:8080/api/diet/vertical/compliance/999888" | jq .

# Tandoor status
curl -s "http://localhost:8080/tandoor/status" | jq .

# List Tandoor recipes
curl -s "http://localhost:8080/api/tandoor/recipes" | jq .

# Create meal plan
curl -X POST "http://localhost:8080/api/tandoor/meal-plan" \
  -H "Content-Type: application/json" \
  -d '{"recipe_id":"999888","date":"2024-12-14"}' | jq .
```

---

## Metrics to Collect per Agent

For each endpoint tested, record:
- **Request method**: GET, POST, PUT, DELETE, PATCH
- **Endpoint path**: /api/...
- **Status code**: 200, 400, 404, 500, etc.
- **Response time**: milliseconds
- **Response size**: bytes
- **Error message**: if applicable
- **Timestamp**: ISO-8601

## Test Result Format

```json
{
  "agent_id": "agent-1",
  "agent_name": "HealthTester",
  "category": "Health & Status",
  "tests": [
    {
      "endpoint": "GET /health",
      "status": "PASS",
      "status_code": 200,
      "response_time_ms": 15,
      "response_size_bytes": 156,
      "timestamp": "2024-12-14T20:30:00Z"
    }
  ],
  "summary": {
    "total_endpoints": 2,
    "passed": 2,
    "failed": 0,
    "todo": 0,
    "avg_response_time_ms": 20
  }
}
```

---

## Parallel Execution Commands

```bash
# Start all 12 agents in parallel
for i in {1..12}; do
  agent_test_$i &
done
wait

# Aggregate results
cat agent_*.json | jq -s 'add'
```

---

## Known Issues & Quirks

### 2-legged vs 3-legged OAuth
- Foods & Recipes use 2-legged (no user auth)
- Favorites, Diary, Profile use 3-legged (requires user auth)
- Tests may fail if OAuth isn't configured properly

### Test Data Limitations
- Some endpoints expect real FatSecret IDs
- Diary entries require valid dates
- Tandoor endpoints depend on separate DB

### Database State
- Tests should be idempotent (no side effects)
- Use transactions for cleanup
- Run against test database
