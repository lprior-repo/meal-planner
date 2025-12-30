---
doc_id: tutorial/flows/16-architecture
chunk_id: tutorial/flows/16-architecture#chunk-2
heading_path: ["Architecture and data exchange", "Input transform"]
chunk_type: prose
tokens: 438
summary: "Input transform"
---

## Input transform

With the mechanism of input transforms, the input of any step can be the output of any previous step, hence every Flow is actually a [Directed Acyclic Graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph) rather than simple sequences. You can refer to the result of any step using its ID.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="main-video"
	src="/videos/flow-sequence.mp4"
/>

<br />

Every step has an input transform that maps from:

- the Flow input
- any step's result, not only the previous step's result
- [Resource](./meta-3_resources_and_types-index.md)/[Variable](./meta-2_variables_and_secrets-index.md).

to the different parameters of this specific step.

It does that using a JavaScript expression that operates in a more restricted
setting. That JavaScript is using a restricted subset of the standard library
and a few more functions which are the following:

- `flow_input`: the dict/object containing the different parameters of the Flow
  itself.
- `results.{id}`: the result of the step with given ID.
- `resource(path)`: the Resource at path.
- `variable(path)`: the Variable at path.

Using JavaScript in this manner, for every parameter, is extremely flexible and
allows Windmill to be extremely generic in the kind of modules it runs.

### Connecting flow steps

For each field, one has the option to write the JavaScript directly or to use
the quick connect button if the field map one to one with a field of the
`flow_input`, a field of the `previous_result` or of any steps.

From the editor, you can directly get:

- [Static inputs](./tutorial-flows-3-editor-components.md#static-inputs): you can find them on top of the side menu. This tab centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly.
- Dynamic inputs:
  - using the id associated with the step
  - clicking on the plug logo that will let you pick flow inputs or previous steps' results (after testing flow or step).

![Static & Dynamic Inputs](../getting_started/6_flows_quickstart/static_and_dynamic_inputs.png.webp)

You can connect step inputs automatically using [Windmill AI](./meta-22_ai_generation-index.md).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/step_input_copilot.mp4"
/>
