---
doc_id: meta/6_flows_quickstart/index
chunk_id: meta/6_flows_quickstart/index#chunk-4
heading_path: ["Flows quickstart", "Flow editor"]
chunk_type: prose
tokens: 609
summary: "Flow editor"
---

## Flow editor

On the left of the editor, you'll find a graphical view of the flow. From there you can architecture your flow and take action at each step.

![Flow editor menu](./flow_editor_menu.png.webp)

:::tip Pro tips
Keep your flows organized and documented with [sticky notes](./concept-flows-24-sticky-notes.md)! Add free notes anywhere on the canvas for comments and TODOs, or create group notes to explain complex workflow sections to your team.
:::

There are four kinds of scripts: [Action](./tutorial-flows-3-editor-components.md#flow-actions), [Trigger](./concept-flows-10-flow-trigger.md), [Approval](./tutorial-flows-11-flow-approval.md) and [Error handler](./tutorial-flows-7-flow-error-handler.md). You can sequence them how you want. Action is the default script type.

Each script can be called from Workspace or [Hub](https://hub.windmill.dev/), you can also decide to write them inline.

![Import or write scripts](./import_or_write_scripts.png.webp)

<br />

Your flow can be deepened with [additional features](./tutorial-flows-1-flow-editor.md), below are some major ones.

### For loops

[For loops](./tutorial-flows-12-flow-loops.md) are a special type of steps that allows you to iterate over a list of items, given by an iterator expression.

![Flows For loops](./for_loops.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="For loops"
		description="Iterate a series of tasks."
		href="/docs/flows/flow_loops"
	/>
</div>

### While loops

While loops execute a sequence of code indefinitely until the user cancels or a step set to [Early stop](./concept-flows-2-early-stop.md) stops.

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/while_early_stop.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="While loops"
		description="While loops execute a sequence of code indefinitely until the user cancels or a step set to Early stop stops."
		href="/docs/flows/while_loops"
	/>
</div>

### Branching

[Branches](./concept-flows-13-flow-branches.md) build branching logic to create and manage complex workflows based on conditions. There are two of them:

- [Branch one](./concept-flows-13-flow-branches.md#branch-one): allows you to execute a branch if a condition is true.
- [Branch all](./concept-flows-13-flow-branches.md#branch-all): allows you to execute all the branches in parallel, as if each branch is a flow.

![Flow branching](flow_branches.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Branches"
		description="Split the execution of the flow based on a condition."
		href="/docs/flows/flow_branches"
	/>
</div>

### Retries

At each step, Windmill allows you to [customize the number of retries](./ops-flows-14-retries.md) by going on the `Advanced` tabs of the individual script. If defined, upon error this step will be retried with a delay and a maximum number of attempts.

![Flows retries](./flows_retries.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Retries"
		description="Re-try a step in case of error."
		href="/docs/flows/retries"
	/>
</div>

### Suspend/Approval Step

At each step you can add [Approval scripts](./tutorial-flows-11-flow-approval.md) to manage security and control over your flows.

Request approvals can be sent by email, Slack, anything. Then you can automatically resume workflows with secret webhooks after the approval steps.

![Approval step diagram](../../assets/flows/approval_diagram.png 'Approval step diagram')

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Suspend & Approval / Prompts"
		description="Suspend a flow until specific event(s) are received, such as approvals or cancellations."
		href="/docs/flows/flow_approval"
	/>
</div>

You can find all the flows' features in their [dedicated section](./tutorial-flows-1-flow-editor.md).
