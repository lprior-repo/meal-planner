---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-11
heading_path: ["Workers and worker groups", "Dedicated workers / High throughput"]
chunk_type: prose
tokens: 145
summary: "Dedicated workers / High throughput"
---

## Dedicated workers / High throughput

Dedicated Workers are workers that are dedicated to a particular script. They are able to execute any job that target this script much faster than normal workers at the expense of being capable to only execute that one script.
They are as fast as running the same logic in a forloop, but keep the benefit of showing separate jobs per execution.

Dedicated workers / High throughput is a [Cloud plans & Self-Hosted Enterprise Edition](/pricing) feature.

![Dedicated Workers Infographics](../25_dedicated_workers/infographic.png 'Dedicated Workers Infographics')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dedicated workers / High throughput"
		description="Dedicated Workers are workers that are dedicated to a particular script."
		href="/docs/core_concepts/dedicated_workers"
	/>
</div>
