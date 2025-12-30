---
doc_id: meta/13_java_quickstart/index
chunk_id: meta/13_java_quickstart/index#chunk-2
heading_path: ["Java quickstart", "Settings"]
chunk_type: prose
tokens: 245
summary: "Settings"
---

## Settings

![New script](./java_settings.png "New script")

As part of the [settings](./tutorial-script_editor-settings.md) menu, each script has metadata associated with it, enabling it to be defined and configured in depth.

- **Summary** (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.
- **Path** is the Script's unique identifier that consists of the [script's owner](./meta-16_roles_and_permissions-index.md), and the script's name. The owner can be either a user, or a group ([folder](./meta-8_groups_and_folders-index.md#folders)).
- **Description** is where you can give instructions through the [auto-generated UI](./meta-6_auto_generated_uis-index.md) to users on how to run your Script. It supports markdown.
- **Language** of the script.
- **Script kind**: Action (by default), [Trigger](./concept-flows-10-flow-trigger.md), [Approval](./tutorial-flows-11-flow-approval.md), [Error handler](./tutorial-flows-7-flow-error-handler.md) or [Preprocessor](./meta-43_preprocessors-index.md). This acts as a tag to filter appropriate scripts from the [flow editor](./meta-6_flows_quickstart-index.md).

This menu also has additional settings on [Runtime](./tutorial-script_editor-settings.md#runtime), [Generated UI](#generated-ui) and [Triggers](./tutorial-script_editor-settings.md#triggers).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
</div>

Now click on the code editor on the left side.
