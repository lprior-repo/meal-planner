---
doc_id: tutorial/script_editor/script-kinds
chunk_id: tutorial/script_editor/script-kinds#chunk-5
heading_path: ["Script kind", "Error handlers"]
chunk_type: prose
tokens: 109
summary: "Error handlers"
---

## Error handlers

Handle errors for Flows after all retries attempts have been exhausted. If it does not return an exception itself, the Flow is considered to be "recovered" and will have a success status. So in most cases, you will have to rethrow an error to have it be listed as a failed flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Error handler"
		description="The error handler is a special flow step that is executed when an error occurs in the flow."
		href="/docs/flows/flow_error_handler"
	/>
</div>
