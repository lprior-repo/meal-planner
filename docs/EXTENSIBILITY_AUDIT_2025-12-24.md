# Future Extensibility Audit - meal-planner

**Date:** 2025-12-24
**Agent:** Agent-Maintain-2 (81/96)
**Scope:** Module structure, interface design, separation of concerns, extensibility patterns

---

## Executive Summary

**Overall Status:** 🟡 MODERATE - Good architectural foundations with clear improvement path

The meal-planner codebase demonstrates **solid extensibility patterns** in its type system, error handling, and module organization, but is currently hampered by **large monolithic files** that make extension difficult. Active refactoring (Epic MP-0vh) is addressing these issues systematically.

**Key Metrics:**
- Total Gleam files: 163+
- Files >500 lines: 48+ (needs reduction)
- Largest file: 1612 lines (tandoor/client.gleam)
- Module organization: Well-structured by domain (fatsecret/, tandoor/, cli/, types/)
- Type safety: Excellent (opaque types, exhaustive matching, Result types)
- Interface boundaries: Clean (minimal cross-module coupling)

---

## 1. Module Organization

### ✅ Strengths

#### Domain-Based Structure
```
src/meal_planner/
├── fatsecret/          # FatSecret API integration
│   ├── core/           # Config, errors, HTTP, OAuth
│   ├── diary/          # Food diary operations
│   │   ├── types.gleam
│   │   ├── client.gleam
│   │   ├── decoders.gleam
│   │   ├── service.gleam
│   │   └── handlers/   # HTTP handlers (being split)
│   ├── weight/         # Weight tracking
│   ├── exercise/       # Exercise logging
│   ├── foods/          # Food database
│   └── ...
├── tandoor/            # Tandoor API integration
│   ├── core/           # Error, HTTP, pagination, multipart
│   ├── client/         # HTTP client (mod.gleam, http.gleam)
│   ├── types/          # Domain types
│   ├── api/            # Generic CRUD, query builders
│   └── clients/        # Resource-specific clients
├── types/              # Shared type definitions
│   ├── mod.gleam       # Central index
│   ├── macros.gleam
│   ├── nutrition.gleam
│   ├── recipe.gleam
│   └── ...
├── cli/                # TUI interface
│   ├── screens/        # Screen components
│   │   ├── weight/     # MVC split (model, messages, update, view)
│   │   ├── exercise/   # MVC split (model, messages, update, view)
│   │   └── ...
│   ├── domains/        # Command handlers
│   └── components/     # Reusable UI components
└── storage/            # Database layer
```

**Analysis:**
- ✅ Clear separation by integration (fatsecret vs tandoor)
- ✅ Consistent sub-module structure (types, client, service, handlers)
- ✅ Core modules isolated (core/) from resource-specific modules
- ✅ Types centralized in types/ with mod.gleam as index
- ✅ CLI follows emerging MVC pattern (weight, exercise screens split)

#### Layered Architecture (FatSecret Example)

```
fatsecret/diary/
├── types.gleam          # Domain types (FoodEntry, MealType, etc.)
├── client.gleam         # API calls (create_food_entry, get_food_entry)
├── decoders.gleam       # JSON parsing
├── service.gleam        # Business logic orchestration
└── handlers/            # HTTP endpoint handlers
    ├── create.gleam
    ├── get.gleam
    ├── list.gleam
    └── ...
```

**Benefits:**
- Easy to extend with new endpoints (add handler)
- Easy to swap implementations (change client while keeping service)
- Clear testing boundaries (mock client, test service)

### ⚠️ Concerns

#### Large Monolithic Files

| File | Lines | Status | Issue |
|------|-------|--------|-------|
| `tandoor/client.gleam` | 1612 | 🔴 | Monolithic, all operations (tracked: MP-0vh.3) |
| `cli/screens/weight_view.gleam` | 1427 | 🔴 | Model+Msg+Update+View mixed (tracked: MP-0vh.5) |
| `cli/screens/nutrition_view.gleam` | 1392 | 🔴 | Model+Msg+Update+View mixed (tracked: MP-0vh.6) |
| `cli/screens/scheduler_view.gleam` | 1350 | 🔴 | Model+Msg+Update+View mixed |
| `cli/screens/recipe_view.gleam` | 1241 | 🔴 | Model+Msg+Update+View mixed |
| `cli/screens/exercise_view.gleam` | 1159 | 🔴 | Model+Msg+Update+View mixed |
| `tandoor/shopping.gleam` | 1105 | 🔴 | Shopping list operations |
| `cli/domains/nutrition.gleam` | 1063 | 🔴 | Multiple commands in one file |

**Impact on Extensibility:**
- ❌ Difficult to locate specific functionality
- ❌ Merge conflicts when multiple agents/developers work in parallel
- ❌ Cognitive load when reading/understanding
- ❌ Harder to test in isolation
- ❌ AI agents struggle with large context windows

**Mitigation (Active):**
Epic MP-0vh tracks splitting these files to <300 lines each using:
- CLI screens: MVC pattern (model/ messages/ update/ view/)
- API clients: Split by resource type
- Handlers: One handler per endpoint

---

## 2. Interface Design

### ✅ Strengths

#### Opaque Types for Domain Safety

```gleam
// fatsecret/diary/types.gleam
pub opaque type FoodEntryId {
  FoodEntryId(String)
}

pub fn food_entry_id(id: String) -> FoodEntryId {
  FoodEntryId(id)
}

pub fn food_entry_id_to_string(id: FoodEntryId) -> String {
  let FoodEntryId(s) = id
  s
}
```

**Files Using Opaque Types (18 found):**
- `types/recipe.gleam` (RecipeId)
- `types/user_profile.gleam` (UserId)
- `types/pagination.gleam` (PageToken)
- `tandoor/types.gleam` (various IDs)
- `fatsecret/diary/types.gleam` (FoodEntryId)
- `fatsecret/weight/types.gleam` (WeightEntryId)
- `fatsecret/exercise/types.gleam` (ExerciseEntryId)
- ...and 11 more

**Benefits:**
- ✅ Compile-time prevention of ID mixing (can't use WeightEntryId where FoodEntryId expected)
- ✅ Clear API boundaries (explicit constructors)
- ✅ Easy to change internal representation without breaking callers

#### Comprehensive Error Types

```gleam
// fatsecret/core/errors.gleam
pub type FatSecretError {
  ApiError(code: ApiErrorCode, message: String)
  RequestFailed(status: Int, body: String)
  ParseError(message: String)
  OAuthError(message: String)
  NetworkError(message: String)
  ConfigMissing
  InvalidResponse(message: String)
}

pub type ApiErrorCode {
  MissingOAuthParameter
  InvalidSignature
  InvalidAccessToken
  ApiUnavailable
  MissingRequiredParameter
  InvalidDate
  NoEntries
  UnknownError(code: Int)
}

// Helper functions for error classification
pub fn is_recoverable(error: FatSecretError) -> Bool
pub fn is_auth_error(error: FatSecretError) -> Bool
pub fn error_to_string(error: FatSecretError) -> String
```

**Similar patterns in:**
- `tandoor/core/error.gleam` (TandoorError)
- `scheduler/errors.gleam` (SchedulerError)
- `fatsecret/meal_logger/errors.gleam` (MealLoggerError)

**Benefits:**
- ✅ Exhaustive error handling (compiler enforces all cases)
- ✅ Easy to add new error types without breaking existing code
- ✅ Clear error categorization (recoverable vs auth vs validation)
- ✅ Consistent error-to-string conversion

#### Flexible Configuration Types

```gleam
// fatsecret/core/config.gleam
pub type FatSecretConfig {
  FatSecretConfig(
    consumer_key: String,
    consumer_secret: String,
    api_host: Option(String),        // Optional override
    auth_host: Option(String),       // Optional override
  )
}

pub fn from_env() -> Option(FatSecretConfig)
pub fn new(consumer_key: String, consumer_secret: String) -> FatSecretConfig
pub fn get_api_host(config: FatSecretConfig) -> String  // Uses default if None
```

```gleam
// tandoor/client/mod.gleam
pub type AuthMethod {
  SessionAuth(
    username: String,
    password: String,
    session_id: Option(String),
    csrf_token: Option(String),
  )
  BearerAuth(token: String)
}

pub type ClientConfig {
  ClientConfig(
    base_url: String,
    auth: AuthMethod,
    timeout_ms: Int,
    retry_on_transient: Bool,
    max_retries: Int,
  )
}
```

**Benefits:**
- ✅ Backwards-compatible additions (add optional fields with Option)
- ✅ Multiple authentication strategies (SessionAuth vs BearerAuth)
- ✅ Environment-based config (from_env) or explicit construction (new)
- ✅ Sensible defaults with overrides

### ⚠️ Concerns

#### No Plugin/Extension Mechanism

**Current State:**
- API integrations are hardcoded (fatsecret, tandoor)
- No trait/protocol system for "any nutrition API" or "any recipe API"
- Adding new backend requires modifying core CLI/command code

**Impact:**
- ❌ Difficult to add third-party integrations
- ❌ Cannot swap backends without code changes
- ❌ Testing with mock backends requires modifying production code

**Future Improvement:**
Define common interfaces:
```gleam
// Hypothetical extension point
pub type NutritionProvider {
  NutritionProvider(
    get_daily_log: fn(String) -> Result(NutritionData, ProviderError),
    create_food_entry: fn(FoodEntryInput) -> Result(FoodEntry, ProviderError),
    // ...
  )
}

// Implementations
pub fn fatsecret_provider(config: FatSecretConfig) -> NutritionProvider
pub fn tandoor_provider(config: TandoorConfig) -> NutritionProvider
pub fn mock_provider() -> NutritionProvider  // For testing
```

---

## 3. Separation of Concerns

### ✅ Strengths

#### Clean Dependency Boundaries

**Analysis of tandoor/client.gleam imports:**
```gleam
import gleam/dynamic
import gleam/http
import gleam/httpc
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/logger  // Only 1 internal dependency!
```

**Analysis of fatsecret/diary/client.gleam imports:**
```gleam
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth
import meal_planner/fatsecret/diary/decoders
import meal_planner/fatsecret/diary/types
import meal_planner/logger  // Only core + logger dependencies
```

**Benefits:**
- ✅ Minimal coupling between modules
- ✅ Client layer only depends on core infrastructure
- ✅ Easy to test in isolation (few dependencies to mock)
- ✅ Clear layering (core -> client -> service -> handlers)

#### Service Layer Pattern

**Example: fatsecret/diary/service.gleam**
```gleam
// Service orchestrates client calls + business logic
pub fn log_meal(
  config: FatSecretConfig,
  token: AccessToken,
  meal_data: MealData,
) -> Result(MealLogResult, FatSecretError) {
  use entries <- result.try(
    meal_data.foods
    |> list.map(fn(food) {
      client.create_food_entry(config, token, food)
    })
    |> result.all
  )

  // Business logic: Calculate totals
  let totals = calculate_meal_totals(entries)
  Ok(MealLogResult(entries: entries, totals: totals))
}
```

**Benefits:**
- ✅ Business logic isolated from HTTP/API concerns
- ✅ Easy to test (mock client, test service logic)
- ✅ Reusable across different interfaces (CLI, web API, batch jobs)

#### Type-Driven Separation (types/ module)

**From types/mod.gleam:**
```gleam
/// Central type definitions module
///
/// Specific type modules are split for better organization:
/// - macros.gleam: Macros type and calculations
/// - micronutrients.gleam: Vitamins, minerals
/// - food.gleam: Food, FoodEntry, FoodSource
/// - recipe.gleam: Recipe and Ingredient types
/// - meal_plan.gleam: MealPlan and MealSlot types
/// - nutrition.gleam: NutritionData and NutritionGoals
/// - ...
```

**Benefits:**
- ✅ Types separate from operations (no logic in type files)
- ✅ Easy to find type definitions (central index)
- ✅ Low coupling (import only types you need)

### ⚠️ Concerns

#### CLI Commands Tightly Coupled to Backends

**Example: cli/domains/nutrition/commands.gleam**
```gleam
use conn <- result.try(postgres.connect(db_config))
case storage.get_daily_log(conn, date_str) {
  // Directly calls postgres + storage layer
}
```

**Impact:**
- ❌ Cannot easily swap storage backend (postgres -> sqlite, memory, etc.)
- ❌ Testing requires real database or complex mocking
- ❌ Cannot run same command against tandoor vs fatsecret without duplicating code

**Future Improvement:**
Introduce repository pattern:
```gleam
pub type NutritionRepository {
  NutritionRepository(
    get_daily_log: fn(String) -> Result(NutritionData, Error),
    save_daily_log: fn(String, NutritionData) -> Result(Nil, Error),
  )
}

pub fn postgres_repository(conn: Connection) -> NutritionRepository
pub fn in_memory_repository() -> NutritionRepository
```

---

## 4. Extensibility Patterns

### ✅ Strengths

#### Generic CRUD Pattern

**From tandoor/api/generic_crud.gleam:**
```gleam
pub type CrudHandler(item, create_req, update_req, error) {
  CrudHandler(
    list: fn() -> Result(ListResponse(item), error),
    create: fn(create_req) -> Result(item, error),
    get: fn(Int) -> Result(item, error),
    update: fn(Int, update_req) -> Result(item, error),
    delete: fn(Int) -> Result(Nil, error),
    encode_item: fn(item) -> json.Json,
    error_to_response: fn(error) -> Response,
  )
}

pub fn handle_collection(
  req: Request,
  handler: CrudHandler(item, create_req, update_req, error),
) -> Response
```

**Benefits:**
- ✅ Single implementation for all CRUD endpoints
- ✅ Type-safe (compiler enforces all operations)
- ✅ Easy to add new resources (implement handler, plug in)
- ✅ Consistent error handling across all endpoints

#### Consolidated Query Builders

**From tandoor/api/query_builders.gleam:**
```gleam
pub fn build_pagination_params(
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String))

pub fn build_search_params(
  query: Option(String),
  limit: Option(Int),
  page: Option(Int),
) -> List(#(String, String))

pub fn add_optional_string_param(
  params: List(#(String, String)),
  name: String,
  value: Option(String),
) -> List(#(String, String))
```

**Benefits:**
- ✅ Eliminates 150-200 lines of duplication
- ✅ Consistent parameter ordering
- ✅ Easy to add new parameter types
- ✅ Handles Option values transparently

#### MVC Pattern (CLI Screens)

**Emerging pattern in cli/screens/weight/:**
```
weight/
├── mod.gleam        # Re-exports, public API
├── model.gleam      # State types (WeightModel, WeightViewState)
├── messages.gleam   # Events (WeightMsg variants)
├── update.gleam     # State transitions (weight_update function)
└── view.gleam       # Rendering (weight_view function)
```

**Benefits:**
- ✅ Clear separation of concerns (model, view, controller)
- ✅ Easy to test (update function pure, view function pure)
- ✅ Multiple agents can work in parallel (model, messages, view separate)
- ✅ Screens <300 lines each instead of 1400+

### ⚠️ Concerns

#### Inconsistent Pattern Application

**Current State:**
- ✅ weight/ screen: MVC split complete
- ✅ exercise/ screen: MVC split complete
- ⚠️ nutrition_view.gleam: Still monolithic (1392 lines)
- ⚠️ scheduler_view.gleam: Still monolithic (1350 lines)
- ⚠️ recipe_view.gleam: Still monolithic (1241 lines)

**Impact:**
- ❌ Inconsistent developer experience
- ❌ Some screens easy to extend, others difficult
- ❌ Parallel work blocked on unsplit screens

**Mitigation (Active):**
Epic MP-0vh tracks splitting all screens to MVC pattern.

---

## 5. Interface Boundary Analysis

### Module Export Counts

**Sample Analysis (pub fn counts):**
- `ncp.gleam`: 24 public functions
- `config.gleam`: 15+ public functions
- `errors.gleam`: 756 lines, many exports
- `types/nutrition.gleam`: 653 lines, many exports

**Recommendation:**
- Target: <15 public exports per module
- Large export counts suggest potential for sub-module split
- Consider facade pattern (mod.gleam re-exports from sub-modules)

### Cross-Module Coupling

**Low Coupling Examples:**
- ✅ `tandoor/client.gleam` → only imports logger
- ✅ `fatsecret/diary/client.gleam` → only imports core + logger
- ✅ `types/*` → minimal cross-imports (mostly stdlib)

**Higher Coupling Examples:**
- ⚠️ CLI commands → depend on storage + postgres + config
- ⚠️ Handlers → depend on client + encoders + query_builders

**Recommendation:**
- Continue facade pattern (core/ modules)
- Consider dependency injection for storage/database
- Use repository pattern to abstract data access

---

## 6. Testing & Extension Points

### Current Testing Patterns

**From code inspection:**
- Unit tests exist for type conversions (error codes, meal types)
- Integration tests use real HTTP clients
- No clear mock/stub infrastructure

### Missing Extension Points

1. **Mock Transport for Testing**
   - Found: `tandoor/testing/mock_transport.gleam` (exists!)
   - Status: Good foundation for testing without real API

2. **Repository Pattern for Storage**
   - Status: Missing
   - Impact: Tests require real database
   - Recommendation: Add storage abstraction

3. **Provider Pattern for APIs**
   - Status: Missing
   - Impact: Cannot swap backends easily
   - Recommendation: Add common nutrition/recipe interfaces

---

## 7. Recommendations

### High Priority (Blocking Extensibility)

1. **Complete Epic MP-0vh Refactoring** 🔴
   - Split tandoor/client.gleam (1612 lines → resource modules)
   - Split remaining CLI screens to MVC pattern
   - Target: All files <500 lines (ideally <300)
   - **Impact:** Unblocks parallel development, improves AI agent performance

2. **Introduce Repository Pattern** 🔴
   ```gleam
   pub type NutritionRepository {
     NutritionRepository(
       get_daily_log: fn(String) -> Result(NutritionData, Error),
       save_daily_log: fn(String, NutritionData) -> Result(Nil, Error),
     )
   }
   ```
   - **Impact:** Enables storage backend swapping, easier testing

3. **Define Provider Interfaces** 🟡
   ```gleam
   pub type NutritionProvider {
     NutritionProvider(
       get_entry: fn(EntryId) -> Result(FoodEntry, Error),
       create_entry: fn(FoodEntryInput) -> Result(FoodEntry, Error),
       // ...
     )
   }
   ```
   - **Impact:** Enables third-party integrations, mock providers for testing

### Medium Priority (Improves Extensibility)

4. **Reduce Module Export Counts** 🟡
   - Target: <15 public functions per module
   - Use facade pattern (mod.gleam) for controlled exports
   - **Impact:** Clearer APIs, easier to understand module boundaries

5. **Consolidate Error Types** 🟡
   - Consider common error base type
   - Reduce duplication across domain errors
   - **Impact:** Consistent error handling, less code duplication

6. **Document Extension Points** 🟡
   - Create EXTENDING.md guide
   - Document plugin patterns
   - Provide examples for common extensions
   - **Impact:** Lower barrier for contributions

### Low Priority (Nice to Have)

7. **Configuration DSL** 🟢
   - Fluent builder pattern for configs
   - Validation at construction time
   - **Impact:** Better developer experience

8. **Event System** 🟢
   - Pub/sub for cross-module communication
   - Reduce tight coupling
   - **Impact:** More flexible architecture

---

## 8. Conclusion

### Summary Scores

| Category | Score | Rationale |
|----------|-------|-----------|
| **Module Organization** | 🟡 7/10 | Good structure, but large files hinder navigation |
| **Interface Design** | 🟢 8/10 | Excellent use of opaque types, Result, Option |
| **Separation of Concerns** | 🟢 8/10 | Clean layering, minimal coupling |
| **Extensibility Patterns** | 🟡 6/10 | Good patterns exist but inconsistently applied |
| **Testing Support** | 🟡 5/10 | Some infrastructure, but lacks mocking/stubs |
| **Documentation** | 🟡 6/10 | Good inline docs, but missing extension guides |
| **Overall** | 🟡 7/10 | Solid foundation, clear improvement path |

### Key Takeaways

**Strengths:**
1. ✅ Excellent type safety (opaque types, Result, exhaustive matching)
2. ✅ Clean module boundaries (minimal coupling)
3. ✅ Consistent error handling with domain-specific errors
4. ✅ Emerging patterns (MVC, service layer, generic CRUD)
5. ✅ Active refactoring addressing main concerns (Epic MP-0vh)

**Weaknesses:**
1. ❌ Large monolithic files (1000-1600 lines)
2. ❌ Inconsistent pattern application (some screens MVC, others not)
3. ❌ No plugin/provider abstraction
4. ❌ Tight coupling to specific backends in CLI
5. ❌ Limited testing infrastructure (mocks, stubs)

### Extensibility Verdict

**The meal-planner codebase is moderately extensible** with a clear path to excellent extensibility:

- **Current state:** Adding new features requires navigating large files and modifying multiple coupled modules
- **With MP-0vh complete:** Codebase will be highly extensible with small, focused modules and consistent patterns
- **With provider pattern:** Codebase will support third-party integrations and backend swapping

**Recommendation:** Prioritize completing Epic MP-0vh refactoring. The architectural foundations are sound; the main blocker is file size and pattern inconsistency.

---

## Appendix A: File Size Distribution

```
Files by size bracket:
  0-100 lines:    ~30 files
  100-300 lines:  ~60 files
  300-500 lines:  ~35 files
  500-1000 lines: ~25 files
  1000+ lines:    ~13 files  ← Target for splitting

Largest files:
  1612 lines: tandoor/client.gleam
  1427 lines: cli/screens/weight_view.gleam
  1392 lines: cli/screens/nutrition_view.gleam
  1350 lines: cli/screens/scheduler_view.gleam
  1241 lines: cli/screens/recipe_view.gleam
  1159 lines: cli/screens/exercise_view.gleam
  1105 lines: tandoor/shopping.gleam
  1064 lines: cli/screens/diary_view.gleam
  1063 lines: cli/domains/nutrition.gleam
```

---

## Appendix B: Module Dependencies

### Clean Separation Examples

**tandoor/client.gleam:**
```
External: gleam/*, httpc
Internal: meal_planner/logger (1 dependency)
```

**fatsecret/diary/client.gleam:**
```
External: gleam/*
Internal:
  meal_planner/fatsecret/core/*
  meal_planner/fatsecret/diary/types
  meal_planner/fatsecret/diary/decoders
  meal_planner/logger
(All within fatsecret/ domain + logger)
```

### Higher Coupling Examples

**cli/domains/nutrition/commands.gleam:**
```
Internal:
  meal_planner/config
  meal_planner/ncp
  meal_planner/postgres
  meal_planner/storage
  meal_planner/storage/profile
  meal_planner/types/macros
(Crosses multiple domains)
```

**Recommendation:** Introduce repository/provider abstractions to reduce cross-domain coupling.

---

**End of Audit**
