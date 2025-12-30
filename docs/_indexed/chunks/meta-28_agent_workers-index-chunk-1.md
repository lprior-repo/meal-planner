---
doc_id: meta/28_agent_workers/index
chunk_id: meta/28_agent_workers/index#chunk-1
heading_path: ["Agent workers"]
chunk_type: prose
tokens: 366
summary: "Agent workers"
---

# Agent workers

> **Context**: Agent workers are a Cloud & Self-hosted [Enterprise](/pricing) feature.

Agent workers are a Cloud & Self-hosted [Enterprise](/pricing) feature.

Agent workers are remote computing resources that can execute your Windmill jobs from anywhere in the world, even in environments with limited or unreliable network connectivity to your main Windmill cluster. Think of them as lightweight, secure workers that can run your automation tasks in remote locations, behind firewalls, or in untrusted environments without needing direct access to your database.

In terms of [billing](../../misc/7_plans_details/index.mdx), agent workers are counted as 1 [Compute Unit](/pricing#compute-units) per agent worker on self-hosted EE (if not used for compute) and 0.5 Compute Unit on cloud EE (if not used for compute).

Agent workers are a 4th mode of execution of the Windmill binary, but instead of using `MODE=worker`, we use here `MODE=agent`. Instead of using a direct connection to the database, they only require an HTTP connection to an internal base url of the cluster.

They should be used:

- For remote workers with non-low latency to the main database/cluster and or unreliable connectivity to it or complex firewall since they only require an HTTP connection to an internal base url of the cluster
- Untrusted sites, since they do not require access to the database and only have access to a limited set of APIs relative to the jobs that have been assigned to them
- If you need thousands of workers as it is less taxing on the database since the servers act as a connection pooler

Note that agent workers can even be running without docker on Linux, Windows and Apple targets using the cross-compiled binaries of Windmill attached to each release.
