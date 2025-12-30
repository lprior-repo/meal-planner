---
doc_id: meta/10_error_handling/index
chunk_id: meta/10_error_handling/index#chunk-3
heading_path: ["Error handling", "Flows' error handlers"]
chunk_type: prose
tokens: 148
summary: "Flows' error handlers"
---

## Flows' error handlers

The Error handler is a special [flow](./tutorial-flows-1-flow-editor.md) step that is executed when an error occurs within a flow.

If defined, the error handler will take as input the result of the step that errored (which has its error in the 'error field').

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/error_handler.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Error handler"
		description="Configure a script to handle errors."
		href="/docs/flows/flow_error_handler"
	/>
</div>

### Error handling in flows

There are other tricks to do Error handling in flows, see:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Error handling in flows"
		description="There are four ways to handle errors in Windmill flows."
		href="/docs/flows/error_handling"
	/>
</div>
