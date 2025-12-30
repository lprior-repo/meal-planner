---
doc_id: meta/2_python_quickstart/index
chunk_id: meta/2_python_quickstart/index#chunk-3
heading_path: ["Python quickstart", "Code"]
chunk_type: prose
tokens: 150
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for python](./editor_python.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Code editor"
		description="The code editor is Windmill's integrated development environment."
		href="/docs/code_editor"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

As we picked `python` for this example, Windmill provided some python
boilerplate. Let's take a look:

```python
import os
import wmill
