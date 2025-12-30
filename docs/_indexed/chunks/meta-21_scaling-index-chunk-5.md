---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-5
heading_path: ["Scaling workers", "Practical examples"]
chunk_type: prose
tokens: 222
summary: "Practical examples"
---

## Practical examples

### Scenario 1: Batch ETL processing

**Requirement**: Process 1,000 daily reports, each taking 30 seconds, complete within 2 hours

- Total processing time: 1,000 × 30s = 30,000 seconds
- Available time: 2 hours = 7,200 seconds
- Minimum workers: 30,000 / 7,200 = 4.2 → **5 workers**

With 5 workers, all jobs complete in approximately 100 minutes.

### Scenario 2: Real-time webhook processing

**Requirement**: Handle 100 webhooks/minute during business hours, each taking 5 seconds, max latency 10 seconds

- Arrival rate: 100/60 = 1.67 jobs/second
- Minimum workers: 1.67 × 5 = 8.3 workers
- For 10s max latency headroom: **10 workers**

### Scenario 3: Weekend traffic spikes

**Requirement**: Normal load 2 jobs/sec, weekend peaks at 8 jobs/sec, jobs take 1 second each

- Normal load: 2 × 1 = 2 workers minimum
- Peak load: 8 × 1 = 8 workers minimum
- **Recommended**: Use autoscaling with min=3, max=10

Configure autoscaling to scale up when queue depth increases and scale down when occupancy drops below 25%.
