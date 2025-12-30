---
id: meta/6_flows_quickstart/index
title: "Flows quickstart"
category: meta
tags: ["6_flows_quickstart", "meta", "flows"]
---

import DocCard from '@site/src/components/DocCard';

# Flows quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

The present document will introduce you to [Flows](./tutorial-flows-1-flow-editor.md) and how to build your first one.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/yE-eDNWTj3g"
	title="Flows quickstart"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

> [Here](https://hub.windmill.dev/flows/43/) is an example of a simple flow built with Windmill.

<br />

Have in mind that in Windmill, Scripts are at the basis of Flows and Apps. To sum up roughly, workflows are state machines [represented as DAGs](./tutorial-flows-16-architecture.md) (Directed Acyclic Graphs) to compose scripts together. To learn more about scripts, check the [Script quickstart](./meta-0_scripts_quickstart-index.md). You will not necessarily have to re-build each script as you can reuse them from your workspace or from the [Hub](https://hub.windmill.dev/).

Those workflows can run for-loops, branches (parralellizable) suspend themselves until a timeout or receiving events such as webhooks or approvals. They can be scheduled very frequently and check for new external items to process (what we call "Trigger" script).

The result of a flow is the result of the last step executed, unless [error](./concept-flows-8-error-handling.md) was returned before or [Early return](./ops-flows-19-early-return.md) is set.

The overhead and coldstart between each step is about 20ms, which is [faster than any other orchestration engine](/blog/launch-week-1/fastest-workflow-engine), by a large margin.

To create your first workflow, you could also pick one from our [Hub](https://hub.windmill.dev/flows) and fork it. Here, we're going to build our own flow from scratch, step by step.

From [Windmill](./meta-00_how_to_use_windmill-index.md), click on `+ Flow`, and let's get started!

:::tip

Follow our [detailed section](./tutorial-flows-1-flow-editor.md) on the Flow editor for more information.

:::

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

## How data is exchanged between steps

Flows on Windmill are generic and reusable, they therefore expose inputs. Input and outputs are piped together.

Inputs are either:

- [Static](./tutorial-flows-3-editor-components.md#static-inputs): you can find them on top of the side menu. This tab centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly.
- [Dynamically linked to others](./tutorial-flows-16-architecture.md): with [JSON objects](./meta-13_json_schema_and_parsing-index.md) as result that allow to refer to the output of any step.
  You can refer to the result of any step:
  - using the id associated with the step
  - clicking on the plug logo that will let you pick flow inputs or previous steps' results (after testing flow or step).

![Static & Dynamic Inputs](./static_and_dynamic_inputs.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Architecture and data exchange"
		description="A workflow is a JSON serializable value in the OpenFlow format."
		href="/docs/flows/architecture"
	/>
</div>

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

## Triggers

There are several ways to trigger a flow with Windmill.

1. The most direct one is from the [autogenerated UI provided by Windmill](./meta-6_auto_generated_uis-index.md). It is the one you will see from the flow editor.
2. A similar but more customized way is to use Windmill Apps using the [App editor](./meta-7_apps_quickstart-index.md).
3. We saw above that you can trigger flows using [schedules](./meta-1_scheduling-index.md) that you can check from the [Runs](./meta-5_monitor_past_and_future_runs-index.md) page. One special way to use scheduling is to combine it with [trigger scripts](./concept-flows-10-flow-trigger.md).
4. [Execute flows from the CLI](./meta-3_cli-index.md) to trigger your flows from your terminal.
5. [Trigger the flow from another flow](./meta-8_triggers-index.md#trigger-from-flows).
6. Using [trigger scripts](./concept-flows-10-flow-trigger.md) to trigger only if a condition has been met.
7. [Webhooks](./meta-4_webhooks-index.md). Each Flow created in the app gets autogenerated webhooks. You can see them once you flow is saved. You can even [trigger flows without leaving Slack](/blog/handler-slack-commands)!

You can test your triggers in test mode:

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/nI3P3q4Okx8"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Triggering flows"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

## Test your flow

You don't have to explore all Flow editor possibilities at once. At each step, test what you're building to keep control on your wonder. You can also test up to a certain step by clicking on an action (x) and then on `Test up to x`.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	src="/videos/test_flow.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Testing flows"
		description="Iterate quickly and get control on your flow testing."
		href="/docs/flows/test_flows"
	/>
</div>

When you're done, [deploy](./meta-0_draft_and_deploy-index.md) your flow, schedule it, [create and app from it](./meta-6_auto_generated_uis-index.md), or even [publish it to Hub](../../misc/1_share_on_hub/index.md).

Follow our [detailed section](./tutorial-flows-1-flow-editor.md) on the Flow editor for more information.

## Flow as Code

Flows are not the only way to write distributed programs that execute distinct jobs. Another approach is to write a program that defines the jobs and their dependencies, and then execute that program within a [Python](./meta-2_python_quickstart-index.md) or [TypeScript](./meta-1_typescript_quickstart-index.md) script. This is known as workflows as code.

![Flow as code](../../core_concepts/31_workflows_as_code/python_editor.png)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workflows as code"
		description="Automate tasks and their flow with only code."
		href="/docs/core_concepts/workflows_as_code"
	/>
</div>


## See Also

- [Flows](../../flows/1_flow_editor.mdx)
- [represented as DAGs](../../flows/16_architecture.mdx)
- [Script quickstart](../0_scripts_quickstart/index.mdx)
- [error](../../flows/8_error_handling.mdx)
- [Early return](../../flows/19_early_return.mdx)
