---
doc_id: tutorial/windmill/16-architecture
chunk_id: tutorial/windmill/16-architecture#chunk-4
heading_path: ["Architecture and data exchange", "Shared directory"]
chunk_type: prose
tokens: 154
summary: "Shared directory"
---

## Shared directory

By default, flows on Windmill are based on a result basis (see above). A step will take as input the results of previous steps. And this works fine for lightweight automation.

For heavier ETLs and any output that is not suitable for JSON, you might want to use the `Shared Directory` to share data between steps. Steps share a folder at `./shared` in which they can store heavier data and pass them to the next step.

Get more details on the [Persistent storage & databases dedicated page](./meta-windmill-index-25.md).

![Flows shared directory](../getting_started/6_flows_quickstart/flows_shared_directory.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Persistent storage & databases"
		description="Ensure that your data is safely stored and easily accessible whenever required."
		href="/docs/core_concepts/persistent_storage"
	/>
</div>
