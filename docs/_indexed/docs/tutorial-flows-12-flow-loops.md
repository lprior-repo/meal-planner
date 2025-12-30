---
id: tutorial/flows/12-flow-loops
title: "For loops"
category: tutorial
tags: ["beginner", "flows", "tutorial", "for"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>For Loops</title>
  <description>Iterate over list of items with parallel execution options</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="For loops" level="1"/>
    <section name="Configuration options" level="2"/>
    <section name="Test an iteration" level="2"/>
    <section name="Iterate on steps" level="2"/>
  </sections>
  <features>
    <feature>for_loops</feature>
    <feature>parallel_execution</feature>
    <feature>squash</feature>
    <feature>iterator_expression</feature>
  </features>
  <dependencies>
    <dependency type="feature">flow_branches</dependency>
    <dependency type="feature">early_stop</dependency>
  </dependencies>
  <examples count="3">
    <example>Iterate over cities list</example>
    <example>Parallel item processing</example>
    <example>Squashed iterations on same worker</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,for,loop,iterate,parallel,squash,iterator,expression</tags>
</doc_metadata>
-->

# For loops

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>For Loops</title> <description>Iterate over list of items with parallel e

For loops is a special type of steps that allows you to iterate over a list of items, given by an iterator expression.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    autoPlay
    loop
    controls
    id="main-video"
    src="/videos/flow-loop.mp4"
/>

<br/>

## Configuration options

Clicking on the `For loop` step on the mini-map, it will open the `For loop` step editor.
There are 4 configuration options:

### Iterator expression

The [JavaScript expression](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Expressions_and_Operators) that will be evaluated to get the list of items to iterate over. You can also [connect with a previous result](./tutorial-flows-16-architecture.md) that contain several items, it will iterate over all of them.

It can be pre-filled automatically by [Windmill AI](./meta-22_ai_generation-index.md) from flow context:

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
In addition, for supported languages ([TypeScript](./meta-1_typescript_quickstart-index.md) and [Python](./meta-2_python_quickstart-index.md)), a single runner per step will be used for the entire loop, eliminating cold starts between iterations.
We use the same logic as for [Dedicated workers](./meta-25_dedicated_workers-index.md), but the worker is only "dedicated" to the flow steps for the duration of the loop.

Squashing cannot be used in combination with parallelization.

## Test an iteration

You can get a [test](./meta-23_instant_preview-index.md) of the current iteration by clicking on the `Test an iteration` button.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/test_iteration.mp4"
	description="Test an iteration"
/>

## Iterate on steps

Steps within the flow can use both the iteration index and value. For example with iterator expression `["Paris", "Lausanne", "Lille"]`, for iteration index "1", "Lausanne" is the value.

![Iter value & index](../assets/flows/iter_value_index.png.webp 'Iter value & index')

When a flow has been run or tested, you can inspect the details (arguments, logs, results) of each iteration directly from the graph. The forloop detail page lists every iteration status, even if you have a thousand one without having to load them all.

<video
className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
controls
src="/videos/inspect_iteration.mp4"
/>


## See Also

- [connect with a previous result](./16_architecture.mdx)
- [Windmill AI](../core_concepts/22_ai_generation/index.mdx)
- [For loop step](../assets/flows/flow_for_loop.png.webp 'For loop step')
- [TypeScript](../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx)
- [Python](../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx)
