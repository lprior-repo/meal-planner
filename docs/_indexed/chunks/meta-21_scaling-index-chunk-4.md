---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-4
heading_path: ["Scaling workers", "Sizing your worker pool"]
chunk_type: code
tokens: 266
summary: "Sizing your worker pool"
---

## Sizing your worker pool

The right number of workers depends on your specific requirements. Consider these factors:

### Job duration and arrival rate

The fundamental relationship is:

```text
Required workers ≥ Job arrival rate × Average job duration
```

For example, if jobs arrive at 10/second and each takes 2 seconds:
- Minimum workers needed: 10 × 2 = 20 workers

With fewer workers, jobs will queue up. With more workers, some will be idle.

### Maximum acceptable queue time

If jobs must not wait more than X seconds before starting:

```text
Required workers = (Peak arrival rate × Job duration) + (Peak arrival rate × Max queue time)
```

**Example**: Peak rate 5 jobs/sec, duration 3s, max wait 2s:
- Workers needed: (5 × 3) + (5 × 2) = 15 + 10 = 25 workers

This ensures even during peak load, no job waits more than 2 seconds.

### Handling traffic peaks

If your workload has predictable peaks (weekends, end of month, etc.):

1. **Fixed capacity**: Size for peak load, accept idle workers during off-peak
2. **Autoscaling**: Configure min/max workers to automatically adjust

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Autoscaling"
		description="Automatically scale workers based on queue depth and occupancy."
		href="/docs/core_concepts/autoscaling"
	/>
</div>
