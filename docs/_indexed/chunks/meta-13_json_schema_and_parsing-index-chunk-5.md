---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-5
heading_path: ["JSON schema and parsing", "oneOf"]
chunk_type: code
tokens: 197
summary: "oneOf"
---

## oneOf

`oneOf` is a type that can be used to have the user pick between two objects through [auto-generated UI](./meta-6_auto_generated_uis-index.md). Within a [TypeScript](./meta-1_typescript_quickstart-index.md), it can be used with the following syntax:

```ts
example_oneof: { label: "Option 1", attribute: string } | { label: "Option 2", other_attribute: string }
```

And the auto-generated UI will render:

![oneOf Script](./one_of_script.png 'oneOf Script')

For flows, `oneOf` can be added as a [flow input](./tutorial-flows-3-editor-components.md#flow-inputs).

![oneOf Flow](./one_of_flow.png 'oneOf Flow')

The result of the user's selection will be the selected object. With the example above if user picks Option 2 and enters a custom value:

```json
{
    "label": "Option 2",
    "other_attribute": "Value that the user entered"
}
```

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/oneof.mp4"
/>

<br />

`oneOf` input can also be filled with [CLI](./meta-3_cli-index.md) or [webhooks](./meta-4_webhooks-index.md), for example with `wmill` CLI:

```bash
wmill script run u/user/path -d '{"example_oneof":{"label":"Option 2","attribute":"Value that the user entered"}}'
```
