---
doc_id: meta/6_flows_quickstart/index
chunk_id: meta/6_flows_quickstart/index#chunk-2
heading_path: ["Flows quickstart", "Settings"]
chunk_type: prose
tokens: 547
summary: "Settings"
---

## Settings

### Metadata

The first thing you'll see is the [Settings](./tutorial-flows-3-editor-components.md#settings) menu. From there, you can set the [permissions](./meta-16_roles_and_permissions-index.md) of the workflow: User (by default, you), and [Folder](./meta-8_groups_and_folders-index.md) (referring to read and/or write groups).

Also, you can give succinctly a Name, a Summary and a Description to your flow. Those are supposed to be explicit, we recommend you to give context and make them as self-explanatory as possible.

![Flows metadata](./flows_metadata.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
		color="teal"
	/>
</div>

### Schedule

On another tab, you can configure a [Schedule](./meta-1_scheduling-index.md) to trigger your flow. Flows can be [triggered](./meta-8_triggers-index.md) by any schedules, their [webhooks](./meta-4_webhooks-index.md) or their UI but they only have only one primary schedule with which they share the same path. This menu is where you set the primary schedule with CRON. The default schedule is none.

![Flows schedule](./flows_schedule.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Schedules"
		description="Scheduling allows you to define schedules for Scripts and Flows, automatically running them at set frequencies."
		href="/docs/core_concepts/scheduling"
	/>
</div>

### Shared directory

Last tab of the settings menu is the [Shared Directory](./concept-11_persistent_storage-within-windmill.md#shared-directory).

By default, flows on Windmill are based on a [result basis](#how-data-is-exchanged-between-steps). A step will take as inputs the results of previous steps. And this works fine for lightweight automation.

For heavier ETLs and any output that is not suitable for JSON, you might want to use the `Shared Directory` to share data between steps. Steps share a folder at `./shared` in which they can store heavier data and pass them to the next step.

Get more details on the [Persistent storage & databases dedicated page](./meta-11_persistent_storage-index.md).

![Flows shared directory](./flows_shared_directory.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Persistent storage & databases"
		description="Ensure that your data is safely stored and easily accessible whenever required."
		href="/docs/core_concepts/persistent_storage"
	/>
</div>

### Worker group

When a [worker group](./meta-9_worker_groups-index.md) is defined at the flow level, any steps inside the flow will run on that worker group, regardless of the steps' worker group. If no worker group is defined, the flow controls will be executed by the default worker group 'flow' and the steps will be executed in their respective worker group.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
</div>

You can always go back to this menu by clicking on `Settings` on the top lef, or on the name of the flow on the [toolbar](./tutorial-flows-3-editor-components.md#toolbar).
