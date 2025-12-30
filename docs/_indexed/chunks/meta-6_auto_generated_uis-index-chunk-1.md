---
doc_id: meta/6_auto_generated_uis/index
chunk_id: meta/6_auto_generated_uis/index#chunk-1
heading_path: ["Auto-generated UIs"]
chunk_type: prose
tokens: 318
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Auto-generated UIs

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill automatically generates user interfaces (UIs) for scripts and flows based on their parameters.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/auto_generated_uis.mp4"
/>

<br />

:::info Windmill App editor

You might also be interested by Windmill's [App editor](./meta-7_apps_quickstart-index.md), providing a comprehensive solution to customize UIs and interactions for your scripts and flows.

:::

By analyzing the parameters of the main function, Windmill generates an input specification for the script or flow in the [JSON Schema](./meta-13_json_schema_and_parsing-index.md) format. Windmill then renders the UI for the Script or Flow from that specification.

You don't need to directly interact with the JSON Schema associated with the Script or Flow. It is the result of the analysis of the script parameters of the main function and the optional UI customization.

The parsing of the main function will be used to generate an UI for scripts, or scripts used as flow steps (useful to [link steps together](./tutorial-flows-16-architecture.md)).
The auto-generated UI of a flow is made from [Flow Input](./tutorial-flows-3-editor-components.md#flow-inputs).

In the [UI customization interface](./tutorial-script_editor-customize-ui.md), you can refine information that couldn't be inferred directly from the parameters, such as specifying string enums or restricting lists to numbers. You can also add helpful descriptions to each field.

![Customize inputs](./customize_inputs.png)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>
