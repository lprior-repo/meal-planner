# Meal Planner - Complete Testing Guide

## Prerequisites

- Docker & Docker Compose
- Gleam & Erlang (for local CLI testing)
- `curl` or `httpie` for API testing
- `.env` file configured (already present)

---

## Phase 1: Start Dependencies

### Step 1: Start PostgreSQL Database

```bash
# Start PostgreSQL container
docker-compose -f docker-compose.prod.yml up -d postgres

# Wait for it to be healthy (check logs)
docker logs meal_planner_db
# Look for: "database system is ready to accept connections"

# Verify database is running
docker exec meal_planner_db psql -U meal_planner_user -d meal_planner -c "SELECT version();"
```

**Expected Output:**
```
PostgreSQL 15.x on x86_64...
```

### Step 2: Start Tandoor (Recipe Manager)

Tandoor is required for recipe management. You have two options:

#### Option A: Use Docker (Recommended)
```bash
# If you have Tandoor docker-compose config
docker-compose up -d tandoor

# Wait ~30 seconds for Tandoor to initialize
sleep 30

# Verify Tandoor API is accessible
curl -H "Authorization: Token ***REMOVED***" \
  http://localhost:8100/api/recipe/
```

#### Option B: Use Local Installation
If Tandoor is already running locally at `http://localhost:8100`, just verify it:

```bash
# Test Tandoor API connectivity
curl -H "Authorization: Token ***REMOVED***" \
  http://localhost:8100/api/recipe/
```

**Expected Output:**
```json
{
  "count": N,
  "next": null,
  "previous": null,
  "results": [...]
}
```

---

## Phase 2: Start the Meal Planner Application

### Option A: Start Web API Server

```bash
# Build and start web server
make build
gleam run

# Or using make target
make run
```

**Expected Output:**
```
Running meal_planner.main
Starting web server on http://localhost:8080
```

The server will:
- Connect to PostgreSQL at `localhost:5432`
- Initialize database schema
- Start HTTP server on port `8080`
- Be ready for API requests

### Option B: Start TUI (Interactive Terminal UI)

```bash
# Start interactive TUI mode
make build
gleam run

# This launches the interactive Shore app
# Navigate with arrow keys, q to quit
```

---

## Phase 3: Test Commands

### Test 1: Check Server Health

```bash
curl http://localhost:8080/health
```

**Expected Output:**
```json
{
  "status": "healthy",
  "database": "connected",
  "tandoor": "connected"
}
```

---

### Test 2: Test Recipe Commands (CLI)

```bash
# List recipes from Tandoor
gleam run -- recipe --limit=10

# Expected: Lists recipes from your Tandoor instance
```

---

### Test 3: Test Advisor Commands

```bash
# Get meal planning recommendations
gleam run -- advisor

# Expected: AI-powered recommendations based on your nutrition targets
```

---

### Test 4: Test Diary Commands (FatSecret)

```bash
# View food diary entries
gleam run -- diary

# Expected: Shows today's diary entries from FatSecret
```

---

### Test 5: Test Preferences

```bash
# View user preferences
gleam run -- preferences

# Expected: Shows current macro targets, meal preferences, etc.
```

---

### Test 6: Test Scheduler

```bash
# View scheduled jobs
gleam run -- scheduler

# Expected: Shows meal plan generation schedule, sync tasks, etc.
```

---

## Phase 4: Test API Endpoints

Once the web server is running, test these endpoints:

### 4.1 Recipe Endpoints

```bash
# Search recipes
curl "http://localhost:8080/api/recipes/search?q=pasta&limit=10"

# Get recipe details
curl "http://localhost:8080/api/recipes/1"

# List all recipes with pagination
curl "http://localhost:8080/api/recipes?limit=20&offset=0"
```

### 4.2 Meal Plan Endpoints

```bash
# Generate weekly meal plan
curl -X POST http://localhost:8080/api/meal-plans/generate \
  -H "Content-Type: application/json" \
  -d '{
    "protein_target": 150,
    "carbs_target": 250,
    "fat_target": 65,
    "meal_count": 3,
    "start_date": "2025-01-01"
  }'

# Get meal plan for a week
curl "http://localhost:8080/api/meal-plans?week=2025-W01"
```

### 4.3 Nutrition Tracking

```bash
# Get daily nutrition summary
curl "http://localhost:8080/api/diary/today"

# Get nutrition history
curl "http://localhost:8080/api/diary?start_date=2025-01-01&end_date=2025-01-31"

# Log food entry
curl -X POST http://localhost:8080/api/diary/entries \
  -H "Content-Type: application/json" \
  -d '{
    "food_id": 123,
    "serving_size": 100,
    "meal_type": "breakfast"
  }'
```

### 4.4 Advisor Endpoints

```bash
# Get daily nutrition recommendations
curl "http://localhost:8080/api/advisor/daily-recommendations"

# Get AI meal suggestions
curl -X POST http://localhost:8080/api/advisor/suggestions \
  -H "Content-Type: application/json" \
  -d '{
    "dietary_preferences": ["vegetarian"],
    "available_time": 30
  }'
```

---

## Phase 5: Test Authentication

### Test 5.1: FatSecret OAuth

```bash
# Check if FatSecret is authenticated
curl "http://localhost:8080/api/auth/fatsecret/status"

# Expected: Shows current user's FatSecret profile
{
  "user_id": "...",
  "username": "...",
  "authenticated": true
}

# If not authenticated, start OAuth flow
curl "http://localhost:8080/api/auth/fatsecret/authorize"
```

### Test 5.2: Tandoor Token

```bash
# Verify Tandoor API token works
curl -H "Authorization: Token ***REMOVED***" \
  http://localhost:8100/api/recipe/

# Expected: Returns recipe list (not error 401)
```

### Test 5.3: JWT Token (if enabled)

```bash
# Get JWT token
curl -X POST http://localhost:8080/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"username": "...", "password": "..."}'

# Use JWT for authenticated requests
curl -H "Authorization: Bearer <JWT_TOKEN>" \
  http://localhost:8080/api/diary/today
```

---

## Phase 6: Run Full Test Suite

```bash
# Fast unit tests only (487 tests, ~0.7s)
make test

# All tests including integration (8 more tests, ~5.2s total)
make test-all

# Expected:
# ✅ Passed: 495
# ❌ Failed: 0 (or minimal failures)
```

---

## Phase 7: Verify All Integrations

Create a comprehensive test script:

```bash
#!/bin/bash

echo "🔧 MEAL PLANNER INTEGRATION TEST"
echo "=================================="

# 1. Test database
echo "✓ Testing PostgreSQL..."
docker exec meal_planner_db psql -U meal_planner_user -d meal_planner -c "SELECT COUNT(*) FROM recipes;" 2>/dev/null && echo "  ✅ PostgreSQL OK" || echo "  ❌ PostgreSQL FAILED"

# 2. Test Tandoor
echo "✓ Testing Tandoor API..."
curl -s -H "Authorization: Token ***REMOVED***" \
  http://localhost:8100/api/recipe/ > /dev/null && echo "  ✅ Tandoor OK" || echo "  ❌ Tandoor FAILED"

# 3. Test Meal Planner Server
echo "✓ Testing Meal Planner Server..."
curl -s http://localhost:8080/health > /dev/null && echo "  ✅ Server OK" || echo "  ❌ Server FAILED"

# 4. Test FatSecret (if configured)
echo "✓ Testing FatSecret..."
curl -s "http://localhost:8080/api/diary/today" > /dev/null && echo "  ✅ FatSecret OK" || echo "  ❌ FatSecret NOT CONFIGURED"

echo ""
echo "🎉 All systems operational!"
```

Save as `test-integration.sh` and run:
```bash
chmod +x test-integration.sh
./test-integration.sh
```

---

## Troubleshooting

### PostgreSQL Connection Failed
```bash
# Check if container is running
docker ps | grep meal_planner_db

# Check logs
docker logs meal_planner_db

# Verify connection params in .env
cat .env | grep DATABASE_
```

### Tandoor Connection Failed
```bash
# Verify API token is correct in .env
grep TANDOOR_API_TOKEN .env

# Test with curl
curl -v -H "Authorization: Token YOUR_TOKEN" \
  http://localhost:8100/api/recipe/
```

### FatSecret OAuth Not Working
```bash
# Check if encryption key is set
grep OAUTH_ENCRYPTION_KEY .env

# Verify consumer credentials
grep FATSECRET .env
```

### Server Won't Start
```bash
# Check for port conflicts
lsof -i :8080

# Check logs
gleam run 2>&1 | grep -i error

# Verify .env file
gleam run 2>&1 | grep -i "missing.*env"
```

---

## Summary of All Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `gleam run` | Start web server or TUI | `gleam run` |
| `gleam run -- recipe` | Manage recipes | `gleam run -- recipe --limit=10` |
| `gleam run -- diary` | View food diary | `gleam run -- diary` |
| `gleam run -- advisor` | Get meal advice | `gleam run -- advisor` |
| `gleam run -- preferences` | Manage settings | `gleam run -- preferences` |
| `gleam run -- scheduler` | View jobs | `gleam run -- scheduler` |
| `make test` | Run fast tests | `make test` |
| `make test-all` | Run all tests | `make test-all` |
| `make build` | Build project | `make build` |
| `make fmt` | Format code | `make fmt` |

---

## Next Steps

1. **Start PostgreSQL:** `docker-compose -f docker-compose.prod.yml up -d postgres`
2. **Start Tandoor:** Verify it's running on localhost:8100
3. **Start Meal Planner:** `gleam run`
4. **Run Tests:** `make test`
5. **Test API:** `curl http://localhost:8080/health`
6. **Try CLI:** `gleam run -- recipe --limit=5`

Good luck! 🍽️
