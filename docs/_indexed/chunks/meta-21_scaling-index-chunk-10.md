---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-10
heading_path: ["Scaling workers", "Cost optimization"]
chunk_type: prose
tokens: 118
summary: "Cost optimization"
---

## Cost optimization

Worker billing is based on usage time with minute granularity:

- 10 workers for 1/10th of the month costs the same as 1 worker for the full month
- Use autoscaling to minimize idle workers
- Consider [dedicated workers](./meta-25_dedicated_workers-index.md) for high-throughput single-script scenarios

Mark development and staging instances as "Non-prod" in [instance settings](./meta-18_instance_settings-index.md) so they don't count toward your compute limits.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Plans and pricing"
		description="Understand compute units and pricing."
		href="/docs/misc/plans_details"
	/>
	<DocCard
		title="Dedicated workers"
		description="High-throughput execution for single scripts."
		href="/docs/core_concepts/dedicated_workers"
	/>
</div>
