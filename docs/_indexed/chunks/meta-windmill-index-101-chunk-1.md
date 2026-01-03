---
doc_id: meta/windmill/index-101
chunk_id: meta/windmill/index-101#chunk-1
heading_path: ["Script editor"]
chunk_type: code
tokens: 478
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Script editor

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In Windmill, Scripts are the basis of all major features (they are the steps of [flows](./meta-windmill-index-97.md), [linked to apps components](../apps/3_app-runnable-panel.mdx), or can be [run as standalone](./meta-windmill-index-99.md)).

A Script can be written in:
[TypeScript (Deno & Bun)](./meta-windmill-index-87.md),
[Python](./meta-windmill-index-88.md),
[Go](./meta-windmill-index-89.md),
[Bash](./meta-windmill-index-90.md) or
[SQL](./meta-windmill-index-91.md). Its
two most important components are the input [JSON Schema](./meta-windmill-index-27.md)
specification and the [code content](../code_editor/index.mdx).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/QRf8C8qF7CY"
	title="Scripts quickstart"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

Python and Go Scripts also have an
auto-generated [lockfile](./meta-windmill-index-17.md) that ensure that executions of the same Script always
use the exact same set of versioned dependencies. To fit Windmill's execution model, the code must always have a
main function, which is its entrypoint when executed as an individual serverless
endpoint or a [Flow](./tutorial-windmill-1-flow-editor.md) module and typed parameters used to infer the script's inputs and [auto-generated UI](./meta-windmill-index-77.md):

<Tabs className="unique-tabs">
<TabItem value="TypeScript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
async function main(param1: string, param2: { nested: string }) {
	...
}
```

</TabItem>
<TabItem value="Python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
def main(param1: str, param2: dict, ...):
	...
```

</TabItem>
<TabItem value="Go" label="Go" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```go
  func main(x string, nested struct{ Foo string \`json:"foo"\` }) (interface{}, error) {
  	...
  }
```

</TabItem>
<TabItem value="Bash" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

There is no main needed for Bash. The body is executed and the args are passed directly.

</TabItem>
</Tabs>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Scripts quickstart"
		description="Start writing scripts in Python, TypeScript, Go, PHP, Bash and Sql."
		href="/docs/getting_started/scripts_quickstart"
	/>
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

For scripts with numerous lines of code (+1,000), we recommend splitting the logic into [Flows](./tutorial-windmill-1-flow-editor.md) or [Sharing common logic](./meta-windmill-index-16.md).
