# Architectural Audit: meal-planner vs. Event-Driven Principles

**Date:** 2025-12-27
**Scope:** Assess alignment with "Serverless Event-Driven Architecture" principles
**Reference:** Sam Newman's patterns (CPCQ, autonomous services, event-first)

---

## Executive Summary

**Current Architecture:** Synchronous API monolith with shared PostgreSQL
**Target Architecture:** Event-driven autonomous services
**Alignment Score:** 20/100 (Good foundations, missing event-first layer)

### Key Findings:

✅ **STRONG:** Type-safe error handling (Result monad), clear service boundaries, excellent test infrastructure
⚠️ **MODERATE:** Consolidated query builders/encoders, thoughtful domain design, but no event backbone
❌ **MISSING:** Event sourcing, CQRS, eventual consistency, async messaging, bulkheads, event replay

---

## 1. Current Architecture Analysis

### 1.1 Architecture Type: Synchronous Monolith

```
┌─────────────────────────────────────────────┐
│      CURRENT: Synchronous Monolith         │
├─────────────────────────────────────────────┤
│                                             │
│  HTTP Request                              │
│      ↓                                      │
│  Wisp Handler                              │
│      ↓                                      │
│  Service Layer (Tandoor/FatSecret client)  │
│      ↓                                      │
│  External API Call (blocking)              │
│      ↓                                      │
│  Shared PostgreSQL Database                │
│      ↓                                      │
│  HTTP Response (synchronous)               │
│                                             │
└─────────────────────────────────────────────┘
```

**Characteristics:**
- Request → Handler → Service → API → DB → Response (all blocking)
- NO message queues between services
- NO event topics or subscribers
- NO eventual consistency
- Strong consistency via shared DB transactions

### 1.2 Data Flow Example: Meal Planning

**Current Flow (Synchronous):**

```
1. Handler receives request: POST /api/meals/generate
2. Calls get_recipes() → Tandoor API (HTTP blocking)
3. Calls get_nutrition() → FatSecret API (HTTP blocking)
4. Calls calculate_plan() → NCP module (in-memory)
5. Writes result to PostgreSQL (transaction)
6. Returns HTTP 200 with result

Total latency: Sum of all network calls + DB write
Failure mode: If FatSecret is down, entire request fails
```

**Desired Flow (Event-Driven):**

```
1. Handler receives request: POST /api/meals/generate
2. Publishes "MealGenerationRequested" event
3. Returns HTTP 202 Accepted (async)
4. Consumer1 listens for event, fetches recipes, publishes "RecipesFetched"
5. Consumer2 listens for "RecipesFetched", fetches nutrition, publishes "NutritionCalculated"
6. Consumer3 listens for "NutritionCalculated", generates plan, publishes "PlanGenerated"
7. Handler polls event stream OR websocket for completion

Total latency: Reduced (async processing)
Failure mode: Each consumer independent; failures don't cascade
```

---

## 2. Service Analysis: Autonomy Assessment

### 2.1 Tandoor Integration Service

| Aspect | Current | Needed | Gap |
|--------|---------|--------|-----|
| **Data Ownership** | Shared PostgreSQL | Own DB + Event Store | HIGH |
| **Communication** | Sync HTTP calls | Async event publish | HIGH |
| **Deployment** | Single binary | Independent deployment | MEDIUM |
| **Isolation** | None (shared DB) | Circuit breaker + timeouts | MEDIUM |
| **Event Store** | None | Immutable log | HIGH |
| **Failure Recovery** | Transactional rollback | Event replay | HIGH |

**Current Code Pattern:**
```gleam
pub fn get_recipe_detail(config: ClientConfig, id: Int) -> Result(Recipe, TandoorError) {
  use response <- result.try(http_client.get(...))  // Blocking
  use parsed <- result.try(json.decode(response.body, recipe_decoder))
  Ok(parsed)
}
// Called synchronously from handler
// If FatSecret is slow, this waits for it
```

**Event-Driven Pattern:**
```gleam
pub fn get_recipe_detail(config: ClientConfig, id: Int) -> Result(EventId, PublishError) {
  use event_id <- result.try(
    event_bus.publish("RecipeDetailRequested", RecipeDetailRequestedPayload(id))
  )
  Ok(event_id)  // Returns immediately
}
// Handler returns 202 Accepted
// Async consumer fetches recipe, publishes RecipeDetailFetched
// Client polls or subscribes to RecipeDetailFetched event
```

**Autonomy Score: 40/100**
- ❌ Data not autonomous (shared DB)
- ❌ Communication is synchronous
- ✅ Domain boundary is clear
- ✅ Error handling is explicit
- ❌ No failure isolation

---

### 2.2 FatSecret Integration Service

| Aspect | Current | Needed | Gap |
|--------|---------|--------|-----|
| **State Management** | OAuth tokens in shared DB | Own token store + event stream | HIGH |
| **Data Consistency** | Strong (transactional) | Eventual (event-based sync) | HIGH |
| **User Sessions** | Stateless handlers | Event-sourced user state | MEDIUM |
| **Meals Logged** | Direct DB insert | Event-sourced meal events | HIGH |
| **Recovery** | Rollback on error | Replay meal events | HIGH |

**Current OAuth Flow:**
```gleam
pub fn get_profile(conn: pog.Connection) -> Result(Profile, ServiceError) {
  use token <- result.try(storage.load_token(conn))  // DB lookup
  use response <- result.try(oauth_client.get_profile(token))  // HTTP call
  Ok(profile)
}
// If DB is slow, entire request stalls
// If token expires, must be refreshed in DB (strong consistency)
```

**Event-Driven Pattern:**
```gleam
pub fn get_profile_async(user_id: String) -> Result(EventId, PublishError) {
  use event_id <- result.try(
    event_bus.publish("ProfileRefreshRequested", ProfileRefreshPayload(user_id))
  )
  Ok(event_id)
}
// Consumer1: Listens for ProfileRefreshRequested
// Consumer1: Fetches fresh token, publishes TokenRefreshed
// Consumer2: Listens for TokenRefreshed
// Consumer2: Fetches profile, publishes ProfileRefreshed
// Read model: ProfileCache subscribes to ProfileRefreshed for fast reads
```

**Autonomy Score: 35/100**
- ❌ OAuth state in shared DB (couples to DB schema)
- ❌ All operations synchronous
- ✅ Domain boundary clear (oauth, diary, exercise, etc.)
- ✅ Good error types (ServiceError)
- ❌ No async retry or bulkheads

---

### 2.3 Cross-Service Dependencies

**Current Dependency Graph:**
```
Handler (web/handlers)
    ├── → Tandoor Service → PostgreSQL (recipes table)
    ├── → FatSecret Service → PostgreSQL (oauth_tokens table)
    ├── → NCP Module → In-memory calculation
    ├── → Generator Module → In-memory knapsack solver
    └── → Meal Sync → Orchestrates all above

PostgreSQL (single point of contention)
    ├── oauth_tokens (FatSecret concern)
    ├── recipes (Tandoor concern)
    ├── nutrition_data (Aggregate concern)
    └── user_profiles (Shared concern)
```

**Problem:** Any DB migration must coordinate all services.

**Event-Driven Alternative:**
```
Handler
    ├── → Event Bus (async, returns immediately)
    │
    ├── Consumer: RecipeRefresh Listener
    │   ├── Fetches from Tandoor
    │   └── Publishes RecipeFetched
    │       ├── RecipeDatabase subscribes (caches in own table)
    │       └── RecipeCache subscribes (in-memory cache)
    │
    ├── Consumer: MealLogListener
    │   ├── Fetches from FatSecret
    │   └── Publishes MealLogged
    │       └── NutritionModel subscribes (denormalized view)
    │
    └── Consumer: PlanGenerationListener
        ├── Runs knapsack solver
        └── Publishes PlanGenerated
            └── PlanCache subscribes
```

**Benefits:** Each consumer owns its data store. Changes don't cascade.

---

## 3. Event-Driven Principles: Gap Analysis

### 3.1 CPCQ Flow (Command, Publish, Consume, Query)

**Expected Pattern:**

```
┌──────────────────────────────────────┐
│     CPCQ: Event-First Design         │
├──────────────────────────────────────┤
│                                      │
│  COMMAND: Synchronous action         │
│  ├─ Validate input                   │
│  ├─ Update local state (own DB)      │
│  └─ Publish event                    │
│                                      │
│  PUBLISH: Event to hub (async)       │
│  └─ Event broker (Windmill queue)    │
│                                      │
│  CONSUME: Async subscribers          │
│  ├─ Consumer 1: Fetch data           │
│  ├─ Consumer 2: Calculate            │
│  └─ Consumer N: Denormalize          │
│                                      │
│  QUERY: Read own cache               │
│  └─ Own database (eventual...)       │
│                                      │
└──────────────────────────────────────┘
```

**Current Implementation: Missing PCQQ Components**

| Step | Current | Gap | Severity |
|------|---------|-----|----------|
| **Command** | ✅ Handlers validate | — | Low |
| **Publish** | ❌ None (synchronous) | No event broker | CRITICAL |
| **Consume** | ❌ None (direct calls) | No subscribers | CRITICAL |
| **Query** | ✅ PostgreSQL reads | But not eventual... | Low |

**What's Missing:**

1. **Publish Step:** No event bus to publish domain events
   ```gleam
   // Current (not happening)
   // publish("MealLogged", MealLoggedPayload(...))
   ```

2. **Consume Step:** No async consumers listening for events
   ```gleam
   // Current (not happening)
   // event_bus.subscribe("MealLogged", fn(event) {
   //   update_nutrition_cache(event.meal)
   // })
   ```

3. **Event Storage:** Events not stored, only mutations
   ```gleam
   // Current: Direct DB writes
   INSERT INTO meals (user_id, recipe_id, ...) VALUES (...)

   // Needed: Event-first writes
   INSERT INTO events (id, type, payload, timestamp) VALUES (...)
   INSERT INTO meals_denormalized (user_id, recipe_id, ...) VALUES (...)
   ```

---

### 3.2 Event Sourcing: The Missing Layer

**Expected Pattern:**

```
┌─────────────────────────────────────────────┐
│    Event Sourcing: Source of Truth          │
├─────────────────────────────────────────────┤
│                                             │
│  Event Store (Immutable Log)                │
│  ├─ 2025-12-27T10:00:00 UserCreated        │
│  ├─ 2025-12-27T10:05:00 MealLogged         │
│  ├─ 2025-12-27T10:06:00 GoalUpdated        │
│  └─ 2025-12-27T10:07:00 ProfileRefreshed  │
│                                             │
│  Read Models (Derived, Denormalized)       │
│  ├─ UserProfile (for fast GET /user)       │
│  ├─ MealDiary (for fast GET /meals)        │
│  ├─ NutritionCache (for analytics)         │
│  └─ RankingCache (for leaderboards)        │
│                                             │
│  Recovery: Replay events → rebuild any view │
│                                             │
└─────────────────────────────────────────────┘
```

**Current Implementation: Direct Writes Only**

```gleam
// No event store
// Direct mutation of state:
INSERT INTO meals (user_id, recipe_id, date, servings) VALUES (...)
INSERT INTO nutrition_data (...) VALUES (...)

// Problems:
// - No audit trail of WHY changes happened
// - Can't replay events to debug
// - Can't rebuild read model if cache corrupted
// - Coupling between write and read models
```

**What Would Change:**

```gleam
// With event sourcing:
pub fn log_meal(user_id, recipe_id, date, servings) -> Result(EventId, Error) {
  // Step 1: Validate
  let payload = MealLoggedPayload(user_id, recipe_id, date, servings)

  // Step 2: Publish immutable event
  use event_id <- result.try(
    event_store.append(event_id, "MealLogged", payload, timestamp)
  )

  // Step 3: Update denormalized read models
  use _ <- result.try(
    meals_cache.insert(user_id, recipe_id, payload)
  )
  use _ <- result.try(
    nutrition_cache.add_meal_nutrients(user_id, payload)
  )

  Ok(event_id)
}

// Recovery: If cache corrupted:
// 1. Clear caches
// 2. Replay all events from event_store
// 3. Rebuild caches
```

**Event Sourcing Score: 0/100**
- ❌ No event store
- ❌ No immutable log
- ❌ No event replay capability
- ❌ No audit trail
- ❌ Directly mutating state (not event-first)

---

### 3.3 CQRS: Command Query Responsibility Segregation

**Expected Pattern:**

```
┌──────────────────────────────────────┐
│  WRITE PATH (Command)                │
├──────────────────────────────────────┤
│  POST /meals/log                     │
│  ├─ Validate MealLogCommand          │
│  ├─ Publish MealLogged event         │
│  └─ Return 202 Accepted              │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  READ PATH (Query)                   │
├──────────────────────────────────────┤
│  GET /user/nutrition                 │
│  ├─ Query denormalized ReadModel     │
│  ├─ Return optimized view            │
│  └─ O(1) lookup (not O(N) scan)      │
└──────────────────────────────────────┘

Both paths separate, independent databases
```

**Current Implementation: Single Model**

```gleam
// Single table serves both read and write
pub type Meal {
  Meal(
    id: Int,
    user_id: String,
    recipe_id: Int,
    logged_at: String,
    servings: Float,
    calories: Int,
    protein: Float,
    ...  // 50+ fields for various read concerns
  )
}

// Write: INSERT INTO meals (...)
// Read: SELECT * FROM meals WHERE user_id = ? ORDER BY logged_at DESC

// Problems:
// - Write schema coupled to read concerns
// - Adding "total_protein_today" field requires all consumers to change
// - No optimization for specific read patterns
// - Can't denormalize without mutating write model
```

**What Would Change with CQRS:**

```gleam
// WRITE MODEL: Just capture the command
pub type Meal {
  Meal(
    id: Int,
    user_id: String,
    recipe_id: Int,
    logged_at: String,
    servings: Float,
    source: MealSource,  // Where logged (FatSecret, manual, etc.)
  )
}

// READ MODELS: Optimized for different concerns

pub type MealDiaryView {
  MealDiaryView(
    date: String,
    meals: List(Meal),
    total_calories: Int,
    total_protein: Float,
    total_carbs: Float,
    total_fat: Float,
  )
}

pub type MealHistoryView {
  MealHistoryView(
    user_id: String,
    recent_meals: List(Meal),  // Last 30 meals
    meal_frequency: Dict(Int, Int),  // recipe_id -> count
    favorite_recipes: List(Int),
  )
}

pub type NutritionTrendView {
  NutritionTrendView(
    date_range: #(String, String),
    daily_averages: List(DailyAverage),
    trend_line: Option(TrendMetrics),
  )
}

// Each READ MODEL subscribes to "MealLogged" event
// Each one maintains its own optimized table
// Write path doesn't know or care about reads
```

**CQRS Score: 0/100**
- ❌ Single model for reads and writes
- ❌ No denormalized views
- ❌ No read model optimization
- ❌ Write and read paths coupled

---

### 3.4 Bulkheads & Resilience

**Expected Pattern:**

```
┌────────────────────────────────────────┐
│    Service A (RecipeService)           │
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │  Event Outbound Bulkhead         │  │
│  │  ├─ Buffer outgoing events       │  │
│  │  └─ Circuit breaker (fail-fast) │  │
│  └──────────────────────────────────┘  │
│           ↓                             │
│       Event Hub (async)                 │
│           ↓                             │
│  ┌──────────────────────────────────┐  │
│  │  Event Inbound Bulkhead          │  │
│  │  ├─ Cache consumed events        │  │
│  │  └─ Replay capability            │  │
│  └──────────────────────────────────┘  │
│           ↓                             │
│    Own database (eventually consistent) │
└────────────────────────────────────────┘
```

**Current Implementation: No Bulkheads**

```gleam
// No isolation between services
pub fn get_recipe(config: ClientConfig, id: Int) -> Result(Recipe, Error) {
  // If Tandoor is down:
  // → timeout (default 30s)
  // → entire handler stalls
  // → client waits
  // → cascades up to load balancer
  // → user sees degradation

  http_client.get(url, timeout: 30000)  // Blocking, no circuit breaker
}

// No recovery mechanism
// If Tandoor returns partial data:
// → stored in DB as-is
// → no rollback, no replay
```

**What's Needed:**

```gleam
// Circuit Breaker Pattern
pub type CircuitBreakerState {
  Closed
  Open(fail_count: Int, last_failure: String)
  HalfOpen
}

pub fn get_recipe_with_breaker(
  config: ClientConfig,
  id: Int,
  breaker: CircuitBreaker,
) -> Result(Recipe, Error) {
  case breaker.state {
    Open(_) -> Error(CircuitBreakerOpen)
    _ -> {
      case http_client.get(config.url, timeout: 5000) {  // Shorter timeout
        Ok(recipe) -> {
          breaker.on_success()  // Reset fail count
          Ok(recipe)
        }
        Error(e) -> {
          breaker.on_failure()  // Increment fail count
          if breaker.fail_count > 5 {
            breaker.open()  // Trip the breaker
          }
          Error(e)
        }
      }
    }
  }
}

// Bulkhead: Event Outbound
pub fn publish_meal_logged(event) -> Result(EventId, PublishError) {
  // Persist to local queue first (in own database)
  use event_id <- result.try(
    local_event_queue.enqueue(event)
  )

  // Then try to publish to hub (best effort)
  use _ <- result.try(
    event_hub.publish(event)
  )

  Ok(event_id)  // Return immediately, even if hub is unreachable
}

// Bulkhead: Event Inbound
pub fn consume_recipe_fetched_event(event) {
  // Cache event locally first
  use _ <- result.try(
    event_cache.store(event)
  )

  // Then update read model (best effort)
  use _ <- result.try(
    recipe_cache.update(event.recipe)
  )

  Ok(())
}
```

**Resilience Score: 20/100**
- ❌ No circuit breakers
- ❌ No timeouts on external calls
- ⚠️ Basic error types (could add retry logic)
- ✅ Result monad allows explicit error handling
- ❌ No bulkheads or isolation

---

### 3.5 Observability & Instrumentation

**Expected Pattern:**

```gleam
// Every public function logs entry, exit, errors

pub fn log_meal(
  user_id: String,
  recipe_id: Int,
  date: String,
  servings: Float,
) -> Result(EventId, Error) {
  // Log entry with trace ID
  logger.info("log_meal.enter", [
    #("user_id", user_id),
    #("recipe_id", string.from_int(recipe_id)),
    #("trace_id", trace_id),
  ])

  // ... implementation ...

  case result {
    Ok(event_id) -> {
      logger.info("log_meal.success", [
        #("event_id", event_id),
        #("trace_id", trace_id),
        #("duration_ms", elapsed),
      ])
      metrics.counter("meals_logged", 1)
      Ok(event_id)
    }
    Error(e) -> {
      logger.error("log_meal.failure", [
        #("error", error_to_string(e)),
        #("trace_id", trace_id),
      ])
      metrics.counter("meals_logged.failed", 1)
      Error(e)
    }
  }
}
```

**Current Implementation: Basic Logging Only**

```gleam
// Minimal instrumentation
pub fn log_meal(...) -> Result(EventId, Error) {
  // No entry/exit logs
  // No structured logging
  // No metrics
  // No trace propagation

  // Only error logging via top-level error handler
}
```

**What's Missing:**
- ❌ Structured logging (JSON with key-value pairs)
- ❌ Trace ID propagation across calls
- ❌ Metrics emission (counters, gauges, histograms)
- ❌ Performance instrumentation (latency per operation)
- ❌ Event count tracking

**Observability Score: 15/100**
- ✅ Error types are descriptive
- ✅ Can add logging without changing logic
- ❌ No current instrumentation
- ❌ No metrics framework
- ❌ No trace context

---

## 4. Positive Findings: What's Working Well

### 4.1 Error Handling Architecture ✅

**Strong Points:**

```gleam
pub type AppError {
  ConfigError(message: String, hint: String)
  DbError(message: String, hint: String)
  NetError(message: String, hint: String)
  AuthenticationError(message: String, hint: String)
  IoError(message: String, hint: String)
  UsageError(message: String, hint: String)
  ApplicationError(message: String, hint: String)
  WrappedError(error: AppError, cause: AppError, context: Dict(String, String))
}

// Compiler forces exhaustive matching
pub fn http_status_code(error: AppError) -> Int {
  case error {
    ConfigError(_) -> 500
    AuthenticationError(_) -> 401
    // All 8 variants covered - compiler error if one is missing
  }
}
```

**Why This Is Important:**
- No silent failures (all errors explicit)
- No exceptions to catch (easier to reason about)
- Rich error context (can debug from logs)
- Compatible with event-driven (errors are events too)

**Recommendation:** Keep this pattern. Extend to emit error events:
```gleam
case result {
  Ok(x) -> Ok(x)
  Error(e) -> {
    event_bus.publish("ErrorOccurred", ErrorPayload(e))
    Error(e)
  }
}
```

---

### 4.2 Domain-Driven Module Boundaries ✅

**Strong Points:**

```
tandoor/                 # Autonomous domain
  ├── core/              # Shared interfaces
  ├── handlers/          # HTTP entry points
  ├── client/            # HTTP client
  ├── decoders/          # JSON parsing
  ├── encoders/          # JSON serialization
  ├── storage/           # Persistence (future event store)
  └── types/             # Domain types

fatsecret/               # Autonomous domain
  ├── profile/
  ├── diary/
  ├── exercise/
  └── service/           # Public API
```

**Why This Is Important:**
- Clear responsibility boundaries
- Easy to find code (mental model matches file structure)
- Testable in isolation
- Ready for event-driven refactoring

**Recommendation:** Formalize as "Aggregate Roots":
```gleam
// tandoor/mod.gleam - public API only
pub fn get_recipe(config, id) -> Result(Recipe, Error)
pub fn list_recipes(config, query) -> Result(Paginated(Recipe), Error)

// fatsecret/service.gleam - business logic
pub fn get_profile(conn) -> Result(Profile, ServiceError)
pub fn log_meal(conn, meal) -> Result(MealLogged, ServiceError)

// Each aggregate responsible for publishing its events
```

---

### 4.3 Consolidated Query Builders & Encoders ✅

**Strong Points:**

```gleam
// shared/query_builders.gleam
pub fn build_pagination_params(limit: Option(Int), offset: Option(Int)) {
  // Eliminates 150-200 lines of duplicate code
}

// shared/response_encoders.gleam
pub fn paginated_response(results, count, next, previous) {
  // Single source of truth for response format
}
```

**Why This Is Important:**
- DRY principle (avoids copy-paste errors)
- Consistency across API
- Easier to refactor (change once, fixes everywhere)
- Foundation for event payload standardization

**Recommendation:** Extract "Event Envelope" pattern:
```gleam
pub type EventEnvelope(T) {
  EventEnvelope(
    event_id: String,           // UUID
    event_type: String,         // "MealLogged", "RecipeFetched"
    payload: T,
    timestamp: String,          // ISO8601
    version: Int,               // Schema version
    trace_id: Option(String),   // For debugging
  )
}

// Single function wraps all events
pub fn create_event_envelope(event_type, payload, trace_id) {
  EventEnvelope(
    event_id: uuid.v4(),
    event_type,
    payload,
    timestamp: datetime.now(),
    version: 1,
    trace_id,
  )
}
```

---

## 5. Gap Summary: What Needs to Change

| Component | Current | Needed | Priority | Effort |
|-----------|---------|--------|----------|--------|
| **Data Ownership** | Shared DB | Autonomous (per service) | CRITICAL | HIGH |
| **Inter-Service Communication** | Sync HTTP | Async events | CRITICAL | HIGH |
| **Event Storage** | None | Immutable event log | HIGH | HIGH |
| **CQRS Models** | Single unified | Separate read/write | HIGH | MEDIUM |
| **Event Publishing** | None | Event bus/broker | HIGH | MEDIUM |
| **Event Consumption** | None | Async subscribers | HIGH | MEDIUM |
| **Bulkheads/Resilience** | Minimal | Circuit breakers, timeouts | MEDIUM | MEDIUM |
| **Observability** | Basic | Structured logging, metrics | MEDIUM | MEDIUM |
| **Feature Flags** | None | Deploy/release decoupling | MEDIUM | LOW |
| **Event Replay** | None | Recovery capability | MEDIUM | HIGH |

---

## 6. Migration Path: Immediate to Long-Term

### Phase 1: Foundation (Weeks 1-2) - Low Risk

**Goal:** Add event infrastructure without changing existing code paths

1. **Create Event Store Table**
   ```sql
   CREATE TABLE events (
     id UUID PRIMARY KEY,
     aggregate_id VARCHAR NOT NULL,  -- user_id, recipe_id, etc.
     event_type VARCHAR NOT NULL,    -- "MealLogged", "RecipeFetched"
     payload JSONB NOT NULL,
     timestamp TIMESTAMP DEFAULT NOW(),
     version INT DEFAULT 1,
     trace_id UUID
   );
   ```

2. **Add Event Bus Abstraction**
   ```gleam
   pub type EventBus {
     EventBus(
       append: fn(EventEnvelope(T)) -> Result(EventId, Error),
       subscribe: fn(EventType, Consumer) -> Result(Subscription, Error),
     )
   }

   // In-memory implementation first (for testing)
   pub fn in_memory_event_bus() -> EventBus

   // PostgreSQL implementation next
   pub fn postgres_event_bus(conn: pog.Connection) -> EventBus
   ```

3. **Add Event Logging to Existing Handlers** (no behavior change)
   ```gleam
   // In handlers, after DB write succeeds:
   case event_bus.append(created_event) {
     Ok(_) -> logger.info("Event logged", [])
     Error(e) -> logger.warn("Event logging failed (non-blocking)", [])
   }
   ```

4. **Create Event Types for Each Domain**
   ```gleam
   // tandoor/events.gleam
   pub type TandoorEvent {
     RecipeFetched(recipe_id: Int, timestamp: String)
     RecipesCached(count: Int, timestamp: String)
   }

   // fatsecret/events.gleam
   pub type FatSecretEvent {
     MealLogged(user_id: String, recipe_id: Int, timestamp: String)
     TokenRefreshed(user_id: String, timestamp: String)
   }
   ```

**Benefits:** Non-breaking, can revert easily, builds foundation.

---

### Phase 2: Async Consumers (Weeks 3-4) - Medium Risk

**Goal:** Add async event consumers without changing handlers

1. **Implement First Async Consumer**
   ```gleam
   // consumers/nutrition_cache_consumer.gleam
   pub fn start_listening(event_bus: EventBus, cache: Cache) -> Result(Subscription, Error) {
     event_bus.subscribe(
       event_type: "MealLogged",
       handler: fn(event: EventEnvelope(MealLoggedPayload)) {
         // Update nutrition cache asynchronously
         cache.add_meal_nutrients(event.payload.user_id, event.payload.meal_data)
       }
     )
   }
   ```

2. **Create Consumer Supervisor** (in Windmill)
   ```yaml
   # windmill/flows/consumer_supervisor.yaml
   modules:
     - id: nutrition_consumer
       type: script
       path: f/consumers/nutrition_cache_consumer
       trigger: on_every_event(event_type: "MealLogged")
   ```

3. **Test Event Replay**
   ```gleam
   // In tests: publish event, verify cache updated
   test("mealLogged event updates nutrition cache") {
     let event = create_meal_logged_event(...)
     assert Ok(_) = event_bus.append(event)
     assert Ok(cached_nutrition) = cache.get_nutrition(user_id)
     assert cached_nutrition == expected_nutrition
   }
   ```

**Benefits:** Real async processing, can add multiple consumers independently.

---

### Phase 3: CQRS Read Models (Weeks 5-6) - Higher Risk

**Goal:** Introduce read/write model separation

1. **Extract First Read Model**
   ```gleam
   // read_models/meal_diary_view.gleam
   pub type MealDiaryView {
     MealDiaryView(
       date: String,
       meals: List(MealSummary),
       total_calories: Int,
       total_protein: Float,
       // Optimized for the specific read concern (daily view)
     )
   }

   // Create separate table: meal_diary_denormalized
   pub fn update_from_event(event: EventEnvelope(MealLoggedPayload)) -> Result(Nil, Error) {
     // Denormalize: aggregate calories, protein, etc.
     // Single query instead of joining tables
   }
   ```

2. **Parallel Read/Write Paths**
   ```gleam
   // Write path: unchanged
   pub fn log_meal(conn, user_id, recipe_id, date) {
     // Insert into meals table (write model)
     let result = meals_table.insert(...)
     // Publish event
     event_bus.append(MealLoggedEvent(...))
   }

   // Read path: new denormalized query
   pub fn get_daily_nutrition(conn, user_id, date) {
     // Query optimized read model (fast)
     meal_diary_view.get_by_date(conn, user_id, date)
   }
   ```

**Benefits:** Read queries become O(1), can scale reads independently.

---

### Phase 4: Event-First Handlers (Weeks 7-8) - Major Change

**Goal:** Make handlers truly async (return 202 Accepted)

```gleam
// Before: Synchronous
pub fn handle_log_meal(req) -> Response {
  let meal = parse_request(req)
  case meal_logger.log_meal(conn, meal) {
    Ok(result) -> json_response(result, 200)
    Error(e) -> error_response(e, 400)
  }
}

// After: Asynchronous
pub fn handle_log_meal_async(req) -> Response {
  let meal = parse_request(req)
  case event_bus.publish(MealLogRequestedEvent(meal)) {
    Ok(event_id) -> json_response(
      json.object([
        #("status", "PENDING"),
        #("event_id", event_id),
        #("follow_up", "/api/events/" <> event_id),
      ]),
      202
    )
    Error(e) -> error_response(e, 500)
  }
}

// Client polls: GET /api/events/{event_id} -> returns result when ready
// Or: WebSocket subscribe to /api/events/{event_id} -> pushed result
```

---

## 7. Windmill Integration Strategy

**Current State:** Windmill runs imperative scripts (Python, TypeScript)
**Target State:** Windmill as event orchestrator

### Transformation:

```yaml
# Before: Imperative flow
- id: fetch_recipes
  type: script
  content: |
    result = fetch_recipes_api()
    db.insert_recipes(result)
    return result

- id: generate_plan
  depends_on: fetch_recipes
  content: |
    recipes = db.get_recipes()
    plan = generate_plan_algorithm(recipes)
    return plan

# After: Event-driven flow
- id: publish_recipe_refresh
  type: script
  content: |
    event_id = event_bus.publish("RecipeRefreshRequested")
    return { status: "PENDING", event_id }

- id: listen_recipe_refreshed
  trigger: event_type="RecipeRefreshed"
  content: |
    event = listen_for_event()
    cache_recipes(event.payload.recipes)
    event_bus.publish("RecipeCached", event)

- id: listen_plan_generated
  trigger: event_type="RecipeCached"
  content: |
    recipes = get_cached_recipes()
    plan = generate_plan_algorithm(recipes)
    event_bus.publish("PlanGenerated", plan)
```

**Windmill as Event Broker:**
- Each Windmill task publishes/consumes events
- Triggers are event subscriptions (`trigger: event_type="X"`)
- No direct DB writes (only via event consumers)
- Can replay entire workflow by replaying events

---

## 8. Quick Wins: No Architecture Change Required

These can be done immediately to move toward event-driven principles without refactoring:

### 8.1 Add Structured Logging ✅

```gleam
// Before
logger.info("Recipe fetched")

// After
logger.info("RecipeFetched", [
  #("recipe_id", string.from_int(id)),
  #("user_id", user_id),
  #("duration_ms", elapsed),
  #("trace_id", trace_id),
])
```

**Why:** Foundation for understanding event flow, debugging, observability.

---

### 8.2 Add Timeout + Retry Logic ✅

```gleam
// Before
http_client.get(url)

// After
result.try_with_retries(
  fn() { http_client.get(url, timeout: 5000) },
  max_attempts: 3,
  backoff: exponential(base: 1000)
)
```

**Why:** Resilience against transient failures.

---

### 8.3 Document Domain Events (DDD) ✅

Create `DOMAIN_EVENTS.md`:
```markdown
## Tandoor Domain Events

### RecipeFetched
- **When:** User requests a specific recipe
- **Payload:** recipe_id, user_id, timestamp
- **Consumers:** RecipeCache, Analytics
- **Example:** {"event_type": "RecipeFetched", "recipe_id": 123}

### RecipesCached
- **When:** Bulk recipe fetch completes
- **Payload:** recipe_ids, count, timestamp
- **Consumers:** RecipeCache, SearchIndex
```

**Why:** Clarity on what events exist, foundation for event-driven design.

---

### 8.4 Add Feature Flags for Deployment Decoupling ✅

```gleam
pub fn handle_get_recipes(req) {
  case feature_flags.is_enabled("use_async_recipe_fetch") {
    True -> {
      // New event-driven path (when ready)
      event_bus.publish("RecipeListRequested", ListPayload(...))
    }
    False -> {
      // Old synchronous path
      tandoor_client.list_recipes(config)
    }
  }
}
```

**Why:** Deploy async code path without enabling it. Gradually roll out.

---

### 8.5 Add Circuit Breaker to External Calls ✅

```gleam
pub fn get_recipe_with_breaker(config, id) {
  let breaker = circuit_breaker.new(
    failure_threshold: 5,
    reset_timeout: 60000,
  )

  case breaker.is_open() {
    True -> Error(CircuitBreakerOpen)
    False -> {
      case http_client.get(config.url, timeout: 5000) {
        Ok(resp) -> {
          breaker.record_success()
          Ok(resp)
        }
        Error(e) -> {
          breaker.record_failure()
          Error(e)
        }
      }
    }
  }
}
```

**Why:** Prevents cascading failures to external APIs.

---

## 9. Recommendations

### Immediate (This Sprint)

1. ✅ Document domain events (DOMAIN_EVENTS.md)
2. ✅ Add structured logging with trace IDs
3. ✅ Add timeouts to all external API calls
4. ✅ Implement circuit breaker for Tandoor/FatSecret clients
5. ✅ Create event types for each domain (no behavior change)

### Short-Term (2-3 Sprints)

6. 📋 Create PostgreSQL event store table
7. 📋 Implement EventBus abstraction (in-memory + PostgreSQL)
8. 📋 Add event appending to existing handlers (non-blocking)
9. 📋 Create first async consumer (nutrition cache)
10. 📋 Add feature flag for async paths

### Medium-Term (4-6 Sprints)

11. 🏗️ Extract first read model (MealDiaryView)
12. 🏗️ Implement event replay capability
13. 🏗️ Deploy FatSecret as standalone service (own DB + events)
14. 🏗️ Windmill flows become event publishers, not data transformers

### Long-Term (Ongoing)

15. 🚀 All services autonomous with event stores
16. 🚀 Cross-service consistency via eventual consistency
17. 🚀 Event lake for audit and replay
18. 🚀 Observability dashboard tracking all events

---

## 10. Conclusion

**Current State:** Synchronous monolith with shared DB, strong type safety, clear domain boundaries.

**Target State:** Event-driven autonomous services with eventual consistency, async messaging, bulkheads.

**Gap:** Missing event infrastructure (event bus, event store, async consumers, CQRS read models).

**Path:** Non-breaking incremental migration (Phase 1-4, 6-8 weeks).

**Foundation:** Excellent error handling and domain design already in place. Ready to layer event-driven patterns on top.

**Windmill Role:** Transform from imperative orchestrator to event broker. Each Windmill task becomes an async event consumer.

**Key Principle:** Start with events as audit trail (append-only). Gradually extract events as primary interaction mechanism.

---

**Next Step:** Approve Phase 1 (Foundation). Create Beads issues for:
1. Event store schema
2. EventBus abstraction
3. Event types per domain
4. Event appending to existing handlers (non-breaking)

