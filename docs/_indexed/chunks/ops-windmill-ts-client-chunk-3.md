---
doc_id: ops/windmill/ts-client
chunk_id: ops/windmill/ts-client#chunk-3
heading_path: ["TypeScript client", "Usage"]
chunk_type: code
tokens: 167
summary: "Usage"
---

## Usage

The TypeScript client provides several functions that you can use to interact with the Windmill platform. Here's an example of how to use the client to get a resource from Windmill:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.318.0';

export async function main() {
	let x = await wmill.getResource('u/user/name');
}
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client@1.147.3';

export async function main() {
	let x = await wmill.getResource('u/user/name');
}
```

</TabItem>
</Tabs>

In the example above, the `getResource` function is used to retrieve a resource with the path `'u/user/name'` from the Windmill platform. The returned resource can be further processed or used as needed in your application.
