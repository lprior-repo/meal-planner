# API Endpoint Coverage Matrix

**Generated:** 2025-12-14
**Purpose:** Complete overview of all API endpoints with test coverage status
**Priority:** P1 - Critical Documentation

---

## Coverage Summary

| Category | Total Endpoints | Tested | Untested | Coverage % |
|----------|----------------|--------|----------|------------|
| Health | 2 | 0 | 2 | 0% |
| Dashboard | 2 | 0 | 2 | 0% |
| Food Logging | 2 | 0 | 2 | 0% |
| AI/Recipe Scoring | 1 | 0 | 1 | 0% |
| Diet Compliance | 1 | 0 | 1 | 0% |
| Macros | 1 | 0 | 1 | 0% |
| FatSecret OAuth | 4 | 0 | 4 | 0% |
| FatSecret Profile | 2 | 0 | 2 | 0% |
| FatSecret Recipes | 4 | 0 | 4 | 0% |
| FatSecret Foods | 2 | 0 | 2 | 0% |
| Tandoor Status | 1 | 0 | 1 | 0% |
| Tandoor Recipes | 2 | 0 | 2 | 0% |
| Tandoor Meal Plans | 3 | 0 | 3 | 0% |
| **TOTAL** | **27** | **0** | **27** | **0%** |

> **Note:** This matrix covers HTTP endpoint handlers only. Unit tests exist for 73 internal modules (Tandoor API, decoders, encoders, types, etc.) but do not test the web layer endpoints directly.

---

## 1. Health & Status Endpoints

### 1.1 Health Check
- **Endpoint:** `GET /` or `GET /health`
- **Handler:** `meal_planner/web/handlers/health.handle()`
- **Function:** Returns service health status
- **Request:** None
- **Response:** `{ "status": "healthy", "service": "meal-planner", "version": "1.0.0" }`
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/health_test.gleam`
- **Priority:** P2
- **Notes:** Basic health check, low complexity

### 1.2 Tandoor Status
- **Endpoint:** `GET /tandoor/status`
- **Handler:** `handlers.handle_tandoor_status()`
- **Function:** Check Tandoor Recipe Manager connectivity
- **Request:** None
- **Response:** JSON status object
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_status_test.gleam`
- **Priority:** P2
- **Notes:** Integration endpoint

---

## 2. Dashboard & UI Endpoints

### 2.1 Dashboard UI
- **Endpoint:** `GET /dashboard`
- **Handler:** `handlers.handle_dashboard(req, ctx.db)`
- **Function:** Render dashboard HTML with nutrition tracking
- **Request:** None
- **Response:** HTML page
- **Test Coverage:** ❌ None (501 Not Implemented)
- **Implementation Status:** 🔴 Not Implemented
- **Test File Needed:** `gleam/test/web/handlers/dashboard_test.gleam`
- **Priority:** P3
- **Notes:** Handler returns 501, needs implementation first

### 2.2 Dashboard Data API
- **Endpoint:** `GET /api/dashboard/data`
- **Handler:** `handlers.handle_dashboard_data(req, ctx.db)`
- **Function:** Fetch dashboard data (JSON)
- **Request:** None
- **Response:** JSON nutrition data
- **Test Coverage:** ❌ None (501 Not Implemented)
- **Implementation Status:** 🔴 Not Implemented
- **Test File Needed:** `gleam/test/web/handlers/dashboard_data_test.gleam`
- **Priority:** P3
- **Notes:** Handler returns 501, needs implementation first

---

## 3. Food Logging Endpoints

### 3.1 Log Food Form UI
- **Endpoint:** `GET /log/food/{fdc_id}`
- **Handler:** `handlers.handle_log_food_form(req, ctx.db, fdc_id)`
- **Function:** Render food logging form
- **Request:** Path parameter `fdc_id`
- **Response:** HTML form
- **Test Coverage:** ❌ None (501 Not Implemented)
- **Implementation Status:** 🔴 Not Implemented
- **Test File Needed:** `gleam/test/web/handlers/log_food_form_test.gleam`
- **Priority:** P3
- **Notes:** Handler returns 501, needs implementation first

### 3.2 Log Food API
- **Endpoint:** `POST /api/logs/food`
- **Handler:** `handlers.handle_log_food(req, ctx.db)`
- **Function:** Submit food log entry
- **Request:** JSON food log data
- **Response:** JSON confirmation
- **Test Coverage:** ❌ None (501 Not Implemented)
- **Implementation Status:** 🔴 Not Implemented
- **Test File Needed:** `gleam/test/web/handlers/log_food_test.gleam`
- **Priority:** P3
- **Notes:** Handler returns 501, needs implementation first

---

## 4. AI & Recipe Analysis Endpoints

### 4.1 AI Recipe Scoring
- **Endpoint:** `POST /api/ai/score-recipe`
- **Handler:** `handlers.handle_score_recipe(req)`
- **Function:** AI-powered recipe nutritional scoring
- **Request:** JSON recipe data
- **Response:** JSON scoring result
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/recipes_test.gleam`
- **Priority:** P1
- **Notes:** Core feature, high value

---

## 5. Diet Compliance Endpoints

### 5.1 Vertical Diet Compliance Check
- **Endpoint:** `GET /api/diet/vertical/compliance/{recipe_id}`
- **Handler:** `handlers.handle_diet_compliance(req, recipe_id)`
- **Function:** Check recipe compliance with Vertical Diet
- **Request:** Path parameter `recipe_id`
- **Response:** JSON compliance analysis
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/diet_test.gleam`
- **Priority:** P1
- **Notes:** Core feature for diet tracking

---

## 6. Macro Calculation Endpoints

### 6.1 Calculate Macros
- **Endpoint:** `POST /api/macros/calculate`
- **Handler:** `handlers.handle_macros_calculate(req)`
- **Function:** Calculate macronutrients for meals
- **Request:** JSON meal data
- **Response:** JSON macro breakdown
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/macros_test.gleam`
- **Priority:** P1
- **Notes:** Core nutrition feature

---

## 7. FatSecret OAuth & Authentication Endpoints

### 7.1 OAuth Connect (Start Flow)
- **Endpoint:** `GET /fatsecret/connect`
- **Handler:** `handlers.handle_fatsecret_connect(req, ctx.db, base_url)`
- **Function:** Initiate OAuth 1.0a flow, redirect to FatSecret
- **Request:** None
- **Response:** HTTP 302 redirect
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_oauth_test.gleam`
- **Priority:** P1
- **Notes:** Critical auth flow, needs mocking

### 7.2 OAuth Callback
- **Endpoint:** `GET /fatsecret/callback`
- **Handler:** `handlers.handle_fatsecret_callback(req, ctx.db)`
- **Function:** Handle OAuth callback, exchange tokens
- **Request:** Query params `oauth_token`, `oauth_verifier`
- **Response:** HTML success/error page
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_oauth_test.gleam`
- **Priority:** P1
- **Notes:** Critical auth flow, complex error handling

### 7.3 Connection Status
- **Endpoint:** `GET /fatsecret/status`
- **Handler:** `handlers.handle_fatsecret_status(req, ctx.db)`
- **Function:** Display FatSecret connection status page
- **Request:** None
- **Response:** HTML status page
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_status_test.gleam`
- **Priority:** P2
- **Notes:** UI endpoint, validate status checks

### 7.4 Disconnect
- **Endpoint:** `POST /fatsecret/disconnect`
- **Handler:** `handlers.handle_fatsecret_disconnect(req, ctx.db)`
- **Function:** Remove stored access token
- **Request:** None (form POST)
- **Response:** JSON success/error
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_disconnect_test.gleam`
- **Priority:** P2
- **Notes:** Token deletion, database cleanup

---

## 8. FatSecret Profile & Diary Endpoints (3-Legged Auth Required)

### 8.1 Get User Profile
- **Endpoint:** `GET /api/fatsecret/profile`
- **Handler:** `handlers.handle_fatsecret_profile(req, ctx.db)`
- **Function:** Fetch authenticated user's FatSecret profile
- **Request:** None (requires valid access token in DB)
- **Response:** JSON user profile
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_profile_test.gleam`
- **Priority:** P1
- **Error Cases:** 401 not connected, 401 auth revoked, 500 config missing
- **Notes:** Requires OAuth token validation

### 8.2 Get Food Diary Entries
- **Endpoint:** `GET /api/fatsecret/entries?date=YYYY-MM-DD`
- **Handler:** `handlers.handle_fatsecret_entries(req, ctx.db)`
- **Function:** Fetch food diary entries for specific date
- **Request:** Query param `date` (YYYY-MM-DD)
- **Response:** JSON food entries
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_entries_test.gleam`
- **Priority:** P1
- **Error Cases:** 400 missing date, 401 not connected
- **Notes:** Critical diary sync feature

---

## 9. FatSecret Recipes API (2-Legged, No Auth)

### 9.1 Get Recipe Types
- **Endpoint:** `GET /api/fatsecret/recipes/types`
- **Handler:** `handlers.handle_fatsecret_recipe_types(req)`
- **Function:** List available recipe categories
- **Request:** None
- **Response:** JSON recipe type list
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_recipes_test.gleam`
- **Priority:** P2
- **Notes:** Public API, no auth required

### 9.2 Search Recipes
- **Endpoint:** `GET /api/fatsecret/recipes/search?search_expression={query}&max_results={n}`
- **Handler:** `handlers.handle_fatsecret_search_recipes(req)`
- **Function:** Search recipes by keyword
- **Request:** Query params `search_expression`, optional `max_results`
- **Response:** JSON recipe search results
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_recipes_test.gleam`
- **Priority:** P2
- **Notes:** Public API, pagination support

### 9.3 Search Recipes by Type
- **Endpoint:** `GET /api/fatsecret/recipes/search/type/{type_id}?max_results={n}`
- **Handler:** `handlers.handle_fatsecret_search_recipes_by_type(req, type_id)`
- **Function:** Filter recipes by category
- **Request:** Path param `type_id`, query param `max_results`
- **Response:** JSON recipe list
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_recipes_test.gleam`
- **Priority:** P2
- **Notes:** Category filtering

### 9.4 Get Recipe Details
- **Endpoint:** `GET /api/fatsecret/recipes/{recipe_id}`
- **Handler:** `handlers.handle_fatsecret_get_recipe(req, recipe_id)`
- **Function:** Fetch complete recipe with nutrition
- **Request:** Path param `recipe_id`
- **Response:** JSON recipe details
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_recipes_test.gleam`
- **Priority:** P1
- **Notes:** Core recipe lookup

---

## 10. FatSecret Foods API (2-Legged, No Auth)

### 10.1 Search Foods
- **Endpoint:** `GET /api/fatsecret/foods/search?search_expression={query}&max_results={n}`
- **Handler:** `handlers.handle_fatsecret_search_foods(req)`
- **Function:** Search foods by name/keyword
- **Request:** Query params `search_expression`, optional `max_results`
- **Response:** JSON food search results
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_foods_test.gleam`
- **Priority:** P1
- **Notes:** Critical food database search

### 10.2 Get Food Details
- **Endpoint:** `GET /api/fatsecret/foods/{food_id}`
- **Handler:** `handlers.handle_fatsecret_get_food(req, food_id)`
- **Function:** Fetch complete food nutrition data
- **Request:** Path param `food_id`
- **Response:** JSON food details with nutrition
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/fatsecret_foods_test.gleam`
- **Priority:** P1
- **Notes:** Nutrition data lookup

---

## 11. Tandoor Recipe Manager Endpoints

### 11.1 List Recipes
- **Endpoint:** `GET /api/tandoor/recipes?page={n}&page_size={n}`
- **Handler:** `handlers.handle_tandoor_list_recipes(req)`
- **Function:** List recipes from Tandoor
- **Request:** Query params `page`, `page_size`
- **Response:** JSON paginated recipe list
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_recipes_test.gleam`
- **Priority:** P2
- **Notes:** Integration with Tandoor API
- **Related Unit Tests:** `tandoor/api/recipe/list_test.gleam` (SDK only)

### 11.2 Get Recipe
- **Endpoint:** `GET /api/tandoor/recipes/{recipe_id}`
- **Handler:** `handlers.handle_tandoor_get_recipe(req, recipe_id)`
- **Function:** Fetch single recipe details
- **Request:** Path param `recipe_id`
- **Response:** JSON recipe object
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_recipes_test.gleam`
- **Priority:** P2
- **Notes:** Recipe detail view
- **Related Unit Tests:** `tandoor/api/recipe/get_test.gleam` (SDK only)

---

## 12. Tandoor Meal Plan Endpoints

### 12.1 Get Meal Plan
- **Endpoint:** `GET /api/tandoor/meal-plan?date={YYYY-MM-DD}`
- **Handler:** `handlers.handle_tandoor_get_meal_plan(req)`
- **Function:** Fetch meal plan for date range
- **Request:** Query param `date`
- **Response:** JSON meal plan entries
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_meal_plan_test.gleam`
- **Priority:** P1
- **Notes:** Core meal planning feature
- **Related Unit Tests:** `tandoor/api/mealplan/get_test.gleam` (SDK only)

### 12.2 Create Meal Plan Entry
- **Endpoint:** `POST /api/tandoor/meal-plan`
- **Handler:** `handlers.handle_tandoor_create_meal_plan(req)`
- **Function:** Add recipe to meal plan
- **Request:** JSON meal plan entry
- **Response:** JSON created entry
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_meal_plan_test.gleam`
- **Priority:** P1
- **Notes:** Critical planning feature
- **Related Unit Tests:** `tandoor/api/mealplan/create_test.gleam` (SDK only)

### 12.3 Delete Meal Plan Entry
- **Endpoint:** `DELETE /api/tandoor/meal-plan/{entry_id}`
- **Handler:** `handlers.handle_tandoor_delete_meal_plan(req, entry_id)`
- **Function:** Remove entry from meal plan
- **Request:** Path param `entry_id`
- **Response:** 204 No Content
- **Test Coverage:** ❌ None
- **Test File Needed:** `gleam/test/web/handlers/tandoor_meal_plan_test.gleam`
- **Priority:** P2
- **Notes:** Plan management

---

## Test Coverage Analysis

### Current State
- **Web Handler Tests:** 0/27 endpoints (0%)
- **Unit Tests (SDK/Internal):** 73 test files covering internal modules
- **Gap:** HTTP routing layer completely untested

### Why Zero Coverage?
1. **Unit tests focus on SDK layer:** Tandoor API client, decoders, encoders
2. **No integration tests for web layer:** HTTP handlers not tested end-to-end
3. **No request/response validation:** Query params, path params, error cases untested
4. **OAuth flows untested:** Complex authentication flows have no coverage

### Priority Test Files to Create

#### P1 - Critical (Must Have)
1. **`gleam/test/web/handlers/fatsecret_oauth_test.gleam`**
   - Test OAuth connect flow
   - Test callback handling (success & error cases)
   - Test token storage/retrieval
   - Mock FatSecret API responses

2. **`gleam/test/web/handlers/fatsecret_profile_test.gleam`**
   - Test authenticated profile fetch
   - Test 401 error cases (not connected, revoked)
   - Mock OAuth token validation

3. **`gleam/test/web/handlers/fatsecret_entries_test.gleam`**
   - Test date parameter validation
   - Test diary entry retrieval
   - Test error handling

4. **`gleam/test/web/handlers/fatsecret_foods_test.gleam`**
   - Test food search with various queries
   - Test food detail retrieval
   - Test pagination

5. **`gleam/test/web/handlers/fatsecret_recipes_test.gleam`**
   - Test recipe search
   - Test recipe types listing
   - Test recipe detail fetch

6. **`gleam/test/web/handlers/tandoor_meal_plan_test.gleam`**
   - Test GET/POST/DELETE meal plan operations
   - Test date filtering
   - Test error handling

7. **`gleam/test/web/handlers/recipes_test.gleam`**
   - Test AI recipe scoring
   - Test input validation

8. **`gleam/test/web/handlers/diet_test.gleam`**
   - Test vertical diet compliance checks
   - Test recipe ID validation

9. **`gleam/test/web/handlers/macros_test.gleam`**
   - Test macro calculations
   - Test input validation

#### P2 - Important (Should Have)
10. **`gleam/test/web/handlers/health_test.gleam`**
    - Test health check responses

11. **`gleam/test/web/handlers/tandoor_recipes_test.gleam`**
    - Test recipe listing with pagination
    - Test recipe detail fetch

12. **`gleam/test/web/handlers/fatsecret_status_test.gleam`**
    - Test status page rendering
    - Test connection validation

#### P3 - Nice to Have (When Implemented)
13. **`gleam/test/web/handlers/dashboard_test.gleam`** (when implemented)
14. **`gleam/test/web/handlers/log_food_test.gleam`** (when implemented)

---

## Testing Strategy Recommendations

### 1. Integration Test Setup
Create `gleam/test/integration_test_helper.gleam` with:
- Mock HTTP client for FatSecret API
- Mock Tandoor API responses
- Test database setup/teardown
- OAuth token fixtures

### 2. Test Pattern
```gleam
// Example test structure
import gleam/http
import gleeunit/should
import wisp/testing

pub fn test_get_recipe_success() {
  let req = testing.get("/api/fatsecret/recipes/12345")
  let response = handlers.handle_fatsecret_get_recipe(req, "12345")

  response.status |> should.equal(200)
  response.headers |> should.contain(#("content-type", "application/json"))
  // Assert response body contains recipe data
}

pub fn test_get_recipe_not_found() {
  let req = testing.get("/api/fatsecret/recipes/invalid")
  let response = handlers.handle_fatsecret_get_recipe(req, "invalid")

  response.status |> should.equal(404)
}
```

### 3. Mock Strategy
- **FatSecret API:** Mock HTTP responses for 2-legged and 3-legged calls
- **Database:** Use test database with fixtures
- **OAuth:** Pre-populate test tokens in database
- **Tandoor API:** Mock SDK responses

### 4. Coverage Goals
- **Phase 1 (P1):** 100% coverage of critical endpoints (9 test files)
- **Phase 2 (P2):** Add important endpoints (3 test files)
- **Phase 3 (P3):** Add nice-to-have when features implemented (2 test files)

---

## Implementation Notes

### Existing Test Infrastructure
- **Unit tests:** 73 files covering Tandoor SDK, decoders, encoders
- **Test helpers:** `integration_test_helper.gleam`, `test_setup.gleam`
- **Tandoor test builders:** `tandoor/testing/builders.gleam`

### What's Missing
1. HTTP request/response testing utilities
2. Mock HTTP client for external APIs
3. Test fixtures for OAuth tokens
4. Integration test database setup
5. Wisp test harness setup

### Dependencies
- `wisp/testing` - HTTP testing utilities
- Mock libraries for external API calls
- Test database migration strategy

---

## Appendix: HTTP Method Summary

| Method | Count | Endpoints |
|--------|-------|-----------|
| GET | 20 | Health, status, recipes, foods, meal plans, profile, entries |
| POST | 5 | Score recipe, calculate macros, log food, create meal plan, disconnect |
| DELETE | 1 | Delete meal plan entry |
| **Total** | **26** | (Plus 1 dual GET/POST route) |

---

## Next Steps

1. **Create test directory structure:**
   ```bash
   mkdir -p gleam/test/web/handlers
   ```

2. **Implement P1 test files** (9 files, ~18-27 tests minimum)

3. **Set up test infrastructure:**
   - HTTP test helpers
   - Mock FatSecret API client
   - Mock Tandoor API client
   - Test database fixtures

4. **Run coverage analysis:**
   ```bash
   gleam test --coverage
   ```

5. **Iterate on P2 and P3** as features stabilize

---

**End of Coverage Matrix**
