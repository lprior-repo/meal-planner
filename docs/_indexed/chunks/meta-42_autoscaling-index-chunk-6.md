---
doc_id: meta/42_autoscaling/index
chunk_id: meta/42_autoscaling/index#chunk-6
heading_path: ["Autoscaling", "Billing"]
chunk_type: prose
tokens: 92
summary: "Billing"
---

## Billing

In terms of billing for Windmill [Enterprise Edition](/pricing), Windmill measures how long the workers are online with a minute granularity. If you use 10 workers with 2GB for 1/10th of the month, it will count the same as if you had a single worker for the full month. It's like if in your [Windmill setup](../../misc/7_plans_details/index.mdx#setup-and-compute-units), the replicas of the worker group would adjust for a given amount of time.
