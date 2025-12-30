---
doc_id: concept/flows/8-error-handling
chunk_id: concept/flows/8-error-handling#chunk-2
heading_path: ["Error handling in flows", "Error handler"]
chunk_type: prose
tokens: 97
summary: "Error handler"
---

## Error handler

The Error handler is a special flow step that is executed when an error occurs within a flow.

If defined, the error handler will take as input the result of the step that errored (which has its error in the 'error field').

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/error_handler.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Error handler"
		description="Configure a script to handle errors."
		href="/docs/flows/flow_error_handler"
	/>
</div>
