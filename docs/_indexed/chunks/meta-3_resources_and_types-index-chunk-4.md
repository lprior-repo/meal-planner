---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-4
heading_path: ["Resources and resource types", "States"]
chunk_type: code
tokens: 1030
summary: "States"
---

## States

States are used by scripts to keep data persistent between runs of the same script by the same trigger (schedule or user).

In Windmill, states are considered as resources (rich objects in JSON), but they are excluded from the Workspace tab for clarity.
They are displayed on the Resources menu, under a dedicated tab.

A state is an object stored as a resource of the resource type `state` which is meant to persist across distinct executions of the same script.

```py
import requests
from wmill import set_state, get_state

def main():
	# Get temperature from last execution
    last_temperature = get_state()

    # Fetch the temperature in Paris from wttr.in
    response = requests.get("http://wttr.in/Paris?format=%t")

    new_temperature = response.text.strip("°F")

	# Set current temperature to state
    set_state(new_temperature)

    # Compare last_temperature and new_temperature
    if last_temperature < new_temperature:
        return "The temperature has increased."
    elif last_temperature > new_temperature:
        return "The temperature has decreased."
    else:
        return "The temperature has remained the same."
```

States are what enable Flows to watch for changes in most event watching scenarios ([trigger scripts](./concept-flows-10-flow-trigger.md)). The pattern is as follows:

- Retrieve the last state or, if undefined, assume it is the first execution.
- Retrieve the current state in the external system you are watching, e.g. the
  list of users having starred your repo or the maximum ID of posts on Hacker News.
- Calculate the difference between the current state and the last internal
  state. This difference is what you will want to act upon.
- Set the new state as the current state so that you do not process the
  elements you just processed.
- Return the differences calculated previously so that you can process them in
  the next steps. You will likely want to [forloop](./tutorial-flows-12-flow-loops.md) over the items and trigger
  one Flow per item. This is exactly the pattern used when your Flow is in the
  mode of "Watching changes regularly".

The convenience functions do this are:

_TypeScript_

- `getState()` which retrieves an object of any type (internally a simple
  Resource) at a path determined by `getStatePath`, which is unique to the user
  currently executing the Script, the Flow in which it is currently getting
  called in - if any - and the path of the Script.
- `setState(value: any)` which sets the new state.

> Please note it requires [importing](./meta-6_imports-index.md) the wmill client library from Deno/Bun.

<br />

_Python_

- `get_state()` which retrieves an object of any type (internally a simple
  Resource) at a path determined by `get_state_path`, which is unique to the user
  currently executing the Script, the Flow in which it is currently getting
  called in - if any - and the path of the Script.
- `set_state(value: Any)` which sets the new state.

> Please note it requires [importing](./meta-6_imports-index.md) the wmill client library from Python.

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Persistent storage & databases"
		description="Ensure that your data is safely stored and easily accessible whenever required."
		href="/docs/core_concepts/persistent_storage"
	/>
</div>

### States path

States are stored in a [path](./meta-16_roles_and_permissions-index.md#path) that is unique to the [script](./meta-script_editor-index.md), script within a [flow](./tutorial-flows-1-flow-editor.md) or [schedule](./meta-1_scheduling-index.md). The state path [is defined](https://github.com/windmill-labs/windmill/blob/19547e90c681db1566559c31a508eb093eb05968/backend/windmill-common/src/variables.rs#L150) as:

```rust
    let state_path = {
        let trigger = if schedule_path.is_some() {
            username.to_string()
        } else {
            "user".to_string()
        };

        if let Some(flow_path) = flow_path.clone() {
            format!(
                "{flow_path}/{}_{trigger}",
                step_id.clone().unwrap_or_else(|| "nostep".to_string())
            )
        } else if let Some(script_path) = path.clone() {
            let script_path = if script_path.ends_with("/") {
                "noname".to_string()
            } else {
                script_path
            };
            format!("{script_path}/{trigger}")
        } else {
            format!("u/{username}/tmp_state")
        }
    };
```

For example, if a script using states is used within a flow that is scheduled, the state will take a new path as: `folder/flow_path/script_path/schedule_path`, or more concretely: `u/username/u/username/flow_name/u/username/script_name/u/username/schedule_name`.

### Custom flow states

Custom flow states are a way to store data across steps in a [flow](./tutorial-flows-1-flow-editor.md). You can set and retrieve a value given a key from any step of flow and it will be available from within the flow globally. That state will be stored in the flow state itself and thus has the same lifetime as the flow [job](./meta-20_jobs-index.md) itself.

It's a powerful escape hatch when [passing data as output/input](./tutorial-flows-16-architecture.md) is not feasible and using [getResource/setResource](#fetching-them-from-within-a-script-by-using-the-wmill-client-in-the-respective-language) has the issue of cluttering the workspace and inconvenient UX.

**Important note:** Don't store large content in flow user state. For files, store them on [S3](./meta-38_object_storage_in_windmill-index.md) and store the path in flow user state.

<Tabs className="unique-tabs">
<TabItem value="TypeScript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import * as wmill from 'windmill-client@1.297.0';

export async function main(x: string) {
	// Set flow user state
	await wmill.setFlowUserState('FOO', 42);

	// Get flow user state
	return await wmill.getFlowUserState('FOO');
}
```

</TabItem>
<TabItem value="Python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
#extra_requirements:
#wmill==1.297.0

def main(x: str):
    # Set flow user state
    wmill.set_flow_user_state("foobar", 43)

    # Get flow user state
    return wmill.get_flow_user_state("foobar")
```

</TabItem>
<TabItem value="Bash" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
