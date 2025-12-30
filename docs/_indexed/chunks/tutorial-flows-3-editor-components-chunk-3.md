---
doc_id: tutorial/flows/3-editor-components
chunk_id: tutorial/flows/3-editor-components#chunk-3
heading_path: ["Flow editor components", "Settings"]
chunk_type: prose
tokens: 367
summary: "Settings"
---

## Settings

Each flow has metadata associated with it, enabling it to be defined and configured in depth.

### Summary

Summary (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.

#### Path

**Path** is the Flow's unique identifier that consists of the [flow's owner](./meta-16_roles_and_permissions-index.md#permissions-and-access-control), and the script's name.
The owner can be either a user, or a group of users ([folder](./meta-8_groups_and_folders-index.md#folders)).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
		color="teal"
	/>
	<DocCard
		title="Groups and folders"
		description="Groups and folders enable efficient permission management by grouping users with similar access levels."
		href="/docs/core_concepts/groups_and_folders"
		color="teal"
	/>
</div>

#### Description

This is where you can give instructions to users on how to run your Flow. It supports markdown.

![Flow Metadata](../assets/flows/flow_settings_metadata.png 'Flow Metadata')

![Flow Metadata Markdown](../assets/flows/flow_settings_metadata_markdown.png 'Flow Metadata Markdown')

### Advanced

![Flow Advanced](../assets/flows/flow_advanced_settings.png 'Flow Advanced')

The advanced section allows to configure the following:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Worker groups and tags"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		color="teal"
		title="Caching"
		description="Caching a flow means caching the results of that flow for a certain duration."
		href="/docs/flows/cache"
	/>
	<DocCard
		color="teal"
		title="Early stop for flow"
		description="Stop early a flow based on a condition."
		href="/docs/flows/early_stop#early-stop-for-flow"
	/>
	<DocCard
		color="teal"
		title="Early return"
		description="Define a node at which the flow will return at for sync endpoints. The rest of the flow will continue asynchronously."
		href="/docs/flows/early_return"
	/>
	<DocCard
		color="teal"
		title="Shared Directory"
		description="The Shared Directory allows steps within a flow to share data by storing it in a designated folder"
		href="/docs/core_concepts/persistent_storage/within_windmill#shared-directory"
	/>
</div>
