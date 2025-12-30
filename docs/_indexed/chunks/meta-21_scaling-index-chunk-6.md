---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-6
heading_path: ["Scaling workers", "Priority queues with worker groups"]
chunk_type: prose
tokens: 143
summary: "Priority queues with worker groups"
---

## Priority queues with worker groups

For mixed workloads where some jobs are more time-sensitive:

1. Create separate [worker groups](./meta-9_worker_groups-index.md) with different tags
2. Assign high-priority jobs to dedicated workers
3. Let lower-priority jobs share remaining capacity

**Example configuration**:

- `high-priority` worker group: 5 dedicated workers, handles critical customer-facing operations
- `default` worker group: 10 workers, handles everything else
- `low-priority` worker group: 3 workers, handles background analytics

This ensures critical jobs are never blocked by bulk operations.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Worker groups"
		description="Configure worker groups with different tags for job routing."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="High priority jobs"
		description="Set job priorities within a queue."
		href="/docs/core_concepts/jobs#high-priority-jobs"
	/>
</div>
