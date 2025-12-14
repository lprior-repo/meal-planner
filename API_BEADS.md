# API Endpoint Beads - Golden Rules Violations

This file documents beads created to address Golden Rule violations in Gleam API endpoints.

Generated from: `GRADING_REPORT.md`
Date: 2025-12-14
Total Beads: 7

---

## CRITICAL BEADS (Must complete before production)

### Bead 1: Fix Recipe Scoring Endpoint
**ID:** `meal-planner-fix-recipe-scoring`
**Title:** [API] Fix recipe scoring endpoint to parse actual JSON requests
**Severity:** 🔴 CRITICAL
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/handlers/recipes.gleam:158`

**Problem:**
The recipe scoring endpoint currently returns hardcoded sample data regardless of input. The function `read_scoring_request()` at line 158 ignores the request parameter and always returns identical sample data.

```gleam
// CURRENT (BROKEN):
fn read_scoring_request(_req: wisp.Request) -> Result(ScoringRequest, String) {
  Ok(ScoringRequest(
    recipes: [ /* hardcoded samples */ ],
    macro_targets: MacroTargets(...),
    weights: ScoringWeights(...),
  ))
}
```

**Required Changes:**
1. Use `wisp.require_json(req)` to parse request body
2. Create JSON decoder for `ScoringRequest` type using `gleam/dynamic/decode`
3. Define decoder for nested types:
   - `ScoringRequest` (recipes, macro_targets, weights)
   - `ScoringRecipeInput` (id, name, macros, vertical_compliant, fodmap_level)
   - `MacroTargets` (protein, fat, carbs)
   - `ScoringWeights` (diet_compliance, macro_match, variety)
   - `types.Macros` (protein, fat, carbs)

**Test Case:**
```bash
curl -X POST http://localhost:8080/api/ai/score-recipe \
  -H "Content-Type: application/json" \
  -d '{
    "recipes": [{
      "id": "test-1",
      "name": "Test Recipe",
      "macros": {"protein": 50, "fat": 30, "carbs": 20},
      "vertical_compliant": true,
      "fodmap_level": "low"
    }],
    "macro_targets": {"protein": 40, "fat": 25, "carbs": 35},
    "weights": {"diet_compliance": 0.4, "macro_match": 0.5, "variety": 0.1}
  }'
```

**Golden Rules Violated:**
- Rule 4: JSON Handling - No decoder; hardcoded sample
- Rule 3: Middleware - Missing `wisp.rescue_crashes`, `wisp.handle_head`
- Rule 5: Error Handling - No error mapping for invalid JSON

**Estimate:** 3 hours
**Dependencies:** None
**Priority:** 1

---

### Bead 2: Fix Macros Calculator Endpoint
**ID:** `meal-planner-fix-macros-calculator`
**Title:** [API] Fix macros calculator endpoint to process requests
**Severity:** 🔴 CRITICAL
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/handlers/macros.gleam:13`

**Problem:**
The macros calculator endpoint has no request body parsing. It always returns documentation/sample response regardless of input.

```gleam
// CURRENT (BROKEN):
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  let body = json.object([
    #("status", json.string("success")),
    // ... hardcoded example response
  ])

  wisp.json_response(body, 200)
}
```

**Required Changes:**
1. Add `wisp.require_json(req)` to parse request body
2. Define request type and decoder:
   ```gleam
   type MacrosRequest {
     MacrosRequest(recipes: List(RecipeServing))
   }
   type RecipeServing {
     RecipeServing(id: String, servings: Float, macros: types.Macros)
   }
   ```
3. Implement aggregation logic to sum macros across recipes
4. Return actual calculated totals, not sample data

**Test Case:**
```bash
curl -X POST http://localhost:8080/api/macros/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "recipes": [
      {
        "id": "recipe-1",
        "servings": 1.5,
        "macros": {"protein": 50, "fat": 20, "carbs": 70}
      },
      {
        "id": "recipe-2",
        "servings": 1.0,
        "macros": {"protein": 30, "fat": 15, "carbs": 40}
      }
    ]
  }'

# Expected response (aggregated):
# {
#   "status": "success",
#   "total_macros": {"protein": 95, "fat": 50, "carbs": 155},
#   "total_calories": 1470
# }
```

**Golden Rules Violated:**
- Rule 4: JSON Handling - No request parsing; hardcoded response
- Rule 3: Middleware - Missing complete middleware chain
- Rule 5: Error Handling - No error handling

**Estimate:** 3 hours
**Dependencies:** None
**Priority:** 1

---

### Bead 3: Fix Diet Compliance Endpoint
**ID:** `meal-planner-fix-diet-compliance`
**Title:** [API] Fix diet compliance endpoint to check actual recipes
**Severity:** 🔴 CRITICAL
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/handlers/diet.gleam:15`

**Problem:**
The diet compliance endpoint ignores the `recipe_id` parameter and always evaluates a hardcoded mock recipe.

```gleam
// CURRENT (BROKEN):
pub fn handle_compliance(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let mock_recipe = vertical_diet_compliance.Recipe( /* hardcoded */ )
  let result = vertical_diet_compliance.check_compliance(mock_recipe)
  // ... recipe_id parameter unused!
}
```

**Required Changes:**
1. Fetch actual recipe from database using `recipe_id`
2. Map database recipe to `vertical_diet_compliance.Recipe` type
3. Pass actual recipe to compliance checker
4. Handle errors:
   - Invalid recipe_id format → 400
   - Recipe not found → 404
   - Database errors → 500

**Test Case:**
```bash
# GET a recipe's compliance
curl http://localhost:8080/api/diet/vertical/compliance/recipe-123

# Expected for compliant recipe:
# {
#   "recipe_id": "recipe-123",
#   "recipe_name": "Grass-Fed Beef Bowl",
#   "compliant": true,
#   "score": 95,
#   "reasons": [...],
#   "recommendations": [...]
# }

# Expected for non-compliant recipe:
# {
#   "recipe_id": "recipe-456",
#   "compliant": false,
#   "score": 45,
#   "reasons": ["Contains dairy", "Has legumes"],
#   "recommendations": [...]
# }
```

**Golden Rules Violated:**
- Rule 4: JSON Handling - Mock data instead of actual input
- Rule 3: Middleware - Minimal middleware chain
- Rule 5: Error Handling - No error cases for invalid ID

**Estimate:** 3 hours
**Dependencies:** Recipe database access
**Priority:** 1

---

## HIGH-PRIORITY BEADS

### Bead 4: Add Missing Middleware Chains
**ID:** `meal-planner-add-api-middleware`
**Title:** [API] Add missing middleware chains to all handlers
**Severity:** 🟠 HIGH
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/handlers/recipes.gleam:111` (handle_score)
- `gleam/src/meal_planner/web/handlers/macros.gleam:13` (handle_calculate)
- `gleam/src/meal_planner/web/handlers/diet.gleam:15` (handle_compliance)

**Problem:**
Three endpoints are missing the standard middleware chain. Every handler should include:
```gleam
use <- wisp.log_request(req)
use <- wisp.rescue_crashes
use req <- wisp.handle_head(req)
```

**Current (recipes.gleam:111):**
```gleam
pub fn handle_score(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)
  // ... missing rescue_crashes, handle_head, logging
}
```

**Required:**
```gleam
pub fn handle_score(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  // ... rest of handler
}
```

**Middleware Purpose:**
- `log_request`: Logs all HTTP requests for debugging
- `rescue_crashes`: Catches panics; returns 500 error gracefully
- `handle_head`: Converts HEAD requests to GET responses

**Golden Rules Violated:**
- Rule 3: Middleware & Control Flow (required pattern)

**Estimate:** 1 hour
**Dependencies:** None
**Priority:** 2

---

### Bead 5: Add JSON Decoders for Type Safety
**ID:** `meal-planner-add-json-decoders`
**Title:** [API] Add JSON decoders for type-safe request parsing
**Severity:** 🟠 HIGH
**Status:** Open
**Affected Endpoints:** 16+ POST/PUT handlers

**Problem:**
Multiple endpoints lack JSON decoders for request bodies. This violates the "strict typing" requirement of Golden Rule 4.

**Endpoints Missing Decoders:**
1. POST /api/ai/score-recipe - ScoringRequest
2. POST /api/macros/calculate - MacrosRequest
3. POST /api/fatsecret/saved-meals - SavedMealRequest
4. PUT /api/fatsecret/saved-meals/:id - SavedMealEditRequest
5. POST /api/fatsecret/saved-meals/:id/items - SavedMealItemRequest
6. PUT /api/fatsecret/saved-meals/:id/items/:item_id - SavedMealItemEditRequest
7. And 10+ more FatSecret endpoints

**Example - Missing Decoder Pattern:**
```gleam
// CURRENT (UNSAFE):
case wisp.require_json(req) {
  Ok(_body) -> {
    // Can't safely access fields; it's dynamic
    wisp.json_response(body, 200)
  }
  Error(_) -> error_response(400, "Invalid JSON")
}

// REQUIRED (TYPE-SAFE):
let decoder = decode.decode3(
  SavedMealRequest,
  decode.field("title", decode.string),
  decode.field("from_date", decode.string),
  decode.field("to_date", decode.string),
)
case json.parse(body, decoder) {
  Ok(request) -> {
    // Now 'request' is typed; compiler ensures field access is safe
    create_meal(request.title, request.from_date, request.to_date)
  }
  Error(_) -> error_response(400, "Invalid JSON structure")
}
```

**Steps:**
1. Define request/response types for each endpoint
2. Write decoders using `gleam/dynamic/decode`
3. Replace unsafe `wisp.require_json` with type-safe parsing
4. Update error handling for decoder failures

**Golden Rules Violated:**
- Rule 4: JSON Handling (strict typing requirement)

**Estimate:** 4-5 hours
**Dependencies:** None
**Priority:** 2

---

## MEDIUM-PRIORITY BEADS

### Bead 6: Integrate FatSecret Diary Handlers into Router
**ID:** `meal-planner-integrate-diary-handlers`
**Title:** [API] Integrate FatSecret diary handlers into main router
**Severity:** 🟠 HIGH
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/router.gleam:170-197` (Integration)
- `gleam/src/meal_planner/fatsecret/diary/handlers.gleam:1-824` (Already implemented!)

**Problem:**
The FatSecret diary API has a **complete, production-ready 824-line implementation** in `fatsecret/diary/handlers.gleam`, but the main router.gleam (lines 170-197) returns `wisp.not_found()` with TODO comments instead of delegating to the handlers.

**Actual Implementation Status:**
✅ `POST /api/fatsecret/diary/entries` - Create food entry (fully implemented)
✅ `GET /api/fatsecret/diary/entries/:entry_id` - Get single entry (fully implemented)
✅ `PATCH /api/fatsecret/diary/entries/:entry_id` - Edit entry (fully implemented)
✅ `DELETE /api/fatsecret/diary/entries/:entry_id` - Delete entry (fully implemented)
✅ `GET /api/fatsecret/diary/day/:date_int` - Get all entries for date (fully implemented)
✅ `GET /api/fatsecret/diary/month/:date_int` - Get month summary (fully implemented)

**Required Changes:**
1. Import diary handlers module in router.gleam:
   ```gleam
   import meal_planner/fatsecret/diary/handlers as diary_handlers
   ```
2. Replace TODO blocks (lines 170-197) with delegation:
   ```gleam
   [\"api\", \"fatsecret\", \"diary\"] -> diary_handlers.handle_diary_routes(req, ctx)
   ```
3. Update route comments to reflect actual implementation

**Why This is HIGH Priority (Not Medium):**
- Implementation is already complete and tested
- Router integration is trivial (2-3 lines)
- 6 endpoints become immediately production-ready upon integration
- Zero risk (no new code to write, just delegation)

**Estimate:** 30 minutes (integration only)
**Dependencies:** None (handlers already implemented)
**Priority:** 2 (HIGH - Easy win for 6 production endpoints)

---

### Bead 7: Implement Food Logging Handlers
**ID:** `meal-planner-implement-log-food`
**Title:** [API] Implement food logging handlers
**Severity:** 🟡 MEDIUM
**Status:** Open
**Files:**
- `gleam/src/meal_planner/web/handlers.gleam:71-90`

**Endpoints to Implement:**
1. `GET /log/food/{fdc_id}` - Return HTML form for logging food
2. `POST /api/logs/food` - Process food log submission

**Current Status:**
Both handlers return HTTP 501 (Not Implemented).

**Required:**
1. Create HTML form for user input (HTMX-compatible)
2. Parse form submission
3. Store food log in database
4. Return success response

**Golden Rules Violations:**
- Rule 6: File Structure (unimplemented handlers)

**Estimate:** 4 hours
**Dependencies:** Database schema for food logs
**Priority:** 3

---

## SUMMARY TABLE

| Bead ID | Title | Severity | Estimate | Status |
|---------|-------|----------|----------|--------|
| meal-planner-fix-recipe-scoring | Fix recipe scoring JSON | 🔴 Critical | 3h | Open |
| meal-planner-fix-macros-calculator | Fix macros calculator | 🔴 Critical | 3h | Open |
| meal-planner-fix-diet-compliance | Fix diet compliance | 🔴 Critical | 3h | Open |
| meal-planner-add-api-middleware | Add middleware chains | 🟠 High | 1h | Open |
| meal-planner-add-json-decoders | Add JSON decoders | 🟠 High | 4h | Open |
| meal-planner-integrate-diary-handlers | Integrate diary handlers into router | 🟠 High | 0.5h | Open |
| meal-planner-implement-log-food | Implement food logging | 🟡 Medium | 4h | Open |

**Total Estimate:** 18.5 hours (2.5 days) - Down from 24 hours due to diary already being implemented
**Note:** Diary API endpoints are production-ready; only router integration needed

---

## GOLDEN RULES REFERENCE

### Rule 1: THE STACK & IMPORTS
Use `gleam_wisp` for requests, `gleam_mist` for server, `gleam/json` for encoding, `gleam/http/*` for HTTP types.

### Rule 2: ROUTING STRATEGY
Route using `case wisp.path_segments(req)` with explicit pattern matching. No DSLs.

### Rule 3: MIDDLEWARE & CONTROL FLOW
All handlers must start with:
```gleam
use <- wisp.log_request(req)
use <- wisp.rescue_crashes
use req <- wisp.handle_head(req)
```

### Rule 4: JSON HANDLING (Strict Typing)
Define types for request/response data. Write decoders using `gleam/dynamic/decode`. Never treat JSON as generic map.

### Rule 5: ERROR HANDLING
Use Result types for all operations. Use `use var <- result.try(operation)` to unwrap or short-circuit. Map errors to HTTP codes.

### Rule 6: FILE STRUCTURE
Group handlers by domain. Keep main router simple. Delegate to modules.

### Rule 7: NO MAGIC
No macros. No DSLs. If reading body, use `wisp.require_json`.

---

## NEXT STEPS

### PRIORITY 1 (This Week - Critical Blocking Issues)
1. **meal-planner-fix-recipe-scoring** (3h) - Hardcoded sample data
2. **meal-planner-fix-macros-calculator** (3h) - No request parsing
3. **meal-planner-fix-diet-compliance** (3h) - Mock data, ignores recipe_id

**Why:** These 3 endpoints return hardcoded/mock data and block API usability

### PRIORITY 2 (Next Week - Quick Wins + Quality)
1. **meal-planner-integrate-diary-handlers** (0.5h) ⭐ **QUICK WIN** - 6 production endpoints unlocked!
2. **meal-planner-add-api-middleware** (1h) - Add rescue_crashes, handle_head
3. **meal-planner-add-json-decoders** (4h) - Type-safe request parsing

**Why:** Diary integration is trivial and immediate payoff. Middleware/decoders improve robustness.

### PRIORITY 3 (Following Week - Enhancement)
1. **meal-planner-implement-log-food** (4h) - Food logging UI + handlers

**Why:** Lower priority; blocked by other work; fewer users affected

### Key Change: Diary API Discovery
**PREVIOUSLY:** Listed as "Implement FatSecret diary endpoints (6h)" - UNIMPLEMENTED
**DISCOVERY:** Found complete 824-line production implementation in `fatsecret/diary/handlers.gleam`
**CHANGE:** Now a 30-minute integration task instead of 6-hour implementation
**IMPACT:** Saves ~5.5 hours; enables 6 endpoints immediately upon integration

All beads should include:
- ✅ Test cases
- ✅ Before/after code examples
- ✅ Golden Rule reference
- ✅ Acceptance criteria
