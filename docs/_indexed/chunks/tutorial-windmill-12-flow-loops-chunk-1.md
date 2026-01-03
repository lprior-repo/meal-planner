---
doc_id: tutorial/windmill/12-flow-loops
chunk_id: tutorial/windmill/12-flow-loops#chunk-1
heading_path: ["For loops"]
chunk_type: prose
tokens: 165
summary: "<!--"
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
