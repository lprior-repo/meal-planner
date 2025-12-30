---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-3
heading_path: ["Scaling workers", "Interactive simulator"]
chunk_type: prose
tokens: 124
summary: "Interactive simulator"
---

## Interactive simulator

Use this simulator to visualize how jobs flow through the queue and understand the relationship between job arrival rate, job duration, and worker count.

<WorkerQueueSimulator />

### Simulator modes

- **Batch**: All jobs are submitted at once, simulating scheduled bulk operations
- **Continuous**: Jobs arrive at a steady rate, simulating regular workloads
- **Random**: Jobs arrive at varying intervals, simulating unpredictable traffic

### Key metrics

- **Elapsed time**: Total time from first job to last completion
- **Jobs/sec**: Actual throughput achieved
- **Worker occupancy**: Percentage of time each worker spent processing (vs idle)
