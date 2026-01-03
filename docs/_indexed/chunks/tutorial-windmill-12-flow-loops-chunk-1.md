---
doc_id: tutorial/windmill/12-flow-loops
chunk_id: tutorial/windmill/12-flow-loops#chunk-1
heading_path: ["For loops"]
chunk_type: prose
tokens: 314
summary: "<!--"
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
