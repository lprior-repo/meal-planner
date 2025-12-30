---
doc_id: ops/windmill/dag-visualization
chunk_id: ops/windmill/dag-visualization#chunk-2
heading_path: ["Windmill Documentation DAG Visualization", "Layer Structure"]
chunk_type: prose
tokens: 156
summary: "Layer Structure"
---

## Layer Structure

┌─────────────────────────────────────────────────────────────┐
│                  LAYER 1: Flow Features                  │
├─────────────────────────────────────────────────────────────┤
│  [retries] ←→ [error_handler] ←→ [flow_branches] │
│       ↓                                             │
│  [step_mocking] ←→ [caching]                       │
│       ↓                                             │
│  [for_loops] ←→ [early_stop]                      │
│       ↓                                             │
│  [flow_branches]                                      │
│                                                      │
│  [custom_timeout], [sleep], [priority], [lifetime]      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│               LAYER 2: Core Concepts                  │
├─────────────────────────────────────────────────────────────┤
│  [caching], [concurrency_limits], [job_debouncing]   │
│  [staging_prod] ←→ [multiplayer]                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│            LAYER 3: Tools & SDKs                     │
├─────────────────────────────────────────────────────────────┤
│  [wmill_cli] ←→ [python_client]                     │
│       ↓                                              │
│  [rust_sdk]                                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              LAYER 4: Deployment                      │
├─────────────────────────────────────────────────────────────┤
│  [windmill_deployment] ← [oauth], [schedules]       │
│       ↑                                              │
│  [wmill_cli] ←→ [staging_prod]                     │
│       ↑                                              │
│  [windmill_resources]                                  │
└─────────────────────────────────────────────────────────────┘
