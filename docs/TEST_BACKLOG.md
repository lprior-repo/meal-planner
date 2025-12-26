# Test Coverage Backlog
**Generated:** 2025-12-24
**Priority:** Ranked by risk and impact

---

## P0 - CRITICAL (Must fix before production)

### MP-TEST-1: Storage Module Test Coverage
**Risk:** 🔴 CRITICAL - Database operations untested
**Effort:** 40-60 hours
**Coverage:** 0% → 60%

**Files to test:**
- [ ] `storage/mod.gleam` - Storage initialization and connection pooling
- [ ] `storage/schema.gleam` - Database schema migrations
- [ ] `storage/foods.gleam` - Food CRUD operations
- [ ] `storage/nutrients.gleam` - Nutrient tracking CRUD
- [ ] `storage/profile.gleam` - User profile CRUD
- [ ] `storage/scheduler.gleam` - Scheduler state persistence
- [ ] `storage/audit.gleam` - Audit log operations
- [ ] `storage/logs.gleam` - Log persistence
- [ ] `storage/utils.gleam` - Storage utilities

**Test requirements:**
- Test database setup/teardown
- CRUD operations for all entities
- Constraint violations (unique, foreign key, not null)
- Transaction rollback on error
- Connection pool exhaustion
- SQL injection prevention (parameterized queries)
- Empty result sets
- Large result sets (pagination)
- Concurrent access (if applicable)

**Success criteria:**
- All storage operations have unit tests
- Integration tests with test database
- All error paths tested
- No SQL injection vulnerabilities

---

### MP-TEST-2: Web Handler Test Coverage
**Risk:** 🔴 CRITICAL - HTTP endpoints are attack surface
**Effort:** 60-80 hours
**Coverage:** 5% → 40%

**Handlers to test:**

#### Core Handlers (P0)
- [ ] `web/handlers/health.gleam` - Health check endpoint
- [ ] `web/handlers/recipes.gleam` - Recipe CRUD
- [ ] `web/handlers/meal_planning.gleam` - Meal plan CRUD
- [ ] `web/handlers/shopping_list.gleam` - Shopping list operations
- [ ] `web/handlers/nutrition.gleam` - Nutrition tracking

#### Proxy Handlers (P1)
- [ ] `web/handlers/tandoor/recipes.gleam` - Tandoor recipe proxy
- [ ] `web/handlers/tandoor/meal_plans.gleam` - Tandoor meal plan proxy
- [ ] `web/handlers/tandoor/shopping_lists.gleam` - Tandoor shopping list proxy
- [ ] `web/handlers/tandoor/foods.gleam` - Tandoor food proxy
- [ ] `web/handlers/tandoor/ingredients.gleam` - Tandoor ingredient proxy
- [ ] `web/handlers/fatsecret/brands.gleam` - FatSecret brand search

#### Secondary Handlers (P2)
- [ ] `web/handlers/advisor.gleam` - Nutrition advisor
- [ ] `web/handlers/diet.gleam` - Diet management
- [ ] `web/handlers/macros.gleam` - Macro tracking
- [ ] `web/handlers/tandoor/preferences.gleam`
- [ ] `web/handlers/tandoor/keywords.gleam`
- [ ] `web/handlers/tandoor/steps.gleam`
- [ ] `web/handlers/tandoor/import_logs.gleam`
- [ ] `web/handlers/tandoor/export_logs.gleam`

**Test requirements:**
- Request validation (malformed JSON, missing fields, type errors)
- Authentication (401 for unauthenticated requests)
- Authorization (403 for unauthorized access)
- Not found (404 for missing resources)
- Server errors (500 with error logging)
- Bad requests (400 for validation failures)
- Success responses (200, 201, 204)
- Pagination (offset, limit, total count)
- Filtering and sorting
- CORS headers (if applicable)
- Rate limiting (if applicable)

**Success criteria:**
- All critical endpoints have tests
- Request/response contract validated
- Error handling tested
- Authentication/authorization enforced

---

## P1 - HIGH PRIORITY (Before major features)

### MP-TEST-3: Automation Module Test Coverage
**Risk:** 🟡 HIGH - Sync and optimization bugs cause poor UX
**Effort:** 20-30 hours
**Coverage:** 17% → 50%

**Files to test:**
- [ ] `automation/fatsecret_sync.gleam` - FatSecret data synchronization
- [ ] `automation/macro_optimizer.gleam` - Macro optimization algorithms
- [ ] `automation/preferences.gleam` - User preference management
- [ ] `automation/rotation.gleam` - Recipe rotation logic
- [ ] `automation/shopping_consolidator.gleam` - Shopping list consolidation

**Test requirements:**
- Mock FatSecret API responses
- Test sync success and failure scenarios
- Test optimization with various constraints
- Test impossible constraint detection
- Test preference conflict resolution
- Test rotation fairness (no recipe spam)
- Test consolidation of duplicate items

**Success criteria:**
- Sync logic tested with mocks
- Optimizer edge cases covered
- Rotation produces varied plans
- Consolidator handles duplicates

---

### MP-TEST-4: FatSecret Integration Test Coverage
**Risk:** 🟡 MEDIUM - API integration bugs cause sync failures
**Effort:** 15-20 hours
**Coverage:** 19% → 50%

**Files to test:**
- [ ] `fatsecret/auth/client.gleam` - OAuth authentication
- [ ] `fatsecret/auth/types.gleam` - Auth types
- [ ] `fatsecret/diary/client.gleam` - Diary API client
- [ ] `fatsecret/diary/handlers.gleam` - Diary handlers (split into separate files)
- [ ] `fatsecret/foods/client.gleam` - Food search client
- [ ] `fatsecret/recipes/client.gleam` - Recipe search client
- [ ] Additional decoders and encoders

**Test requirements:**
- Mock API responses (success, error, timeout)
- Test rate limiting handling
- Test pagination
- Test retry logic
- Test OAuth flow
- Test token refresh

**Success criteria:**
- All API clients tested
- Error scenarios covered
- Decoders handle edge cases
- Encoders produce valid JSON

---

## P2 - MEDIUM PRIORITY (Ongoing improvement)

### MP-TEST-5: Tandoor Integration Test Coverage
**Risk:** 🟡 MEDIUM - Proxy errors cause UX degradation
**Effort:** 15-20 hours
**Coverage:** 14% → 40%

**Files to test:**
- [ ] `tandoor/client/*.gleam` - All client modules
- [ ] `tandoor/types/*.gleam` - Type decoders/encoders
- [ ] Additional integration scenarios

---

### MP-TEST-6: Cache Module Test Coverage
**Risk:** 🟢 LOW - Cache bugs cause stale data
**Effort:** 5-10 hours
**Coverage:** 0% → 80%

**Files to test:**
- [ ] `cache.gleam` - Cache operations
- [ ] `cache/invalidation.gleam` - Invalidation logic

**Test requirements:**
- Test cache hit/miss
- Test expiration
- Test invalidation
- Test concurrent access

---

### MP-TEST-7: CLI Domain Command Coverage
**Risk:** 🟢 LOW - CLI bugs are user-visible but low risk
**Effort:** 10-15 hours
**Coverage:** Varies by domain

**Files to test:**
- [ ] `cli/domains/diary/commands/*.gleam`
- [ ] `cli/domains/nutrition/commands.gleam`
- [ ] `cli/domains/advisor.gleam`
- [ ] `cli/domains/plan.gleam`

---

## P3 - LOW PRIORITY (Nice to have)

### MP-TEST-8: UI Module Test Coverage
**Files to test:**
- [ ] `ui/*.gleam` - UI rendering components

---

### MP-TEST-9: Property-Based Testing
**Effort:** Ongoing
**Goal:** Add qcheck property tests for:
- JSON decoders/encoders
- Date/time parsing
- Macro calculations
- Constraint solving

---

## Test Quality Improvements (Ongoing)

### Reduce `panic as` usage in tests
- Replace `let assert Ok(x) = result; panic as "..."` with `should.be_ok()`
- Replace `let assert Some(x) = option; panic as "..."` with `should.be_some()`

### Add property-based tests
- Use qcheck for decoders, encoders, parsers
- Test invariants (e.g., encode(decode(x)) == x)

### Improve test organization
- Split large test files (>500 LOC) by feature area
- Use consistent naming conventions
- Add test categories (unit, integration, property)

---

## Tracking Progress

### Current Status (2025-12-24)
```
Overall: 22.6% file coverage
Test LOC: 18,071
Critical gaps: 5 modules with <20% coverage
```

### Target Status (1 month)
```
Overall: 45% file coverage
Test LOC: 30,000+
Critical gaps: 0 modules with <20% coverage
Storage: 60%+
Web handlers: 40%+
Automation: 50%+
```

### Target Status (3 months)
```
Overall: 70% file coverage
All modules: 50%+
Storage: 80%+
Web handlers: 70%+
```

---

## Test Development Workflow

1. **Create Beads task:** `bd create --title "Tests for [module]"`
2. **Lock symbols:** Use Serena to lock files being tested
3. **TDD discipline:** RED → GREEN → REFACTOR
4. **Run tests:** `make test` (must pass)
5. **Commit:** Follow TCR protocol
6. **Save learnings:** Update mem0 with patterns discovered

---

**Last Updated:** 2025-12-24
**Next Review:** After P0 tasks complete
