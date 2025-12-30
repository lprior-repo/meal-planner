---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-8
heading_path: ["Ruby quickstart", "Instant preview & testing"]
chunk_type: prose
tokens: 148
summary: "Instant preview & testing"
---

## Instant preview & testing

Look at the UI preview on the right: it was updated to match the input
signature. Run a test (`Ctrl` + `Enter`) to verify everything works.

You can change how the UI behaves by changing the main signature. For example,
if you remove the default for the `name` argument, the UI will consider this field
as required.

```ruby
def main(name)
```

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="On top of its integrated editors, Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

Now let's go to the last step: the "Generated UI" settings.
