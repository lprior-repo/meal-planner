---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-13
heading_path: ["TypeScript quickstart", "Instant preview & testing"]
chunk_type: code
tokens: 231
summary: "Instant preview & testing"
---

## Instant preview & testing

Look at the UI preview on the right: it was updated to match the input
signature. Run a test (`Ctrl` + `Enter`) to verify everything works.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/auto_g_ui_landing.mp4"
/>

<br />

You can change how the UI behaves by changing the main signature. For example, if you add a default for the `name` argument, the UI won't consider this field as required anymore.

<Tabs className="unique-tabs">
<TabItem value="bash" label="Bash" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
argument_name="${1:-Its default value}"
```

</TabItem>
<TabItem value="powershell" label="PowerShell" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```bash
$argument_name = "Its default value"
```

</TabItem>
<TabItem value="nu" label="Nu" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
def main [ argument_name = "Its default value" ] { }
```

</TabItem>
</Tabs>

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="On top of its integrated editors, Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

Now let's go to the last step: the "Generated UI" settings.
