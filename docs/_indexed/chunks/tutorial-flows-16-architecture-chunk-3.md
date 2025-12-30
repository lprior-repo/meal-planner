---
doc_id: tutorial/flows/16-architecture
chunk_id: tutorial/flows/16-architecture#chunk-3
heading_path: ["Architecture and data exchange", "Custom flow states"]
chunk_type: code
tokens: 302
summary: "Custom flow states"
---

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
