---
doc_id: meta/25_dedicated_workers/index
chunk_id: meta/25_dedicated_workers/index#chunk-2
heading_path: ["Dedicated workers / High throughput", "How to assign dedicated workers to a script"]
chunk_type: prose
tokens: 188
summary: "How to assign dedicated workers to a script"
---

## How to assign dedicated workers to a script

From Windmill UI's Workers page:

1. "Edit config" of a [worker group](./meta-9_worker_groups-index.md) and enter script's workspace & [path](./tutorial-script_editor-settings.md#path) as `worker:path`.

![Worker group config](./worker_group_config.png.webp)

The worker group will restart (assuming the pods/restart are set to restart automatically) and will now wait for step 2. below to happen:

1. Toggle the "Dedicated Workers" option for that script in the [script Settings](./tutorial-script_editor-settings.md):

![Dedicated Workers in Settings](./dedicated_workers.png 'Dedicated Workers in Settings')

Each [run](./meta-5_monitor_past_and_future_runs-index.md) will have a Worker group tag assigned to it. [Worker group tags](./meta-9_worker_groups-index.md) allow to assign custom worker groups to scripts and flows in Windmill for efficient execution on different machines with varying specifications.

![Dedicated Workers Tag](./dedicated_worker_tag.png 'Dedicated Workers Tag')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
</div>
