---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-16
heading_path: ["Workers and worker groups", "Workers and compute units"]
chunk_type: prose
tokens: 403
summary: "Workers and compute units"
---

## Workers and compute units

Even though Windmill's architecture relies on workers, Windmill's [pricing](/pricing) is based on compute units. A compute unit corresponds to 2 worker-gb-month. For example, a worker with 2GB of memory limit (standard worker) counts as 1 compute unit. A worker with 4GB of memory counts as 2 compute units. On self-hosted plans, any worker with memory above 2GB counts as 2 compute units (16GB worker counts as 2 compute units). Each worker can run up to ~26M jobs per month (at 100ms per job).

The number of compute units will depend on the workload and the jobs Windmill will need to run. Each worker only executes one job at a time, by design to use the full resource of the worker. Workers come in different sizes based on memory: small (1GB), standard (2GB), and large (> 2GB). Each worker is extremely efficient to execute a job, and you can execute up to 26 million jobs per month per worker if each one lasts 100ms. However, it completely depends on the nature of the jobs, their number and duration.

As a note, keep in mind that the number of compute units considered is the number of production compute units of your workers, not of development staging, if you have separate instances. You can set staging instances as 'Non-prod' in the [Instance settings](./meta-18_instance_settings-index.md#non-prod-instance). The compute units are calculated based on the memory limits set in [docker-compose](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml) or in Kubernetes. For example, a standard worker with 2GB memory counts as 1 compute unit, while a large worker with >2GB memory counts as 2 compute units (on self-hosted plans, any worker with memory above 2GB still counts as 2 compute units Small workers are counted as 0.5 compute unit.

Also, for the [Enterprise Edition](/pricing), the free trial of one month is meant to help you evaluate your needs in practice.
