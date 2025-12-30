---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-6
heading_path: ["JSON schema and parsing", "Dynamic select"]
chunk_type: code
tokens: 552
summary: "Dynamic select"
---

## Dynamic select

Dynamic select is a helper function that allows you to create a select field with dynamic options that recompute based on other input values. It's available in both [scripts](./meta-script_editor-index.md) and [flows](./tutorial-flows-1-flow-editor.md), but with different implementation requirements.

### Dynamic select in scripts

For scripts, you must export both the string type as `DynSelect_<name>` and the function as `<name>`:

<Tabs className="unique-tabs">
<TabItem value="typescript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
export type DynSelect_foo = string;

export async function foo(x: string, y: number, text: string) {
	if (text === '42') {
		return [{ value: '42', label: 'The answer to the universe' }];
	}
	if (x === 'bar') {
		return [{ value: 'barbar', label: 'barbarbar' }];
	}
	return [
		{ value: '1', label: 'Foo' + x + y },
		{ value: '2', label: 'Bar' },
		{ value: '3', label: 'Foobar' }
	];
}

export async function main(y: number, x: string, xy: DynSelect_foo) {
	console.log(xy);
	return xy;
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
DynSelect_foo = str

def foo(x: str, y: int, text):
  if text == "42":
    return [{"value": "42", "label": "The answer to the universe"}]
  if x == "bar":
    return [{"value": "barbar", "label": "barbarbar"}]
  return [
    { "value": '1', "label": 'Foo' + x + str(y) },
    { "value": '2', "label": 'Bar' },
    { "value": '3', "label": 'Foobar' }
  ]

def main(x: str, y: int, xy: DynSelect_foo):
	print(xy)
	return xy
```

</TabItem>
</Tabs>

### Dynamic select in flows

In flows, dynamic select is only available for flow input steps. You must define one function for each flow input field that is of dynamic select type. The function name must exactly match the name of the flow input field. No export type is required.

<Tabs className="unique-tabs">
<TabItem value="typescript" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
// Function for flow input field named "foo"
async function foo(x: string, y: number, text: string) {
	if (text === '42') {
		return [{ value: '42', label: 'The answer to the universe' }];
	}
	if (x === 'bar') {
		return [{ value: 'barbar', label: 'barbarbar' }];
	}
	return [
		{ value: '1', label: 'Foo' + x + y },
		{ value: '2', label: 'Bar' },
		{ value: '3', label: 'Foobar' }
	];
}

// If you have another dynamic select input named "category"
async function category(department: string) {
	if (department === 'engineering') {
		return [
			{ value: 'frontend', label: 'Frontend' },
			{ value: 'backend', label: 'Backend' }
		];
	}
	return [{ value: 'general', label: 'General' }];
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
