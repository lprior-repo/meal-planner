---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-8
heading_path: ["JSON schema and parsing", "If you have another dynamic select input named \"category\""]
chunk_type: prose
tokens: 154
summary: "If you have another dynamic select input named \"category\""
---

## If you have another dynamic select input named "category"
def category(department: str):
  if department == "engineering":
    return [
      {"value": "frontend", "label": "Frontend"},
      {"value": "backend", "label": "Backend"}
    ]
  return [
    {"value": "general", "label": "General"}
  ]
```

</TabItem>
</Tabs>

### How dynamic select works

The select options recompute dynamically based on other input arguments.

You can implement custom filtering and sorting logic within your function. In the examples above in the foo function, when `x` equals "bar" or `text` equals "42", the options are filtered to show only one option.

#### Dynamic select in scripts

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/dynamic_select_script.mp4"
/>

#### Dynamic select in flows

<video
	className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/dynamic_select_flow.mp4"
/>
