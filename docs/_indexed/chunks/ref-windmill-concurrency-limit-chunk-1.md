---
doc_id: ref/windmill/concurrency-limit
chunk_id: ref/windmill/concurrency-limit#chunk-1
heading_path: ["Concurrency limits"]
chunk_type: prose
tokens: 279
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>windmill</category>
  <title>Concurrency limits</title>
  <description>The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, e</description>
  <created_at>2026-01-02T19:55:28.161293</created_at>
  <updated_at>2026-01-02T19:55:28.161293</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Max number of executions within the time window" level="2"/>
    <section name="Time window in seconds" level="2"/>
    <section name="Custom concurrency key" level="2"/>
  </sections>
  <features>
    <feature>custom_concurrency_key</feature>
    <feature>time_window_in_seconds</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-76</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../assets/code_editor/concurrency_limit.png</entity>
    <entity relationship="uses">/pricing</entity>
    <entity relationship="uses">../core_concepts/5_monitor_past_and_future_runs/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,api,reference,concurrency</tags>
</doc_metadata>
-->

# Concurrency limits

> **Context**: The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prev

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

![Concurrency limit](../assets/code_editor/concurrency_limit.png)

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:
