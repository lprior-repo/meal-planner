---
doc_id: meta/23_instant_preview/index
chunk_id: meta/23_instant_preview/index#chunk-3
heading_path: ["Instant preview & testing", "Instant preview in Flow editor"]
chunk_type: prose
tokens: 573
summary: "Instant preview in Flow editor"
---

## Instant preview in Flow editor

The flow editor has several methods of previewing results instantly.

Testing the flow or certain steps is often required to have the outputs of previous steps suggested as input for another step:

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_preview_results.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Flow editor"
		description="Windmill's Flow editor allows you to build flows with a low-code builder."
		href="/docs/flows/flow_editor"
	/>
</div>

### Test flow

While editing the flow, you can run the whole flow as a test.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_flow.mp4"
/>

<br />

Click on `Test flow`. This will open a drawer with the [flow's inputs](./tutorial-flows-3-editor-components.md#flow-inputs) and its status.

Upon execution, you can graphically preview (as a directed acyclic graph) the execution of the flow & the results & logs of each step.

![Flow status](./flow_status.png 'Flow status')

From the menu, you can also access [past runs](./meta-5_monitor_past_and_future_runs-index.md) & [saved inputs](./meta-6_auto_generated_uis-index.md#saved-inputs).

![Input library](./input_library.png 'Input library')

At last, you can fill arguments from a request.

![Fill from request](./fill_from_request.png 'Fill from request')

### Test up to step

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_up_to.mp4"
/>

<br />

As for `Test flow`, you will get the same components (Flow inputs, status, input library etc.), only the flow will execute until a given step, included.

### Test an iteration

[For loops](./tutorial-flows-12-flow-loops.md) and [While loops](./tutorial-flows-22-while-loops.md) can be tested for a specific iteration.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/test_iteration.mp4"
	description="Test an iteration"
/>

### Restart from step, iteration or branch

Restart a flow at any given top level step. For-loop and branch-all can be restarted at a specific iteration/branch.
In the flow preview page, just select a top level node and a "Re-start from X" button will appear at the top, next to "Test flow".

To see how it works, see our [dedicated blog post](/blog/launch-week-1/restartable-flows).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/5_NRFmUxfW0?vq=hd1440"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Under [Cloud plans and Self-Hosted Enterprise edition](/pricing), this feature is also available for [deployed](./meta-0_draft_and_deploy-index.md) flows.

![Restart deployed flow](./restart_flow_2.png 'Restart deployed flow')

### Test this step

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_this_step.mp4"
/>

<br />

`Test this step` is a way to test a single step of the flow. It comes useful to check your code or to have the results of your current steps suggested as inputs for further steps.

The arguments are pre-filled from the step inputs (if the arguments use results from previous steps, they will be used if those were tested before), but you can change them manually.
