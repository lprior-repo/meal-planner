---
doc_id: ops/windmill/dag-visualization
chunk_id: ops/windmill/dag-visualization#chunk-8
heading_path: ["Windmill Documentation DAG Visualization", "Search Optimization"]
chunk_type: prose
tokens: 80
summary: "Search Optimization"
---

## Search Optimization

### Entity Search Map
retry → [retries, error_handler]
error → [error_handler, retries]
loop → [for_loops, early_stop]
branch → [flow_branches, for_loops]
cache → [caching, step_mocking]
deploy → [staging_prod, windmill_deployment, wmill_cli]
cli → [wmill_cli, python_client]
rust → [rust_sdk]
oauth → [oauth]
schedule → [schedules, wmill_cli]
resource → [windmill_resources, wmill_cli, rust_sdk, python_client]
job → [windmill_jobs, job_debouncing, retries]
async → [windmill_jobs, rust_sdk, python_client]
