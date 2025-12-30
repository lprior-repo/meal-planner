---
doc_id: tutorial/flows/22-while-loops
chunk_id: tutorial/flows/22-while-loops#chunk-2
heading_path: ["While loops", "How to stop a while loop"]
chunk_type: prose
tokens: 292
summary: "How to stop a while loop"
---

## How to stop a while loop

The loop will continue to run until canceled, there are 3 ways to stop a while loop:
- Cancel manually
- Early stop/Break for loop
- Early stop for step

### Cancel manually

You can cancel flow manually from the flow page, it can be accessed when the flow is triggered manually or from the [Runs page](./meta-5_monitor_past_and_future_runs-index.md).

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    controls
    src="/videos/cancel_while_manually.mp4"
/>

### Early stop / Break

The Early stop/Break feature allows you to define a predicate expression that determines whether the flow - or here, loop - should stop early at the end or before a step.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    controls
    src="/videos/while_early_stop.mp4"
/>

<br/>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Early stop / Break"
		description="Stop early a flow based on a step's result."
		href="/docs/flows/early_stop"
	/>
</div>

### Early stop for step

For each step of the flow, an early stop can be defined. The result of the step will be compared to a previously defined predicate expression, and if the condition is met, the flow will stop after that step.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    controls
    src="/videos/while_early_stop_step.mp4"
/>

<br/>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Early stop for step"
		description="For each step of the flow, an early stop can be defined."
		href="/docs/flows/early_stop#early-stop-for-step"
	/>
</div>
