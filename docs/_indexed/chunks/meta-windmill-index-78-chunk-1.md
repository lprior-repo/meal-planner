---
doc_id: meta/windmill/index-78
chunk_id: meta/windmill/index-78#chunk-1
heading_path: ["Multiplayer"]
chunk_type: code
tokens: 611
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>windmill</category>
  <title>Script editor</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:28.165823</created_at>
  <updated_at>2026-01-02T19:55:28.165823</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Script editor features" level="2"/>
    <section name="Workflows as code" level="2"/>
    <section name="Code editor features" level="2"/>
  </sections>
  <features>
    <feature>code_editor_features</feature>
    <feature>js_main</feature>
    <feature>python_main</feature>
    <feature>script_editor_features</feature>
    <feature>workflows_as_code</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-97</dependency>
    <dependency type="feature">meta/windmill/index-99</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-89</dependency>
    <dependency type="feature">meta/windmill/index-90</dependency>
    <dependency type="feature">meta/windmill/index-91</dependency>
    <dependency type="feature">meta/windmill/index-27</dependency>
    <dependency type="feature">meta/windmill/index-17</dependency>
    <dependency type="feature">tutorial/windmill/1-flow-editor</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../getting_started/6_flows_quickstart/index.mdx</entity>
    <entity relationship="uses">../apps/3_app-runnable-panel.mdx</entity>
    <entity relationship="uses">../getting_started/8_triggers/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/4_bash_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/5_sql_quickstart/index.mdx</entity>
    <entity relationship="uses">../core_concepts/13_json_schema_and_parsing/index.mdx</entity>
    <entity relationship="uses">../code_editor/index.mdx</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,meta,advanced,script</tags>
</doc_metadata>
-->

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
