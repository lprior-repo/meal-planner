---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-9
heading_path: ["Scaling workers", "Worker memory sizing"]
chunk_type: prose
tokens: 335
summary: "Worker memory sizing"
---

## Worker memory sizing

Workers come in different sizes based on memory limits. The right size depends on your job requirements:

| Worker size | Memory | Compute units |
| --- | --- | --- |
| Small | 1GB | 0.5 CU |
| Standard | 2GB | 1 CU |
| Large | >2GB | 2 CU (self-hosted capped at 2 CU regardless of actual memory) |

### Choosing the right memory limit

Set worker memory based on the **maximum memory any individual job will need**, plus some headroom:

- **Simple API calls, webhooks, light scripts**: 1-2GB is typically sufficient
- **Data processing, ETL jobs**: May need 4GB+ depending on data volume processed in memory
- **Large file processing, ML inference**: Consider 8GB+ for memory-intensive operations

If a job exceeds the worker's memory limit, it will be killed by the operating system. Monitor job memory usage and increase worker memory if you see OOM (out of memory) errors.

### Memory vs worker count trade-off

For the same compute budget, you can choose between:

- **More small workers**: Better parallelism for many short jobs
- **Fewer large workers**: Better for memory-intensive jobs that can't be parallelized

**Example**: 4 CUs can be configured as:
- 8 small workers (1GB each) - good for high-volume, light jobs
- 4 standard workers (2GB each) - balanced configuration
- 2 large workers (4GB each) - good for memory-intensive ETL

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Plans and pricing"
		description="Understand compute units and how worker memory affects billing."
		href="/docs/misc/plans_details"
	/>
</div>
