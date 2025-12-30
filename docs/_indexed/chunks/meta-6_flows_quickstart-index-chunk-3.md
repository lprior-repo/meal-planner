---
doc_id: meta/6_flows_quickstart/index
chunk_id: meta/6_flows_quickstart/index#chunk-3
heading_path: ["Flows quickstart", "How data is exchanged between steps"]
chunk_type: prose
tokens: 202
summary: "How data is exchanged between steps"
---

## How data is exchanged between steps

Flows on Windmill are generic and reusable, they therefore expose inputs. Input and outputs are piped together.

Inputs are either:

- [Static](./tutorial-flows-3-editor-components.md#static-inputs): you can find them on top of the side menu. This tab centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly.
- [Dynamically linked to others](./tutorial-flows-16-architecture.md): with [JSON objects](./meta-13_json_schema_and_parsing-index.md) as result that allow to refer to the output of any step.
  You can refer to the result of any step:
  - using the id associated with the step
  - clicking on the plug logo that will let you pick flow inputs or previous steps' results (after testing flow or step).

![Static & Dynamic Inputs](./static_and_dynamic_inputs.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Architecture and data exchange"
		description="A workflow is a JSON serializable value in the OpenFlow format."
		href="/docs/flows/architecture"
	/>
</div>
