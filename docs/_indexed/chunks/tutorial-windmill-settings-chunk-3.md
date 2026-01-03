---
doc_id: tutorial/windmill/settings
chunk_id: tutorial/windmill/settings#chunk-3
heading_path: ["Settings", "Runtime"]
chunk_type: prose
tokens: 673
summary: "Runtime"
---

## Runtime

Runtime settings allow you to configure how your script is executed.

![Script runtime](../../static/images/script_runtime.png "Script runtime")

### Concurrency limits

The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Concurrency limit"
		description="The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows."
		href="/docs/script_editor/concurrency_limit"
	/>
</div>

### Debouncing

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Job debouncing"
		description="Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics."
		href="/docs/core_concepts/job_debouncing"
	/>
</div>

### Worker group tag

Scripts can be assigned custom [worker groups](./meta-windmill-index-80.md) for efficient execution on different machines with varying specifications.

For scripts saved on the script editor, select the corresponding worker group tag in the [settings](./tutorial-windmill-settings.md) section.

![Worker group tag](../core_concepts/9_worker_groups/select_script_builder.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Worker Groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
</div>

### Cache

Caching a script step means caching the results for a certain duration. If the script is triggered with the same inputs during the given duration, it will return the cached result.

### Timeout

Add a custom timeout for this script, for a given duration.

If enabled to execution will be stopped after the timeout.

### Perpetual script

Perpetual scripts restart upon ending unless canceled.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Running services with perpetual scripts"
		description="Perpetual scripts restart upon ending unless canceled."
		href="/docs/script_editor/perpetual_scripts"
	/>
</div>

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/5uw3JWiIFp0"
	title="Running services with perpetual scripts"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

### Dedicated workers

In this mode, the script is meant to be run on [dedicated workers](./meta-windmill-index-80.md) that run the script at native speed. Can reach >1500rps per dedicated worker. Only available on enterprise edition and for Python3, Deno and Bun. For other languages, the efficiency is already on par with deidcated workers since they do not spawn a full runtime.

### Delete after use

Delete [logs](./meta-windmill-index-28.md), arguments and results after use.

:::warning

This settings ONLY applies to [synchronous webhooks](./meta-windmill-index-68.md#synchronous) or when the script is used within a [flow](./tutorial-windmill-1-flow-editor.md). If used individually, this script must be triggered using a synchronous endpoint to have the desired effect.
<br/>
The logs, arguments and results of the job will be completely deleted from Windmill once it is complete and the result has been returned.
<br/>
The deletion is irreversible.

:::

### High priority script

Jobs within a same job queue can be given a [priority](./meta-windmill-index-35.md#high-priority-jobs) between 1 and 100. Jobs with a higher priority value will be given precedence over jobs with a lower priority value in the job queue.

### Runs visibility

When this [option](./meta-windmill-index-76.md#invisible-runs) is enabled, manual [executions](./meta-windmill-index-76.md) of this script are invisible to users other than the user running it, including the [owner(s)](./meta-windmill-index-30.md). This setting can be overridden when this script is run manually from the advanced menu (available when the script is [deployed](./meta-windmill-index-23.md)).
