# 🔍 FATSECRET DOMAIN CUPID AUDIT - Rust/Windmill vs Gleam

**Date:** 2025-12-28  
**Auditor:** OpenCode (Skeptical Mode Activated)  
**Scope:** FatSecret domain implementation across Gleam, Rust, and Windmill

---

## EXECUTIVE SUMMARY

### 🚨 VERDICT: CRITICAL GAPS - Implementation is ~5% of Gleam functionality

The current Rust/Windmill implementation has **MASSIVE GAPS** compared to the mature Gleam codebase. This is not production-ready. This is barely proof-of-concept ready.

**Key Findings:**
- ✅ Gleam: 69 modules, complete implementation of 11 FatSecret API domains
- ❌ Rust: 1 file (fatsecret_sync.rs) with only type definitions, NO implementations
- ❌ Windmill: 1 stub script (sync_foods) that does nothing
- 🚨 **CUPID Compliance: 1.8/10 average across all principles**

---

## 📊 FEATURE COVERAGE MATRIX

| Domain | Gleam Modules | Rust Modules | Windmill Scripts | Implementation Gap |
|--------|---------------|--------------|------------------|-------------------|
| **Core (OAuth, Config, Errors)** | 4 | 0 | 0 | **100%** |
| **Foods** | 5 (client, service, handlers, types, decoders) | 0 | 1 stub | **95%** |
| **Diary** | 9 (client, service, 7 handlers, types, decoders) | 0 | 0 | **100%** |
| **Profile** | 6 (client, service, oauth, handlers, types, decoders) | 0 | 0 | **100%** |
| **Recipes** | 5 | 0 | 0 | **100%** |
| **Weight** | 5 | 0 | 0 | **100%** |
| **Exercise** | 5 | 0 | 0 | **100%** |
| **Favorites** | 5 | 0 | 0 | **100%** |
| **Saved Meals** | 5 | 0 | 0 | **100%** |
| **Food Brands** | 3 | 0 | 0 | **100%** |
| **Meal Logger** | 5 (batch, retry, validation, macros, errors) | 0 | 0 | **100%** |
| **Storage/Crypto** | 2 | 0 | 0 | **100%** |

**TOTAL:**
- Gleam: **69 modules** (100% coverage)
- Rust: **1 file** (types only, no behavior)
- Windmill: **1 stub script** (placeholder only)
- **Average Gap: 97.5%**

---

## 🎯 CUPID COMPLIANCE AUDIT

### ❌ **C - Composable** (Score: 1/10)

**Gleam Implementation:** ✅ **Excellent** (10/10)
- Perfect layered architecture: `client → service → handler`
- Example: `foods/client.gleam` (API calls) → `foods/service.gleam` (business logic) → `foods/handlers.gleam` (HTTP)
- Reusable decoders across all domains
- Small, focused modules with clear dependencies
- Easy to compose: `get_food |> validate_nutrition |> cache_result`

**Rust Implementation:** ❌ **Non-existent** (1/10)
- Only one monolithic file: `fatsecret_sync.rs`
- No separation between data structures and behavior
- Types without any functions = not composable
- **VIOLATION:** No layering, no composition, no reusability

**Windmill Implementation:** ❌ **Stub only** (1/10)
- Single placeholder script with no real logic
- **VIOLATION:** Cannot compose what doesn't exist

**Recommendation:**
Create separate modules for each layer:
```
src/meal_planner/fatsecret/
  core/         # OAuth, config, errors, HTTP
  types/        # Domain types (Foods, Diary, etc.)
  client/       # API client layer
  service/      # Business logic layer
```

---

### ❌ **U - Unix Philosophy** (Do one thing well) (Score: 2/10)

**Gleam Implementation:** ✅ **Excellent** (10/10)
- Each module does ONE thing:
  - `diary/handlers/delete.gleam` - Only handles DELETE requests
  - `diary/handlers/create.gleam` - Only handles CREATE requests
  - `foods/decoders.gleam` - Only decodes JSON to types
  - `core/oauth.gleam` - Only handles OAuth flow
- Functions are small (10-30 lines typical)
- Clear single responsibility

**Rust Implementation:** ❌ **Violates Principle** (2/10)
- `fatsecret_sync.rs` tries to do EVERYTHING:
  - Meal plan matching
  - Nutrition comparison
  - Sync orchestration
  - Type definitions
- **VIOLATION:** "Swiss army knife" anti-pattern
- Functions like `sync_diary_to_plan` are placeholders that claim to do complex work but return empty results

**Windmill Implementation:** ❌ **Unknown** (2/10)
- Not enough implementation to judge
- Stub suggests monolithic approach

**Recommendation:**
Split `fatsecret_sync.rs` into focused modules:
- `fatsecret/matching/nutrition.rs` - Nutrition comparison only
- `fatsecret/matching/names.rs` - Name similarity only
- `fatsecret/sync/orchestrator.rs` - Coordinates sync flow
- `fatsecret/sync/mapper.rs` - Maps data structures

---

### ❌ **P - Predictable** (Score: 1/10)

**Gleam Implementation:** ✅ **Excellent** (10/10)
- Consistent error handling: All functions return `Result(T, FatSecretError)`
- Opaque ID types prevent misuse:
  ```gleam
  pub opaque type FoodId { FoodId(String) }
  pub opaque type ServingId { ServingId(String) }
  ```
  Cannot accidentally use `FoodId` where `ServingId` expected
- Validation functions with clear error messages:
  ```gleam
  validate_custom_entry(...) -> Result(Nil, String)
  validate_number_of_units(0.0) -> Error("must be greater than 0")
  ```
- No surprises: If it compiles, it's likely correct

**Rust Implementation:** ❌ **Completely Unpredictable** (1/10)
- No error handling at all
- Functions lie about capabilities:
  ```rust
  pub fn calculate_match_confidence(...) -> f64 {
      // Placeholder - always returns 0.0
      0.0
  }
  ```
  **VIOLATION:** This will ALWAYS return 0.0, making all matches invalid
- Raw primitive types for IDs (String, i32) - can be mixed up
- No validation anywhere
- **VIOLATION:** Code looks like it works but does nothing

**Windmill Implementation:** ❌ **Unknown** (1/10)
- Stub implementation unreliable

**Recommendation:**
1. Use `Result<T, E>` for ALL fallible operations
2. Use `thiserror` for structured errors
3. Create newtype wrappers for IDs:
   ```rust
   #[derive(Debug, Clone, PartialEq, Eq)]
   pub struct FoodId(String);
   ```
4. Remove placeholder functions or mark them with `unimplemented!()`

---

### ❌ **I - Idiomatic** (Score: 3/10)

**Gleam Implementation:** ✅ **Excellent** (10/10)
- Uses `Result` for errors, `Option` for nullability (proper type-driven design)
- Pattern matching everywhere:
  ```gleam
  case meal_type_from_string(s) {
    Ok(Breakfast) -> ...
    Ok(Lunch) -> ...
    Error(_) -> ...
  }
  ```
- Pipe operator for composition:
  ```gleam
  date
  |> date_to_int
  |> result.map(create_entry)
  |> result.map_error(from_fatsecret_error)
  ```
- Type-safe JSON decoders with `decode` library

**Rust Implementation:** ⚠️ **Half-Idiomatic** (3/10)
- ✅ Uses `Option` and `Result` in type signatures
- ✅ Uses `serde` derives for serialization
- ❌ No actual implementations using Result/Option idiomatically
- ❌ Missing:
  - `thiserror` for error types (using manual structs)
  - `?` operator for error propagation (no code to use it)
  - Builder pattern for complex types
  - Type-state pattern for workflows
- **VIOLATION:** Types look Rust-like, but no behavior to judge

**Windmill Implementation:** ❌ **Unknown** (3/10)

**Recommendation:**
1. Use `thiserror` for errors:
   ```rust
   #[derive(Error, Debug)]
   pub enum FatSecretError {
       #[error("API error {code}: {message}")]
       ApiError { code: ApiErrorCode, message: String },
   }
   ```
2. Use `?` operator throughout:
   ```rust
   pub fn get_food(config: &Config, id: FoodId) -> Result<Food, FatSecretError> {
       let response = http::get(&config.api_url()?)?;
       let food = serde_json::from_str(&response)?;
       Ok(food)
   }
   ```

---

### ❌ **D - Domain-Based** (Score: 2/10)

**Gleam Implementation:** ✅ **Excellent** (10/10)
- Strong domain modeling with opaque types:
  ```gleam
  pub opaque type FoodEntryId { FoodEntryId(String) }
  ```
  Compiler enforces you cannot create/access IDs improperly
- Rich domain types capturing business rules:
  ```gleam
  pub type FoodEntryInput {
    FromFood(food_id, serving_id, ...)  // From FatSecret DB
    Custom(name, calories, ...)         // User-created
  }
  ```
- Business validation IN the domain layer:
  ```gleam
  validate_custom_entry(calories: Float) -> Result(Nil, String) {
    case calories <. 0.0 {
      True -> Error("Nutrition values cannot be negative")
      False -> Ok(Nil)
    }
  }
  ```
- Clear bounded contexts:
  - `core/` - Shared infrastructure
  - `diary/` - Food logging domain
  - `foods/` - Food search/details domain
  - `profile/` - User profile domain

**Rust Implementation:** ❌ **Anemic Domain Model** (2/10)
- Types exist but are disconnected from behavior
- No opaque types (IDs are raw `String` and `i32`)
- **VIOLATION:** Can create invalid IDs:
  ```rust
  let fake_id = "not-a-real-id".to_string(); // compiles fine
  ```
- No domain validation
- No business logic in domain types
- Missing 10 out of 11 subdomains entirely

**Windmill Implementation:** ❌ **Missing** (1/10)
- No domain structure

**Recommendation:**
1. Create opaque newtype wrappers:
   ```rust
   #[derive(Debug, Clone, PartialEq, Eq)]
   pub struct FoodId(String);
   
   impl FoodId {
       pub fn new(id: String) -> Result<Self, InvalidId> {
           if id.is_empty() { return Err(InvalidId); }
           Ok(FoodId(id))
       }
   }
   ```
2. Add domain validation to constructors
3. Organize by bounded context (core, diary, foods, profile)
4. Put business rules in domain types, not services

---

## 🚨 CRITICAL MISSING FEATURES

### 1. **OAuth Implementation** ❌ **BLOCKER**
- **Gleam:** Complete 3-legged OAuth 1.0a flow
  - src/meal_planner/fatsecret/core/oauth.gleam (217 lines)
  - Request token → Authorization → Access token
  - HMAC-SHA256 signature generation
  - Nonce and timestamp generation
- **Rust:** None
- **Windmill:** None
- **Impact:** **CANNOT AUTHENTICATE USERS AT ALL**
- **Effort:** 3-5 days (OAuth 1.0a is complex)

### 2. **HTTP Client Layer** ❌ **BLOCKER**
- **Gleam:** Full HTTP client with automatic OAuth signing
  - src/meal_planner/fatsecret/core/http.gleam
  - Automatic header injection
  - Request/response handling
- **Rust:** None
- **Windmill:** None
- **Impact:** **CANNOT MAKE API CALLS**
- **Effort:** 2-3 days

### 3. **Error Handling** ❌ **CRITICAL**
- **Gleam:** 16 distinct API error codes, structured errors
  - src/meal_planner/fatsecret/core/errors.gleam (201 lines)
  - Recoverable vs non-recoverable classification
  - Auth error detection
- **Rust:** None
- **Windmill:** None
- **Impact:** **CANNOT DIAGNOSE FAILURES**
- **Effort:** 1-2 days

### 4. **JSON Decoders** ❌ **BLOCKER**
- **Gleam:** Type-safe decoders for all 11 domains
  - foods/decoders.gleam
  - diary/decoders.gleam
  - profile/decoders.gleam
  - etc.
- **Rust:** None (has serde derives but no actual parsing logic)
- **Windmill:** None
- **Impact:** **CANNOT PARSE API RESPONSES**
- **Effort:** 4-5 days (complex nested structures)

### 5. **Client Functions (API Layer)** ❌ **BLOCKER**
- **Gleam:** 50+ API client functions across 9 client modules
  - foods/client.gleam: search, get, autocomplete
  - diary/client.gleam: CRUD operations, summaries
  - profile/client.gleam: create, get, auth
  - weight/client.gleam: CRUD, summaries
  - exercise/client.gleam: CRUD
  - recipes/client.gleam: search, autocomplete
  - favorites/client.gleam: CRUD
  - saved_meals/client.gleam: CRUD
  - food_brands/client.gleam: get, search
- **Rust:** 0 functions
- **Windmill:** 0 functions
- **Impact:** **CANNOT INTERACT WITH FATSECRET API AT ALL**
- **Effort:** 10-15 days (50+ functions)

### 6. **Service Layer (Business Logic)** ❌ **CRITICAL**
- **Gleam:** Business logic layer for all 8 domains
  - foods/service.gleam: Caching, enrichment
  - diary/service.gleam: Daily tracking, goal validation
  - profile/service.gleam: Goal calculations
  - etc.
- **Rust:** None
- **Windmill:** None
- **Impact:** **NO BUSINESS RULES ENFORCEMENT**
- **Effort:** 8-10 days

### 7. **HTTP Handlers (Web API)** ❌ **CRITICAL**
- **Gleam:** 8 complete handler modules integrated with Wisp framework
  - foods/handlers.gleam
  - diary/handlers/ (7 sub-handlers: create, delete, update, get, list, summary, copy)
  - profile/handlers.gleam
  - recipes/handlers.gleam
  - weight/handlers.gleam
  - exercise/handlers.gleam
  - favorites/handlers.gleam
  - saved_meals/handlers.gleam
- **Rust:** Only web/mod.rs with health checks
- **Windmill:** None (Windmill doesn't do HTTP handlers)
- **Impact:** **CANNOT EXPOSE API ENDPOINTS**
- **Effort:** 8-10 days

### 8. **Validation** ❌ **CRITICAL**
- **Gleam:** Input validation throughout
  - validate_custom_entry: Nutrition values, names
  - validate_number_of_units: Serving quantities
  - validate_date_int_string: Date parsing
- **Rust:** None
- **Windmill:** None
- **Impact:** **GARBAGE IN, GARBAGE OUT**
- **Effort:** 2-3 days

### 9. **Meal Logger** ❌ **FEATURE LOSS**
- **Gleam:** Complete meal logging system
  - meal_logger.gleam: Main orchestration
  - meal_logger/batch.gleam: Batch operations
  - meal_logger/retry.gleam: Exponential backoff retry
  - meal_logger/validators.gleam: Input validation
  - meal_logger/macro_calculator.gleam: Calculate macros from ingredients
- **Rust:** None
- **Windmill:** None
- **Impact:** **CANNOT LOG MEALS PROGRAMMATICALLY**
- **Effort:** 5-7 days

### 10. **Storage Layer (Token Persistence)** ❌ **BLOCKER**
- **Gleam:** Encrypted token storage
  - storage.gleam: PostgreSQL storage
  - crypto.gleam: AES-256 encryption
- **Rust:** None
- **Windmill:** None
- **Impact:** **CANNOT PERSIST OAUTH TOKENS = NO USERS**
- **Effort:** 2-3 days

---

## 📈 IMPLEMENTATION ROADMAP

### ✅ Tasks Created in Vibe Kanban

**25 tasks created in meal-planner project:**

#### Phase 1: Core Foundation (BLOCKERS) - 10-15 days
1. ✅ [CORE] Implement FatSecret OAuth flow in Rust
2. ✅ [CORE] Implement FatSecret Config module in Rust
3. ✅ [CORE] Implement FatSecret Error types with thiserror
4. ✅ [CORE] Implement HTTP client with OAuth signing

#### Phase 2: Domain Types - 5-7 days
5. ✅ [TYPES] Implement Foods domain types with opaque IDs
6. ✅ [TYPES] Implement Diary domain types with opaque IDs
7. ✅ [TYPES] Implement Profile, Weight, Exercise, Recipes types

#### Phase 3: API Clients - 10-15 days
8. ✅ [CLIENT] Implement Foods API client
9. ✅ [CLIENT] Implement Diary API client
10. ✅ [CLIENT] Implement Profile API client
11. ✅ [CLIENT] Implement Weight, Exercise, Recipes API clients

#### Phase 4: Business Logic - 8-10 days
12. ✅ [SERVICE] Implement Foods service layer with business logic
13. ✅ [SERVICE] Implement Diary service layer with business logic
14. ✅ [STORAGE] Implement encrypted OAuth token storage

#### Phase 5: Windmill Integration - 10-12 days
15. ✅ [WINDMILL] Create FatSecret OAuth flow scripts
16. ✅ [WINDMILL] Create Foods domain Windmill scripts
17. ✅ [WINDMILL] Create Diary domain Windmill scripts
18. ✅ [WINDMILL] Create Profile, Weight, Exercise scripts
19. ✅ [WINDMILL] Create Meal Logger batch operations
20. ✅ [WINDMILL] Create FatSecret sync flow orchestration

#### Phase 6: Testing - 8-10 days
21. ✅ [TESTING] Create integration tests for FatSecret OAuth
22. ✅ [TESTING] Create integration tests for Foods API
23. ✅ [TESTING] Create integration tests for Diary API

#### Phase 7: Documentation - 3-5 days
24. ✅ [DOCS] Create FatSecret Rust module documentation
25. ✅ [DOCS] Create Windmill deployment guide

**TOTAL ESTIMATED EFFORT: 54-84 days (2-4 months)**

---

## 🎯 IMMEDIATE NEXT STEPS

### Priority 1: Core Foundation (BLOCKERS)
Start with these 4 tasks to unblock everything else:

1. **OAuth Flow** - Task ID: 45a02d2d-c9d0-4267-8874-c8befcdfc6d3
   - Port core/oauth.gleam to Rust
   - Use `oauth1` crate or implement HMAC-SHA256 manually
   - Reference: 217 lines of Gleam code

2. **Config Module** - Task ID: 023c4cf3-030f-4f40-9ec0-e28fa4685d30
   - Port core/config.gleam to Rust
   - Environment variable loading
   - Reference: 87 lines of Gleam code

3. **Error Types** - Task ID: a345fa47-7d67-44e2-acf1-e11ae102a2d7
   - Port core/errors.gleam with thiserror
   - 16 API error codes
   - Reference: 201 lines of Gleam code

4. **HTTP Client** - Task ID: 05a40056-e2ed-4b98-871c-b6e18595f849
   - Port core/http.gleam with reqwest
   - OAuth signing integration
   - Reference: ~150 lines of Gleam code

**These 4 tasks are CRITICAL PATH. Nothing else can work without them.**

---

## 🔥 BRUTALLY HONEST ASSESSMENT

### What We Have
- ✅ Types that look nice (Rust structs with serde)
- ✅ Good intentions (stub implementations show awareness)
- ✅ Windmill infrastructure exists

### What We DON'T Have
- ❌ Any actual working code
- ❌ Ability to authenticate with FatSecret
- ❌ Ability to make API calls
- ❌ Ability to parse responses
- ❌ Ability to store user tokens
- ❌ Ability to validate inputs
- ❌ Any business logic
- ❌ Any HTTP endpoints
- ❌ Any tests

### Reality Check
**Current implementation status: ~5% of Gleam functionality**

This is NOT:
- ❌ Production ready
- ❌ MVP ready
- ❌ POC ready
- ❌ Demo ready

This IS:
- ✅ Type definitions only
- ✅ Placeholder code
- ✅ A todo list in disguise

---

## 💡 RECOMMENDATIONS

### Option 1: Full Rust Port (Recommended for Production)
**Effort:** 2-4 months  
**Pros:**
- Type safety with Rust
- Performance
- CUPID compliant if done right

**Cons:**
- Significant effort
- Must port all 69 modules

**Steps:**
1. Start with Phase 1 (Core Foundation) - 2 weeks
2. Implement Phase 2 (Types) - 1 week
3. Implement Phase 3 (Clients) - 2-3 weeks
4. Continue through all phases

### Option 2: Keep Gleam, Add Windmill Wrappers
**Effort:** 2-3 weeks  
**Pros:**
- Leverage existing 69 Gleam modules
- Faster to production
- Already working code

**Cons:**
- FFI complexity (Gleam ↔ Rust)
- Deployment complexity

**Steps:**
1. Create Windmill scripts that call Gleam CLI
2. Use Gleam as library, expose functions
3. Minimal Rust wrapper for Windmill integration

### Option 3: Hybrid Approach
**Effort:** 1-2 months  
**Pros:**
- Best of both worlds
- Gradual migration

**Cons:**
- Maintain two codebases temporarily

**Steps:**
1. Implement Core Foundation in Rust (OAuth, HTTP, Errors)
2. Use Gleam for business logic initially
3. Gradually port domain by domain to Rust

---

## 📊 CUPID COMPLIANCE SUMMARY

| Principle | Gleam Score | Rust Score | Gap |
|-----------|-------------|------------|-----|
| **C**omposable | 10/10 | 1/10 | 90% |
| **U**nix Philosophy | 10/10 | 2/10 | 80% |
| **P**redictable | 10/10 | 1/10 | 90% |
| **I**diomatic | 10/10 | 3/10 | 70% |
| **D**omain-based | 10/10 | 2/10 | 80% |
| **AVERAGE** | **10/10** | **1.8/10** | **82%** |

---

## 🎯 SUCCESS CRITERIA

Implementation is CUPID-compliant when:

1. **Composable:** Can combine small modules to build complex flows
2. **Unix Philosophy:** Each module does ONE thing well
3. **Predictable:** No surprises, errors are typed, IDs are opaque
4. **Idiomatic:** Uses Rust idioms (Result, ?, thiserror, builder pattern)
5. **Domain-based:** Rich domain models with validation

---

## 📝 CONCLUSION

The Gleam implementation is **exemplary** - it demonstrates CUPID principles perfectly.

The Rust/Windmill implementation is **almost entirely missing** - only types exist, no behavior.

**You have 25 tasks in Vibe Kanban. Get to work. 🚀**

---

**Audit Date:** 2025-12-28  
**Next Review:** After Phase 1 completion (Core Foundation)  
**Vibe Kanban Project:** meal-planner (0822d2f5-692d-4f0a-acbb-b9c1422876e9)
