# Meal Planner EDA Architecture

## Overview

Complete migration from Gleam + Wisp to **Pure Rust + Windmill EDA Orchestration**.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Windmill (EDA Orchestrator)               │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ Event Bus / Message Broker                         │   │
│  └────────────────┬─────────────────────────────────────────┘   │
│                   │                                        │
│         ┌─────────┼─────────┐                           │
│         │         │         │                           │
│         ▼         ▼         ▼                           │
│   ┌──────────┐ ┌─────────┐ ┌─────────┐              │
│   │ Recipe   │ │  Meal   │ │ Nutrition│  Rust Handlers  │
│   │ Handler  │ │  Plan   │ │ Handler  │  (Business Logic)│
│   └──────────┘ └─────────┘ └─────────┘              │
│         │         │         │                           │
│         └─────────┼─────────┘                           │
│                   │                                        │
│                   ▼                                        │
│         ┌──────────────────────┐                              │
│         │   PostgreSQL       │  - State Store              │
│         │   Database         │  - Event Store             │
│         └──────────────────────┘                              │
│                                                          │
│  ┌───────────────────────────────────────────────────────┐    │
│  │ EDA Patterns                                     │    │
│  │ - Idempotency                                    │    │
│  │ - Dead Letter Queue                               │    │
│  │ - Circuit Breaker                                │    │
│  │ - Retry (Exponential Backoff)                     │    │
│  │ - Saga (Distributed Transactions)                 │    │
│  └───────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
windmill/f/meal-planner/
├── events/
│   ├── schemas/              # Event definitions
│   │   └── mod.rs        # All domain event types
│   ├── producers/            # Emit events
│   │   └── emit_event/    # Event producer script
│   └── consumers/            # Process events (future)
├── handlers/              # Business logic (replaces Gleam)
│   ├── recipes/            # Recipe CRUD, nutrition calculation
│   ├── meal_planning/     # Meal plan generation
│   ├── nutrition/          # Nutrition goals, tracking
│   ├── shopping_list/      # Shopping list management
│   ├── fatsecret/         # FatSecret sync
│   └── tandoor/           # Tandoor import/export
├── patterns/              # Reusable EDA patterns
│   ├── idempotency/       # Prevent duplicate processing
│   ├── dlq/              # Dead letter queue
│   ├── retry/             # Retry with backoff
│   ├── circuit_breaker/    # Fail fast on errors
│   └── saga/             # Distributed transactions
├── workflows/             # Orchestration flows
│   ├── recipe_lifecycle/  # Recipe creation/update/delete
│   ├── meal_plan_generation/
│   ├── nutrition_analysis/
│   ├── sync_fatsecret/
│   └── sync_tandoor/
└── resources/             # Resource definitions
    ├── aws/               # Lambda, SQS, SNS configs
    ├── database/           # PostgreSQL configs
    └── external_apis/     # FatSecret, Tandoor configs
```

## Domain Events

All events follow AWS EventBridge pattern:

```rust
pub struct Event<T> {
    pub version: String,      // "1.0"
    pub id: String,           // UUID
    pub source: String,       // "meal-planner"
    pub account: String,      // AWS account or "local"
    pub time: String,         // ISO 8601 timestamp
    pub region: String,       // AWS region or "us-east-1"
    pub resources: Vec<String>, // Affected resources
    pub detail_type: String,   // Event type
    pub detail: T,           // Event-specific data
}
```

### Event Types

**Recipe Events:**
- `RecipeCreated` - New recipe added
- `RecipeUpdated` - Recipe modified
- `RecipeDeleted` - Recipe removed
- `RecipeImported` - Imported from Tandoor/FatSecret

**Meal Plan Events:**
- `MealPlanCreated` - New meal plan
- `MealPlanGenerated` - AI-generated plan
- `MealPlanActivated` - Plan set as active

**Nutrition Events:**
- `NutritionCalculated` - Nutrition computed
- `NutritionGoalSet` - User goals updated

**Shopping List Events:**
- `ShoppingListCreated` - New list
- `ShoppingListUpdated` - Items modified
- `ShoppingListCompleted` - Marked complete

**Sync Events:**
- `FatSecretSyncStarted` - Sync initiated
- `FatSecretSyncCompleted` - Sync finished
- `TandoorImportStarted` - Import initiated
- `TandoorImportCompleted` - Import finished

## EDA Patterns

### 1. Idempotency

**Purpose:** Prevent duplicate event processing

**Implementation:**
```rust
// Check if event already processed
fn check_processed(event_id: String, operation: String) -> bool

// Mark event as processed after success
fn mark_processed(event_id: String, operation: String)
```

**Storage:**
- Redis (production)
- Windmill state (development)
- PostgreSQL with TTL

### 2. Dead Letter Queue

**Purpose:** Handle failed events for replay

**Implementation:**
```rust
fn send_to_dlq(
    event_id: String,
    error_type: String,  // "transient" | "permanent"
    error_message: String,
    retry_count: u32,
)
```

**Actions:**
- Store failed event
- Send alert on permanent errors
- Track retry count
- Enable manual replay

### 3. Circuit Breaker

**Purpose:** Fail fast on cascading failures

**States:**
- **Closed:** Normal operation
- **Open:** Failures exceeded threshold, fail fast
- **Half-Open:** Testing if service recovered

**Triggers:**
- 5 consecutive failures → Open
- 1 success → Close
- After 30s timeout → Half-Open

### 4. Retry with Exponential Backoff

**Purpose:** Handle transient failures

**Strategy:**
```
Attempt 1: immediate
Attempt 2: wait 2s
Attempt 3: wait 4s
Attempt 4: wait 8s
Attempt 5: wait 16s
```

**Error Types:**
- Transient: Timeout, network glitch → Retry
- Permanent: Invalid data → DLQ

### 5. Saga Pattern

**Purpose:** Distributed transactions with compensation

**Example: Create Meal Plan**
```
1. Create Plan (DB)
2. Calculate Nutrition (External API)
3. Generate Shopping List (DB)
4. Send Email Notification (External API)

If step 3 fails:
    - Compensate: Delete Plan (step 1)
    - Compensate: Email user (step 4 partial)
```

## Handler Function Pattern

All Rust handlers follow this structure:

```rust
use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Input {
    pub field1: String,
    pub field2: u32,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    pub data: Option<serde_json::Value>,
    pub message: String,
}

pub fn main(input: Input) -> Result<Output> {
    // 1. Validate input
    // 2. Perform business logic
    // 3. Emit events if needed
    // 4. Return Result

    Ok(Output {
        success: true,
        data: Some(json!({})),
        message: "Success".to_string(),
    })
}
```

## Windmill Features Used

**Step Retries:**
```yaml
retry:
  exponential:
    attempts: 3
    seconds: 2
    multiplier: 2
```

**Timeouts:**
```yaml
timeout: 30  # Seconds
```

**Error Handlers:**
```yaml
failure_module:
  id: dlq_handler
  type: script
  path: f/meal-planner/patterns/dlq/send_to_dlq/script
```

**Caching:**
```yaml
cache_ttl: 3600  # 1 hour
```

**For Loops:**
```yaml
type: forloopflow
iterator:
  type: javascript
  expr: "Array.from({length: 10}, (_, i) => i + 1)"
skip_failures: true
```

## Migration from Gleam

| Gleam Component | Rust Equivalent | Windmill Path |
|----------------|----------------|----------------|
| `web/handlers/recipes.gleam` | `handlers/recipes/create_recipe/script.rs` | `f/meal-planner/handlers/recipes/create_recipe/script` |
| `web/routes/recipes.gleam` | `workflows/recipe_lifecycle/*` | Orchestrated by Windmill |
| Wisp HTTP routes | Not needed (event-driven) | Windmill webhooks/triggers |
| Middleware | EDA patterns | `f/meal-planner/patterns/*` |

## Deployment

**Prerequisites:**
1. Install Windmill CLI: `pip install wmill`
2. Configure workspace in `wmill.yaml`
3. Generate metadata: `wmill script generate-metadata`

**Sync to Windmill:**
```bash
# Validate all scripts
wmill script generate-metadata

# Push to staging
wmill workspace switch meal-planner-staging
wmill sync push

# Promote to production
wmill workspace switch meal-planner-prod
wmill sync push
```

**Resources:**
```bash
# Create PostgreSQL resource
wmill resource-type create postgresql --path f/meal-planner/database/postgres

# Create FatSecret API resource
wmill resource-type create custom --path f/meal-planner/external_apis/fatsecret
```

## Monitoring

**Windmill provides:**
- Job execution logs
- Success/failure rates
- Execution duration metrics
- Error stack traces
- Resource usage

**Custom monitoring:**
- Event bus metrics (event rates, consumer lag)
- DLQ depth (failed events)
- Circuit breaker state
- Handler performance

## Next Steps

1. ✅ Directory structure created
2. ✅ Event schemas defined
3. ✅ EDA patterns created (idempotency, DLQ)
4. ⏳ Complete business handlers
5. ⏳ Create EDA patterns (circuit breaker, retry, saga)
6. ⏳ Define Windmill resources
7. ⏳ Create orchestration workflows
8. ⏳ Generate metadata and sync
