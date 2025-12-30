---
doc_id: meta/10_error_handling/index
chunk_id: meta/10_error_handling/index#chunk-8
heading_path: ["Error handling", "Special case: throw an error in a script"]
chunk_type: prose
tokens: 96
summary: "Special case: throw an error in a script"
---

## Special case: throw an error in a script

Errors have a specific format to be [rendered](./meta-19_rich_display_rendering-index.md#error) properly in Windmill.

```ts
return { "error": { "name": "418", "message": "I'm a teapot", "stack": "Error: I'm a teapot" }}
```

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Rich Display Rendering"
		description="Windmill processes some outputs (from scripts or flows) intelligently to provide rich display rendering, allowing you to customize the display format of your results."
		href="/docs/core_concepts/rich_display_rendering"
	/>
</div>
