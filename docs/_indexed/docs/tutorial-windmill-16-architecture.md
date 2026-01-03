---
id: tutorial/windmill/16-architecture
title: "Architecture and data exchange"
category: tutorial
tags: ["windmill", "tutorial", "beginner", "architecture"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Architecture and data exchange</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.954715</created_at>
  <updated_at>2026-01-02T19:55:27.954715</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Input transform" level="2"/>
    <section name="Connecting flow steps" level="3"/>
    <section name="Custom flow states" level="2"/>
    <section name="Shared directory" level="2"/>
  </sections>
  <features>
    <feature>connecting_flow_steps</feature>
    <feature>custom_flow_states</feature>
    <feature>input_transform</feature>
    <feature>js_main</feature>
    <feature>python_main</feature>
    <feature>shared_directory</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-100</dependency>
    <dependency type="feature">meta/windmill/index-96</dependency>
    <dependency type="feature">meta/windmill/index-30</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-89</dependency>
    <dependency type="feature">meta/windmill/index-91</dependency>
    <dependency type="feature">meta/windmill/index-18</dependency>
    <dependency type="feature">concept/windmill/10-flow-trigger</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../openflow/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/index.mdx</entity>
    <entity relationship="uses">../core_concepts/16_roles_and_permissions/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/5_sql_quickstart/index.mdx</entity>
    <entity relationship="uses">../advanced/7_docker/index.mdx</entity>
    <entity relationship="uses">./10_flow_trigger.mdx</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,tutorial,beginner,architecture</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Architecture and data exchange

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In Windmill, a workflow is a JSON serializable value in the [OpenFlow](./meta-windmill-index-100.md) format that consists of an input spec (similar to [Scripts](./meta-windmill-index-96.md)), and a linear sequence of steps, also referred to as modules. Each step consists of either:

1. Reference to a Script from the [Hub](https://hub.windmill.dev/).
2. Reference to a Script in your [workspace](./meta-windmill-index-30.md#workspace).
3. Inlined Script in [TypeScript](./meta-windmill-index-87.md) (Deno), [Python](./meta-windmill-index-88.md), [Go](./meta-windmill-index-89.md), [Bash](./meta-windmill-index-89.md), [SQL](./meta-windmill-index-91.md) or [non-supported languages](./meta-windmill-index-18.md).
4. [Trigger scripts](./concept-windmill-10-flow-trigger.md) which are a kind of Scripts that are meant to be first step of a scheduled Flow, that watch for external events and early exit the Flow if there is no new events.
5. [For loop](./tutorial-windmill-12-flow-loops.md) that iterates over elements and triggers the execution of an embedded flow for each element. The list is calculated dynamically as an [input transform](#input-transform).
6. [Branch](./concept-windmill-13-flow-branches.md#branch-one) to the first subflow that has a truthy predicate (evaluated in-order).
7. [Branches to all](./concept-windmill-13-flow-branches.md#branch-all) subflows and collect the results of each branch into an array.
8. [Approval/Suspend steps](./tutorial-windmill-11-flow-approval.md) which suspend the flow at no cost until it is resumed by getting an approval/resume signal.
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
- [Resource](./meta-windmill-index-57.md)/[Variable](./meta-windmill-index-46.md).

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

- [Static inputs](./tutorial-windmill-3-editor-components.md#static-inputs): you can find them on top of the side menu. This tab centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly.
- Dynamic inputs:
  - using the id associated with the step
  - clicking on the plug logo that will let you pick flow inputs or previous steps' results (after testing flow or step).

![Static & Dynamic Inputs](../getting_started/6_flows_quickstart/static_and_dynamic_inputs.png.webp)

You can connect step inputs automatically using [Windmill AI](./meta-windmill-index-37.md).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/step_input_copilot.mp4"
/>

## Custom flow states

A [state](./meta-windmill-index-57.md#states) is an object stored as a [resource](./meta-windmill-index-57.md) of the resource type `state` which is meant to persist across distinct
executions of the same Script. This is what enables Flows to watch for changes in most [event-watching scenarios](./concept-windmill-10-flow-trigger.md).

Custom flow states are a way to store data across steps in a flow. You can set and retrieve a value given a key from any step of flow and it will be available from within the flow globally. That state will be stored in the flow state itself and thus has the same lifetime as the flow [job](./meta-windmill-index-35.md) itself.

It's a powerful escape hatch when passing data as output/input is not feasible and using [getResource/setResource](./meta-windmill-index-57.md#fetching-them-from-within-a-script-by-using-the-wmill-client-in-the-respective-language) has the issue of cluttering the workspace and inconvenient UX.

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

Get more details on the [Persistent storage & databases dedicated page](./meta-windmill-index-25.md).

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
