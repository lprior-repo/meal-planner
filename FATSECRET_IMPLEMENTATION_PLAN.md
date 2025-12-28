# FatSecret Domain Implementation Plan

**Created:** 2025-12-28  
**Status:** Ready for Implementation  
**Epic:** MP-feq4 (Beads) / meal-planner project (Vibe Kanban)

---

## Overview

Port complete FatSecret domain from Gleam (69 modules) to Rust/Windmill with CUPID compliance.

**Current Gap:** 97.5% missing functionality  
**Tasks Created:** 25 tasks + 1 epic  
**Estimated Effort:** 54-84 days (2-4 months)

---

## Task Organization

### ✅ Vibe Kanban
- **Project:** meal-planner (0822d2f5-692d-4f0a-acbb-b9c1422876e9)
- **Tasks:** 25 tasks created
- **Status:** All in "todo" status
- **Access:** Via Vibe Kanban MCP

### ✅ Beads (bd)
- **Epic:** MP-feq4 - FatSecret Domain: Port Gleam to Rust/Windmill (CUPID-compliant)
- **Tasks:** 26 tasks created
- **Labels:** fatsecret, rust, windmill, core, client, service, testing, docs
- **Priority:** P0 (blockers), P1 (critical), P2 (normal), P3 (docs)

---

## Implementation Phases

### Phase 1: Core Foundation (BLOCKERS) - 10-15 days
**Priority:** P0 - Must complete before anything else

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-w41r | [CORE] Implement FatSecret OAuth flow in Rust | 45a02d2d |
| MP-a8vl | [CORE] Implement FatSecret Config module in Rust | 023c4cf3 |
| MP-b1wx | [CORE] Implement FatSecret Error types with thiserror | a345fa47 |
| MP-b7ps | [CORE] Implement HTTP client with OAuth signing | 05a40056 |

**Dependencies:**
- oauth1 crate or manual HMAC-SHA256 implementation
- reqwest for HTTP
- thiserror for errors
- Environment variable handling

**Reference:**
- src/meal_planner/fatsecret/core/oauth.gleam (217 lines)
- src/meal_planner/fatsecret/core/config.gleam (87 lines)
- src/meal_planner/fatsecret/core/errors.gleam (201 lines)
- src/meal_planner/fatsecret/core/http.gleam (~150 lines)

---

### Phase 2: Domain Types - 5-7 days
**Priority:** P1

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-4njw | [TYPES] Implement Foods domain types with opaque IDs | cccd838f |
| MP-f90u | [TYPES] Implement Diary domain types with opaque IDs | 25c92429 |
| MP-ycn3 | [TYPES] Implement Profile, Weight, Exercise, Recipes types | 8093b070 |

**CUPID Focus:**
- Opaque newtype wrappers for IDs (type safety)
- Rich domain types with validation
- Serde derives for JSON serialization

---

### Phase 3: API Clients - 10-15 days
**Priority:** P1-P2

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-yhp1 | [CLIENT] Implement Foods API client | 7b03f78a |
| MP-90sn | [CLIENT] Implement Diary API client | 5381fa30 |
| MP-hf9h | [CLIENT] Implement Profile API client | e8f136e5 |
| MP-hlz9 | [CLIENT] Implement Weight, Exercise, Recipes API clients | f90c6144 |

**API Coverage:**
- Foods: search, get, autocomplete (2-legged OAuth)
- Diary: CRUD + summaries (3-legged OAuth)
- Profile: create, get, auth (3-legged OAuth)
- Weight, Exercise, Recipes, Favorites, SavedMeals: CRUD

**Total Functions:** 50+ API client functions

---

### Phase 4: Business Logic - 8-10 days
**Priority:** P1-P2

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-w0nk | [SERVICE] Implement Foods service layer with business logic | a3a874e9 |
| MP-g51d | [SERVICE] Implement Diary service layer with business logic | bce55d31 |
| MP-9z1z | [STORAGE] Implement encrypted OAuth token storage | bdafe94e |

**Business Rules:**
- Food caching and enrichment
- Daily calorie tracking and validation
- Nutrition goal adherence checks
- Batch operations
- AES-256-GCM token encryption

---

### Phase 5: Windmill Integration - 10-12 days
**Priority:** P1-P2

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-9qvg | [WINDMILL] Create FatSecret OAuth flow scripts | d49aee92 |
| MP-4su1 | [WINDMILL] Create Foods domain Windmill scripts | e3ecb152 |
| MP-qhz4 | [WINDMILL] Create Diary domain Windmill scripts | 2b0e2ca8 |
| MP-1pox | [WINDMILL] Create Profile, Weight, Exercise scripts | 15994553 |
| MP-w27i | [WINDMILL] Create Meal Logger batch operations | 4b0b8a41 |
| MP-d1p3 | [WINDMILL] Create FatSecret sync flow orchestration | 1ad9da6a |

**Windmill Scripts:**
- Auth: 4 scripts (request_token, authorize_url, exchange_token, store_credentials)
- Foods: 4 scripts (search, get_details, autocomplete, cache_popular)
- Diary: 6 scripts (get_entries, create, update, delete, daily_summary, copy_day)
- Profile/Weight/Exercise: 7 scripts
- Meal Logger: 4 scripts (batch_create, validate_macros, calculate_macros, retry_failed)
- Sync Flow: 1 orchestration flow (saga pattern)

**Total:** 26 Windmill scripts + 1 flow

---

### Phase 6: Testing - 8-10 days
**Priority:** P2

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-0qkz | [TESTING] Create integration tests for FatSecret OAuth | e816c3d8 |
| MP-meji | [TESTING] Create integration tests for Foods API | ec00a12f |
| MP-prw6 | [TESTING] Create integration tests for Diary API | 2d541ff0 |

**Test Coverage:**
- OAuth flow (request → authorize → access)
- Error handling (invalid credentials, expired tokens)
- Signature generation (HMAC-SHA256 verification)
- Token storage/retrieval with encryption
- All API client functions
- Edge cases (empty responses, invalid dates, negative nutrition)

**Fixtures:** Use test/fixtures/fatsecret/scraped/

---

### Phase 7: Documentation - 3-5 days
**Priority:** P3

| Beads ID | Task | Vibe ID |
|----------|------|---------|
| MP-p0aj | [DOCS] Create FatSecret Rust module documentation | fadf47c8 |
| MP-frd1 | [DOCS] Create Windmill deployment guide | ab31998c |

**Documentation:**
- README.md in src/meal_planner/fatsecret/
- Architecture diagrams (OAuth flow, API layers)
- CUPID compliance analysis per module
- Code examples for common operations
- Migration guide (Gleam → Rust)
- Windmill setup (resources, variables, schedules)
- Deployment runbook

---

## CUPID Compliance Targets

### Current Scores (Rust/Windmill)
- **C**omposable: 1/10 → Target: 10/10
- **U**nix Philosophy: 2/10 → Target: 10/10
- **P**redictable: 1/10 → Target: 10/10
- **I**diomatic: 3/10 → Target: 10/10
- **D**omain-based: 2/10 → Target: 10/10

**Average:** 1.8/10 → Target: 10/10

### Implementation Guidelines

**Composable:**
- Separate modules: types, client, service, handlers
- Small, focused functions (10-30 lines)
- Clear dependency injection

**Unix Philosophy:**
- Each module does ONE thing
- Example: `diary/handlers/delete.rs` only handles DELETE
- No "Swiss army knife" functions

**Predictable:**
- All fallible operations return `Result<T, E>`
- Use thiserror for structured errors
- Opaque newtype wrappers for IDs
- Remove all placeholder functions

**Idiomatic:**
- Use `?` operator for error propagation
- Builder pattern for complex types
- thiserror for errors
- serde for JSON

**Domain-based:**
- Rich domain types with validation
- Business rules in domain layer
- Clear bounded contexts (core, diary, foods, profile)

---

## Quick Start

### View Tasks in Beads
```bash
cd /home/lewis/src/meal-planner

# View all FatSecret tasks
bd list --label fatsecret

# View P0 blockers (Core Foundation)
bd list --label fatsecret --label p0

# View by phase
bd list --label fatsecret --label core    # Phase 1
bd list --label fatsecret --label types   # Phase 2
bd list --label fatsecret --label client  # Phase 3
bd list --label fatsecret --label service # Phase 4
bd list --label fatsecret --label windmill # Phase 5
bd list --label fatsecret --label testing # Phase 6
bd list --label fatsecret --label docs    # Phase 7

# Show epic
bd show MP-feq4
```

### Start Phase 1 (Blockers)
```bash
# Claim first task
bd show MP-w41r  # OAuth implementation
bd update MP-w41r --status in_progress

# Reference Gleam implementation
cat src/meal_planner/fatsecret/core/oauth.gleam

# Create Rust module
mkdir -p src/fatsecret/core
touch src/fatsecret/core/oauth.rs
```

### Track Progress
```bash
# Mark task complete
bd close MP-w41r

# Sync with git
bd sync

# View remaining work
bd ready --label fatsecret
```

---

## Reference Documentation

### Audit Report
- **File:** FATSECRET_CUPID_AUDIT_2025-12-28.md
- **Contains:** Full CUPID analysis, feature gaps, recommendations

### Gleam Implementation
- **Location:** src/meal_planner/fatsecret/
- **Modules:** 69 files
- **Domains:** core, foods, diary, profile, weight, exercise, recipes, favorites, saved_meals, food_brands, meal_logger

### Test Fixtures
- **Location:** test/fixtures/fatsecret/scraped/
- **Contains:** JSON responses for all API endpoints

---

## Success Criteria

Implementation is complete when:

1. ✅ All 25 tasks closed in both Beads and Vibe Kanban
2. ✅ CUPID scores all 10/10
3. ✅ All 50+ API client functions implemented
4. ✅ OAuth flow working end-to-end
5. ✅ Token storage encrypted in PostgreSQL
6. ✅ 26 Windmill scripts deployed
7. ✅ Integration tests passing
8. ✅ Documentation complete

---

## Next Steps

1. **Start Phase 1:** Implement Core Foundation (4 tasks, P0 blockers)
2. **Review:** FATSECRET_CUPID_AUDIT_2025-12-28.md for detailed analysis
3. **Reference:** Gleam implementations in src/meal_planner/fatsecret/
4. **Track:** Update task status in both Beads and Vibe Kanban

**Epic:** MP-feq4  
**First Task:** MP-w41r - [CORE] Implement FatSecret OAuth flow in Rust

---

**Let's build this CUPID-compliant implementation! 🚀**
