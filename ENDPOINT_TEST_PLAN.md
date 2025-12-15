# Endpoint Testing Plan - 12 Agent Parallel Distribution

## Summary
**Total Endpoints:** 45+
**Test Agents:** 12
**Distribution Strategy:** Group by API domain

---

## Agent 1: Health & Status (2 endpoints)
- `GET /` - Homepage/health check
- `GET /health` - Health status

## Agent 2: FatSecret OAuth (4 endpoints)
- `GET /fatsecret/connect` - Start OAuth flow
- `GET /fatsecret/callback` - OAuth callback handler
- `GET /fatsecret/status` - Check auth status
- `POST /fatsecret/disconnect` - Disconnect account

## Agent 3: FatSecret Foods API (2 endpoints)
- `GET /api/fatsecret/foods/search` - Search foods
- `GET /api/fatsecret/foods/:id` - Get food details

## Agent 4: FatSecret Recipes API (4 endpoints)
- `GET /api/fatsecret/recipes/types` - List recipe types
- `GET /api/fatsecret/recipes/search` - Search recipes
- `GET /api/fatsecret/recipes/search/type/:type_id` - Search by type
- `GET /api/fatsecret/recipes/:id` - Get recipe details

## Agent 5: FatSecret Favorites Foods (5 endpoints)
- `GET /api/fatsecret/favorites/foods` - List favorite foods
- `POST /api/fatsecret/favorites/foods/:id` - Add favorite food
- `DELETE /api/fatsecret/favorites/foods/:id` - Remove favorite food
- `GET /api/fatsecret/favorites/foods/most-eaten` - Get most eaten
- `GET /api/fatsecret/favorites/foods/recently-eaten` - Get recently eaten

## Agent 6: FatSecret Favorites Recipes (2 endpoints)
- `GET /api/fatsecret/favorites/recipes` - List favorite recipes
- `POST /api/fatsecret/favorites/recipes/:id` - Add/delete favorite recipe
- `DELETE /api/fatsecret/favorites/recipes/:id` - Remove favorite recipe

## Agent 7: FatSecret Saved Meals (6 endpoints)
- `GET /api/fatsecret/saved-meals` - List saved meals
- `POST /api/fatsecret/saved-meals` - Create saved meal
- `PUT /api/fatsecret/saved-meals/:id` - Edit saved meal
- `DELETE /api/fatsecret/saved-meals/:id` - Delete saved meal
- `GET /api/fatsecret/saved-meals/:id/items` - Get meal items
- `POST /api/fatsecret/saved-meals/:id/items` - Add item
- `PUT /api/fatsecret/saved-meals/:id/items/:item_id` - Edit item
- `DELETE /api/fatsecret/saved-meals/:id/items/:item_id` - Delete item

## Agent 8: FatSecret Diary API (6 endpoints)
- `POST /api/fatsecret/diary/entries` - Create entry
- `GET /api/fatsecret/diary/entries/:entry_id` - Get entry
- `PATCH /api/fatsecret/diary/entries/:entry_id` - Edit entry
- `DELETE /api/fatsecret/diary/entries/:entry_id` - Delete entry
- `GET /api/fatsecret/diary/day/:date_int` - Get day entries
- `GET /api/fatsecret/diary/month/:date_int` - Get month summary

## Agent 9: FatSecret Profile & Exercise (5 endpoints)
- `GET /api/fatsecret/profile` - Get user profile
- `GET /api/fatsecret/exercises` - Search exercises (TODO)
- `GET /api/fatsecret/exercise-entries` - Get day's entries (TODO)
- `POST /api/fatsecret/exercise-entries` - Create entry (TODO)
- `PUT /api/fatsecret/exercise-entries/:entry_id` - Update entry (TODO)
- `DELETE /api/fatsecret/exercise-entries/:entry_id` - Delete entry (TODO)

## Agent 10: FatSecret Weight API (4 endpoints)
- `GET /api/fatsecret/weight` - Get weight for date (TODO)
- `POST /api/fatsecret/weight` - Update weight (TODO)
- `GET /api/fatsecret/weight/month` - Get month summary (TODO)

## Agent 11: Legacy Dashboard APIs (4 endpoints)
- `GET /dashboard` - Dashboard UI
- `GET /log/food/:fdc_id` - Log food form
- `GET /api/dashboard/data` - Dashboard data
- `POST /api/logs/food` - Log food entry

## Agent 12: AI & Diet APIs (5 endpoints)
- `POST /api/ai/score-recipe` - Score recipe with AI
- `POST /api/diet/vertical/compliance/:recipe_id` - Diet compliance check
- `POST /api/macros/calculate` - Calculate macros
- `GET /tandoor/status` - Tandoor status
- `GET /api/tandoor/recipes` - List Tandoor recipes
- `GET /api/tandoor/recipes/:recipe_id` - Get Tandoor recipe
- `GET /api/tandoor/meal-plan` - Get meal plan
- `POST /api/tandoor/meal-plan` - Create meal plan
- `DELETE /api/tandoor/meal-plan/:entry_id` - Delete meal plan entry

---

## Test Execution Strategy

### Phase 1: Setup (Parallel)
- Start 12 agents with assigned endpoints
- Each agent reserves its test files
- Health check all agents ready

### Phase 2: Testing (Parallel)
- Each agent tests all assigned endpoints
- Record request/response times
- Track success/failure rates
- Log errors and edge cases

### Phase 3: Reporting (Sequential)
- Aggregate results from all agents
- Generate coverage report
- Identify untested/TODO endpoints
- Create performance baseline

### Phase 4: Integration (Sequential)
- Run cross-endpoint tests
- Verify OAuth flow dependencies
- Test error handling chains
- Final validation

---

## Endpoint Status Summary

| Category | Total | Implemented | TODO | Status |
|----------|-------|-------------|------|--------|
| Health & Status | 2 | 2 | 0 | ✅ Ready |
| OAuth | 4 | 4 | 0 | ✅ Ready |
| Foods | 2 | 2 | 0 | ✅ Ready |
| Recipes | 4 | 4 | 0 | ✅ Ready |
| Favorites (Foods) | 5 | 5 | 0 | ✅ Ready |
| Favorites (Recipes) | 3 | 3 | 0 | ✅ Ready |
| Saved Meals | 8 | 8 | 0 | ✅ Ready |
| Diary | 6 | 6 | 0 | ✅ Ready |
| Profile/Exercise | 6 | 1 | 5 | 🟡 Partial |
| Weight | 3 | 0 | 3 | 🔴 TODO |
| Legacy Dashboard | 4 | 4 | 0 | ✅ Ready |
| AI/Diet/Tandoor | 9 | 7 | 2 | 🟡 Partial |
| **TOTAL** | **56** | **46** | **10** | **82% Ready** |

---

## Test Data Requirements

### Authentication
- Valid FatSecret OAuth token (3-legged)
- Application credentials for 2-legged OAuth

### Sample IDs
- Food IDs: 1234567, 2345678, etc.
- Recipe IDs: 999888, 888777, etc.
- User ID: from OAuth session

### Date Format
- Date integer: YYYYMMDD (e.g., 20241214)
- ISO date: YYYY-MM-DD

---

## Success Criteria

- [ ] All 46 implemented endpoints return 2xx/3xx/4xx responses
- [ ] Response times < 2000ms for 95th percentile
- [ ] Error responses have proper error codes and messages
- [ ] OAuth flow works end-to-end
- [ ] Database operations are atomic
- [ ] No memory leaks after 100 requests/agent
