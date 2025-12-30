---
doc_id: meta/47_environment_variables/index
chunk_id: meta/47_environment_variables/index#chunk-5
heading_path: ["Environment variables", "Environment variables passed to jobs"]
chunk_type: prose
tokens: 106
summary: "Environment variables passed to jobs"
---

## Environment variables passed to jobs

From a [worker group](./meta-9_worker_groups-index.md), you can add static and dynamic environment variables that will be [passed to jobs](./meta-9_worker_groups-index.md#environment-variables-passed-to-jobs) handled by this worker group. Dynamic environment variable values will be loaded from the worker host environment variables while static environment variables will be set directly from their values below.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
</div>
