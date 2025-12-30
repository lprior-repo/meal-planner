---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-8
heading_path: ["Scaling workers", "Autoscaling configuration"]
chunk_type: prose
tokens: 169
summary: "Autoscaling configuration"
---

## Autoscaling configuration

For dynamic workloads, configure autoscaling to automatically adjust worker count:

| Parameter | Recommended starting value |
| --- | --- |
| Min workers | Expected base load / job duration |
| Max workers | Peak load / job duration × 1.5 |
| Scale-out trigger | 75% occupancy or jobs waiting > min_workers |
| Scale-in trigger | Less than 25% occupancy for 5+ minutes |
| Cooldown | 60-120 seconds between scaling events |

The autoscaling algorithm checks every 30 seconds and considers:
- Number of jobs waiting in queue
- Worker occupancy rates over 15s, 5m, and 30m intervals
- Cooldown periods to prevent thrashing

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Autoscaling"
		description="Configure automatic worker scaling based on demand."
		href="/docs/core_concepts/autoscaling"
	/>
</div>
