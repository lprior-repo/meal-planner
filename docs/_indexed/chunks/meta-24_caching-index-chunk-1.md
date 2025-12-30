---
doc_id: meta/24_caching/index
chunk_id: meta/24_caching/index#chunk-1
heading_path: ["Caching"]
chunk_type: prose
tokens: 244
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Caching</title>
  <description>Store results to reduce redundant computations</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Caching" level="1"/>
    <section name="Cache scripts" level="2"/>
    <section name="Cache flows" level="2"/>
    <section name="Cache flow steps" level="2"/>
  </sections>
  <features>
    <feature>caching</feature>
    <feature>performance_optimization</feature>
    <feature>script_caching</feature>
    <feature>flow_caching</feature>
    <feature>step_caching</feature>
  </features>
  <dependencies>
    <dependency type="feature">step_mocking</dependency>
  </dependencies>
  <examples count="4">
    <example>Cache expensive API calls</example>
    <example>Cache database query results</example>
    <example>Cache flow execution</example>
    <example>Cache inline script results</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,cache,performance,optimization,script,flow,step</tags>
</doc_metadata>
-->

# Caching

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>core_concepts</category> <title>Caching</title> <description>Store results to reduce redundant co

Caching is used to cache the results of a script, flow, flow step or app inline scripts for a specified number of seconds, thereby reducing the need for redundant computations when re-running the same step with identical input.

When you configure caching, Windmill stores the result in a cache for the duration you specify. If the same runnable is re-triggered with the same input within this duration, Windmill instantly retrieves the cached result instead of re-computing it.

This feature can significantly improve the performance of your scripts & flows, especially for steps that are computationally demanding or dependent on external resources, such as APIs or databases.
