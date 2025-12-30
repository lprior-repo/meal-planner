---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-14
heading_path: ["Workers and worker groups", "Queue metrics"]
chunk_type: prose
tokens: 171
summary: "Queue metrics"
---

## Queue metrics

You can visualize metrics for delayed jobs per tag and queue delay per tag.

Queue metrics is an [Enterprise Edition](/pricing) feature.

Metrics are available under "Queue metrics" button on the Workers page.

Only tags for jobs that have been delayed by more than 3 seconds in the last 14 days are included in the graph.

![Queue Metrics](./queue_metrics.png 'Queue Metrics')

### Queue metric alerts

[Enterprise Edition](/pricing) users can set up [Critical alerts](./meta-37_critical_alerts-index.md) on the [Queue Metrics page](#queue-metrics), and be notified when the number of delayed jobs in a queue is above a certain threshold for more than a configured amount of time. The "cooldown" parameter determines the minimum duration between two consecutive alerts if the number of waiting jobs are fluctuating around the configured threshold.

![Queue Metrics](./queue_metrics_alert.png 'Queue Metrics Alert')
