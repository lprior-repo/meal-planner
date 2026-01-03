---
doc_id: concept/windmill/10-flow-trigger
chunk_id: concept/windmill/10-flow-trigger#chunk-1
heading_path: ["Trigger scripts"]
chunk_type: prose
tokens: 243
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Trigger scripts

> **Context**: import DocCard from '@site/src/components/DocCard';

Trigger scripts are designed to pull data from an external source and return all of the new items since the last run, without resorting to external webhooks. A trigger script is intended to be used as scheduled poll with [schedules](./meta-windmill-index-34.md) and [states](./meta-windmill-index-57.md#states) (rich objects in JSON, persistent from one run to another) in order to compare the execution to the previous one and process each new item in a [for loop](./tutorial-windmill-12-flow-loops.md). If there are no new items, the flow will be skipped.

By default, adding a trigger will set the schedule to 15 minutes.

:::info

Check our pages dedicated to [Scheduling](./meta-windmill-index-34.md) and [Triggering flows](./meta-windmill-index-99.md).

:::

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="States"
		description="A state is an object stored as a resource of the resource type `state` which is meant to persist across distinct executions of the same script."
		href="/docs/core_concepts/resources_and_types#states"
		color="teal"
	/>
	<DocCard
		title="Schedules"
		description="Scheduling allows you to define schedules for Scripts and Flows, automatically running them at set frequencies."
		href="/docs/core_concepts/scheduling"
		color="teal"
	/>
	<DocCard
		color="teal"
		title="For loops"
		description="Iterate a series of tasks."
		href="/docs/flows/flow_loops"
	/>
</div>
