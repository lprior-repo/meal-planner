---
doc_id: tutorial/windmill/12-flow-loops
chunk_id: tutorial/windmill/12-flow-loops#chunk-4
heading_path: ["For loops", "Iterate on steps"]
chunk_type: prose
tokens: 122
summary: "Iterate on steps"
---

## Iterate on steps

Steps within the flow can use both the iteration index and value. For example with iterator expression `["Paris", "Lausanne", "Lille"]`, for iteration index "1", "Lausanne" is the value.

![Iter value & index](../assets/flows/iter_value_index.png.webp 'Iter value & index')

When a flow has been run or tested, you can inspect the details (arguments, logs, results) of each iteration directly from the graph. The forloop detail page lists every iteration status, even if you have a thousand one without having to load them all.

<video
className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
controls
src="/videos/inspect_iteration.mp4"
/>
