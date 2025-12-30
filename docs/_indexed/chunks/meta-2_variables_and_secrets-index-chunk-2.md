---
doc_id: meta/2_variables_and_secrets/index
chunk_id: meta/2_variables_and_secrets/index#chunk-2
heading_path: ["Variables and secrets", "User-defined variables"]
chunk_type: code
tokens: 275
summary: "User-defined variables"
---

## User-defined variables

User-defined Variables is essentially a key-value store where every user can
read, set and share values at given keys as long as they have the privilege to
do so.

They are editable in the UI and also readable if they are not
Secret Variables.

Inside the Scripts, one would use the Windmill client to interact with the
user-defined Variables.

<Tabs className="unique-tabs">
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill

wmill.get_variable("u/user/foo")
wmill.set_variable("u/user/foo", value)
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import { getVariable, setVariable } from 'windmill-client';

getVariable('u/user/foo');
setVariable('u/user/foo', value);
```

</TabItem>
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import { getVariable, setVariable } from 'npm:windmill-client@1';

getVariable('u/user/foo');
setVariable('u/user/foo', value);
```

</TabItem>
</Tabs>

Note that there is a similar API for getting and setting [Resources](./meta-3_resources_and_types-index.md)
which are simply Variables that can contain any JSON values, not just a string
and that are labeled with a [Resource Type](./meta-3_resources_and_types-index.md#create-a-resource-type) to be automatically
discriminated in the auto-generated form to be of the proper type (e.g. a
parameter in TypeScript of type `pg: Postgresql` is only going to
offer a selection over the resources of type postgresql in the auto-generated UI).

There is also a concept of [state](./meta-3_resources_and_types-index.md#states) to share values
across script executions.
