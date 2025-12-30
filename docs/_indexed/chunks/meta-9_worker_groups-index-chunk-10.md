---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-10
heading_path: ["Workers and worker groups", "Worker scripts"]
chunk_type: prose
tokens: 293
summary: "Worker scripts"
---

## Worker scripts

Worker scripts are bash scripts that run at regular intervals on workers, complementing init scripts which only run at worker startup. While init scripts handle one-time setup tasks like installing dependencies or configuring the environment, worker scripts are designed for ongoing maintenance tasks that need to be executed repeatedly during the worker's lifetime.

### Key differences from init scripts

- **Init scripts**: Run once when the worker starts, ideal for setup and configuration tasks
- **Worker scripts**: Run continuously at specified intervals (minimum 60 seconds), ideal for maintenance and monitoring tasks

### Common use cases

Worker scripts are particularly useful for:

- **System maintenance**: Cleaning temporary files, rotating logs, or performing health checks
- **Cache management**: Clearing expired cache entries or warming up caches  
- **Resource monitoring**: Collecting metrics or monitoring system resources
- **Security tasks**: Running periodic security scans or updating security configurations

### Configuration and execution

Under the [Cloud plans & Self-Hosted Enterprise Edition](/pricing), worker scripts can be configured from the Windmill UI in the worker group settings, similar to init scripts.

When adjustments are made in the Worker Management UI, the workers will shut down and are expected to be restarted by their supervisor (Docker or k8s).

The execution of worker scripts is inspectable in the superadmin workspace, with Kind = All filter. The path of those executions are `periodic_script_{worker_name}_{timestamp}`.
