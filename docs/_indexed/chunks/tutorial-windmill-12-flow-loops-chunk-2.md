---
doc_id: tutorial/windmill/12-flow-loops
chunk_id: tutorial/windmill/12-flow-loops#chunk-2
heading_path: ["For loops", "Configuration options"]
chunk_type: prose
tokens: 278
summary: "Configuration options"
---

## Configuration options

Clicking on the `For loop` step on the mini-map, it will open the `For loop` step editor.
There are 4 configuration options:

### Iterator expression

The [JavaScript expression](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Expressions_and_Operators) that will be evaluated to get the list of items to iterate over. You can also [connect with a previous result](./tutorial-windmill-16-architecture.md) that contain several items, it will iterate over all of them.

It can be pre-filled automatically by [Windmill AI](./meta-windmill-index-37.md) from flow context:

<video
className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
controls
src="/videos/iterator_prefill.mp4"
/>

### Skip failure

If set to `true`, the loop will continue to the next item even if the current item failed.

### Run in parallel

Iif set to `true`, all iterations will be run in parallel.

### Parallelism

Assign a maximum number of branches run in parallel to control huge for-loops.

![For loop step](../assets/flows/flow_for_loop.png.webp 'For loop step')

### Squash

If set to `true`, all iterations will be run on the same worker.
In addition, for supported languages ([TypeScript](./meta-windmill-index-87.md) and [Python](./meta-windmill-index-88.md)), a single runner per step will be used for the entire loop, eliminating cold starts between iterations.
We use the same logic as for [Dedicated workers](./meta-windmill-index-41.md), but the worker is only "dedicated" to the flow steps for the duration of the loop.

Squashing cannot be used in combination with parallelization.
