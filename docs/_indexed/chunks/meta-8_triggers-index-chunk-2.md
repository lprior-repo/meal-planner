---
doc_id: meta/8_triggers/index
chunk_id: meta/8_triggers/index#chunk-2
heading_path: ["Triggers", "On-demand triggers"]
chunk_type: prose
tokens: 817
summary: "On-demand triggers"
---

## On-demand triggers

### Auto-generated UIs

Windmill automatically generates user interfaces (UIs) for scripts and flows based on their parameters.

By analyzing the main function parameters, it creates an input specification in the JSON Schema format, which is then used to render the UI. Users do not need to interact with the JSON Schema directly, as Windmill simplifies the process and allows for optional UI customization.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/auto_generated_uis.mp4"
/>

<br />

This feature is also usable directly in the script editor to test a script in the making:

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ui_from_script_editor.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

### Customized UIs with the App editor

Windmill provides a WYSIWYG app editor. It allows you to build your own UI with drag-and-drop components and to connect your data to scripts and flows in minutes.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/app_editor_fast.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="App editor"
		color="orange"
		description="Detailed section on Windmill's App editor."
		href="/docs/apps/app_editor"
	/>
</div>

You can also [automatically generate](./meta-6_auto_generated_uis-index.md) a dedicated app to execute your script.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/cowsay_app.mp4"
/>

### Trigger from flows

Flows are basically sequences of scripts that execute one after another or [in parallel](./concept-flows-13-flow-branches.md#branch-all).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/crm-automation-execution.mp4"
/>

<br />


Flows themselves can be triggered from other flows. This is called inner flows.

![Inner flows](./inner_flow.png "Inner flows")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Flow editor"
		color="teal"
		description="Detailed section on Windmill's Flow editor."
		href="/docs/flows/flow_editor"
	/>
</div>

### Workflows as code

Flows are not the only way to write distributed programs that execute distinct jobs. Another approach is to write a program that defines the jobs and their dependencies, and then execute that program within a [Python](./meta-2_python_quickstart-index.md) or [TypeScript](./meta-1_typescript_quickstart-index.md) script. This is known as workflows as code.

![Flow as code](../../core_concepts/31_workflows_as_code/python_editor.png)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workflows as code"
		description="Automate tasks and their flow with only code."
		href="/docs/core_concepts/workflows_as_code"
	/>
</div>

### Schedule

Windmill allows you to schedule scripts using a user-friendly interface and control panel, **similar to [cron](https://crontab.guru/)** but with more features.

You can create schedules by specifying a script or flow, its arguments, and a CRON expression to control the execution frequency, ensuring that your tasks run automatically at the desired intervals.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schedule-cron-menu.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Schedules"
		description="Scheduling allows you to define schedules for Scripts and Flows, automatically running them at set frequencies."
		href="/docs/core_concepts/scheduling"
	/>
</div>

### CLI (Command-line interface)

The `wmill` CLI allows you to interact with Windmill instances right from your terminal.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/TXtmLrToxoI"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Command-line interface"
		description="Interact with Windmill instances right from your terminal."
		href="/docs/advanced/cli"
	/>
</div>

### Trigger from API

Windmill provides a RESTful API that allows you to interact with your Windmill instance programmatically.

In particular, the operation [run script by path](https://app.windmill.dev/openapi.html#/operations/runScriptByPath) is designed to trigger a script by its path, passing the required arguments.

It's an efficient way to run a script from another script.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="OpenAPI"
		description="Interact with Windmill."
		href="https://app.windmill.dev/openapi.html"
	/>
</div>


### Trigger from LLM clients with MCP

Windmill supports the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) to trigger scripts and flows from LLM clients. All you need is an MCP URL to connect your LLM client to Windmill.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="MCP"
		description="Trigger scripts and flows from LLM clients with MCP."
		href="/docs/core_concepts/mcp"
	/>
</div>
