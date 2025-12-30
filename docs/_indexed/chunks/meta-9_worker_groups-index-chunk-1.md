---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-1
heading_path: ["Workers and worker groups"]
chunk_type: prose
tokens: 565
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Workers and worker groups

> **Context**: import DocCard from '@site/src/components/DocCard';

Workers are autonomous processes that run one script at a time using the entire cpu and memory available
to them. They are at the basis of [Windmill's architecture](../../misc/10_architecture/index.md) as run the jobs.
The number of workers can be horizontally scaled up or down depending on needs without any overhead.
Each worker on Windmill can run up to 26 million jobs a month, where each job lasts approximately 100ms.

Workers pull [jobs](./meta-20_jobs-index.md) from the queue of jobs in the order of their
`scheduled_for` datetime as long as it is in the past. As soon as a worker pulls
a job, it atomically sets its state to "running", runs it, streams its logs then
once it is finished, the final result and logs are stored for as long as the retention period allows. Logs are optionally stored to S3.

By default, every worker is the same and interchangeable. However, there are often needs to assign jobs to a specific worker pool, and to configure this worker pool to behave specifically or have different pre-installed binaries. To that end, we introduce the concept of "worker groups".

You can assign groups to flows and flow steps to be executed on specific queues. The name of those queues are called tags. Worker groups listen to those tags.

![Workers page](./workers_page.png 'Workers page')

In the [Community Edition](/pricing), worker management is done using tags that can be respectively assigned to workers (through the [env variable](#how-to-assign-worker-tags-to-a-worker-group) `WORKER_TAGS`) and scripts or flows, so that the workers listen to specific jobs queues.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Set tags to assign specific queues"
		description="You can assign groups to flows and flow steps to be executed on specific queues."
		href="#set-tags-to-assign-specific-queues"
	/>
</div>

<br />

In the [Cloud plans & Self-Hosted Enterprise Edition](/pricing), workers can be commonly managed based on the group they are in, from the UI. Specifically, you can group the workers into worker groups, groups for which you can manage the tags they listen to, assignment to a single script, or the worker init scripts, from the UI.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Create worker group config"
		description="workers can be commonly managed based on the group they are in, from the UI."
		href="#create-worker-group-config"
	/>
</div>

<br />

Examples of configurations include:

1. [Assign different jobs to specific worker groups](#set-tags-to-assign-specific-queues) by giving them tags.
2. [Set an init or periodic script](#worker-scripts) that will run at the start of the workers or periodically (e.g. to pre-install binaries).
3. [Dedicate your worker to a specific script or flow](#dedicated-workers--high-throughput) for high throughput.
