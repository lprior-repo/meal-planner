# Windmill as Centralized Event Broker + Rust Services

**Architecture Vision:** Windmill IS the event orchestrator and broker. Rust services are autonomous, stateless compute units.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   WINDMILL (Central Hub)                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EVENT TRIGGERING SYSTEM               │   │
│  │  • Webhooks (external events)                       │   │
│  │  • Schedules (time-based events)                    │   │
│  │  • Flow-to-flow calls (choreography)               │   │
│  │  • Internal event topics (future)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        FLOW DAG (Orchestration Layer)              │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │   │
│  │  │ Pre-     │→ │ Module 1 │→ │ Module 2 │→ ...   │   │
│  │  │processor │  │(Rust)    │  │(Rust)    │        │   │
│  │  └──────────┘  └──────────┘  └──────────┘        │   │
│  │       ↓            ↓              ↓               │   │
│  │  Immutable    JSON I/O       JSON I/O            │   │
│  │  Contract     State          State               │   │
│  └─────────────────────────────────────────────────────┘   │
│          ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         FLOW STATE & RESULTS (In-Flow Memory)      │   │
│  │  • results.step_id (read-only, immutable)          │   │
│  │  • flow_input (flow parameters)                    │   │
│  │  • Intermediate state between steps                │   │
│  └─────────────────────────────────────────────────────┘   │
│          ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        CHOREOGRAPHY (Flow Triggers)                │   │
│  │  • Flow A publishes event (via HTTP/webhook)      │   │
│  │  • Webhook triggers Flow B                        │   │
│  │  • Flow B runs independently with new context     │   │
│  │  • No direct dependencies between flows           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │     PERSISTENCE & OBSERVABILITY                    │   │
│  │  • Job logs (audit trail)                          │   │
│  │  • Flow execution history                          │   │
│  │  • Job results (cacheable)                         │   │
│  │  • Task metrics (time, status, retry counts)       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         ↓                    ↓                    ↓
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │   Rust   │      │   Rust   │      │   Rust   │
    │ Service1 │      │ Service2 │      │ Service3 │
    │          │      │          │      │          │
    │Tandoor   │      │FatSecret │      │Generator │
    │Client    │      │Service   │      │Logic     │
    └──────────┘      └──────────┘      └──────────┘
    (Stateless)       (Stateless)       (Stateless)
    (Autonomous)      (Autonomous)      (Autonomous)
```

---

## Key Design Principles

### 1. Windmill = Event Broker + Orchestrator (Not Custom Infrastructure)

**Current State:**
```yaml
# windmill/f/meal_planning/plan_generation.flow/flow.yaml
summary: Generate meal plan for user

modules:
  - id: preprocessor
    type: rawscript
    content: !inline preprocessor.ts
    # Converts webhook/external event into flow parameters
    # Returns: { user_id, target_calories, dietary_preferences }

  - id: fetch_recipes
    type: script
    path: f/services/tandoor/fetch_recipes
    input_transforms:
      base_url: { type: static, value: "$res:f/config/tandoor_url" }
      query: { type: javascript, expr: "flow_input.dietary_preferences" }

  - id: generate_plan
    type: script
    path: f/services/generator/generate_plan
    input_transforms:
      recipes: { type: javascript, expr: "results.fetch_recipes.recipes" }
      target_calories: { type: javascript, expr: "flow_input.target_calories" }

    retry:
      exponential:
        attempts: 3
        seconds: 2
        multiplier: 2

    timeout: 30000

  - id: sync_to_fatsecret
    type: script
    path: f/services/fatsecret/sync_meals
    input_transforms:
      plan: { type: javascript, expr: "results.generate_plan" }
      user_id: { type: javascript, expr: "flow_input.user_id" }

  - id: notify_user
    type: rawscript
    content: !inline notify.ts
    input_transforms:
      plan: { type: javascript, expr: "results.generate_plan" }
      webhook_url: { type: javascript, expr: "flow_input.webhook_callback" }
```

**What Windmill Provides (No Custom Code Needed):**
- ✅ Event triggering (webhook receives event)
- ✅ Flow orchestration (executes steps in order)
- ✅ Data flow between steps (`results.step_id`)
- ✅ Retry logic (per-step exponential backoff)
- ✅ Timeouts (per-step execution limits)
- ✅ Result caching (TTL-based)
- ✅ Error handling (failure module)
- ✅ Audit trail (job logs)
- ✅ State isolation (flow instance = event context)

**What Rust Services Provide:**
- ✅ Stateless compute (no memory between invocations)
- ✅ Pure functions (input → processing → output)
- ✅ Error handling (Result<T, E>)
- ✅ External integrations (HTTP calls to APIs)
- ✅ Observability (structured logging)

---

### 2. Choreography: Flows Trigger Flows (Not Orchestration)

**Pattern: Loose Coupling Between Flows**

```typescript
// Scenario: Meal plan generation triggers nutrition sync

// Flow 1: Generate meal plan
modules:
  - id: notify_on_complete
    type: rawscript
    content: |
      export async function main(plan: Plan, webhook_url: string) {
        // Publish event: this is a trigger for other flows
        await fetch(webhook_url, {
          method: "POST",
          body: JSON.stringify({
            event_type: "PlanGenerated",
            plan_id: plan.id,
            user_id: plan.user_id,
            timestamp: new Date().toISOString()
          })
        });

        return { status: "published" };
      }
    input_transforms:
      plan: { type: javascript, expr: "results.generate_plan" }
      webhook_url: { type: static, value: "https://windmill.local/api/w/meal/flows/sync_nutrition/trigger" }

// Flow 2: Sync nutrition (triggered independently)
// Windmill webhook endpoint receives the event
// Spawns new flow execution with new context
// No dependency on Flow 1 after event published
```

**Benefits:**
- ✅ Flows are completely independent
- ✅ Flow 1 doesn't wait for Flow 2
- ✅ Flow 2 can be retried independently
- ✅ New consumers can subscribe to same event (by creating new flows)
- ✅ Failures don't cascade between flows

---

### 3. Windmill Features (Already Aligned with Event-Driven)

| Feature | Purpose | Event-Driven Pattern |
|---------|---------|---------------------|
| **Flow Input** | Flow parameters | Event payload |
| **Preprocessor** | Transform external event → flow input | Event normalization |
| **Step Results** | `results.step_id` | Immutable intermediate state |
| **Input Transforms** | Map inputs to steps | Event routing |
| **Retry Logic** | Exponential backoff per step | Failure resilience |
| **Timeout** | Per-step execution limit | Circuit breaker |
| **Caching** | TTL-based result caching | Event memoization |
| **Job Logs** | Complete execution history | Audit trail |
| **Failure Module** | Triggered on any step failure | Error event handler |
| **Webhooks** | HTTP event trigger | Event ingestion |
| **Schedules** | CRON-based triggers | Time-based events |
| **Flow-to-Flow** | Subflow calls | Event choreography |

**All Built-In. No Custom Event Infrastructure Needed.**

---

## Migration Guide: Current → Event-Driven

### Phase 1: Deploy Rust Services (Week 1-2)

Move meal-planner services from Gleam to Rust Windmill scripts:

```bash
windmill/f/services/
├── tandoor/
│   ├── fetch_recipes/
│   │   ├── script.rs          # Rust script (stateless)
│   │   ├── script.yaml        # Windmill metadata
│   │   └── script.lock        # Dependency lock
│   └── list_recipes/
│
├── fatsecret/
│   ├── sync_meals/
│   │   ├── script.rs
│   │   ├── script.yaml
│   │   └── script.lock
│   └── get_nutrition/
│
├── generator/
│   ├── generate_plan/
│   │   ├── script.rs
│   │   ├── script.yaml
│   │   └── script.lock
│   └── validate_meal/
│
└── shared/
    ├── notify_completion/
    ├── log_event/
    └── error_handler/
```

Each script:
```rust
// windmill/f/services/tandoor/fetch_recipes/script.rs
use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Deserialize)]
pub struct Input {
    base_url: String,
    query: String,
    api_token: String,
}

#[derive(Serialize)]
pub struct Output {
    recipes: Vec<Recipe>,
    count: usize,
}

fn main(input: Input) -> Result<Output> {
    // Stateless, pure function
    // Input → Process → Output
    // No state persistence
    // Single responsibility

    let client = reqwest::blocking::Client::new();
    let recipes = client
        .get(&format!("{}/api/recipes", input.base_url))
        .bearer_auth(&input.api_token)
        .query(&[("q", &input.query)])
        .send()?
        .json::<Vec<Recipe>>()?;

    Ok(Output {
        count: recipes.len(),
        recipes,
    })
}
```

### Phase 2: Create Flows (Week 2-3)

Orchestrate services into flows:

```yaml
# windmill/f/flows/user_meal_planning.flow/flow.yaml
summary: Complete meal planning workflow

schema:
  type: object
  required: [user_id, target_calories]
  properties:
    user_id: { type: string }
    target_calories: { type: integer }
    dietary_preferences: { type: array, items: { type: string } }
    webhook_url: { type: string, description: "Where to POST results" }

value:
  modules:
    # Step 1: Validate input
    - id: validate_input
      type: rawscript
      content: !inline validate.ts
      input_transforms:
        user_id: { type: javascript, expr: "flow_input.user_id" }
        calories: { type: javascript, expr: "flow_input.target_calories" }

    # Step 2: Fetch recipes (independent Rust service)
    - id: fetch_recipes
      type: script
      path: f/services/tandoor/fetch_recipes
      input_transforms:
        base_url: { type: static, value: "$res:f/config/tandoor_url" }
        query: { type: javascript, expr: "flow_input.dietary_preferences.join(' ')" }
        api_token: { type: static, value: "$res:f/config/tandoor_api_token" }

    # Step 3: Generate meal plan (independent Rust service)
    - id: generate_plan
      type: script
      path: f/services/generator/generate_plan
      input_transforms:
        recipes: { type: javascript, expr: "results.fetch_recipes.recipes" }
        target_calories: { type: javascript, expr: "flow_input.target_calories" }
        constraints: { type: javascript, expr: "flow_input.dietary_preferences" }

    # Step 4: Sync to FatSecret (independent Rust service)
    - id: sync_meals
      type: script
      path: f/services/fatsecret/sync_meals
      input_transforms:
        plan: { type: javascript, expr: "results.generate_plan" }
        user_id: { type: javascript, expr: "flow_input.user_id" }

      # Resilience: retry independently
      retry:
        exponential:
          attempts: 3
          seconds: 1
          multiplier: 2

    # Step 5: Notify user (publish event for other flows)
    - id: publish_event
      type: rawscript
      content: !inline publish_event.ts
      input_transforms:
        plan: { type: javascript, expr: "results.generate_plan" }
        user_id: { type: javascript, expr: "flow_input.user_id" }
        webhook_url: { type: javascript, expr: "flow_input.webhook_url" }

  # Failure handler: runs if any step fails
  failure_module:
    id: failure
    type: rawscript
    content: !inline handle_failure.ts
```

### Phase 3: Event-Driven Choreography (Week 3-4)

Create dependent flows triggered by completion events:

```yaml
# windmill/f/flows/nutrition_analysis.flow/flow.yaml
summary: Analyze nutrition metrics (triggered by PlanGenerated event)

schema:
  type: object
  properties:
    plan: { type: object }
    user_id: { type: string }

value:
  modules:
    - id: analyze_nutrition
      type: script
      path: f/services/ncp/analyze_nutrition
      input_transforms:
        plan: { type: javascript, expr: "flow_input.plan" }
        user_id: { type: javascript, expr: "flow_input.user_id" }

    - id: update_cache
      type: rawscript
      content: |
        export async function main(analysis, user_id) {
          // Update nutrition cache (stateless)
          return { cached: true };
        }
```

**Webhook to Trigger:**
```
POST /api/w/meal/flows/nutrition_analysis/trigger
```

**Payload (from meal planning flow):**
```json
{
  "plan": { "meals": [...], "total_calories": 2000 },
  "user_id": "user-123"
}
```

---

## Design Principles Summary

### What Windmill Provides (Don't Reinvent)

✅ **Event Triggering**
- Webhooks (external events)
- Schedules (time-based)
- Flow-to-flow calls (choreography)

✅ **Orchestration**
- DAG execution model
- Step result passing
- Conditional branching
- Loops and parallel execution

✅ **Resilience**
- Per-step retry
- Per-step timeout
- Per-step caching
- Error handling (failure module)

✅ **Observability**
- Job logs
- Execution history
- Performance metrics
- Audit trail

### What Rust Services Provide (Autonomous Units)

✅ **Stateless Compute**
- No persistent state
- Pure functions
- Input → processing → output

✅ **External Integration**
- HTTP calls to APIs
- Database queries (read-only within flow context)
- External service calls

✅ **Error Handling**
- Result<T, E> pattern
- Explicit error types
- Structured logging

---

## Architecture Quality Checklist

| Principle | Status | How Achieved |
|-----------|--------|--------------|
| **Autonomous Services** | ✅ | Rust scripts own their processing |
| **Decoupled Communication** | ✅ | Flows trigger flows via webhooks |
| **Immutable Contracts** | ✅ | JSON input/output between steps |
| **Resilience** | ✅ | Per-step retry, timeout, caching |
| **Event-First** | ✅ | Webhooks publish events that trigger flows |
| **Clean & Crisp** | ✅ | No custom event infrastructure |
| **Eventual Consistency** | ✅ | Each flow runs independently |
| **Observable** | ✅ | Job logs and execution history |
| **Scalable** | ✅ | Windmill workers scale independently |

---

## Key Takeaways

1. **Windmill IS the event broker** - Use its native trigger system, don't build custom infrastructure
2. **Rust scripts = stateless compute units** - Like Lambda functions, they process events and return results
3. **Flows = event processors** - Each flow handles a specific domain event
4. **Choreography = loose coupling** - Flows trigger other flows via webhooks, not dependencies
5. **Crisp & clean = no extra complexity** - Lean on Windmill's built-in features

---

## Validation Questions

- [ ] Are Rust scripts truly stateless? (No in-memory state between invocations)
- [ ] Does each script have a single responsibility? (One actor, one verb)
- [ ] Are flows triggered by events, not dependencies? (No `depends_on` chains)
- [ ] Is the result of each flow published for downstream consumers? (Via webhook/event)
- [ ] Can I deploy each Rust service independently? (No monolith)
- [ ] Can I retry each step independently? (No cascading failures)
- [ ] Can I replace any Rust service without affecting others? (Loose coupling)

