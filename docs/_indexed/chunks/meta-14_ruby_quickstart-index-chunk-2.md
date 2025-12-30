---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-2
heading_path: ["Ruby quickstart", "Settings"]
chunk_type: prose
tokens: 252
summary: "Settings"
---

## Settings

![Ruby Settings](./ruby-settings.png "Ruby Settings")

As part of the [settings](./tutorial-script_editor-settings.md) menu, each script has metadata associated with it, enabling it to be defined and configured in depth.

- **Path** is the Script's unique identifier that consists of the
  [script's owner](./meta-16_roles_and_permissions-index.md), and the script's name.
  The owner can be either a user, or a group ([folder](./meta-8_groups_and_folders-index.md#folders)).
- **Summary** (optional) is a short, human-readable summary of the Script. It
  will be displayed as a title across Windmill. If omitted, the UI will use the `path` by
  default.
- **Language** of the script.
- **Description** is where you can give instructions through the [auto-generated UI](./meta-6_auto_generated_uis-index.md)
  to users on how to run your Script. It supports markdown.
- **Script kind**: Action (by default), [Trigger](./concept-flows-10-flow-trigger.md), [Approval](./tutorial-flows-11-flow-approval.md) or [Error handler](./tutorial-flows-7-flow-error-handler.md). This acts as a tag to filter appropriate scripts from the [flow editor](./meta-6_flows_quickstart-index.md).

This menu also has additional settings on [Runtime](./tutorial-script_editor-settings.md#runtime), [Generated UI](#generated-ui) and [Triggers](./tutorial-script_editor-settings.md#triggers).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
</div>

Now click on the code editor on the left side, and let's build our Hello World!
