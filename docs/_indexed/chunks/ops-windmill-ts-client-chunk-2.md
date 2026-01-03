---
doc_id: ops/windmill/ts-client
chunk_id: ops/windmill/ts-client#chunk-2
heading_path: ["TypeScript client", "Installation"]
chunk_type: code
tokens: 111
summary: "Installation"
---

## Installation

To use the TypeScript client, you need to have Deno or Bun installed on your system. Follow the installation instructions from the official [Deno documentation](https://deno.land/manual@v1.36.1/getting_started/installation) or [Bun documentation](https://bun.sh/docs/installation).

Once Deno/Bun is installed, you can import the `windmill` module directly from the Deno third-party module registry.

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.318.0';
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
```

</TabItem>
</Tabs>
