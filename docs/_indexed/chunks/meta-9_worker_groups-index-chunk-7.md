---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-7
heading_path: ["Workers and worker groups", "Environment variables passed to jobs"]
chunk_type: prose
tokens: 117
summary: "Environment variables passed to jobs"
---

## Environment variables passed to jobs

Add static and dynamic environment variables that will be passed to jobs handled by this worker group. Dynamic environment variable values will be loaded from the worker host environment variables while static environment variables will be set directly from their values below.

![Environment variables passed to jobs](./environment_variables_passed_to_jobs.png 'Environment variables passed to jobs')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Environment variables"
		description="Environment variables are used to configure the behavior of scripts and services, allowing for dynamic and flexible execution across different environments."
		href="/docs/core_concepts/environment_variables"
	/>
</div>
