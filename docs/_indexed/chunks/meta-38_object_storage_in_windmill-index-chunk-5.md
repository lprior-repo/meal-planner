---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-5
heading_path: ["Object storage in Windmill (S3)", "Instance object storage"]
chunk_type: prose
tokens: 821
summary: "Instance object storage"
---

## Instance object storage

Under [Enterprise Edition](/pricing), instance object storage offers advanced features to enhance performance and scalability at the [instance](./meta-18_instance_settings-index.md) level. This integration is separate from the [Workspace object storage](#workspace-object-storage) and provides solutions for large-scale log management and distributed dependency caching.

![Instance object storage infographic](./instance_object_storage_infographic.png 'Instance object storage infographic')

This can be configured from the [instance settings](./meta-18_instance_settings-index.md#instance-object-storage), with configuration options for S3, Azure Blob, Google Cloud Storage, or AWS OIDC.

![S3/Azure for Python/Go cache & large logs](../../core_concepts/20_jobs/s3_azure_cache.png 'S3/Azure for Python/Go cache & large logs')

### Large job logs management

To optimize log storage and performance, Windmill leverages S3 for log management. This approach minimizes database load by treating the database as a temporary buffer for up to 5000 characters of logs per job.

For jobs with extensive logging needs, Windmill [Enterprise Edition](/pricing) users benefit from seamless log streaming to S3. This ensures logs, regardless of size, are stored efficiently without overwhelming local resources.

This allows the handling of large-scale logs with minimal database impact, supporting more efficient and scalable workflows.

For large logs storage (and display) and cache for distributed Python jobs, you can [connect your instance to a bucket](./meta-20_jobs-index.md#large-job-logs-management). This feature is at the Instance-level, and has no overlap with the Workspace object storage.

### Instance object storage distributed cache for Python, Rust, Go

[Workers](./meta-9_worker_groups-index.md) cache aggressively the [dependencies](./meta-6_imports-index.md) (and each version of them since every script has its own lockfile with a specific version for each dependency) so they are never pulled nor installed twice on the same worker. However, with a bigger cluster, for each script, the likelihood of being seen by a worker for the first time increases (and the cache hit ratio decreases).

However, you may have noticed that our multi-tenant [cloud solution](https://app.windmill.dev) runs as if most dependencies were cached all the time, even though we have hundreds of workers on there. For TypeScript, we do nothing special as npm has sufficient networking and npm packages are just tars that take no compute to extract. However, [Python](./meta-2_python_quickstart-index.md#caching) is a whole other story and to achieve the same swiftness in cold start the secret sauce is a global cache backed by S3.

This feature is available on [Enterprise Edition](/pricing) and is configurable from the [instance settings](./meta-18_instance_settings-index.md#instance-object-storage).

For [Bun](./meta-1_typescript_quickstart-index.md#caching), Rust, and [Go](./meta-3_go_quickstart-index.md#caching), the binary bundle is cached on disk by default. However, if Instance Object storage is configured, these bundles can also be stored on the configured object storage (like S3), providing a distributed cache across all workers.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instance object storage distributed cache for Python, Rust, Go"
		description="Leverage a global S3 cache to speed up Python dependency handling by storing and reusing pre-installed package."
		href="/docs/misc/s3_cache"
	/>
</div>

#### Global Python dependency cache

The first time a dependency is seen by a worker, if it is not cached locally, the worker search in the bucket if that specific `name==version` is there:

1. If it is not, install the dependency from pypi, then do a snapshot of installed dependency, tar it and push it to S3 (we call this a "piptar").
2. If it is, simply pull the "piptar" and extract it in place of installing from pypi. It is much faster than installing from pypi because that S3 is much closer to your workers than pypi and because there is no installation step to be done, a simple tar extract is sufficient which takes no compute.

### Service logs storage

[Logs are stored in S3](./meta-36_service_logs-index.md) if S3 instance object storage is configured. This option provides more scalable storage and is ideal for larger-scale deployments or where long-term log retention is important.

![Service logs](../36_service_logs/service_logs.png 'Service logs')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Service logs"
		description="View logs from any worker or servers directly within the service logs section of the search modal."
		href="/docs/core_concepts/service_logs"
	/>
</div>
