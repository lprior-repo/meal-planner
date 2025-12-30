---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-16
heading_path: ["Windmill Deployment Guide", "Initialize wmill configuration"]
chunk_type: code
tokens: 169
summary: "Initialize wmill configuration"
---

## Initialize wmill configuration
wmill init
```text

### 3. Project Structure

```
windmill/
├── f/meal-planner/           # Scripts and flows
│   ├── events/               # Event-driven foundation
│   │   ├── schemas/          # Event type definitions
│   │   ├── producers/        # Event emitters
│   │   └── consumers/        # Event handlers
│   ├── patterns/             # EDA patterns
│   │   ├── idempotency/
│   │   ├── dlq/
│   │   ├── circuit_breaker/
│   │   ├── retry/
│   │   └── saga/
│   ├── handlers/             # Business logic
│   │   ├── recipes/
│   │   ├── meal_planning/
│   │   ├── nutrition/
│   │   ├── shopping_list/
│   │   ├── fatsecret/
│   │   └── tandoor/
│   └── workflows/            # Flow orchestrations
├── resources/                # Resource definitions
├── variables/                # Variable definitions
└── wmill.yaml                # CLI configuration
```text

### 4. wmill.yaml Configuration

```yaml
