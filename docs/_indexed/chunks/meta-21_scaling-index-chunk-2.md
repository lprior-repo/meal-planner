---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-2
heading_path: ["Scaling workers", "How workers process jobs"]
chunk_type: prose
tokens: 152
summary: "How workers process jobs"
---

## How workers process jobs

Workers are autonomous processes that pull jobs from a queue in order of their scheduled time. Each worker:

- Executes one job at a time using full CPU and memory
- Pulls the next job as soon as the current one completes
- Can run up to 26 million jobs per month (at 100ms per job)

This architecture is horizontally scalable: add more workers to increase throughput, remove workers to reduce costs. There is no coordination overhead between workers.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Learn about Windmill's worker architecture and how to configure worker groups."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="Architecture"
		description="Overview of Windmill's technical architecture."
		href="/docs/misc/architecture"
	/>
</div>
