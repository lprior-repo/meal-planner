---
doc_id: concept/flows/24-sticky-notes
chunk_id: concept/flows/24-sticky-notes#chunk-6
heading_path: ["Sticky notes", "Working with group notes"]
chunk_type: prose
tokens: 179
summary: "Working with group notes"
---

## Working with group notes

Group notes automatically maintain their association with the selected nodes. However, there are some limitations when editing the grouped nodes:

**To modify nodes in a group note:**

- **Option 1**: Delete the note, make your node changes, then create a new group note with the updated selection
- **Option 2**: Edit the flow directly in YAML/JSON format to modify the grouped nodes while preserving the note

Group notes are particularly useful for:

- Documenting complex logic blocks
- Explaining error handling sections
- Describing data transformation steps
- Marking deprecated or experimental features

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Flow editor components"
		description="Details on the flow editor's major components including toolbar and canvas features."
		href="/docs/flows/editor_components"
	/>
	<DocCard
		color="teal"
		title="Testing flows"
		description="Iterate quickly and get control on your flow testing."
		href="/docs/flows/test_flows"
	/>
</div>
