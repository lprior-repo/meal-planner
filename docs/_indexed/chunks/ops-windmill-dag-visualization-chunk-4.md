---
doc_id: ops/windmill/dag-visualization
chunk_id: ops/windmill/dag-visualization#chunk-4
heading_path: ["Windmill Documentation DAG Visualization", "Key Relationships"]
chunk_type: prose
tokens: 98
summary: "Key Relationships"
---

## Key Relationships

### Error Handling
retries → error_handler (triggers)
error_handler ← flow_branches (can-trigger)
retries → flow_branches (continues-on)

### Flow Control
for_loops → early_stop (can-break)
for_loops → flow_branches (can-branch)

### Optimization
step_mocking ←→ caching (related-to)

### Deployment
wmill_cli → staging_prod (deploys-to)
staging_prod → windmill_deployment (part-of)
wmill_cli → windmill_deployment (enables)
windmill_resources → windmill_deployment (required-for)
oauth → windmill_deployment (required-for)
schedules → windmill_deployment (part-of)

### SDK/Tool Integration
wmill_cli → windmill_resources (manages)
python_client → windmill_resources (accesses)
rust_sdk → windmill_resources (accesses)
