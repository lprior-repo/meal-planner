---
id: tutorial/windmill/12-flow-loops
title: "For loops"
category: tutorial
tags: ["windmill", "tutorial", "for", "beginner"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>For loops</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;For Loops&lt;/title&gt; &lt;description&gt;Iterate over list of items with parallel execution options&lt;/description&gt; &lt;created_at&gt;2025-12</description>
  <created_at>2026-01-02T19:55:27.944453</created_at>
  <updated_at>2026-01-02T19:55:27.944453</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Configuration options" level="2"/>
    <section name="Iterator expression" level="3"/>
    <section name="Skip failure" level="3"/>
    <section name="Run in parallel" level="3"/>
    <section name="Parallelism" level="3"/>
    <section name="Squash" level="3"/>
    <section name="Test an iteration" level="2"/>
    <section name="Iterate on steps" level="2"/>
  </sections>
  <features>
    <feature>configuration_options</feature>
    <feature>iterate_on_steps</feature>
    <feature>iterator_expression</feature>
    <feature>parallelism</feature>
    <feature>run_in_parallel</feature>
    <feature>skip_failure</feature>
    <feature>squash</feature>
    <feature>test_an_iteration</feature>
  </features>
  <dependencies>
    <dependency type="feature">tutorial/windmill/16-architecture</dependency>
    <dependency type="feature">meta/windmill/index-37</dependency>
    <dependency type="feature">meta/windmill/index-87</dependency>
    <dependency type="feature">meta/windmill/index-88</dependency>
    <dependency type="feature">meta/windmill/index-41</dependency>
    <dependency type="feature">meta/windmill/index-39</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./16_architecture.mdx</entity>
    <entity relationship="uses">../core_concepts/22_ai_generation/index.mdx</entity>
    <entity relationship="uses">../assets/flows/flow_for_loop.png.webp &apos;For loop step&apos;</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx</entity>
    <entity relationship="uses">../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx</entity>
    <entity relationship="uses">../core_concepts/25_dedicated_workers/index.mdx</entity>
    <entity relationship="uses">../core_concepts/23_instant_preview/index.mdx</entity>
    <entity relationship="uses">../assets/flows/iter_value_index.png.webp &apos;Iter value &amp; index&apos;</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,tutorial,for,beginner</tags>
</doc_metadata>
-->

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

## Test an iteration

You can get a [test](./meta-windmill-index-39.md) of the current iteration by clicking on the `Test an iteration` button.

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
