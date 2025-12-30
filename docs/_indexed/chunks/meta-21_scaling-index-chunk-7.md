---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-7
heading_path: ["Scaling workers", "Monitoring and alerting"]
chunk_type: prose
tokens: 96
summary: "Monitoring and alerting"
---

## Monitoring and alerting

Track worker performance to identify scaling needs:

- **Queue metrics**: Monitor delayed jobs per tag and queue wait times
- **Occupancy rates**: High sustained occupancy (>75%) suggests adding workers
- **Worker alerts**: Get notified when workers go offline

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Queue metrics"
		description="Visualize queue depth and delays across worker groups."
		href="/docs/core_concepts/worker_groups#queue-metrics"
	/>
	<DocCard
		title="Critical alerts"
		description="Configure alerts for worker failures and queue buildup."
		href="/docs/core_concepts/critical_alerts"
	/>
</div>
