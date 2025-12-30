---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-6
heading_path: ["Meal Planner Architecture", "Windmill Integration"]
chunk_type: code
tokens: 78
summary: "Windmill Integration"
---

## Windmill Integration

### Orchestration Model

```
┌─────────────────────────────────────────────────────────┐
│                    Windmill Flow                        │
│  (Orchestration, scheduling, retries, error handling)   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Rust Binary                          │
│  (Pure function: JSON in → JSON out)                    │
│  Deployed to worker container via Dagger                │
└─────────────────────────────────────────────────────────┘
```

### Flows for Composition

Complex operations are Windmill **flows** that compose multiple binaries:

```yaml
