---
id: tutorial/flows/16-architecture
title: "Architecture and data exchange"
category: tutorial
tags: ["flows", "tutorial", "beginner", "architecture"]
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Architecture and data exchange

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In Windmill, a workflow is a JSON serializable value in the [OpenFlow](./meta-openflow-index.md) format that consists of an input spec (similar to [Scripts](./meta-0_scripts_quickstart-index.md)), and a linear sequence of steps, also referred to as modules. Each step consists of either:

1. Reference to a Script from the [Hub](https://hub.windmill.dev/).
2. Reference to a Script in your [workspace](./meta-16_roles_and_permissions-index.md#workspace).
3. Inlined Script in [TypeScript](./meta-1_typescript_quickstart-index.md) (Deno), [Python](./meta-2_python_quickstart-index.md), [Go](./meta-3_go_quickstart-index.md), [Bash](./meta-3_go_quickstart-index.md), [SQL](./meta-5_sql_quickstart-index.md) or [non-supported languages](./meta-7_docker-index.md).
4. [Trigger scripts](./concept-flows-10-flow-trigger.md) which are a kind of Scripts that are meant to be first step of a scheduled Flow, that watch for external events and early exit the Flow if there is no new events.
5. [For loop](./tutorial-flows-12-flow-loops.md) that iterates over elements and triggers the execution of an embedded flow for each element. The list is calculated dynamically as an [input transform](#input-transform).
6. [Branch](./concept-flows-13-flow-branches.md#branch-one) to the first subflow that has a truthy predicate (evaluated in-order).
7. [Branches to all](./concept-flows-13-flow-branches.md#branch-all) subflows and collect the results of each branch into an array.
8. [Approval/Suspend steps](./tutorial-flows-11-flow-approval.md) which suspend the flow at no cost until it is resumed by getting an approval/resume signal.
9. Inner flows.

![Flow architecture](../assets/flows/flow_architecture.png.webp 'Flow architecture')

## Input transform

With the mechanism of input transforms, the input of any step can be the output of any previous step, hence every Flow is actually a [Directed Acyclic Graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph) rather than simple sequences. You can refer to the result of any step using its ID.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	id="main-video"
	src="/videos/flow-sequence.mp4"
/>

<br />

Every step has an input transform that maps from:

- the Flow input
- any step's result, not only the previous step's result
- [Resource](./meta-3_resources_and_types-index.md)/[Variable](./meta-2_variables_and_secrets-index.md).

to the different parameters of this specific step.

It does that using a JavaScript expression that operates in a more restricted
setting. That JavaScript is using a restricted subset of the standard library
and a few more functions which are the following:

- `flow_input`: the dict/object containing the different parameters of the Flow
  itself.
- `results.{id}`: the result of the step with given ID.
- `resource(path)`: the Resource at path.
- `variable(path)`: the Variable at path.

Using JavaScript in this manner, for every parameter, is extremely flexible and
allows Windmill to be extremely generic in the kind of modules it runs.

### Connecting flow steps

For each field, one has the option to write the JavaScript directly or to use
the quick connect button if the field map one to one with a field of the
`flow_input`, a field of the `previous_result` or of any steps.

From the editor, you can directly get:

- [Static inputs](./tutorial-flows-3-editor-components.md#static-inputs): you can find them on top of the side menu. This tab centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly.
- Dynamic inputs:
  - using the id associated with the step
  - clicking on the plug logo that will let you pick flow inputs or previous steps' results (after testing flow or step).

![Static & Dynamic Inputs](../getting_started/6_flows_quickstart/static_and_dynamic_inputs.png.webp)

You can connect step inputs automatically using [Windmill AI](./meta-22_ai_generation-index.md).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/step_input_copilot.mp4"
/>

## Custom flow states

A [state](./meta-3_resources_and_types-index.md#states) is an object stored as a [resource](./meta-3_resources_and_types-index.md) of the resource type `state` which is meant to persist across distinct
executions of the same Script. This is what enables Flows to watch for changes in most [event-watching scenarios](./concept-flows-10-flow-trigger.md).

Custom flow states are a way to store data across steps in a flow. You can set and retrieve a value given a key from any step of flow and it will be available from within the flow globally. That state will be stored in the flow state itself and thus has the same lifetime as the flow [job](./meta-20_jobs-index.md) itself.

It's a powerful escape hatch when passing data as output/input is not feasible and using [getResource/setResource](./meta-3_resources_and_types-index.md#fetching-them-from-within-a-script-by-using-the-wmill-client-in-the-respective-language) has the issue of cluttering the workspace and inconvenient UX.

<Tabs className="unique-tabs">
<TabItem value="TypeScript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import * as wmill from "windmill-client@1.297.0"

export async function main(x: string) {
  await wmill.setFlowUserState("FOO", 42)
  return await wmill.getFlowUserState("FOO")

}
```

</TabItem>
<TabItem value="Python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
#extra_requirements:
#wmill==1.297.0

def main(x: str):
    wmill.set_flow_user_state("foobar", 43)
    return wmill.get_flow_user_state("foobar")
```

</TabItem>
</Tabs>

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_state.mp4"
/>

<br/>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Custom flow states"
		description="You can set and retrieve a value given a key from any step of flow and it will be available from within the flow globally."
		href="/docs/core_concepts/resources_and_types#custom-flow-states"
		color="teal"
	/>
</div>

## Shared directory

By default, flows on Windmill are based on a result basis (see above). A step will take as input the results of previous steps. And this works fine for lightweight automation.

For heavier ETLs and any output that is not suitable for JSON, you might want to use the `Shared Directory` to share data between steps. Steps share a folder at `./shared` in which they can store heavier data and pass them to the next step.

Get more details on the [Persistent storage & databases dedicated page](./meta-11_persistent_storage-index.md).

![Flows shared directory](../getting_started/6_flows_quickstart/flows_shared_directory.png.webp)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Persistent storage & databases"
		description="Ensure that your data is safely stored and easily accessible whenever required."
		href="/docs/core_concepts/persistent_storage"
	/>
</div>

## See Also

- [OpenFlow](../openflow/index.mdx)
- [Scripts](../getting_started/0_scripts_quickstart/index.mdx)
- [workspace](../core_concepts/16_roles_and_permissions/index.mdx#workspace)
- [TypeScript](../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx)
- [Python](../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx)
