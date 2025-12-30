---
doc_id: meta/7_docker_quickstart/index
chunk_id: meta/7_docker_quickstart/index#chunk-9
heading_path: ["Docker quickstart", "Settings"]
chunk_type: prose
tokens: 391
summary: "Settings"
---

## Settings

![New script](../../../../static/images/script_languages.png "New script")

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

### Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for Bash](../4_bash_quickstart/editor_bash.png.webp)

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

As we picked `Docker` for this example, Windmill provided some Bash
boilerplate. Let's take a look:

```bash
