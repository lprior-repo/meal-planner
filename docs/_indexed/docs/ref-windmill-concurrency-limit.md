---
id: ref/windmill/concurrency-limit
title: "Concurrency limits"
category: ref
tags: ["windmill", "api", "reference", "concurrency"]
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

## Max number of executions within the time window

The maximum number of executions allowed within the time window. If the number of executions exceeds this limit, the job is queued for execution at the next available optimal slot.

## Time window in seconds

Set in seconds, the time window defines the period within which the maximum number of executions is allowed.

## Custom concurrency key

This parameter is optional. Concurrency keys are global, you can have them be workspace specific using the variable `$workspace`. You can also use an argument's value using `$args[name_of_arg]`.

Jobs can be filtered from the [Runs menu](./meta-windmill-index-76.md) using the Concurrency Key.

## See Also

- [Concurrency limit](../assets/code_editor/concurrency_limit.png)
- [Cloud plans and Pro Enterprise Self-Hosted](/pricing)
- [Runs menu](../core_concepts/5_monitor_past_and_future_runs/index.mdx)
