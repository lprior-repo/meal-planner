---
doc_id: meta/20_jobs/index
chunk_id: meta/20_jobs/index#chunk-1
heading_path: ["Jobs"]
chunk_type: prose
tokens: 314
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Jobs

> **Context**: import DocCard from '@site/src/components/DocCard';

A job represents a past, present or future "task" or "work" to be executed by a
[worker](./meta-9_worker_groups-index.md). Future jobs or jobs waiting for a worker are called "queued
jobs", and are ordered by the time at which they were scheduled for
(`scheduled_for`). Jobs that are created without being given a future
`scheduled_for` are [scheduled](./meta-1_scheduling-index.md) for the time at which they were created.

[Workers](./meta-9_worker_groups-index.md) fetch jobs from the queue, start executing them, atomically
set their state in the queue to "running", stream the logs while executing them,
then once completed remove them from the queue and create a new "completed job".

Every job has a unique UUID attached to it and as long as you have visibility
over the execution of the script, you are able to inspect the execution logs,
output and metadata in the dedicated details page of the job.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="Dedicated workers / High throughput"
		description="Dedicated Workers are workers that are dedicated to a particular script."
		href="/docs/core_concepts/dedicated_workers"
	/>
	<DocCard
		title="Worker groups management UI"
		description="On Enterpris Edition, worker groups can be managed through Windmill UI."
		href="/docs/misc/worker_group_management_ui"
	/>
	<DocCard
		title="Init scripts"
		description="Init scripts are executed at the beginning when the worker starts."
		href="/docs/advanced/preinstall_binaries#init-scripts"
	/>
</div>
