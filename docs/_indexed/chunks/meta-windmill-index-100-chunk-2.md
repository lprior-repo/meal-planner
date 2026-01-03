---
doc_id: meta/windmill/index-100
chunk_id: meta/windmill/index-100#chunk-2
heading_path: ["OpenFlow", "Script editor features"]
chunk_type: prose
tokens: 260
summary: "Script editor features"
---

## Script editor features

The Script editor is made of the following features:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
	<DocCard
		title="Script kind"
		description="You can attach additional functionalities to Scripts by specializing them into specific Script kinds."
		href="/docs/script_editor/script_kinds"
	/>
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
	<DocCard
		title="Versioning"
		description="Scripts, when deployed, can have a parent script identified by its hash."
		href="/docs/core_concepts/versioning#script-versioning"
	/>
	<DocCard
		title="Concurrency limit"
		description="The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows."
		href="/docs/script_editor/concurrency_limit"
	/>
	<DocCard
		title="Running services with perpetual scripts"
		description="Perpetual scripts restart upon ending unless canceled."
		href="/docs/script_editor/perpetual_scripts"
	/>
	<DocCard
		title="Custom environment variables"
		description="In a self-hosted environment, Windmill allows you to set custom environment variables for your scripts."
		href="/docs/script_editor/custom_environment_variables"
	/>
	<DocCard
		title="Multiplayer"
		description="The Multiplayer feature allows you to collaborate with team members on scripts simultaneously."
		href="/docs/script_editor/multiplayer"
	/>
	<DocCard
		title="Run scripts in VS Code"
		description="The Windmill VS Code extension allows you to run your scripts and preview the output within VS Code."
		href="/docs/script_editor/vs_code_scripts"
	/>
</div>
