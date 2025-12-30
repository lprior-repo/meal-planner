---
doc_id: meta/47_environment_variables/index
chunk_id: meta/47_environment_variables/index#chunk-4
heading_path: ["Environment variables", "Custom environment variables"]
chunk_type: prose
tokens: 153
summary: "Custom environment variables"
---

## Custom environment variables

In a self-hosted environment, Windmill allows you to set custom environment variables for your scripts. This feature is useful when a script needs an environment variable prior to the main function executing itself. For instance, some libraries in Go do some setup in the 'init' function that depends on environment variables.

To add a custom environment variable to a script in Windmill, you should follow this format: `<KEY>=<VALUE>`. Where `<KEY>` is the name of the environment variable and `<VALUE>` is the corresponding value of the environment variable.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Custom environment variables"
		description="In a self-hosted environment, Windmill allows you to set custom environment variables for your scripts."
		href="/docs/script_editor/custom_environment_variables"
	/>
</div>
