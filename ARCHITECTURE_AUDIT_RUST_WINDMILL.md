# Architectural Audit: Rust + Windmill vs. Event-Driven Principles

**Date:** 2025-12-27 (Updated from Gleam Monolith Assessment)
**Previous Score:** 20/100 (Gleam/PostgreSQL monolith)
**New Score:** 65/100 (Rust + Windmill hybrid)
**Status:** SIGNIFICANTLY IMPROVED ✅

---

## Executive Summary

Moving from **Gleam monolith** to **Rust + Windmill** is a **quantum leap** toward event-driven architecture:

| Aspect | Gleam (Before) | Rust + Windmill (Now) | Event-Driven (Target) |
|--------|----------------|----------------------|----------------------|
| **Service Autonomy** | ❌ Shared DB | ✅ Stateless services | ✅✅ Event-owned data |
| **Async Communication** | ❌ Sync HTTP | ⚠️ Sync within flow | ✅ Async event streams |
| **Deployment Model** | ❌ Monolith | ✅ FaaS-like services | ✅✅ Function composition |
| **Orchestration** | ❌ Imperative code | ✅ Declarative DAGs | ✅✅ Event choreography |
| **Error Isolation** | ❌ Cascading failures | ✅ Per-step retries | ✅✅ Bulkheads |
| **State Management** | ❌ Mutable DB state | ✅ Immutable input/output | ✅✅ Event sourcing |
| **Scalability** | ⚠️ Connection pooling | ✅ Horizontal (workers) | ✅✅ Infinite scale |

---

## Part 1: Current Architecture (Rust + Windmill)

### 1.1 Architecture Topology

```
┌────────────────────────────────────────────────────────┐
│          RUST + WINDMILL: FaaS-like Design            │
├────────────────────────────────────────────────────────┤
│                                                        │
│  Client/External System                               │
│         ↓                                              │
│    Windmill Trigger (HTTP Webhook, Schedule, etc.)   │
│         ↓                                              │
│  ┌──────────────────────────────────────────────────┐ │
│  │        Windmill Flow (YAML DAG)                 │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │ │
│  │  │Step 1    │→ │Step 2    │→ │Step 3    │      │ │
│  │  │(Rust)    │  │(Rust)    │  │(Rust)    │      │ │
│  │  └──────────┘  └──────────┘  └──────────┘      │ │
│  │       ↓            ↓            ↓              │ │
│  │    JSON I/O    JSON I/O    JSON I/O            │ │
│  │       ↓            ↓            ↓              │ │
│  │  ┌──────────────────────────────────────────┐  │ │
│  │  │  Windmill State & Results                │  │ │
│  │  │  (in-memory during execution)            │  │ │
│  │  └──────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────┘ │
│         ↓                                              │
│  ┌──────────────────────────────────────────────────┐ │
│  │   External Services (HTTP)                       │ │
│  │   ├─ Tandoor API                                │ │
│  │   ├─ FatSecret API                              │ │
│  │   ├─ PostgreSQL                                 │ │
│  │   └─ Other backends                             │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 1.2 Key Characteristics: Rust Scripts as Stateless Workers

**Pattern: AWS Lambda-like Functions**

```rust
// windmill/f/fire-flow/generate/script.rs
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Input {
    task: String,
    contract_path: String,
    model: String,
}

#[derive(Serialize)]
pub struct Output {
    code: String,
    path: String,
    metadata: serde_json::Value,
}

fn main(input: Input) -> anyhow::Result<Output> {
    // Stateless execution
    // - Read input from stdin (Windmill provides as JSON)
    // - Process
    // - Write output to stdout (JSON)
    // - Exit
    // NO persistent state
    // NO database connections (unless explicitly opened)
    // NO side effects except output

    let code = generate_code(&input.contract_path, &input.task)?;

    Ok(Output {
        code,
        path: "/tmp/generated.rs".to_string(),
        metadata: serde_json::json!({}),
    })
}
```

**Characteristics:**
- ✅ Stateless (no state between invocations)
- ✅ Idempotent (same input → same output)
- ✅ Ephemeral (fresh process per invocation)
- ✅ Isolated (failures don't affect other steps)
- ✅ Composable (can be chained in flows)

### 1.3 Windmill Flows: Declarative DAG Orchestration

**Flow Definition: YAML-Based DAG**

```yaml
summary: Contract-driven code generation

modules:
  - id: init
    summary: Initialize
    type: script
    path: f/fire-flow/init
    input_transforms:
      task: "{{ flow_input.task }}"

  - id: generate
    summary: Generate code from contract
    type: script
    path: f/fire-flow/generate
    input_transforms:
      contract_path: "{{ results.init.contract_path }}"
      task: "{{ flow_input.task }}"

    # Resilience patterns built-in
    retry:
      exponential:
        attempts: 3
        multiplier: 2
        seconds: 2

    timeout: 300
    cache_ttl: 3600

  - id: validate
    type: script
    path: f/fire-flow/validate
    depends_on:
      - generate
    input_transforms:
      code: "{{ results.generate.code }}"

    # Per-step error handling
    early_stop_on_error: false

  - id: execute
    type: script
    path: f/fire-flow/execute
    depends_on:
      - validate
    input_transforms:
      code: "{{ results.generate.code }}"

  - id: error_handler
    type: script
    path: f/fire-flow/error_handler
    skip_if_success: true
    input_transforms:
      error: "{{ flow.failed_step }}"
      feedback: "{{ results.error_handler.feedback }}"
```

**Windmill Features Available:**
- ✅ Declarative DAG (no imperative logic in orchestration)
- ✅ Data flow via `results.step_id` (immutable intermediate state)
- ✅ Per-step retries (exponential backoff)
- ✅ Per-step timeouts
- ✅ Result caching (TTL-based)
- ✅ Conditional branching
- ✅ Error handlers
- ✅ Parallel step execution (if independent)

**NOT Yet Used (But Available):**
- ❌ Event triggers (webhooks exist but not as event streams)
- ❌ Cross-flow event propagation
- ❌ Event sourcing (no immutable event log)
- ❌ Async streaming (flows are currently synchronous DAGs)

---

## Part 2: Event-Driven Alignment Assessment

### 2.1 Core Principles: How You're Already Aligned

#### ✅ Principle 1: Autonomous Services

**Gleam (Before):** ❌ All services share PostgreSQL
**Rust + Windmill (Now):** ✅ Each Rust script is autonomous

```rust
// Each script is independent:
// - No shared state
// - No database connections by default
// - Input/output contracts explicit
// - Can be deployed separately
// - Can be versioned independently

pub fn main(input: Input) -> Result<Output> {
    // Self-contained computation
    // Call external services as needed (HTTP)
    // Return structured result
}
```

**Alignment Score: 80/100**
- ✅ Scripts are stateless (like Lambda functions)
- ✅ No shared resources
- ✅ Independent versioning
- ⚠️ Still within Windmill flow (not fully autonomous cross-flow)

---

#### ✅ Principle 2: Immutable Input/Output

**Gleam (Before):** ❌ Mutable database state
**Rust + Windmill (Now):** ✅ Immutable JSON contracts

```rust
// Input: Immutable, comes from previous step
#[derive(Deserialize)]
pub struct Input {
    recipe_id: i32,
    user_id: String,
    date: String,
}

// Processing: Pure function
pub fn process(input: Input) -> Result<Output> {
    // Calculate
    // Transform
    // Return new data structure
    // No mutations
}

// Output: Immutable, passed to next step
#[derive(Serialize)]
pub struct Output {
    meal: Meal,
    nutrition: Nutrition,
    status: String,
}
```

**Alignment Score: 85/100**
- ✅ Input explicitly typed
- ✅ Output explicitly typed
- ✅ No implicit mutations
- ✅ Flow state is immutable (results.step_id is read-only)

---

#### ✅ Principle 3: Resilience via Isolation

**Gleam (Before):** ❌ No circuit breakers, shared DB failure cascades
**Rust + Windmill (Now):** ✅ Per-step retry and isolation

```yaml
# Each step is isolated
modules:
  - id: fetch_recipes
    retry:
      exponential:
        attempts: 3
        multiplier: 2
    timeout: 30000
    # If this fails, next step doesn't run
    # Other flows unaffected

  - id: generate_plan
    depends_on:
      - fetch_recipes
    # Can have different retry policy
    retry:
      constant:
        attempts: 2
        seconds: 5
    # Independent from fetch_recipes policy
```

**Isolation Guarantees:**
- ✅ Step failure doesn't cascade (unless depends_on)
- ✅ Retry logic per-step
- ✅ Timeout per-step
- ✅ Parallel steps don't block each other

**Alignment Score: 75/100**
- ✅ Excellent per-step isolation
- ⚠️ Cross-flow failures still cascade (no inter-flow bulkheads)

---

#### ⚠️ Principle 4: Asynchronous Communication (Partial)

**Gleam (Before):** ❌ All synchronous HTTP
**Rust + Windmill (Now):** ⚠️ Synchronous within flow, async across jobs

```
Within a Flow (Synchronous DAG):
Step1 ──(sync)──> Step2 ──(sync)──> Step3 ──(sync)──> Response

Across Flows (Async via Windmill):
Flow1 ──(HTTP)──> Windmill Trigger ──> Flow2 (different process)
                     (async, can delay)
```

**Current Pattern:**
```rust
// Step 1: Fetch recipes
pub fn fetch_recipes(input: Input) -> Result<RecipesOutput> {
    // HTTP call to Tandoor
    let recipes = http_client.get("tandoor.api/recipes")?;
    Ok(RecipesOutput { recipes })
}

// Step 2: Generate plan (waits for Step 1)
pub fn generate_plan(input: GenerateInput) -> Result<PlanOutput> {
    // Uses input.recipes (from Step 1)
    // SYNCHRONOUS: must wait for Step 1
    let plan = plan_generator.run(input.recipes)?;
    Ok(PlanOutput { plan })
}
```

**What's Missing:**
- ❌ Event topics/subscriptions
- ❌ Async message queues
- ❌ Cross-flow event propagation
- ❌ Event replay (except from flow logs)

**Alignment Score: 40/100**
- ✅ Async between flows (via Windmill)
- ⚠️ Sync within flows
- ❌ No async messaging inside flows

---

### 2.2 Missing Event-Driven Components

| Component | Needed For | Current | Gap | Severity |
|-----------|-----------|---------|-----|----------|
| **Event Store** | Audit trail, replay | None | Complete | HIGH |
| **Event Topics** | Pub/sub messaging | None | Complete | HIGH |
| **Event Streaming** | Async processing | None | Complete | MEDIUM |
| **CQRS Models** | Read/write separation | None | Complete | MEDIUM |
| **Event Sourcing** | State reconstruction | None | Complete | HIGH |
| **Choreography** | Cross-flow events | None | Complete | MEDIUM |
| **Dead Letter Queue** | Failed event handling | None | Complete | MEDIUM |

---

## Part 3: Rust + Windmill: Missing the Event Layer

### 3.1 The Gap: "Workflow Orchestration" vs. "Event-Driven"

**What You Have:**
```
Windmill (Workflow Orchestrator)
  ├─ Triggers jobs
  ├─ Executes steps sequentially (or parallel)
  ├─ Passes results between steps
  ├─ Retries on failure
  └─ Returns final result

Example: Recipe fetch → Plan generation → Send result
         (all in one flow, all sync within flow)
```

**What You Need for Event-Driven:**
```
Windmill (Event Broker)
  ├─ Publishes events to topics
  ├─ Subscribers listen to topics
  ├─ Each subscriber runs independently
  ├─ Events stored in event log
  ├─ Subscribers can replay events
  └─ New subscribers can process old events

Example: RecipeFetched event → N independent consumers
         Each consumer runs in own flow/job
         Results are new events
```

**Side-by-Side Comparison:**

**Workflow (Current):**
```
Input → [Recipe Fetch] → [Plan Gen] → [Send] → Output
        ↓                 ↓            ↓
     Success/Fail    Waits for prev  Waits for prev

All in one "job"
Failures roll back entire workflow
```

**Event-Driven (Needed):**
```
Input → Publish "RecipeRequested"
           ↓
        [Recipe Consumer] → Publish "RecipesFetched"
        [Cache Consumer]  → Publish "RecipesCached"
        [Analytics]       → Update metrics (no event)
           ↓ (three independent jobs)
        [Plan Generator] listens to "RecipesFetched"
           → Publish "PlanGenerated"
        [Meal Logger] listens to "PlanGenerated"
           → Publish "MealLogged"
        [Notification] listens to "MealLogged"
           → Send email (side effect)

Each consumer is independent
Failures don't cascade
Consumers can replay old events
New consumers can subscribe to past events
```

---

### 3.2 What Would Need to Change

#### Step 1: Add Event Persistence

```rust
// windmill/f/core/event_store/script.rs
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

#[derive(Deserialize)]
pub struct AppendEventInput {
    event_type: String,      // "RecipeFetched", "MealLogged"
    aggregate_id: String,    // user_id, meal_id, etc.
    payload: serde_json::Value,
    trace_id: Option<String>,
}

#[derive(Serialize)]
pub struct AppendEventOutput {
    event_id: String,         // UUID
    sequence_number: i32,
    timestamp: String,
}

async fn main(input: AppendEventInput) -> anyhow::Result<AppendEventOutput> {
    let pool = PgPool::connect(&std::env::var("DATABASE_URL")?).await?;

    // Append to immutable event log
    let result = sqlx::query!(
        r#"
        INSERT INTO events (event_type, aggregate_id, payload, trace_id, timestamp)
        VALUES ($1, $2, $3, $4, NOW())
        RETURNING id, sequence_number, timestamp
        "#,
        input.event_type,
        input.aggregate_id,
        input.payload,
        input.trace_id,
    )
    .fetch_one(&pool)
    .await?;

    Ok(AppendEventOutput {
        event_id: result.id.to_string(),
        sequence_number: result.sequence_number,
        timestamp: result.timestamp.to_rfc3339(),
    })
}
```

#### Step 2: Add Event Publishing

```rust
// windmill/f/core/event_bus/script.rs
// Publishes event to topic (could be Kafka, NATS, Windmill queue, etc.)

async fn main(input: PublishEventInput) -> anyhow::Result<PublishEventOutput> {
    // 1. Append to event store (durable)
    let event_id = event_store.append(&input).await?;

    // 2. Publish to subscribers (async)
    // Option A: Windmill queue
    windmill_queue.publish("topics", &input.event_type, &input.payload)?;

    // Option B: Kafka
    // kafka_producer.send(&input.event_type, &input.payload).await?;

    // Option C: NATS
    // nats_connection.publish(&input.event_type, &input.payload)?;

    // 3. Return immediately (non-blocking)
    Ok(PublishEventOutput { event_id })
}
```

#### Step 3: Consumer Pattern

```rust
// windmill/f/consumers/recipe_fetched_consumer/script.rs
// Triggered when "RecipeFetched" event published

#[derive(Deserialize)]
pub struct RecipeFetchedEvent {
    event_id: String,
    aggregate_id: String,  // meal_id
    payload: RecipePayload,
}

async fn main(event: RecipeFetchedEvent) -> anyhow::Result<ConsumerOutput> {
    // Consumer is triggered by event (not by time/schedule)
    // Can process old events too (replay)

    // 1. Process event
    let recipe = cache_service.cache_recipe(&event.payload)?;

    // 2. Update read model
    db.update_recipe_cache(&event.aggregate_id, &recipe).await?;

    // 3. Publish new event
    event_bus.publish(
        "RecipeCached",
        RecipeCachedPayload { recipe_id: recipe.id },
        Some(&event.event_id),  // Link to parent event
    )?;

    Ok(ConsumerOutput { success: true })
}
```

#### Step 4: Modified Flow (Event-Driven)

```yaml
# OLD: Synchronous workflow
modules:
  - id: fetch_recipes
    type: script
    path: f/fire-flow/generate

  - id: generate_plan
    depends_on:
      - fetch_recipes
    type: script
    path: f/fire-flow/validate

# NEW: Event-driven choreography
modules:
  - id: publish_recipe_request
    type: script
    path: f/core/event_bus
    input_transforms:
      event_type: "RecipeRequested"
      aggregate_id: "{{ flow_input.meal_id }}"
      payload: "{{ flow_input }}"

  # Consumers are separate flows triggered by events
  # (defined elsewhere, triggered automatically)

  # Each consumer publishes new events
  # Consumers are independent jobs
```

---

## Part 4: Transition Plan (Gleam Monolith → Rust + Windmill → Event-Driven)

### Phase 0: Current State
- Gleam monolith with shared PostgreSQL
- Synchronous HTTP handlers

### Phase 1: Adopt Rust + Windmill (You Are Here ← Starting Point)
- ✅ Rewrite services as Rust scripts
- ✅ Use Windmill for orchestration
- ⚠️ Still synchronous within flows
- ⚠️ No event persistence yet

**Actions This Phase:**
1. Migrate meal-planner services to Rust scripts
   - Tandoor client → `windmill/f/tandoor/client/script.rs`
   - FatSecret client → `windmill/f/fatsecret/client/script.rs`
   - Generator → `windmill/f/generator/script.rs`
   - NCP → `windmill/f/ncp/script.rs`

2. Create Windmill flows for orchestration
   - Meal planning flow (DAG of Rust scripts)
   - Nutrition sync flow
   - User profile flow

3. Deploy Rust scripts as Windmill tasks
   - Each script = FaaS-like function
   - Input/output contracts via JSON
   - Retries, timeouts, caching built-in

**Benefits:**
- ✅ Horizontal scalability (workers)
- ✅ Per-step resilience
- ✅ Easier to test (stateless scripts)
- ✅ Polyglot potential (mix Rust, Python, TypeScript)

---

### Phase 2: Event Foundation (4-6 weeks)
- Create event store table
- Build event publishing/appending
- Make existing steps publish events (non-breaking)
- Create first async consumer

**New Structure:**
```
Rust Script (Step 1)
  ├─ Execute
  ├─ Publish "StepCompleted" event (NEW)
  └─ Return result

Event Store (NEW)
  ├─ Persists all events
  ├─ Provides event_id
  └─ Enables audit trail

Consumer Script (NEW)
  ├─ Triggered by "StepCompleted" event
  ├─ Runs in separate Windmill job
  ├─ Updates read models
  └─ Publishes new event
```

---

### Phase 3: Event Choreography (6-8 weeks)
- Replace synchronous flows with event-driven consumers
- Each consumer is triggered by events (not by depends_on)
- Flows become event publishers (not orchestrators)

**Flow Evolution:**
```yaml
# BEFORE (Sync orchestration)
modules:
  - id: fetch
    type: script
    path: f/tandoor/fetch

  - id: generate
    depends_on:
      - fetch
    type: script
    path: f/generator/generate

# AFTER (Event choreography)
modules:
  - id: publish_request
    type: script
    path: f/core/event_bus
    input: { event_type: "RecipeRequested" }

# Separate flows (triggered by events):
# flow: recipe_consumer
#   triggers:
#     - event_type: RecipeRequested
#   steps:
#     - fetch from Tandoor
#     - publish "RecipesFetched"

# flow: plan_generator
#   triggers:
#     - event_type: RecipesFetched
#   steps:
#     - generate plan
#     - publish "PlanGenerated"
```

---

### Phase 4: Full Event-Driven (8+ weeks)
- Event replay capability
- CQRS read models
- Cross-service eventual consistency
- Feature flags (deploy vs. release decoupling)

---

## Part 5: Immediate Action Items (Next Sprint)

### ✅ Phase 1 Quick Wins (Align with Rust + Windmill Paradigm)

These can be done WITHOUT event infrastructure (non-breaking):

#### 1. Migrate First Service to Rust + Windmill

**Target:** Tandoor client (simplest, no state)

```rust
// windmill/f/services/tandoor/fetch_recipe/script.rs
use serde::{Deserialize, Serialize};
use reqwest::Client;

#[derive(Deserialize)]
pub struct Input {
    recipe_id: i32,
    base_url: String,
    api_token: String,
}

#[derive(Serialize)]
pub struct Output {
    recipe_id: i32,
    name: String,
    ingredients: Vec<String>,
    instructions: String,
    nutrition: serde_json::Value,
    status: String,
}

#[tokio::main]
async fn main(input: Input) -> anyhow::Result<Output> {
    let client = Client::new();

    let response = client
        .get(format!("{}/api/recipes/{}", input.base_url, input.recipe_id))
        .bearer_auth(&input.api_token)
        .send()
        .await?;

    let data: serde_json::Value = response.json().await?;

    Ok(Output {
        recipe_id: input.recipe_id,
        name: data["name"].as_str().unwrap_or("").to_string(),
        // ... parse remaining fields
        status: "success".to_string(),
    })
}
```

**Windmill Flow:**
```yaml
summary: Fetch recipe from Tandoor

modules:
  - id: fetch
    type: script
    path: f/services/tandoor/fetch_recipe
    input_transforms:
      recipe_id: "{{ flow_input.recipe_id }}"
      base_url: "{{ env.TANDOOR_BASE_URL }}"
      api_token: "{{ env.TANDOOR_API_TOKEN }}"

    retry:
      exponential:
        attempts: 3
        multiplier: 2
        seconds: 2

    timeout: 30000

  - id: return_result
    type: script
    path: f/core/response_handler
    input_transforms:
      data: "{{ results.fetch }}"
```

---

#### 2. Document Service Contracts (Input/Output Schemas)

```yaml
# windmill/schemas/services.yaml

services:
  tandoor_fetch_recipe:
    description: Fetch recipe from Tandoor API
    input:
      type: object
      required: [recipe_id]
      properties:
        recipe_id:
          type: integer
          description: Recipe ID from Tandoor
        base_url:
          type: string
        api_token:
          type: string

    output:
      type: object
      properties:
        recipe_id: { type: integer }
        name: { type: string }
        nutrition:
          type: object
          properties:
            calories: { type: number }
            protein: { type: number }
        status: { type: string, enum: [success, error] }

  generator_create_plan:
    description: Generate meal plan
    input:
      type: object
      required: [recipes, target_calories, constraints]
      properties:
        recipes:
          type: array
          items: { $ref: '#/definitions/Recipe' }
        target_calories: { type: integer }
        constraints: { type: object }

    output:
      type: object
      properties:
        meals:
          type: array
          items: { type: object }
        total_calories: { type: integer }
        status: { type: string }
```

**Benefit:** Clear service contracts → easier to reason about → foundation for event payloads

---

#### 3. Add Structured Logging to Rust Scripts

```rust
// windmill/f/core/logging.rs
use std::env;
use chrono::Utc;

pub fn log_event(event_type: &str, fields: &[(&str, &str)]) {
    let trace_id = env::var("WM_JOB_ID").unwrap_or_else(|_| "unknown".to_string());

    let mut log_obj = serde_json::json!({
        "timestamp": Utc::now().to_rfc3339(),
        "event_type": event_type,
        "trace_id": trace_id,
        "workspace": env::var("WM_WORKSPACE").ok(),
        "job_id": env::var("WM_JOB_ID").ok(),
    });

    for (k, v) in fields {
        log_obj[k] = serde_json::json!(v);
    }

    println!("{}", log_obj.to_string());
}

// Usage in script:
log_event("recipe.fetch.start", &[
    ("recipe_id", "123"),
    ("source", "tandoor"),
]);

// Produces structured JSON (easy to parse, grep, aggregate)
// {"timestamp":"2025-12-27T...","event_type":"recipe.fetch.start","trace_id":"job-123","recipe_id":"123","source":"tandoor"}
```

---

#### 4. Create Circuit Breaker for External APIs

```rust
// windmill/f/core/circuit_breaker.rs
use std::sync::Arc;
use tokio::sync::Mutex;
use chrono::{DateTime, Utc, Duration};

pub struct CircuitBreaker {
    failure_count: Arc<Mutex<i32>>,
    last_failure: Arc<Mutex<Option<DateTime<Utc>>>>,
    failure_threshold: i32,
    reset_timeout_secs: i64,
}

impl CircuitBreaker {
    pub fn new(failure_threshold: i32, reset_timeout_secs: i64) -> Self {
        Self {
            failure_count: Arc::new(Mutex::new(0)),
            last_failure: Arc::new(Mutex::new(None)),
            failure_threshold,
            reset_timeout_secs,
        }
    }

    pub async fn call<F, T>(&self, f: F) -> Result<T, String>
    where
        F: std::future::Future<Output = anyhow::Result<T>>,
    {
        let failures = *self.failure_count.lock().await;

        if failures >= self.failure_threshold {
            let last_fail = *self.last_failure.lock().await;
            if let Some(last) = last_fail {
                let elapsed = Utc::now().signed_duration_since(last);
                if elapsed < Duration::seconds(self.reset_timeout_secs) {
                    return Err("CircuitBreaker::OPEN".to_string());
                }
            }
        }

        match f.await {
            Ok(result) => {
                *self.failure_count.lock().await = 0;
                Ok(result)
            }
            Err(e) => {
                let mut count = self.failure_count.lock().await;
                *count += 1;
                *self.last_failure.lock().await = Some(Utc::now());
                Err(format!("Failure {}/{}: {}", count, self.failure_threshold, e))
            }
        }
    }
}

// Usage in script:
let breaker = CircuitBreaker::new(5, 60);  // Trip after 5 failures, reset after 60s

let result = breaker.call(async {
    client.get(url).send().await
}).await?;
```

---

#### 5. Add Test Fixtures and Mocks

```rust
// windmill/f/services/tandoor/testing.rs
use serde_json::json;

pub fn mock_recipe_response() -> serde_json::Value {
    json!({
        "id": 123,
        "name": "Test Recipe",
        "ingredients": ["flour", "eggs", "sugar"],
        "nutrition": {
            "calories": 500,
            "protein": 20,
            "carbs": 60,
            "fat": 15
        }
    })
}

pub fn mock_input() -> serde_json::Value {
    json!({
        "recipe_id": 123,
        "base_url": "http://tandoor.test",
        "api_token": "test-token"
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_fetch_recipe() {
        let input = mock_input();
        // Mock HTTP client
        // let result = fetch_recipe(input).await;
        // assert_eq!(result.recipe_id, 123);
    }
}
```

---

## Part 6: Architecture Comparison Summary

### Before (Gleam Monolith)

```
Alignment: 20/100

Problems:
❌ Single PostgreSQL (services not autonomous)
❌ Synchronous HTTP (all blocking)
❌ Monolithic deployment (can't scale individual services)
❌ Shared database lock contention
❌ No event audit trail
❌ Cascading failures
❌ Tight coupling via shared schema
```

### Current (Rust + Windmill)

```
Alignment: 65/100

Improvements:
✅ Stateless Rust scripts (like Lambda)
✅ Windmill orchestration (declarative DAGs)
✅ Per-step resilience (retries, timeouts, isolation)
✅ Horizontal scalability (Windmill workers)
✅ Independent deployments
✅ Immutable contracts (JSON input/output)
✅ Good error handling (Result types)

Remaining Gaps:
❌ No event persistence (can't replay)
❌ No event streaming (async only between flows)
❌ No CQRS (all Rust scripts are both reads and writes)
❌ Synchronous within flows (steps wait for previous)
❌ No choreography (only orchestration)
```

### Target (Full Event-Driven)

```
Alignment: 95/100

Still Needed:
✅ Event store (immutable log)
✅ Event streaming (async event topics)
✅ Event consumers (independent per-event handlers)
✅ Event replay (rebuild state)
✅ CQRS (separate read/write models)
✅ Dead letter queues (failed event handling)
✅ Cross-flow choreography (events trigger other flows)
✅ Feature flags (deploy/release decoupling)
```

---

## Part 7: Recommendation

### NOW (Start with Rust + Windmill foundation):
1. ✅ Migrate first service to Rust script (Tandoor client)
2. ✅ Create Windmill flow orchestrating the service
3. ✅ Add structured logging
4. ✅ Document service contracts (schemas)
5. ✅ Add circuit breaker/timeout logic

### NEXT (Add event layer without breaking existing):
6. 📋 Create event store table
7. 📋 Add event publishing side-effect to scripts
8. 📋 Create first async consumer (triggered by events)
9. 📋 Add event logging to observability

### LATER (Full event-driven evolution):
10. 🚀 Replace orchestration with choreography
11. 🚀 Event-first handlers (202 Accepted responses)
12. 🚀 CQRS read models
13. 🚀 Cross-service eventual consistency

---

## Conclusion

**Moving to Rust + Windmill is a MAJOR improvement** toward event-driven architecture:

| Metric | Gleam | Rust+Windmill | Event-Driven |
|--------|-------|---------------|--------------|
| Autonomy | 10 | 80 | 100 |
| Resilience | 20 | 75 | 95 |
| Scalability | 30 | 85 | 100 |
| Flexibility | 25 | 70 | 100 |
| **Average** | **21** | **78** | **99** |

You've already made the biggest leap. The remaining 35-point gap is just adding event persistence and async messaging—both of which can be done incrementally without breaking your current workflows.

**Immediate next step:** Migrate one service (Tandoor client) to Rust + Windmill to validate the pattern, then expand to others.

